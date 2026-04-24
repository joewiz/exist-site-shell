xquery version "3.1";

(:~
 : Sitewide search module.
 :
 : Queries full-text indexes across all apps in /db/apps using the
 : site-search convention: each registered app may provide a module at
 : modules/site-search-config.xqm that exposes site-search:hits($q, $opts)
 : returning elements with site-* Lucene fields.  Apps without the config
 : module fall back to legacy hardcoded qname queries.
 :
 : Facet counts come from ft:facets() — Lucene-native, scales regardless of
 : result-set size. Filtering uses the "facets" option in ft:query() so
 : Lucene does the work, not post-hoc XQuery where-clauses.
 :)
module namespace search = "http://exist-db.org/site/search";

declare namespace n = "http://exist-db.org/site/nav";
declare namespace xqdoc = "http://www.xqdoc.org/1.0";

(:~ Path to the app registry. :)
declare %private variable $search:REGISTRY-PATH :=
    "/db/apps/exist-site-shell/data/app-registry.xml";

(:~
 : Derive a display title from a search hit.
 :)
declare %private function search:derive-title($hit as node()) as xs:string {
    let $field-title := ft:field($hit, "site-title", "xs:string")
    return
        if ($field-title != "") then $field-title
        else
            let $elem-title := $hit/title/string()
            return
                if ($elem-title != "") then $elem-title
                else replace(util:document-name($hit), "\.[^.]+$", "")
};

(:~
 : Derive a URL for a search hit from its database path.
 :)
declare %private function search:derive-url($hit as node()) as xs:string {
    let $field-url := ft:field($hit, "site-url", "xs:string")
    return
        if ($field-url != "") then
            if (starts-with($field-url, "/") or contains($field-url, "://")) then
                $field-url
            else
                let $app := search:derive-app($hit)
                let $ctx := try { request:get-context-path() } catch * { "/exist" }
                return $ctx || "/apps/" || $app || "/" || $field-url
        else
            let $doc-uri := document-uri(root($hit))
            let $rel-path := substring-after($doc-uri, "/db/apps/")
            let $ctx := try { request:get-context-path() } catch * { "/exist" }
            return
                if ($rel-path) then
                    if (matches($rel-path, "^[^/]+/data/articles/([^/]+)/")) then
                        $ctx || "/apps/" || substring-before($rel-path, "/") || "/articles/" ||
                        replace($rel-path, "^[^/]+/data/articles/([^/]+)/.*$", "$1")
                    else if (matches($rel-path, "^[^/]+/data/functions/")) then
                        $ctx || "/apps/" || substring-before($rel-path, "/") || "/functions/"
                    else if (ends-with($rel-path, ".xml")) then
                        $ctx || "/apps/" || substring($rel-path, 1, string-length($rel-path) - 4)
                    else
                        $ctx || "/apps/" || $rel-path
                else
                    "#"
};

(:~
 : Derive the app name from a search hit using the site-app index field.
 :)
declare %private function search:derive-app($hit as node()) as xs:string {
    let $field-app := ft:field($hit, "site-app", "xs:string")
    return
        if ($field-app != "") then $field-app
        else
            let $rel-path := substring-after(document-uri(root($hit)), "/db/apps/")
            return
                if (contains($rel-path, "/")) then substring-before($rel-path, "/")
                else $rel-path
};

(:~
 : Return elements matching a full-text query across all registered apps.
 :
 : For each installed app in the registry, checks for a site-search config
 : module (modules/site-search-config.xqm).  If present, delegates to the
 : app's site-search:hits() function.  Otherwise falls back to legacy
 : hardcoded qname queries.
 :)
declare %private function search:hits($q as xs:string, $opts as map(*)) as element()* {
    for $entry in doc($search:REGISTRY-PATH)/n:app-registry/n:app
    let $abbrev := $entry/@abbrev/string()
    where xmldb:collection-available("/db/apps/" || $abbrev)
    return search:app-hits($abbrev, $q, $opts)
};

(:~
 : Query a single app for search hits.
 :
 : Tries the site-search convention first; falls back to legacy qnames.
 :)
declare %private function search:app-hits(
    $abbrev as xs:string, $q as xs:string, $opts as map(*)
) as element()* {
    let $config-path := "/db/apps/" || $abbrev || "/modules/site-search-config.xqm"
    return
        if (util:binary-doc-available($config-path)) then
            try {
                util:eval(
                    'import module namespace site-search = "http://exist-db.org/site/search-config"'
                    || '    at "' || $config-path || '";'
                    || ' site-search:hits($q, $opts)',
                    false(),
                    (xs:QName("q"), $q, xs:QName("opts"), $opts)
                )
            } catch * {
                util:log("WARN", ("site-search: error from ", $abbrev, ": ", $err:description)),
                search:legacy-hits($abbrev, $q, $opts)
            }
        else
            search:legacy-hits($abbrev, $q, $opts)
};

(:~
 : Legacy fallback: query known element types in an app's collection.
 :)
