#!/bin/bash
#
# Setup script for the eXist-db site platform.
#
# Installs all packages in the correct order and runs the Jinks
# generator for each app. Prevents dependency overwrites by
# installing the patched jinks-templates last.
#
# Prerequisites:
#   - eXist-db running (default: http://localhost:8080)
#   - xst CLI available
#   - All app repos cloned to ~/workspace/
#
# Usage:
#   ./setup.sh                    # full setup
#   ./setup.sh --apps-only        # skip package installs, just run generators
#   ./setup.sh --profile-only     # just upload the Jinks profile
#
set -e

# --- Configuration ---
EXIST_USER="${EXISTDB_USER:-admin}"
EXIST_PASS="${EXISTDB_PASS:-}"
EXIST_SERVER="${EXISTDB_SERVER:-http://localhost:8080}"
XST="xst"
XST_AUTH="EXISTDB_USER=$EXIST_USER EXISTDB_PASS=$EXIST_PASS EXISTDB_SERVER=$EXIST_SERVER"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SCRIPT_DIR")"

# App XAR locations (built artifacts)
JINKS_TEMPLATES_XAR="$WORKSPACE/jinks-templates/build/jinks-templates.xar"
JINKS_XAR="$WORKSPACE/jinks/build/jinks.xar"
SITE_SHELL_XAR="$SCRIPT_DIR/dist/exist-site-shell-0.9.0-SNAPSHOT.xar"
DASHBOARD_XAR="$WORKSPACE/dashboard-next/dist/dashboard-3.0.0-SNAPSHOT.xar"
DOCS_XAR="$WORKSPACE/documentation-next/dist/docs-0.1.0.xar"
NOTEBOOK_XAR="$WORKSPACE/sandbox/dist/notebook-1.0.0-SNAPSHOT.xar"
BLOG_XAR="$WORKSPACE/wiki-next/dist/blog-0.1.0.xar"
MARKDOWN_XAR="$WORKSPACE/exist-markdown/target/exist-markdown-3.0.0.xar"

# Profile source (in this repo)
PROFILE_DIR="$SCRIPT_DIR/profile"

# --- Helper functions ---
xst_run() {
    EXISTDB_USER="$EXIST_USER" EXISTDB_PASS="$EXIST_PASS" EXISTDB_SERVER="$EXIST_SERVER" $XST "$@"
}

xst_eval() {
    EXISTDB_USER="$EXIST_USER" EXISTDB_PASS="$EXIST_PASS" EXISTDB_SERVER="$EXIST_SERVER" $XST execute "$1"
}

