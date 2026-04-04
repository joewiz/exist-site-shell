---json
{
    "templating": {
        "extends": "templates/base-page.html"
    }
}
---
[% template title %]Search -- [[ $site?name ]][% endtemplate %]

[% template content %]
<div class="search-results-page">
    <h1>Search</h1>

    <form class="search-form" action="[[ $context-path ]]/search" method="get">
        <input type="search" name="q" value="[[ $q ]]"
               placeholder="Search docs, functions, notebooks..."
               aria-label="Search query"/>
        <button type="submit">Search</button>
    </form>

    [% if $q != '' %]
    <p class="search-summary">
        Results for "<strong>[[ $q ]]</strong>"
        ([[ count($search-results?*) ]] found)
    </p>

    [% if count($search-results?*) > 0 %]
    <ol class="search-results">
        [% for $result in $search-results?* %]
        <li class="search-result">
            <h2><a href="[[ $result?url ]]">[[ $result?title ]]</a></h2>
            <div class="search-snippet">[[ $result?snippet ]]</div>
            <div class="search-meta">
                [% if exists($result?app) %]
                <span class="search-app">[[ $result?app ]]</span>
                [% endif %]
            </div>
        </li>
        [% endfor %]
    </ol>
    [% else %]
    <p>No results found. Try a different search term.</p>
    [% endif %]

    [% endif %]
</div>
[% endtemplate %]
