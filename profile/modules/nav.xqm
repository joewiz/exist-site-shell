xquery version "3.1";

(:~
 : Navigation module for eXist-db site apps.
 :
 : Reads the nav items from the Jinks context (defined in config.json)
 : and returns an array of app descriptors for the nav bar template.
 :
 : Apps that are installed locally get a local URL; apps that are listed
 : in the registry but not installed get their configured fallback URL so
 : that the nav bar remains complete regardless of what is deployed.
 :)
module namespace nav = "http://exist-db.org/site/nav";

import module namespace site-config = "http://exist-db.org/site/shell-config"
    at "site-config.xqm";

(:~
 : Build the nav bar array from the configured items.
 :
 : Each returned map contains:
 :   title     - display label
 :   abbrev    - eXpath package abbreviation
 :   url       - local URL if installed, fallback URL otherwise
 :   active    - true if the current request URI is within this app
 :   installed - true if the app is deployed locally
 :
 : @param $items        sequence of maps from config.json nav.items
 : @param $context-path the request context path (e.g. "/exist")
 : @return array of app-descriptor maps
 :)
declare function nav:apps($items as array(*)?, $context-path as xs:string) as array(*) {
    let $current-uri    := request:get-uri()
    let $server-context := request:get-context-path()
    return array {
        if (exists($items)) then
            for $entry in $items?*
            let $abbrev    := $entry?abbrev
            let $local-path := $server-context || "/apps/" || $abbrev
            let $installed  := xmldb:collection-available("/db/apps/" || $abbrev)
            let $url        :=
                if ($installed) then
                    $local-path
                else
                    site-config:app-url($abbrev)
            (: only include apps that have either a local install or a fallback :)
            where $installed or not(starts-with($url, "#unresolved-"))
            return map {
                "title":     $entry?title,
                "abbrev":    $abbrev,
                "url":       $url,
                "active":    $installed and starts-with($current-uri, $local-path),
                "installed": $installed
            }
        else ()
    }
};
