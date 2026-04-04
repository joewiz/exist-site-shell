# Jinks Profile Adoption Guide

## Overview

The `exist-site` Jinks profile (in `~/workspace/jinks/profiles/exist-site/`) is the canonical source for shared resources across eXist-db.org apps. Each app extends this profile to inherit:

- `templates/base-page.tpl` — nav bar, search, login/logout, footer
- `templates/standalone.tpl` — minimal fallback without nav
- `resources/css/exist-site.css` — design foundation
- `modules/nav.xqm` — nav bar builder (reads `nav.items` from config.json)
- `modules/site-config.xqm` — current-user, is-logged-in helpers
- `expath-pkg.tpl.xml`, `repo.tpl.xml` — templated package descriptors

## Per-App config.json

Each app needs a `config.json` at its root. This tells Jinks which profiles to extend and provides app-specific overrides.

### Dashboard (`~/workspace/dashboard-next/config.json`)

```json
{
    "label": "Dashboard",
    "id": "http://exist-db.org/apps/dashboard",
    "description": "Administration dashboard for eXist-db",
    "extends": ["exist-site"],
    "pkg": {
        "abbrev": "dashboard",
        "version": "3.0.0-SNAPSHOT"
    },
    "nav": {
        "items": [
            { "abbrev": "dashboard", "title": "Dashboard" },
            { "abbrev": "docs", "title": "Documentation" },
            { "abbrev": "notebook", "title": "Notebook" },
            { "abbrev": "blog", "title": "Blog" }
        ]
    }
}
```

### Documentation (`~/workspace/documentation-next/config.json`)

```json
{
    "label": "eXist-db Documentation",
    "id": "http://exist-db.org/apps/docs",
    "description": "Documentation and function reference for eXist-db",
    "extends": ["exist-site"],
    "pkg": {
        "abbrev": "docs",
        "version": "0.1.0",
        "dependencies": [
            { "package": "http://tei-publisher.com/library/jinks-templates", "semver": "1" },
            { "package": "http://existsolutions.com/apps/tei-publisher-lib", "semver": "4" }
        ]
    },
    "nav": {
        "items": [
            { "abbrev": "dashboard", "title": "Dashboard" },
            { "abbrev": "docs", "title": "Documentation" },
            { "abbrev": "notebook", "title": "Notebook" },
            { "abbrev": "blog", "title": "Blog" }
        ]
    }
}
```

### Notebook (`~/workspace/sandbox/config.json`)

```json
{
    "label": "Notebook",
    "id": "http://exist-db.org/apps/notebook",
    "description": "Interactive XQuery notebook for eXist-db",
    "extends": ["exist-site"],
    "pkg": {
        "abbrev": "notebook",
        "version": "1.0.0-SNAPSHOT"
    },
    "nav": {
        "items": [
            { "abbrev": "dashboard", "title": "Dashboard" },
            { "abbrev": "docs", "title": "Documentation" },
            { "abbrev": "notebook", "title": "Notebook" },
            { "abbrev": "blog", "title": "Blog" }
        ]
    }
}
```

### Blog (`~/workspace/blog/config.json`)

```json
{
    "label": "Blog",
    "id": "http://exist-db.org/apps/blog",
    "description": "eXist-db project blog",
    "extends": ["exist-site"],
    "pkg": {
        "abbrev": "blog",
        "version": "0.1.0"
    },
    "nav": {
        "items": [
            { "abbrev": "dashboard", "title": "Dashboard" },
            { "abbrev": "docs", "title": "Documentation" },
            { "abbrev": "notebook", "title": "Notebook" },
            { "abbrev": "blog", "title": "Blog" }
        ]
    }
}
```

## How to adopt the profile

For each app:

### 1. Add config.json

Create `config.json` at the app root with the content above.

### 2. Run Jinks to copy profile files

From the Jinks web UI (or REST API):
1. Load the app's config.json
2. Click "Apply" to generate/update
3. Profile files are copied into the app (templates, modules, CSS)

Or manually: copy the profile's files into the app.

### 3. Update view.xq

The app's `view.xq` should:
- Import `nav` and `site-config` modules (already copied by the profile)
- Read the merged context from `context.json` (created by Jinks)
- Pass `$nav?items`, `$site`, `$styles`, and `$context-path` to tmpl:process()

### 4. Update page templates

Each page template uses Jinks `extends`:

```
---json
{
    "templating": {
        "extends": "templates/base-page.tpl"
    }
}
---
[% template title %]My Page -- eXist-db[% endtemplate %]

[% template content %]
... page content ...
[% endtemplate %]
```

Since `base-page.tpl` is now a local file (copied from the profile), no `site:` prefix needed.

### 5. Remove duplicated code

- Delete any hardcoded nav bar HTML
- Delete local copies of shell CSS (use `exist-site.css` from profile)
- Remove shell-detection logic (`repo:list() = "http://exist-db.org/pkg/site-shell"`)
- Remove two-pass rendering workarounds

## Updating shared resources

When the profile is updated (CSS changes, template changes, etc.):

1. Edit files in `~/workspace/jinks/profiles/exist-site/`
2. For each app, re-run Jinks generation to pull in updates
3. Jinks' conflict detection will flag files that the app has customized
4. Choose to keep the app's version or accept the profile update

## What site-shell still owns

Even with the profile, site-shell remains a deployed app that provides:
- Landing page (`/`)
- Sitewide search (`/search`)
- Login/logout (`/login`, `/logout`)
- Markdown pages (`/about`, `/community`, etc.)
- URL redirects

The profile doesn't replace site-shell — it extracts the **shared resources** (CSS, base template, nav module) into a central source. Site-shell and the other apps all consume the same profile.

## File locations

- Profile: `~/workspace/jinks/profiles/exist-site/`
- Jinks repo: `~/workspace/jinks/` (branch: `exist-site-profile`)
- Site-shell: `~/workspace/exist-site-shell/` (branch: `jinks-profile`)
