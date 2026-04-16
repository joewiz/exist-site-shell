xquery version "3.1";

(:~
 : XQSuite tests for search:query() — sitewide search with ft:facets().
 :
 : Tests cover:
 :   - Result structure: results array, hier-facets map
 :   - Hierarchical facet structure: each app entry has count + sections
 :   - App filter: uses Lucene "facets" option (not post-hoc XQuery)
 :   - Section filter: narrows results within a filtered app
 :   - Empty query: returns empty results and empty facets
 :   - Limit: results are bounded by the limit option
 :
 : Requires: docs app installed with at least one indexed article and function.
 : All queries use a common search term ("exist") likely to match docs content.
 :)
module namespace search-test = "http://exist-db.org/apps/exist-site-shell/test/search-suite";

import module namespace search = "http://exist-db.org/site/search"
    at "xmldb:exist:///db/apps/exist-site-shell/modules/search.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

(: ============================================================ :)
(:  Empty query — no results, no facets                        :)
(: ============================================================ :)

declare %test:assertTrue
function search-test:empty-query-returns-empty-results() {
    let $r := search:query("", map {})
    return array:size($r?results) = 0
};

declare %test:assertTrue
function search-test:empty-query-returns-empty-facets() {
    let $r := search:query("", map {})
    return map:size($r?hier-facets) = 0
};

(: ============================================================ :)
(:  Result structure                                            :)
(: ============================================================ :)

declare %test:assertTrue
function search-test:query-returns-results-key() {
    let $r := search:query("exist", map {})
    return map:contains($r, "results")
};

declare %test:assertTrue
function search-test:query-returns-hier-facets-key() {
    let $r := search:query("exist", map {})
    return map:contains($r, "hier-facets")
};

declare %test:assertTrue
function search-test:results-is-array() {
    let $r := search:query("exist", map {})
    return $r?results instance of array(*)
};

declare %test:assertTrue
function search-test:hier-facets-is-map() {
    let $r := search:query("exist", map {})
    return $r?hier-facets instance of map(*)
};

(: ============================================================ :)
(:  Hierarchical facet structure                                :)
(: ============================================================ :)

declare %test:assertTrue
function search-test:hier-facets-has-entries() {
    let $r := search:query("exist", map {})
    return map:size($r?hier-facets) > 0
};

declare %test:assertTrue
function search-test:every-facet-entry-has-count() {
    let $r := search:query("exist", map {})
    return every $app in map:keys($r?hier-facets)
           satisfies map:contains($r?hier-facets($app), "count")
};

declare %test:assertTrue
function search-test:every-facet-entry-has-sections-map() {
    let $r := search:query("exist", map {})
    return every $app in map:keys($r?hier-facets)
           satisfies $r?hier-facets($app)?sections instance of map(*)
};

declare %test:assertTrue
function search-test:facet-counts-are-positive-integers() {
    let $r := search:query("exist", map {})
    return every $app in map:keys($r?hier-facets)
           satisfies $r?hier-facets($app)?count castable as xs:positiveInteger
};

(: ============================================================ :)
(:  App filter — uses Lucene native facet filtering             :)
(: ============================================================ :)

declare %test:assertTrue
function search-test:app-filter-narrows-results() {
    let $all     := search:query("exist", map {})
    let $filtered := search:query("exist", map { "app": "docs" })
    return
        if (array:size($all?results) = 0) then true()  (: no data, skip :)
        else array:size($filtered?results) <= array:size($all?results)
};

declare %test:assertTrue
function search-test:app-filter-results-all-from-that-app() {
    let $r := search:query("exist", map { "app": "docs" })
    return every $result in $r?results?*
           satisfies $result?app = "docs"
};

declare %test:assertTrue
function search-test:app-filter-populates-section-facets() {
    let $r := search:query("exist", map { "app": "docs" })
    return
        if (array:size($r?results) = 0) then true()  (: no data, skip :)
        else
            (: When app filter is set, the selected app's section facets should be populated :)
            map:contains($r?hier-facets, "docs") and
            map:size($r?hier-facets("docs")?sections) > 0
};

declare %test:assertTrue
function search-test:no-app-filter-sections-maps-are-empty() {
    let $r := search:query("exist", map {})
    (: Without app filter, no app should have section counts populated :)
    return every $app in map:keys($r?hier-facets)
           satisfies map:size($r?hier-facets($app)?sections) = 0
};

(: ============================================================ :)
(:  Section filter                                              :)
(: ============================================================ :)

declare %test:assertTrue
function search-test:section-filter-narrows-within-app() {
    let $app-only    := search:query("exist", map { "app": "docs" })
    let $sec-filtered := search:query("exist", map { "app": "docs", "section": "articles" })
    return
        if (array:size($app-only?results) = 0) then true()
        else array:size($sec-filtered?results) <= array:size($app-only?results)
};

declare %test:assertTrue
function search-test:section-filter-results-all-match-section() {
    let $r := search:query("exist", map { "app": "docs", "section": "articles" })
    return every $result in $r?results?*
           satisfies $result?section = "articles"
};

(: ============================================================ :)
(:  Limit option                                                :)
(: ============================================================ :)

declare %test:assertTrue
function search-test:limit-bounds-results() {
    let $r := search:query("exist", map { "limit": 3 })
    return array:size($r?results) <= 3
};

declare %test:assertTrue
function search-test:default-limit-is-20() {
    let $r := search:query("exist", map {})
    return array:size($r?results) <= 20
};

(: ============================================================ :)
(:  Result item structure                                       :)
(: ============================================================ :)

declare %test:assertTrue
function search-test:result-items-have-required-keys() {
    let $r := search:query("exist", map {})
    return every $item in $r?results?*
           satisfies (
               map:contains($item, "title")   and
               map:contains($item, "url")     and
               map:contains($item, "app")     and
               map:contains($item, "section") and
               map:contains($item, "score")
           )
};

declare %test:assertTrue
function search-test:result-urls-are-non-empty() {
    let $r := search:query("exist", map {})
    return every $item in $r?results?*
           satisfies $item?url != "" and $item?url != "#"
};

declare %test:assertTrue
function search-test:results-ordered-by-score-descending() {
    let $r := search:query("exist", map {})
    let $scores := $r?results?*?score
    return
        if (count($scores) < 2) then true()
        else every $i in 1 to count($scores) - 1
             satisfies $scores[$i] >= $scores[$i + 1]
};
