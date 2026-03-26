xquery version "3.1";

(:~
 : Testimonials module.
 :
 : Reads testimonial quotes from data/testimonials.xml.
 :)
module namespace testimonials = "http://exist-db.org/site/testimonials";

import module namespace config = "http://exist-db.org/site/config"
    at "../content/exist-site.xqm";

declare namespace t = "http://exist-db.org/site/testimonials";

(:~
 : Return an array of testimonial maps.
 :
 : @param $limit max number of testimonials (0 = all)
 : @return array of maps with quote, author, role, org
 :)
declare function testimonials:list($limit as xs:integer) as array(*) {
    let $path := $config:app-root || "/data/testimonials.xml"
    let $doc := doc($path)/t:testimonials
    let $items :=
        if ($limit > 0) then
            subsequence($doc/t:testimonial, 1, $limit)
        else
            $doc/t:testimonial
    return array {
        for $t in $items
        return map {
            "quote": $t/t:quote/string(),
            "author": $t/t:author/string(),
            "role": $t/t:role/string(),
            "org": $t/t:org/string()
        }
    }
};
