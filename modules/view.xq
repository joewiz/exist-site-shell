xquery version "3.1";

(:~
 : Template view module.
 :
 : Reads a Jinks template, builds the rendering context, and
 : calls tmpl:process(). Each page template uses Jinks "extends"
 : to inherit the base-page shell (nav, footer, etc.).
 :)

import module namespace tmpl = "http://e-editiones.org/xquery/templates";
import module namespace config = "http://exist-db.org/site/config"
    at "../content/exist-site.xqm";
import module namespace nav = "http://exist-db.org/site/nav"
    at "nav.xqm";
import module namespace search = "http://exist-db.org/site/search"
    at "search.xqm";
import module namespace login = "http://exist-db.org/site/login"
    at "login.xqm";
import module namespace pages = "http://exist-db.org/site/pages"
    at "pages.xqm";
import module namespace launcher = "http://exist-db.org/site/launcher"
    at "launcher.xqm";
import module namespace news = "http://exist-db.org/site/news"
    at "news.xqm";
import module namespace testimonials = "http://exist-db.org/site/testimonials"
    at "testimonials.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";
declare option output:indent "no";

(:~
 : Resolve template paths relative to the shell's app root.
 : Also handles the "site:" prefix for cross-package extends.
 :)
declare function local:resolver($relPath as xs:string) as map(*)? {
    let $effectivePath :=
        if (starts-with($relPath, "site:")) then
            $config:app-root || "/templates/" || substring-after($relPath, "site:")
        else
            $config:app-root || "/" || $relPath
    let $content :=
        if (util:binary-doc-available($effectivePath)) then
            util:binary-doc($effectivePath) => util:binary-to-string()
        else if (doc-available($effectivePath)) then
            doc($effectivePath) => serialize()
        else
            ()
    return
        if ($content) then
            map {
                "path": $effectivePath,
                "content": $content
            }
        else
            ()
};

(: Read controller attributes :)
let $template-rel := request:get-attribute("template")
let $page-slug := request:get-attribute("page-slug")

(: Render Markdown page if requested :)
let $page :=
    if ($page-slug) then
        pages:render($page-slug)
    else
        map {}

(: Build rendering context :)
let $q := request:get-parameter("q", "")
let $context := map:merge((
    config:context(),
    map {
        "nav-apps": nav:apps(),
        "q": $q,
        "login-error": request:get-attribute("login-error"),
        "search-results":
            if ($q != "") then
                search:query($q, map {
                    "app": request:get-parameter("app", ())
                })
            else
                array {},
        "page-title": ($page?title, "")[1],
        "page-html": $page?html,
        "testimonials": testimonials:list(4),
        "news-items": news:latest(3),
        "launcher-apps": launcher:apps()
    }
))

(: Render the template — extends handles the base-page wrapping :)
let $resolved := local:resolver($template-rel)
return
    if (exists($resolved?content)) then
        tmpl:process($resolved?content, $context, map {
            "resolver": local:resolver#1
        })
    else
        <div>Template not found: {$template-rel}</div>
