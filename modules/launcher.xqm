xquery version "3.1";

(:~
 : App launcher module.
 :
 : Lists installed application packages with title, description,
 : icon, and link. Public-facing equivalent of Dashboard's launcher.
 :)
module namespace launcher = "http://exist-db.org/site/launcher";

declare namespace expath = "http://expath.org/ns/pkg";
declare namespace repo = "http://exist-db.org/xquery/repo";

(:~
 : Return an array of maps describing installed application packages.
 :
 : Each map contains:
 :   - title: the package title
 :   - abbrev: package abbreviation
 :   - description: from repo.xml
 :   - url: the app's context path
 :   - icon: URL to the app's icon (or empty string if none)
 :
 : @return array of app descriptor maps
 :)
declare function launcher:apps() as array(*) {
    let $context := request:get-context-path()
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
        let $description := $repo-meta//*:description/string()
        let $app-path := $context || "/apps/" || $abbrev
        let $has-icon :=
            try { exists(repo:get-resource($uri, "icon.png")) }
            catch * { false() }
        order by lower-case($title)
        return map {
            "title": $title,
            "abbrev": $abbrev,
            "description": $description,
            "url": $app-path,
            "icon": if ($has-icon) then $app-path || "/icon.png" else ""
        }
    }
};
