xquery version "3.1";

(:~
 : URL routing controller for the site shell.
 :
 : Handles:
 :   /search?q=...     - sitewide search results
 :   /login             - login form (GET) / authenticate (POST)
 :   /logout            - logout and redirect to /
 :   /resources/*       - static assets (CSS, images)
 :   *                  - check redirect map, then 404
 :)

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

import module namespace redirects = "http://exist-db.org/site/redirects"
    at "modules/redirects.xqm";

if ($exist:path = "" or $exist:path = "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="/"/>
    </dispatch>

else if ($exist:path = "/search") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/view.xq">
            <set-attribute name="template" value="templates/search-results.html"/>
        </forward>
    </dispatch>

else if ($exist:path = "/login") then
    if (request:get-method() = "POST") then
        let $user := request:get-parameter("user", ())
        let $password := request:get-parameter("password", ())
        let $login := xmldb:authenticate("/db", $user, $password)
        return
            if ($login) then
                let $_ := session:set-attribute("user", $user)
                let $redirect := request:get-parameter("redirect", "/")
                return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <redirect url="{$redirect}"/>
                    </dispatch>
            else
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/modules/view.xq">
                        <set-attribute name="template" value="templates/login.html"/>
                        <set-attribute name="login-error" value="Invalid username or password"/>
                    </forward>
                </dispatch>
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/view.xq">
                <set-attribute name="template" value="templates/login.html"/>
            </forward>
        </dispatch>

else if ($exist:path = "/logout") then
    let $_ := session:invalidate()
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="/"/>
        </dispatch>

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
                    <set-attribute name="template" value="templates/error-404.html"/>
                </forward>
            </dispatch>
