xquery version "3.1";

(:~
 : Sitewide search module.
 :
 : Queries full-text indexes across all site-* indexed apps.
 : Apps contribute to sitewide search by defining fields named
 : site-content, site-title, site-app, and site-section in their
 : collection.xconf index configurations.
 :)
module namespace search = "http://exist-db.org/site/search";

import module namespace kwic = "http://exist-db.org/xquery/kwic";

(:~
 : Execute a sitewide full-text search.
 :
 : @param $q the search query string
 : @param $options optional map with:
 :   - limit: max results (default 20)
 :   - app: restrict to a single app collection
 : @return array of result maps with title, snippet, app, section, score
 :)
declare function search:query($q as xs:string, $options as map(*)) as array(*) {
    let $limit := ($options?limit, 20)[1]
    let $app-filter := $options?app
    let $hits :=
        if ($app-filter) then
            collection("/db/apps/" || $app-filter)//*[ft:query(., $q, map { "fields": "site-content" })]
        else
            collection("/db/apps")//*[ft:query(., $q, map { "fields": "site-content" })]
    return array {
        for $hit in subsequence($hits, 1, $limit)
        order by ft:score($hit) descending
        return map {
            "title": ft:field($hit, "site-title", "xs:string"),
            "snippet": kwic:summarize($hit, <config width="80"/>),
            "app": ft:field($hit, "site-app", "xs:string"),
            "section": ft:field($hit, "site-section", "xs:string"),
            "score": ft:score($hit)
        }
    }
};