install_xar() {
    local xar="$1"
    local name="$(basename "$xar")"
    if [ ! -f "$xar" ]; then
        echo "  SKIP $name (not found)"
        return
    fi
    echo "  Installing $name..."
    xst_run package install -f "$xar" 2>&1 || {
        echo "  WARN: xst install failed for $name, trying repo:deploy..."
        xst_eval "repo:install-and-deploy-from-db('/db/system/repo/$name')" 2>/dev/null || true
        xst_eval "repo:deploy('$(unzip -p "$xar" expath-pkg.xml | grep -o 'name="[^"]*"' | head -1 | sed 's/name="//;s/"//')')" 2>/dev/null || true
    }
}

run_generator() {
    local label="$1"
    local config="$2"
    echo "  Generating $label..."
    curl -s -u "$EXIST_USER:$EXIST_PASS" -X POST \
        -H "Content-Type: application/json" \
        -d "$config" \
        "$EXIST_SERVER/exist/apps/jinks/api/generator?overwrite=all" \
        2>&1 | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    msgs = len(d.get('messages', []))
    err = d.get('code', '')
    if err:
        print(f'    ERROR: {err}')
    else:
        print(f'    OK ({msgs} files)')
except:
    print('    ERROR: could not parse response')
" 2>&1
}

upload_profile() {
    echo "  Uploading exist-site profile to Jinks..."

    # Create profile collection
    xst_eval 'if (not(xmldb:collection-available("/db/apps/jinks/profiles/exist-site"))) then xmldb:create-collection("/db/apps/jinks/profiles", "exist-site") else ()' 2>/dev/null

    # Upload profile files
    xst_run upload "$PROFILE_DIR/" /db/apps/jinks/profiles/exist-site 2>&1 | tail -1

    # Fix: store .html templates as binary (xst upload stores them as XML)
    xst_eval '
    let $source := "/db/apps/jinks/profiles/exist-site/templates"
    return
        if (xmldb:collection-available($source)) then
            for $resource in xmldb:get-child-resources($source)
            where ends-with($resource, ".html") and doc-available($source || "/" || $resource)
            let $content := serialize(doc($source || "/" || $resource))
            let $clean := if (starts-with($content, "<?xml")) then
                substring-after($content, "?>")
            else $content
            let $_ := xmldb:remove($source, $resource)
            return xmldb:store($source, $resource, $clean, "application/octet-stream")
        else ()
    ' 2>/dev/null
    echo "    Profile uploaded"
}

# --- Nav config (shared by all apps) ---
NAV_ITEMS='[{"abbrev":"dashboard","title":"Dashboard"},{"abbrev":"docs","title":"Documentation"},{"abbrev":"notebook","title":"Notebook"},{"abbrev":"blog","title":"Blog"}]'

gen_config() {
    local label="$1" id="$2" desc="$3" abbrev="$4" version="$5"
    shift 5
    local extra_deps="$*"
    cat <<EOF
{"config":{"label":"$label","id":"$id","description":"$desc","extends":["exist-site"],"pkg":{"abbrev":"$abbrev","version":"$version"$extra_deps},"nav":{"items":$NAV_ITEMS}}}
EOF
}

# --- Main ---
MODE="${1:-full}"

if [ "$MODE" = "--profile-only" ]; then
    upload_profile
    exit 0
fi

if [ "$MODE" != "--apps-only" ]; then
    echo "=== Installing packages ==="

    echo "Step 1: Dependencies (markdown, jinks)"
    [ -f "$MARKDOWN_XAR" ] && install_xar "$MARKDOWN_XAR"
    [ -f "$JINKS_XAR" ] && install_xar "$JINKS_XAR"

    echo "Step 2: Apps"
    install_xar "$SITE_SHELL_XAR"
    [ -f "$DASHBOARD_XAR" ] && install_xar "$DASHBOARD_XAR"
    [ -f "$DOCS_XAR" ] && install_xar "$DOCS_XAR"
    [ -f "$NOTEBOOK_XAR" ] && install_xar "$NOTEBOOK_XAR"
    [ -f "$BLOG_XAR" ] && install_xar "$BLOG_XAR"

    echo "Step 3: Patched jinks-templates (MUST be last)"
    install_xar "$JINKS_TEMPLATES_XAR"
fi

echo ""
echo "=== Uploading Jinks profile ==="
upload_profile

echo ""
echo "=== Running Jinks generator for each app ==="

run_generator "site-shell" "$(gen_config \
    "eXist-db Site Shell" \
    "http://exist-db.org/pkg/site-shell" \
    "Sitewide navigation shell" \
    "exist-site-shell" "0.9.0-SNAPSHOT" \
    ',"dependencies":[{"package":"http://tei-publisher.com/library/jinks-templates","semver":"1"},{"package":"http://exist-db.org/apps/markdown","semver":"3"}]')"

run_generator "dashboard" "$(gen_config \
    "Dashboard" \
    "http://exist-db.org/apps/dashboard" \
    "Administration dashboard" \
    "dashboard" "3.0.0-SNAPSHOT")"

run_generator "docs" "$(gen_config \
    "eXist-db Documentation" \
    "http://exist-db.org/apps/docs" \
    "Documentation and function reference" \
    "docs" "0.1.0" \
    ',"dependencies":[{"package":"http://tei-publisher.com/library/jinks-templates","semver":"1"},{"package":"http://existsolutions.com/apps/tei-publisher-lib","semver":"4"}]')"

run_generator "notebook" "$(gen_config \
    "Notebook" \
    "http://exist-db.org/pkg/notebook" \
    "Interactive XQuery notebook" \
    "notebook" "1.0.0-SNAPSHOT")"

run_generator "blog" "$(gen_config \
    "Blog" \
    "http://exist-db.org/apps/blog" \
    "eXist-db project blog" \
    "blog" "0.1.0")"

echo ""
echo "=== Done ==="
echo "Patched jinks-templates is installed last to prevent overwrites."
echo "If any future package install pulls in stock jinks-templates,"
echo "re-run: ./setup.sh --apps-only"
