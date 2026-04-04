# Blog: Add site-shell integration

## Current state

Blog app (`~/workspace/blog/` or wherever it lives). Status and architecture TBD — check the app's current rendering pipeline.

## Changes needed

### 1. Template extends

The blog's page template should extend `site:base-page.tpl`:

```
---json
{
    "templating": {
        "extends": "site:base-page.tpl"
    }
}
---
[% template title %][[ $post-title ]] -- Blog[% endtemplate %]

[% template content %]
<article class="blog-post">
    ...
</article>
[% endtemplate %]
```

### 2. Nav and context

Import `nav:apps()` from site-shell. Pass shell context variables.

### 3. Standalone fallback

Add a `standalone.tpl` for rendering without site-shell.

### 4. Feed integration

Site-shell's `modules/news.xqm` has a stub for pulling latest blog entries. Once the blog is integrated, update `news.xqm` to query the blog's data collection (or its Atom feed) to populate the landing page's "Latest News" section.

## Testing

- Blog pages render with site-shell nav bar
- Blog post list, individual posts, and archives work
- "Blog" is highlighted in the nav bar
- Standalone mode works when site-shell is uninstalled
- Site-shell landing page shows latest blog entries in the news section

## Reference

- Site-shell news module: `~/workspace/exist-site-shell/modules/news.xqm`
- Site-shell landing template: `~/workspace/exist-site-shell/templates/index.tpl`
