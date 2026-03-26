xquery version "3.1";

(:~
 : Template view module.
 :
 : Two-pass rendering: first renders the content template, then
 : wraps the result in the base-page shell template.
 :
 : This avoids the Jinks "extends" mechanism which has a context
 : variable propagation bug in recent versions. Instead, view.xq
 : renders the page-specific content template, then renders the
 : base template with that content as a variable.
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
let $content-template := request:get-attribute("template")
let $page-slug := request:get-attribute("page-slug")

(: Render Markdown page if requested :)
let $page :=
    if ($page-slug) then
        pages:render($page-slug)
    else
        map {}

(: Determine page title :)
let $page-title :=
    if ($page?title) then $page?title || " —" || $config:site-name
    else if ($content-template = "templates/index.tpl") then
        "eXist-db —The Open Source Native XML Database"
    else if ($content-template = "templates/search-results.tpl") then
        "Search —" || $config:site-name
    else if ($content-template = "templates/login.tpl") then
        "Login —" || $config:site-name
    else if ($content-template = "templates/apps.tpl") then
        "Applications —" || $config:site-name
    else if ($content-template = "templates/error-404.tpl") then
        "Page Not Found —" || $config:site-name
    else
        $config:site-name

(: Map template paths to content-only templates :)
let $content-file := replace($content-template, "templates/([^.]+)\.tpl", "templates/$1-content.tpl")

(: Extra <head> content for specific pages :)
let $extra-head :=
    if ($content-template = "templates/index.html") then
        '<link rel="stylesheet" href="' || $config:shell-base || '/resources/css/landing.css"/>'
    else
        ""

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
        "page-title": $page-title,
        "page-html": $page?html,
        "extra-head": $extra-head,
        "testimonials": testimonials:list(4),
        "news-items": news:latest(3),
        "launcher-apps": launcher:apps()
    }
))

(: Pass 1: render the content template :)
let $content-resolved := local:resolver($content-file)
let $page-content :=
    if (exists($content-resolved?content)) then
        tmpl:process($content-resolved?content, $context, map {
            "resolver": local:resolver#1
        })
    else
        <div>Content template not found: {$content-file}</div>

(: Pass 2: render base-page.html with $page-content injected :)
let $base-resolved := local:resolver("templates/base-page.tpl")
let $full-context := map:merge((
    $context,
    map { "page-content": $page-content }
))
return
    if (exists($base-resolved?content)) then
        tmpl:process($base-resolved?content, $full-context, map {
            "resolver": local:resolver#1
        })
    else
        <div>Base template not found</div>
