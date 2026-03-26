---json
{
    "templating": {
        "extends": "templates/base-page.html"
    }
}
---
[% template title %][[ $page-title ]] &#8212; [[ $site-name ]][% endtemplate %]

[% template content %]
<article class="page-content">
    [[ $page-html ]]
</article>
[% endtemplate %]
