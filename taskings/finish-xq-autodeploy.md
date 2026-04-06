# Tasking: Add finish.xq for autodeploy Jinks profile integration

**For:** dashboard, docs, notebook, blog

## Problem

When apps are installed via autodeploy (Docker image startup) or `xst package install`, there's no npm or curl to call the Jinks generator API. The profile files (base-page.html, nav.xqm, site-config.xqm, exist-site.css) aren't in the XAR, so the app renders without the shared nav bar until someone manually runs the generator.

## Solution

Add a `finish.xq` that runs automatically after XAR deployment. It calls the Jinks generator to copy profile files into the app. site-shell's `finish.xq` already does this and handles two additional issues:

1. **MIME type fix** — the generator stores `.xqm` files as `application/octet-stream` but eXist needs `application/xquery` to load them as XQuery modules
2. **Graceful degradation** — if Jinks isn't installed, logs a warning instead of crashing

## What to do

### 1. Create `finish.xq` in your app root

Use this template, replacing the config values with your app's:

```xquery
xquery version "3.1";

(:~
 : Post-install script.
 :
 : Calls the Jinks generator to copy profile files (base-page.html,
 : nav.xqm, site-config.xqm, exist-site.css) into this app.
 : Required for autodeploy compatibility.
 :)

declare variable $home external;
declare variable $dir external;
declare variable $target external;

let $config := map {
    "label": "YOUR_APP_TITLE",
    "id": "YOUR_PACKAGE_URI",
    "description": "YOUR_DESCRIPTION",
    "extends": array { "exist-site" },
    "pkg": map {
        "abbrev": "YOUR_ABBREV",
        "version": "YOUR_VERSION"
    },
    "nav": map {
        "items": array {
            map { "abbrev": "dashboard", "title": "Dashboard" },
            map { "abbrev": "docs", "title": "Documentation" },
            map { "abbrev": "notebook", "title": "Notebook" },
            map { "abbrev": "blog", "title": "Blog" }
        }
    }
}

return
    if (util:binary-doc-available("/db/apps/jinks/modules/generator.xqm") or
        doc-available("/db/apps/jinks/modules/generator.xqm")) then
        try {
            let $_ := util:import-module(
                xs:anyURI("http://tei-publisher.com/library/generator"),
                "generator",
                xs:anyURI("/db/apps/jinks/modules/generator.xqm")
            )
            let $_ := util:eval('generator:process(map { "overwrite": () }, $config)', false(),
                    (xs:QName("config"), $config))
            (: Fix MIME type for .xqm modules — the generator stores them as
             : application/octet-stream but eXist needs application/xquery :)
            return
                for $mod in xmldb:get-child-resources($target || "/modules")
                where ends-with($mod, ".xqm")
                let $path := $target || "/modules/" || $mod
                where util:binary-doc-available($path) and
                      xmldb:get-mime-type(xs:anyURI($path)) != "application/xquery"
                let $content := util:binary-to-string(util:binary-doc($path))
                let $_ := xmldb:remove($target || "/modules", $mod)
                return xmldb:store($target || "/modules", $mod, $content, "application/xquery")
        } catch * {
            util:log("WARN", "YOUR_ABBREV: Jinks generator failed: " || $err:description)
        }
    else
        util:log("WARN", "YOUR_ABBREV: Jinks generator not available. Install Jinks and re-deploy.")
```

**Config values per app:**

| App | label | id | abbrev | version |
|-----|-------|----|--------|---------|
| Dashboard | `Dashboard` | `http://exist-db.org/apps/dashboard` | `dashboard` | `3.0.0-SNAPSHOT` |
| Docs | `eXist-db Documentation` | `http://exist-db.org/apps/docs` | `docs` | `0.1.0` |
| Notebook | `Notebook` | `http://exist-db.org/pkg/notebook` | `notebook` | `1.0.0-SNAPSHOT` |
| Blog | `Blog` | `http://exist-db.org/apps/blog` | `blog` | `0.1.0` |

For docs, add dependencies to the pkg map:
```xquery
"dependencies": array {
    map { "package": "http://tei-publisher.com/library/jinks-templates", "semver": "1" },
    map { "package": "http://existsolutions.com/apps/tei-publisher-lib", "semver": "4" }
}
```

### 2. Update `repo.xml.tmpl`

Add `<finish>finish.xq</finish>` inside `<meta>`:

```xml
<meta xmlns="http://exist-db.org/xquery/repo">
    ...
    <target>@target@</target>
    <finish>finish.xq</finish>
</meta>
```

If your app already has a `finish.xq` (like docs), add the Jinks generator call at the end of the existing script.

### 3. Add finish.xq to gulpfile.js

Make sure `finish.xq` is included in the XAR sources:

```javascript
function copyXarSources() {
  return src([
    "controller.xq",
    "finish.xq",    // <-- add this
    ...
  ], { encoding: false, base: "." })
```

### 4. Test

```bash
npm run build
xst package install -f dist/YOUR_APP.xar --force
```

Check Docker logs for:
- `Loading extended profile: exist-site` — generator ran
- No WARN about "Jinks not installed" — if you see this, Jinks needs to be installed first

Verify the app renders with the shared nav bar.

## Prerequisites

The exist-site profile must be available in Jinks at `/db/apps/jinks/profiles/exist-site/`. Site-shell's `finish.xq` handles this automatically — it uploads the profile from its own `profile/` directory. So **install site-shell first** (or at least before the other apps).

## Install order

1. Jinks (the generator app)
2. Patched jinks-templates (with map:merge workaround)
3. exist-site-shell (uploads the profile + runs its own generator)
4. Other apps in any order (each runs its own generator via finish.xq)

## Reference

- Working implementation: `~/workspace/exist-site-shell/finish.xq`
- Profile source: `~/workspace/exist-site-shell/profile/`
