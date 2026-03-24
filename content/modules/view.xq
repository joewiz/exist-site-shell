xquery version "3.1";

(:~
 : Template view module.
 :
 : Processes Jinks templates with the site shell rendering context.
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

declare option output:method "html";
declare option output:media-type "text/html";

let $context := map:merge((
    config:context(),
    map {
        "nav-apps": nav:apps(),
        "q": request:get-parameter("q", ""),
        "login-error": request:get-attribute("login-error"),
        "search-results":
            let $q := request:get-parameter("q", "")
            return
                if ($q != "") then
                    search:query($q, map {
                        "app": request:get-parameter("app", ())
                    })
                else
                    array {}
    }
))
let $path := request:get-attribute("$path")
return
    tmpl:process($path, $context, map {
        "base": "/db/apps/exist-site-shell/templates",
        "modules": map {
            "search": "http://exist-db.org/site/search",
            "nav": "http://exist-db.org/site/nav",
            "login": "http://exist-db.org/site/login"
        }
    })
