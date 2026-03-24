xquery version "3.1";

(:~
 : URL redirect resolver.
 :
 : Checks incoming URIs against the redirect map in data/redirects.xml.
 : Patterns are regex-based; the first match wins.
 :)
module namespace redirects = "http://exist-db.org/site/redirects";

declare namespace r = "http://exist-db.org/site/redirects";

declare variable $redirects:map-path := "/db/apps/exist-site-shell/data/redirects.xml";

(:~
 : Resolve a URI against the redirect map.
 :
 : @param $uri the incoming request URI
 : @return a map with "target" and "status" keys, or empty sequence if no match
 :)
declare function redirects:resolve($uri as xs:string) as map(*)? {
    let $map := doc($redirects:map-path)/r:redirects
    return
        if (exists($map)) then
            let $match :=
                for $rule in $map/r:redirect
                let $pattern := $rule/@pattern/string()
                where matches($uri, $pattern)
                return $rule
            let $first := $match[1]
            return
                if (exists($first)) then
                    map {
                        "target": replace($uri, $first/@pattern/string(), $first/@target/string()),
                        "status": xs:integer(($first/@status, 301)[1])
                    }
                else ()
        else ()
};
