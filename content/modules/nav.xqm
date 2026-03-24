xquery version "3.1";

(:~
 : Navigation module.
 :
 : Discovers installed eXist-db application packages and builds the
 : site navigation menu. Only apps of type "application" are shown.
 :)
module namespace nav = "http://exist-db.org/site/nav";

declare namespace expath = "http://expath.org/ns/pkg";
declare namespace repo = "http://exist-db.org/xquery/repo";

(:~
 : Return an array of maps describing installed application packages,
 : suitable for rendering in the navigation menu.
 :
 : Each map contains:
 :   - title: the package title from expath-pkg.xml
 :   - abbrev: the package abbreviation
 :   - url: the app's context path
 :   - active: true if the current request URI starts with the app's path
 :
 : @return array of app descriptor maps
 :)
declare function nav:apps() as array(*) {
    let $context := request:get-context-path()
    let $current-uri := request:get-uri()
    return array {
        for $uri in repo:list()
        let $repo-meta :=
            try {
                let $raw := repo:get-resource($uri, "repo.xml")
                return
                    if (exists($raw)) then parse-xml(util:binary-to-string($raw))
                    else ()
            } catch * { () }
        let $pkg-meta :=
            try {
                let $raw := repo:get-resource($uri, "expath-pkg.xml")
                return
                    if (exists($raw)) then parse-xml(util:binary-to-string($raw))
                    else ()
            } catch * { () }
        where exists($repo-meta) and exists($pkg-meta)
        let $type := $repo-meta//*:type/string()
        where $type = "application"
        let $abbrev := $pkg-meta/expath:package/@abbrev/string()
        let $title := $pkg-meta/expath:package/expath:title/string()
        let $app-path := $context || "/apps/" || $abbrev
        order by lower-case($title)
        return map {
            "title": $title,
            "abbrev": $abbrev,
            "url": $app-path,
            "active": starts-with($current-uri, $app-path)
        }
    }
};
