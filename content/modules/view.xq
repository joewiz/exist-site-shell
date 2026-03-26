xquery version "3.1";

(:~
 : Template view module.
 :
 : Reads a Jinks template file, builds the rendering context with
 : site config, navigation, search results, and user state, then
 : passes everything to tmpl:process().
 :)

import module namespace tmpl = "http://e-editiones.org/xquery/templates";
import module namespace config = "http://exist-db.org/site/config"
    at "config.xqm";
import module namespace nav = "http://exist-db.org/site/nav"
    at "nav.xqm";
import module namespace search = "http://exist-db.org/site/search"
    at "search.xqm";
import module namespace login = "http://exist-db.org/site/login"
    at "login.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";
declare option output:indent "no";

(:~
 : Resolve template paths relative to the shell's app root.
 :
 : Also handles the "site:" prefix so that apps in other packages
 : can extend shell templates via [% extends "site:base-page.html" %].
 :
 : @param $relPath relative path to resolve
 : @return map with "path" and "content" keys, or empty sequence
 :)
declare function local:resolver($relPath as xs:string) as map(*)? {
    let $effectivePath :=
        if (starts-with($relPath, "site:")) then
            (: Cross-package reference — resolve within shell's templates/ :)
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

(: Get template path from controller's set-attribute :)
let $template-rel := request:get-attribute("template")

(: Read the template content :)
let $resolved := local:resolver($template-rel)
let $template := $resolved?content

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
                array {}
    }
))

return
    if (exists($template)) then
        tmpl:process($template, $context, map {
            "resolver": local:resolver#1
        })
    else
        <div>Template not found: {$template-rel}</div>
