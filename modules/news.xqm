xquery version "3.1";

(:~
 : News feed module.
 :
 : Fetches recent entries from installed blog/content apps.
 : Falls back gracefully if no blog app is installed.
 :)
module namespace news = "http://exist-db.org/site/news";

(:~
 : Fetch the latest N news entries.
 :
 : Currently returns release information from the running eXist instance.
 : When a blog app is installed, this can be extended to pull recent posts.
 :
 : @param $limit maximum number of entries to return
 : @return array of maps with title, date, snippet, url
 :)
declare function news:latest($limit as xs:integer) as array(*) {
    (: For now, return the current eXist version as a "release" entry :)
    let $version := system:get-version()
    let $build := system:get-build()
    return array {
        map {
            "title": "eXist-db " || $version || " available",
            "date": format-date(current-date(), "[MNn] [D], [Y]"),
            "snippet": "The current running instance is eXist-db " || $version || " (build " || $build || ").",
            "url": "https://github.com/eXist-db/exist/releases"
        }
    }
};
