xquery version "3.1";

(:~
 : Navigation module.
 :
 : Reads the nav bar app list from data/nav-config.xml.
 : Only apps listed there appear in the navigation — the shell
 : owns the list, not individual apps.
 :)
module namespace nav = "http://exist-db.org/site/nav";

import module namespace config = "http://exist-db.org/site/config"
    at "../content/exist-site.xqm";

declare namespace n = "http://exist-db.org/site/nav";

(:~
 : Return an array of maps for the nav bar, in document order.
 :
 : Only apps listed in data/nav-config.xml are included.
 : Apps that are listed but not installed are silently skipped.
 :
 : Each map contains:
 :   - title: display title (from nav-config.xml)
 :   - abbrev: package abbreviation
 :   - url: the app's context path
 :   - active: true if the current request URI starts with the app's path
 :
 : @return array of app descriptor maps
 :)
declare function nav:apps() as array(*) {
    let $context := request:get-context-path()
    let $current-uri := request:get-uri()
    let $nav-config := doc($config:app-root || "/data/nav-config.xml")/n:nav-config
    return array {
        for $entry in $nav-config/n:app
        let $abbrev := $entry/@abbrev/string()
        let $app-path := $context || "/apps/" || $abbrev
        (: only include if the app is actually installed :)
        where xmldb:collection-available("/db/apps/" || $abbrev)
        return map {
            "title": $entry/@title/string(),
            "abbrev": $abbrev,
            "url": $app-path,
            "active": starts-with($current-uri, $app-path)
        }
    }
};
