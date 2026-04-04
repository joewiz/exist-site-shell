xquery version "3.1";

(:~
 : Sitewide search module.
 :
 : Queries full-text indexes across all apps in /db/apps.
 : Uses site-* index fields when available, falls back to
 : general full-text search otherwise.
 :)
module namespace search = "http://exist-db.org/site/search";

import module namespace kwic = "http://exist-db.org/xquery/kwic";

(:~
 : Derive a display title from a search hit.
 : Tries site-title field first, then common document elements,
 : then falls back to the resource filename.
 :)
declare %private function search:derive-title($hit as node()) as xs:string {
    let $field-title := ft:field($hit, "site-title", "xs:string")
    return
        if ($field-title != "") then $field-title
        else
            let $doc := root($hit)
            let $doc-title := (
                $doc//*:title[1],
                $doc//*:h1[1],
                $doc//*:heading[@level="1"][1]
            )[1]/string()
            return
                if ($doc-title != "") then $doc-title
                else replace(util:document-name($hit), "\.[^.]+$", "")
};

(:~
 : Derive a URL for a search hit from its database path.
 : Maps /db/apps/{abbrev}/... to /exist/apps/{abbrev}/...
 :)
declare %private function search:derive-url($hit as node()) as xs:string {
    let $doc-uri := document-uri(root($hit))
    let $rel-path := substring-after($doc-uri, "/db/apps/")
    return
        if ($rel-path) then
            request:get-context-path() || "/apps/" || $rel-path
        else
            "#"
};

(:~
 : Derive the app name from a hit's collection path.
 :)
declare %private function search:derive-app($hit as node()) as xs:string {
    let $field-app := ft:field($hit, "site-app", "xs:string")
    return
        if ($field-app != "") then $field-app
        else
            let $doc-uri := document-uri(root($hit))
            let $rel-path := substring-after($doc-uri, "/db/apps/")
            return
                if (contains($rel-path, "/")) then
                    substring-before($rel-path, "/")
                else
                    $rel-path
};

(:~
 : Execute a sitewide full-text search.
 :
 : @param $q the search query string
 : @param $options optional map with:
 :   - limit: max results (default 20)
 :   - app: restrict to a single app collection
 : @return array of result maps with title, snippet, app, url, score
 :)
declare function search:query($q as xs:string, $options as map(*)) as array(*) {
    let $limit := ($options?limit, 20)[1]
    let $app-filter := $options?app
    let $collection :=
        if ($app-filter) then
            "/db/apps/" || $app-filter
        else
            "/db/apps"
    (: Try site-content field first, fall back to general ft:query :)
    let $hits := (
        collection($collection)//*[ft:query(., $q, map { "fields": "site-content" })],
        collection($collection)//*[ft:query(., $q)]
    )
    (: Deduplicate by document URI — keep highest-scoring hit per document :)
    let $seen := map {}
    return array {
        let $results :=
            for $hit in $hits
            let $doc-uri := document-uri(root($hit))
            group by $doc-uri
            let $best := (for $h in $hit order by ft:score($h) descending return $h)[1]
            order by ft:score($best) descending
            return map {
                "title": search:derive-title($best),
                "snippet": string-join(kwic:summarize($best, <config width="80"/>)//text(), ""),
                "app": search:derive-app($best),
                "url": search:derive-url($best),
                "score": ft:score($best)
            }
        return subsequence($results, 1, $limit)
    }
};
