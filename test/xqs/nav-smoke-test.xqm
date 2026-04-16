xquery version "3.1";

(:~
 : Smoke tests for sitewide nav bar links.
 :
 : Fetches every internal nav link and asserts that it returns HTTP 200.
 : External links (Source, github.com, etc.) are skipped — we don't
 : want flaky tests that depend on internet connectivity.
 :
 : These tests require the server to be running and the profile apps
 : (dashboard, docs, notebook, blog) to be installed.
 :)
module namespace nav-smoke = "http://exist-db.org/apps/exist-site-shell/test/nav-smoke";

import module namespace nav = "http://exist-db.org/site/nav"
    at "xmldb:exist:///db/apps/exist-site-shell/modules/nav.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace http = "http://expath.org/ns/http-client";

(:~
 : Build the base URL from the current request context.
 : Falls back to http://localhost:8080 when called outside a request.
 :)
declare %private function nav-smoke:base-url() as xs:string {
    let $ctx  := try { request:get-context-path() } catch * { "/exist" }
    let $host := try { request:get-server-name() } catch * { "localhost" }
    let $port := try { request:get-server-port() } catch * { 8080 }
    let $proto := try {
        if (request:get-header("X-Forwarded-Proto") = "https") then "https"
        else if ($port = 443) then "https"
        else "http"
    } catch * { "http" }
    let $port-suffix :=
        if (($proto = "http" and $port = 80) or ($proto = "https" and $port = 443)) then ""
        else ":" || $port
    return $proto || "://" || $host || $port-suffix
};

(:~
 : Return HTTP status code for a URL, or -1 on network error.
 :)
declare %private function nav-smoke:http-status($url as xs:string) as xs:integer {
    try {
        let $response := http:send-request(<http:request method="GET" href="{$url}" follow-redirect="true"/>)
        return xs:integer($response[1]/@status)
    } catch * {
        -1
    }
};

(: ============================================================ :)
(:  Smoke tests — one per installed internal nav entry          :)
(: ============================================================ :)

declare %test:assertTrue
function nav-smoke:all-internal-nav-links-return-200() {
    (: Summarize: count non-200 responses among all internal links. :)
    let $base     := nav-smoke:base-url()
    let $abbrevs  :=
        for $item in nav:apps()?*
        where not($item?external) and $item?abbrev != ""
        return $item?abbrev
    let $fail-count :=
        count(
            for $abbrev in $abbrevs
            let $item   := nav:apps()?*[?abbrev = $abbrev]
            let $status := nav-smoke:http-status($base || $item?url)
            where $status != 200
            return $abbrev
        )
    return $fail-count = 0
};

declare %test:assertTrue
function nav-smoke:dashboard-returns-200() {
    let $dashboard := nav:apps()?*[?abbrev = "dashboard"]
    return
        if (empty($dashboard)) then true()
        else nav-smoke:http-status(nav-smoke:base-url() || $dashboard?url) = 200
};

declare %test:assertTrue
function nav-smoke:docs-returns-200() {
    let $docs := nav:apps()?*[?abbrev = "docs"]
    return
        if (empty($docs)) then true()
        else nav-smoke:http-status(nav-smoke:base-url() || $docs?url) = 200
};

declare %test:assertTrue
function nav-smoke:notebook-returns-200() {
    let $notebook := nav:apps()?*[?abbrev = "notebook"]
    return
        if (empty($notebook)) then true()
        else nav-smoke:http-status(nav-smoke:base-url() || $notebook?url) = 200
};

declare %test:assertTrue
function nav-smoke:blog-returns-200() {
    let $blog := nav:apps()?*[?abbrev = "blog"]
    return
        if (empty($blog)) then true()
        else nav-smoke:http-status(nav-smoke:base-url() || $blog?url) = 200
};

declare %test:assertTrue
function nav-smoke:community-link-returns-200() {
    let $community := nav:apps()?*[?title = "Community"]
    return
        if (empty($community)) then true()
        else nav-smoke:http-status(nav-smoke:base-url() || $community?url) = 200
};
