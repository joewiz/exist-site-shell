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
        [% if $search-app-filter != '' %]
            within <strong>[[ ($app-names($search-app-filter), $search-app-filter)[1] ]]</strong>
            [% if $search-section-filter != '' %]
                / <strong>[[ $search-section-filter ]]</strong>
            [% endif %]
        [% endif %]
        ([[ $search-start ]]-[[ $search-start + count($search-results?*) - 1 ]] of [[ $search-total ]])
    </p>

    <div class="search-layout">
        <aside class="search-sidebar" aria-label="Filter results">
            [% if map:size(($search-hier-facets, map{})[1]) > 0 %]
            <section class="facet-group">
                <h3 class="facet-heading">Filter</h3>
                <ul class="facet-list">
                    <li>
                        [% if not(exists($search-app-filter)) or $search-app-filter = '' %]
                        <span class="facet-opt facet-active">All apps</span>
                        [% else %]
                        <a class="facet-opt" href="[[ $context-path ]]/search?q=[[ encode-for-uri($q) ]]">All apps</a>
                        [% endif %]
                    </li>
                    [% for $app in map:keys(($search-hier-facets, map{})[1]) %]
                    <li class="facet-app-item">
                        [% if $search-app-filter = $app %]
                        <span class="facet-opt facet-active">[[ ($app-names($app), $app)[1] ]] <span class="facet-count">([[ ($search-hier-facets, map{})[1]($app)?count ]])</span></span>
                        [% else %]
                        <a class="facet-opt" href="[[ $context-path ]]/search?q=[[ encode-for-uri($q) ]]&amp;app=[[ $app ]]">[[ ($app-names($app), $app)[1] ]] <span class="facet-count">([[ ($search-hier-facets, map{})[1]($app)?count ]])</span></a>
                        [% endif %]
                        [% if $search-app-filter = $app and map:size(($search-hier-facets, map{})[1]($app)?sections) > 0 %]
                        <ul class="facet-section-list">
                            <li>
                                [% if not(exists($search-section-filter)) or $search-section-filter = '' %]
                                <span class="facet-opt facet-section facet-active">All sections</span>
                                [% else %]
                                <a class="facet-opt facet-section" href="[[ $context-path ]]/search?q=[[ encode-for-uri($q) ]]&amp;app=[[ $app ]]">All sections</a>
                                [% endif %]
                            </li>
                            [% for $sec in map:keys(($search-hier-facets, map{})[1]($app)?sections) %]
                            <li>
                                [% if $search-section-filter = $sec %]
                                <span class="facet-opt facet-section facet-active">[[ $sec ]] <span class="facet-count">([[ ($search-hier-facets, map{})[1]($app)?sections($sec) ]])</span></span>
                                [% else %]
                                <a class="facet-opt facet-section" href="[[ $context-path ]]/search?q=[[ encode-for-uri($q) ]]&amp;app=[[ $app ]]&amp;section=[[ $sec ]]">[[ $sec ]] <span class="facet-count">([[ ($search-hier-facets, map{})[1]($app)?sections($sec) ]])</span></a>
                                [% endif %]
                            </li>
                            [% endfor %]
                        </ul>
                        [% endif %]
                    </li>
                    [% endfor %]
                </ul>
            </section>
            [% endif %]
        </aside>

        <div class="search-main">
            [% if count($search-results?*) > 0 %]
            <ol class="search-results">
                [% for $result in $search-results?* %]
                <li class="search-result">
                    <h2><a href="[[ $result?url ]]">[[ $result?title ]]</a></h2>
                    <div class="search-snippet">[[ if ($result?snippet != '') then parse-xml("<r>" || $result?snippet || "</r>")/r/node() else () ]]</div>
                    <div class="search-meta">
                        [% if exists($result?app) and $result?app != '' %]
                        <span class="search-app">[[ ($app-names($result?app), $result?app)[1] ]]</span>
                        [% endif %]
                        [% if exists($result?section) and $result?section != '' %]
                        <span class="search-section">[[ $result?section ]]</span>
                        [% endif %]
                    </div>
                </li>
                [% endfor %]
            </ol>
            [% else %]
            <p>No results found. Try a different search term.</p>
            [% endif %]
            [% if $search-total > $search-limit %]
            <nav class="search-pagination" aria-label="Search results pages">
                [% if $search-start > 1 %]
                <a class="page-link" href="[[ $context-path ]]/search?q=[[ encode-for-uri($q) ]]&amp;start=[[ $search-start - $search-limit ]]&amp;limit=[[ $search-limit ]]">Previous</a>
                [% endif %]
                [% if $search-total > ($search-start + $search-limit - 1) %]
                <a class="page-link" href="[[ $context-path ]]/search?q=[[ encode-for-uri($q) ]]&amp;start=[[ $search-start + $search-limit ]]&amp;limit=[[ $search-limit ]]">Next</a>
                [% endif %]
            </nav>
            [% endif %]
        </div>
    </div>

    [% endif %]
</div>
[% endtemplate %]
