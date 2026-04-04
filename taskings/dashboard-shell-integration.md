# Dashboard: Migrate to Jinks extends for site-shell integration

## Current state

Dashboard-next (`~/workspace/dashboard-next/`) uses a 3-pass rendering pipeline:

1. **Pass 1 (html-templating):** Renders page-specific templates (`templates/pages/*.html`) using eXist's built-in `data-template` attribute processing and functions from `app.xqm`
2. **Pass 2 (Jinks):** Wraps the result in `page-content.tpl` (dashboard's internal tab bar)
3. **Pass 3 (Jinks):** Wraps that in site-shell's `base-page.tpl` (nav, footer) — or a minimal standalone wrapper if site-shell isn't installed

The site-shell integration in Pass 3 uses the two-pass workaround (inject `$page-content` as a variable into `base-page.tpl`). This is no longer needed — Jinks `extends` now works correctly.

## Changes needed

### 1. Convert `page-content.tpl` to use `extends`

Dashboard's `page-content.tpl` should extend `site:base-page.tpl` using front matter:

```
---json
{
    "templating": {
        "extends": "site:base-page.tpl"
    }
}
---
[% template title %][[ $page-title ]] -- Dashboard[% endtemplate %]

[% template content %]
<div class="dashboard-tabs">
    ... tab bar ...
</div>
<div class="dashboard-content">
    [[ $tab-content ]]
</div>
[% endtemplate %]
```

The `site:` prefix tells site-shell's resolver to look in `/db/apps/exist-site-shell/templates/`.

### 2. Simplify `view.xq`

Remove the two-pass workaround. Instead of:
- Pass 2: render page-content.tpl → `$dashboard-html`
- Pass 3: render base-page.tpl with `$page-content := $dashboard-html`

Do:
- Pass 1: render page templates (html-templating, unchanged)
- Pass 2: render page-content.tpl (which extends base-page.tpl via Jinks)

The extends handles the base-page wrapping automatically.

### 3. Remove hardcoded nav-apps

Dashboard currently builds its own `$nav-apps` from a hardcoded list. Replace with:

```xquery
import module namespace nav = "http://exist-db.org/site/nav"
    at "/db/apps/exist-site-shell/modules/nav.xqm";

"nav-apps": nav:apps()
```

Site-shell's `nav:apps()` reads from `data/nav-config.xml` — no hardcoding needed.

### 4. Standalone fallback

Keep the `standalone.tpl` (or equivalent) for when site-shell isn't installed. Check with:

```xquery
let $has-shell := xmldb:collection-available("/db/apps/exist-site-shell")
```

If no shell, `page-content.tpl` should extend a local `standalone.tpl` instead of `site:base-page.tpl`.

### 5. Resolver

The resolver in dashboard's `view.xq` needs to handle the `site:` prefix, resolving to site-shell's templates directory. Use the same pattern as site-shell's resolver:

```xquery
if (starts-with($relPath, "site:")) then
    "/db/apps/exist-site-shell/templates/" || substring-after($relPath, "site:")
else
    $app-root || "/" || $relPath
```

### 6. Context variables

Pass these in the Jinks context so `base-page.tpl` renders correctly:

- `shell-base`: `request:get-context-path() || "/apps/exist-site-shell"`
- `site-name`: `"eXist-db"`
- `site-logo`: `$shell-base || "/resources/images/exist-logo.svg"`
- `user`: from `session:get-attribute("user")` or `sm:id()`
- `nav-apps`: from `nav:apps()`

Or import `config:context()` from site-shell's `content/exist-site.xqm`.

## Testing

- Dashboard renders with site-shell nav bar, search, login/logout, footer
- Dashboard renders standalone when site-shell is uninstalled
- Tab navigation still works within dashboard
- Login/logout redirects work from dashboard pages
- Active state highlights "Dashboard" in the nav bar

## Reference

- Dashboard view.xq: `~/workspace/dashboard-next/modules/view.xq`
- Dashboard page-content.tpl: `~/workspace/dashboard-next/templates/page-content.tpl`
- Site-shell base-page.tpl: `~/workspace/exist-site-shell/templates/base-page.tpl`
- Site-shell view.xq (reference pattern): `~/workspace/exist-site-shell/modules/view.xq`
