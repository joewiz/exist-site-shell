# Notebook: Add site-shell integration

## Current state

Notebook (formerly Sandbox, `~/workspace/sandbox/`) is **API-driven** — it uses Roaster for routing and returns HTML/JSON directly from XQuery handlers. It has no Jinks templates, no html-templating, and no site-shell integration.

This is the most work of the four apps since it needs to adopt Jinks from scratch.

## Changes needed

### 1. Add Jinks template rendering

Create a `modules/view.xq` (or equivalent) that renders Jinks templates. The Notebook's main page would be a Jinks template that extends `site:base-page.tpl`:

```
---json
{
    "templating": {
        "extends": "site:base-page.tpl"
    }
}
---
[% template title %]Notebook -- [[ $site-name ]][% endtemplate %]

[% template head %]
<link rel="stylesheet" href="resources/css/notebook.css"/>
[% endtemplate %]

[% template content %]
<div id="notebook-app">
    <!-- Notebook UI rendered here by JS or XQuery -->
</div>
[% endtemplate %]
```

### 2. Controller changes

The controller needs to route the main page through the Jinks view pipeline instead of directly to the Roaster API. API endpoints (`/api/*`) can stay as-is.

Suggested split:
- `/` and `/notebook` → Jinks template (with shell nav)
- `/api/*` → Roaster API (unchanged)
- `/share/*` → Roaster API (unchanged)

### 3. Context variables and nav

Same pattern as dashboard/docs — import `nav:apps()` from site-shell, pass shell context variables.

### 4. Package rename

The nav-config.xml in site-shell lists `abbrev="notebook"`. The package needs to be renamed from `sandbox` to `notebook` (in expath-pkg.xml.tmpl, repo.xml.tmpl, and package.json).

### 5. Standalone fallback

Add a `standalone.tpl` for rendering without site-shell.

## Scope consideration

The Notebook app is fundamentally different from Dashboard and Documentation — it's an interactive code execution environment. The Jinks integration only needs to wrap the outer page shell (nav bar, footer). The actual notebook UI can remain as-is within the `[% template content %]` block.

## Testing

- Notebook page renders with site-shell nav bar
- Code execution and API endpoints still work
- Standalone mode works when site-shell is uninstalled
- "Notebook" is highlighted in the nav bar

## Reference

- Sandbox controller: `~/workspace/sandbox/controller.xq`
- Sandbox API: `~/workspace/sandbox/modules/api.xq`
