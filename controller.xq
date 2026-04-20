xquery version "3.1";

(:~
 : URL routing controller for the site shell.
 :
 : Handles:
 :   /                  - landing page
 :   /search?q=...      - sitewide search results
 :   /login             - login form (GET) / authenticate (POST)
 :   /logout            - logout and redirect to /
 :   /apps              - app launcher
 :   /about, /community, /press, /privacy - static Markdown pages
 :   /resources/*       - static assets (CSS, images)
 :   *                  - check redirect map, then 404
 :)

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

import module namespace login = "http://exist-db.org/xquery/login"
    at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace redirects = "http://exist-db.org/site/redirects"
    at "modules/redirects.xqm";

(: Static Markdown pages :)
declare variable $local:page-slugs := ("about", "community", "press", "privacy");

(: Process persistent login on every request :)
let $_ := login:set-user("org.exist.login", xs:dayTimeDuration("P7D"), false())
let $current-user := request:get-attribute("org.exist.login.user")

return

(: Redirect trailing slashes to canonical non-slash URL (except root) :)
if ($exist:path != "/" and ends-with($exist:path, "/")
    and not(starts-with($exist:path, "/resources/"))) then
    let $clean := replace($exist:path, "/+$", "")
    let $qs := request:get-query-string()
    let $target := request:get-context-path() || $exist:prefix || $exist:controller || $clean
        || (if ($qs) then "?" || $qs else "")
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$target}"/>
        </dispatch>

else if ($exist:path = "" or $exist:path = "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/view.xq">
            <set-attribute name="template" value="templates/index.tpl"/>
        </forward>
    </dispatch>

else if ($exist:path = "/search") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/view.xq">
            <set-attribute name="template" value="templates/search-results.tpl"/>
        </forward>
    </dispatch>

else if ($exist:path = "/apps") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/view.xq">
            <set-attribute name="template" value="templates/apps.tpl"/>
        </forward>
    </dispatch>

else if (substring-after($exist:path, "/") = $local:page-slugs) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/view.xq">
            <set-attribute name="template" value="templates/page.tpl"/>
            <set-attribute name="page-slug" value="{substring-after($exist:path, '/')}"/>
        </forward>
    </dispatch>

else if ($exist:path = "/login" and request:get-method() = "POST") then (
    util:declare-option("exist:serialize", "method=json media-type=application/json"),
    if ($current-user and not($current-user = ("guest", "nobody"))) then
        <status xmlns:json="http://www.json.org">
            <user>{$current-user}</user>
            <isAdmin json:literal="true">{sm:is-dba($current-user)}</isAdmin>
        </status>
    else (
        response:set-status-code(401),
        <status>
            <message>Login failed</message>
        </status>
    )
)

else if ($exist:path = "/login") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/view.xq">
            <set-attribute name="template" value="templates/login.tpl"/>
        </forward>
    </dispatch>

else if ($exist:path = "/logout") then (
    response:set-cookie("org.exist.login", "deleted", xs:dayTimeDuration("-P1D"), false(), (),
        request:get-context-path()),
    session:invalidate(),
    let $redirect := request:get-parameter("redirect", request:get-context-path() || "/apps/exist-site-shell")
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$redirect}"/>
        </dispatch>
)

else if (starts-with($exist:path, "/resources/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}{$exist:path}"/>
    </dispatch>

else
    (: Check redirect map before returning 404 :)
    let $uri := request:get-uri()
    let $redirect := redirects:resolve($uri)
    return
        if ($redirect) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{$redirect?target}"/>
            </dispatch>
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/view.xq">
                    <set-attribute name="template" value="templates/error-404.tpl"/>
                </forward>
            </dispatch>
