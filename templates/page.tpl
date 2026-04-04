---json
{
    "templating": {
        "extends": "templates/base-page.tpl"
    }
}
---
[% template title %][[ $page-title ]] -- [[ $site-name ]][% endtemplate %]

[% template content %]
<article class="page-content">
    [[ $page-html ]]
</article>
[% endtemplate %]
