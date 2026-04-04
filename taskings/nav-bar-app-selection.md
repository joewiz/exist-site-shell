# Site-Shell: Centralized Nav Bar App Selection

## Problem

Currently, each app that renders through site-shell's `base-page.tpl` must supply its own `$nav-apps` array. This means every app (dashboard, fundocs, etc.) independently decides which apps appear in the site-wide navigation bar — duplicating logic and risking inconsistency.

For example, dashboard's `view.xq` hardcodes:

```xquery
"nav-apps": array {
    for $app in ("dashboard", "fundocs", "eXide")
    where map:contains($apps, $app)
    ...
}
```

This is fragile: if a new app should appear in the nav bar, every app that uses site-shell must be updated.

## Proposed Solution

Site-shell should own the nav bar app list. Apps that render through site-shell should be able to call a shared function (or rely on a default) rather than building `$nav-apps` themselves.

### Option A: Shared XQuery Function

Site-shell's `nav.xqm` already has `nav:apps()`. Make this importable by other apps:

```xquery
import module namespace nav="http://exist-db.org/site/nav"
    at "/db/apps/exist-site-shell/modules/nav.xqm";

let $ctx := map {
    "nav-apps": nav:apps(),
    ...
}
```

This way dashboard (and any other app) delegates the nav bar list to site-shell.

### Option B: Convention-Based Discovery

Site-shell discovers nav-bar-worthy apps automatically by looking for a marker in each app's `repo.xml` or `expath-pkg.xml`. For example:

```xml
<!-- in repo.xml -->
<meta xmlns="http://exist-db.org/xquery/repo">
    <nav-bar order="1">Dashboard</nav-bar>
    ...
</meta>
```

Or a tag in `expath-pkg.xml`:

```xml
<tag>nav-bar</tag>
```

Site-shell's `nav:apps()` scans installed packages for this marker and returns only those apps, in order.

### Option C: Configuration File

A `nav-config.xml` in site-shell's data collection:

```xml
<nav-config xmlns="http://exist-db.org/site/nav">
    <app abbrev="dashboard" title="Dashboard" order="1"/>
    <app abbrev="fundocs" title="Functions" order="2"/>
    <app abbrev="eXide" title="eXide" order="3"/>
</nav-config>
```

Editable by admins. New apps register themselves via post-install hooks.

## Recommendation

**Option A** (shared function) is the quickest win — it already exists as `nav:apps()`. The main work is:

1. Ensure `nav:apps()` is importable from other apps (currently it imports sibling modules with relative paths, which may not resolve from another app's context)
2. Document the pattern for app developers
3. Update dashboard to use `nav:apps()` instead of its own hardcoded list
4. Optionally evolve toward Option B for zero-configuration discovery

## Impact

- **Dashboard** — remove hardcoded `$nav-apps` from `view.xq`, call `nav:apps()` instead
- **fundocs** — same (its `view.xq` has a similar hardcoded list)
- **Future apps** — follow the pattern automatically
- **Site-shell** — expose `nav:apps()` as a stable, importable API

## Related

- Dashboard nav bar: `~/workspace/dashboard-next/modules/view.xq` lines 113-124
- Site-shell nav module: `~/workspace/exist-site-shell/modules/nav.xqm`
- Site-shell view: `~/workspace/exist-site-shell/modules/view.xq` line 107 (`nav:apps()`)