declare %private function search:legacy-hits(
    $abbrev as xs:string, $q as xs:string, $opts as map(*)
) as element()* {
    let $root := "/db/apps/" || $abbrev
    return (
        collection($root)//topic[ft:query(., $q, $opts)],
        collection($root)/xqdoc:xqdoc[ft:query(., $q, $opts)],
        collection($root)//notebook[ft:query(., $q, $opts)],
        collection($root)//post[ft:query(., $q, $opts)]
    )
};

(:~
 : Execute a sitewide full-text search.
 :
 : @param $q the search query string
 : @param $options optional map with:
 :   - limit: max results (default 20)
 :   - app: restrict to a single app (facet filter)
 :   - section: restrict to a section within the app (facet filter)
 : @return map with:
 :   - results: array of result maps (title, snippet, app, section, url, score)
 :   - hier-facets: map of app → { count, sections: { section → count } }
 :)
declare function search:query($q as xs:string, $options as map(*)) as map(*) {
    if ($q = "") then
        map { "results": array {}, "hier-facets": map {} }
    else
    let $limit          := ($options?limit, 10)[1]
    let $start          := max((($options?start, 1)[1], 1))
    let $app-filter     := $options?app
    let $section-filter := $options?section
    let $base-opts      := map { "fields": "site-content" }

    (: --- Step 1: Unfiltered query for app-level facet counts ---
     : ft:facets() must be called while the Lucene context is intact,
     : immediately on the sequence returned by ft:query(). :)
    let $all-hits  := search:hits($q, $base-opts)
    let $app-facets := ft:facets($all-hits, "site-app", ())

    (: --- Step 2: App-filtered query for section facet counts ---
     : Pass app filter via Lucene "facets" option — not post-hoc XQuery. :)
    let $app-hits :=
        if ($app-filter and $app-filter != "") then
            search:hits($q,
                map:merge(($base-opts, map { "facets": map { "site-app": $app-filter } })))
        else ()
    let $section-facets :=
        if ($app-filter and $app-filter != "") then
            ft:facets($app-hits, "site-section", ())
        else map {}

    (: --- Step 3: Build hierarchical facet structure ---
     : For the selected app, nest section counts beneath it. :)
    let $hier-facets := map:merge(
        for $app in map:keys($app-facets)
        return map {
            $app: map {
                "count":    $app-facets($app),
                "sections": if ($app-filter = $app) then $section-facets else map {}
            }
        }
    )

    (: --- Step 4: Materialise result hits while Lucene context is intact ---
     : Always use $all-hits for materialisation so ft:highlight-field-matches()
     : has the full Lucene match context.
     : App filtering is applied post-hoc using the materialised app field. :)
    let $all-maps :=
        for $hit in $all-hits
        let $app := search:derive-app($hit)
        (: Skip hits outside the requested app early to avoid unnecessary work :)
        where not($app-filter and $app-filter != "") or $app = $app-filter
        return map {
            "doc-uri": document-uri(root($hit)),
            "score":   ft:score($hit),
            "title":   search:derive-title($hit),
            "snippet":
                let $highlighted := ft:highlight-field-matches($hit, "site-content")
                return
                    if (exists($highlighted)) then
                        let $text := substring(string-join($highlighted//text(), " "), 1, 200)
                        let $nodes := $highlighted//exist:match/..
                        return
                            if (exists($nodes)) then
                                serialize(
                                    element span {
                                        for $node in ($nodes[1])/node()
                                        return
                                            if ($node instance of element(exist:match)) then
                                                element mark { string($node) }
                                            else
                                                substring(string($node), 1, 80)
                                    },
                                    map { "method": "xml" }
                                )
                            else
                                substring($text, 1, 200)
                    else "",
            "app":     $app,
            "section": ft:field($hit, "site-section", "xs:string"),
            "url":     search:derive-url($hit)
        }

    (: --- Step 5: Deduplicate by URL, keeping highest-scoring hit ---
     : Keyed by URL (not doc-uri) so that module-level and function-level
     : hits from the same document survive as separate results. :)
    let $deduped := fold-left($all-maps, map {}, function($acc, $m) {
        let $key := $m?url
        return
            if (map:contains($acc, $key) and $acc($key)?score >= $m?score) then $acc
            else map:put($acc, $key, $m)
    })

    (: --- Step 6: Build ordered result list ---
     : Section filter applied post-hoc (within the already app-filtered set). :)
    let $results :=
        for $uri in map:keys($deduped)
        let $m := $deduped($uri)
        where not($section-filter and $section-filter != "") or $m?section = $section-filter
        order by $m?score descending
        return map {
            "title":   $m?title,
            "snippet": $m?snippet,
            "app":     $m?app,
            "section": $m?section,
            "url":     $m?url,
            "score":   $m?score
        }
    let $total := count($results)
    return map {
        "total":       $total,
        "start":       $start,
        "limit":       $limit,
        "results":     array { subsequence($results, $start, $limit) },
        "hier-facets": $hier-facets
    }
};
