xquery version "3.1";

(:~
 : Markdown page renderer.
 :
 : Reads .md files from data/pages/ and converts them to HTML
 : using the exist-markdown module's markdown:parse() function.
 :)
module namespace pages = "http://exist-db.org/site/pages";

import module namespace markdown = "http://exist-db.org/xquery/markdown";
import module namespace config = "http://exist-db.org/site/config"
    at "../content/exist-site.xqm";

(:~
 : Render a Markdown page to HTML.
 :
 : @param $slug the page name (without .md extension)
 : @return map with "title", "html", and "found" keys
 :)
declare function pages:render($slug as xs:string) as map(*) {
    let $path := $config:app-root || "/data/pages/" || $slug || ".md"
    return
        if (util:binary-doc-available($path)) then
            let $content := util:binary-to-string(util:binary-doc($path))
            let $html := markdown:to-html($content)
            let $title := ($html[self::h1], $html//h1)[1]/string()
            return map {
                "found": true(),
                "title": ($title, $slug)[1],
                "html": $html
            }
        else
            map {
                "found": false(),
                "title": $slug,
                "html": <body><p>Page not found.</p></body>
            }
};

(:~
 : List available pages.
 :
 : @return array of maps with "slug" and "title" keys
 :)
declare function pages:list() as array(*) {
    let $pages-coll := $config:app-root || "/data/pages"
    return array {
        if (xmldb:collection-available($pages-coll)) then
            for $resource in xmldb:get-child-resources($pages-coll)
            where ends-with($resource, ".md")
            let $slug := replace($resource, "\.md$", "")
            let $content := util:binary-to-string(util:binary-doc($pages-coll || "/" || $resource))
            let $title := replace(head(tokenize($content, "\n")[starts-with(., "# ")]), "^#\s*", "")
            order by lower-case($title)
            return map {
                "slug": $slug,
                "title": $title
            }
        else ()
    }
};
