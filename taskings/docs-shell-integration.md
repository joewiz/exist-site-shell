# Documentation: Migrate to Jinks extends for site-shell integration

## Current state

Documentation-next (`~/workspace/documentation-next/`) uses a 3-pass Jinks rendering pipeline:

1. **Pass 1:** Renders page-specific templates (article.tpl, module-list.tpl, etc.)
2. **Pass 2:** Wraps in `page-content.tpl` (docs-specific tab navigation: Articles, Functions, Admin)
3. **Pass 3:** Wraps in site-shell's `base-page.tpl` or local `standalone.tpl`

Has its own `modules/nav.xqm` that dynamically imports site-shell's `nav:apps()`.

## Changes needed

### 1. Convert `page-content.tpl` to use `extends`

```
---json
{
    "templating": {
        "extends": "site:base-page.tpl"
    }
}
---
[% template title %][[ $page-title ]] -- Documentation[% endtemplate %]

[% template content %]
<div class="docs-layout">
    <nav class="docs-tabs">... tab bar ...</nav>
    <div class="docs-content">[[ $tab-content ]]</div>
</div>
[% endtemplate %]
```

### 2. Simplify `view.xq`

Reduce from 3 passes to 2:
- Pass 1: render page-specific template (article, function, search, etc.)
- Pass 2: render page-content.tpl (which extends base-page.tpl)

### 3. Simplify `nav.xqm`

Replace the dynamic import of site-shell's nav module with a direct import:

```xquery
import module namespace site-nav = "http://exist-db.org/site/nav"
    at "/db/apps/exist-site-shell/modules/nav.xqm";
```

Or import `config:context()` from `content/exist-site.xqm` for the full shell context.

### 4. Standalone fallback

`standalone.tpl` already exists. Make `page-content.tpl` conditionally extend either `site:base-page.tpl` or `standalone.tpl`. This could be done by having two versions of page-content.tpl selected in view.xq, or by using a variable-based extends path.

### 5. Resolver and context variables

Same pattern as dashboard — handle `site:` prefix in resolver, pass shell context variables.

## Testing

- Documentation renders with site-shell nav bar
- Article pages, function reference, and search all work
- Breadcrumb navigation still works
- Standalone mode works when site-shell is uninstalled
- "Documentation" is highlighted in the nav bar when browsing docs

## Reference

- Docs view.xq: `~/workspace/documentation-next/modules/view.xq`
- Docs nav.xqm: `~/workspace/documentation-next/modules/nav.xqm`
- Docs page-content.tpl: `~/workspace/documentation-next/templates/page-content.tpl`
- Docs standalone.tpl: `~/workspace/documentation-next/templates/standalone.tpl`
