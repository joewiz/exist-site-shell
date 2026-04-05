# Instructions: Adopt the exist-site Jinks Profile

These instructions are for the **dashboard**, **docs**, and **blog** app sessions. The exist-site Jinks profile is ready and tested. It provides shared navigation, CSS, and login/logout via a base template that your app extends.

## Prerequisites

The following must be installed on the running eXist instance:

- **jinks** (the generator app) — install from `~/workspace/jinks/build/jinks.xar`
- **jinks-templates** (the runtime library) — install from `~/workspace/jinks-templates/build/jinks-templates.xar` (includes the map:merge workaround)
- **exist-site profile** — must be uploaded to `/db/apps/jinks/profiles/exist-site/` (the generator reads profiles from there)

If these aren't already installed, the site-shell session can set them up.

## Step 1: Run the Jinks generator

Call the generator API with your app's config. This copies the profile's shared files into your app's deployed collection.

```bash
curl -s -u admin: -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "config": {
      "label": "YOUR APP TITLE",
      "id": "YOUR PACKAGE URI",
      "description": "YOUR DESCRIPTION",
      "extends": ["exist-site"],
      "pkg": {
        "abbrev": "YOUR ABBREV",
        "version": "YOUR VERSION"
      },
      "nav": {
        "items": [
          {"abbrev": "dashboard", "title": "Dashboard"},
          {"abbrev": "docs", "title": "Documentation"},
          {"abbrev": "notebook", "title": "Notebook"},
          {"abbrev": "blog", "title": "Blog"}
        ]
      }
    }
  }' \
  "http://localhost:8080/exist/apps/jinks/api/generator?overwrite=all"
```

Replace the uppercase placeholders with your app's values. For example, for dashboard:

```json
{
  "label": "Dashboard",
  "id": "http://exist-db.org/apps/dashboard",
  "pkg": { "abbrev": "dashboard", "version": "3.0.0-SNAPSHOT" }
}
```

This copies into your app's `/db/apps/{abbrev}/` collection:
- `templates/base-page.html` — the shared nav/footer template (stored as binary)
- `templates/standalone.html` — minimal fallback without nav
- `modules/nav.xqm` — nav bar builder
- `modules/site-config.xqm` — current-user, is-logged-in helpers
- `resources/css/exist-site.css` — shared design foundation
- `resources/images/exist-logo.svg` — eXist logo
- `expath-pkg.xml`, `repo.xml` — updated package descriptors

**Important:** After running `npm run deploy` (which reinstalls from XAR), you need to re-run the generator to get the profile files back. The XAR doesn't include the profile-generated files. This is a known workflow issue — for now, always run the generator after deploying.

## Step 2: Update your page templates

Each page template should extend the profile's base template using Jinks front matter:

```
---json
{
    "templating": {
        "extends": "templates/base-page.html"
    }
}
---
[% template title %]My Page -- eXist-db[% endtemplate %]

[% template head %]
<link rel="stylesheet" href="[[ $context-path ]]/resources/css/my-app.css"/>
[% endtemplate %]

[% template content %]
<div class="my-page">
    ... your page content ...
</div>
[% endtemplate %]
```

Available blocks: `title`, `head`, `content`.

**Template files must use `.tpl` extension** so eXist stores them as binary (preserving Jinks directives). Do NOT use `.html` for templates that contain `[% %]` or `[[ ]]` — eXist will XML-parse them and corrupt the directives.

## Step 3: Update your view.xq

Your view.xq needs to:

1. Pass the profile's expected context variables
2. Register the profile's modules for template use
3. Use a resolver that handles both relative and absolute paths

### Context variables the base template expects:

```xquery
let $context-path := request:get-context-path() || "/apps/YOUR-ABBREV"
let $context := map {
    "context-path": $context-path,
    "styles": array { "resources/css/exist-site.css", "resources/css/your-app.css" },
    "site": map {
        "name": "eXist-db",
        "logo": "resources/images/exist-logo.svg"
    },
    "nav": map {
        "items": array {
            map { "abbrev": "dashboard", "title": "Dashboard" },
            map { "abbrev": "docs", "title": "Documentation" },
            map { "abbrev": "notebook", "title": "Notebook" },
            map { "abbrev": "blog", "title": "Blog" }
        }
    },
    (: ... your app-specific context variables ... :)
}
```

### Module registration for tmpl:process:

```xquery
tmpl:process($template, $context, map {
    "resolver": local:resolver#1,
    "modules": map {
        "http://exist-db.org/site/nav": map {
            "prefix": "nav",
            "at": $app-root || "/modules/nav.xqm"
        },
        "http://exist-db.org/site/shell-config": map {
            "prefix": "site-config",
            "at": $app-root || "/modules/site-config.xqm"
        }
    }
})
```

### Resolver (must handle absolute paths for module resolution):

```xquery
declare function local:resolver($path as xs:string) as map(*)? {
    let $effectivePath :=
        if (starts-with($path, "/db/")) then $path
        else $app-root || "/" || $path
    let $content :=
        if (util:binary-doc-available($effectivePath)) then
            util:binary-doc($effectivePath) => util:binary-to-string()
        else if (doc-available($effectivePath)) then
            doc($effectivePath) => serialize()
        else ()
    return
        if ($content) then map { "path": $effectivePath, "content": $content }
        else ()
};
```

## Step 4: Remove old nav bar code

- Delete hardcoded nav HTML from your templates
- Remove any `local:nav-apps()` or dynamic site-shell import logic
- Remove two-pass rendering workarounds (the extends mechanism works now)
- Remove shell-detection logic (`repo:list() = "http://exist-db.org/pkg/site-shell"`)
- Keep a standalone fallback path if you want the app to work without the profile files

## Step 5: Test

- Verify the shared nav bar appears with Dashboard, Documentation, Notebook, Blog links
- Verify your app's content renders in the content block
- Verify the active state highlights your app in the nav bar
- Verify login/logout works and redirects back to your app
- Verify the app still works standalone (without the profile files) if you have a fallback

## What the base template provides

The nav bar shows apps listed in the `nav.items` config. Only installed apps appear (checked via `xmldb:collection-available`). The nav module uses `request:get-context-path()` for URL construction, so links work regardless of proxy configuration.

Login/logout links point to `$context-path/login` and `$context-path/logout` with a redirect parameter. Your app's controller needs to handle `/login` and `/logout` routes, or you can point them to site-shell's routes.

The CSS foundation (`exist-site.css`) provides custom properties, typography, nav/footer styles, form elements, buttons, tables, tabs, cards, and alerts. Your app's CSS loads after it and can override any custom property.

## Reference

- Profile source: `~/workspace/jinks/profiles/exist-site/` (branch: `exist-site-profile`)
- Site-shell reference implementation: `~/workspace/exist-site-shell/modules/view.xq`
- Adoption guide: `~/workspace/exist-site-shell/taskings/jinks-profile-adoption.md`
