xquery version "3.1";

(:~
 : XQSuite tests for nav:apps() — the sitewide navigation module.
 :
 : Tests cover:
 :   - <app> entries: presence, structure, URL, abbrev
 :   - <link> entries: Source and Community links with correct URL/external flag
 :   - Scope selector filtering: only <app> entries have non-empty abbrev
 :   - Two-arg compat overload: nav:apps($items, $path) delegates to nav:apps()
 :
 : These tests query the live deployed nav-config.xml so they reflect the
 : real installed state of exist-site-shell.
 :)
module namespace nav-test = "http://exist-db.org/apps/exist-site-shell/test/nav-suite";

import module namespace nav = "http://exist-db.org/site/nav"
    at "xmldb:exist:///db/apps/exist-site-shell/modules/nav.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace n    = "http://exist-db.org/site/nav";

(: ============================================================ :)
(:  nav:apps() — basic structure                                :)
(: ============================================================ :)

declare %test:assertTrue
function nav-test:apps-returns-array() {
    nav:apps() instance of array(*)
};

declare %test:assertTrue
function nav-test:apps-has-items() {
    array:size(nav:apps()) > 0
};

declare %test:assertTrue
function nav-test:every-item-has-required-keys() {
    every $item in nav:apps()?*
    satisfies (
        map:contains($item, "title")    and
        map:contains($item, "abbrev")   and
        map:contains($item, "url")      and
        map:contains($item, "active")   and
        map:contains($item, "external")
    )
};

(: ============================================================ :)
(:  <app> entries                                               :)
(: ============================================================ :)

declare %test:assertTrue
function nav-test:app-entries-have-non-empty-abbrev() {
    let $apps := nav:apps()?*[?abbrev != ""]
    return count($apps) > 0
};

declare %test:assertTrue
function nav-test:app-entry-url-contains-apps-path() {
    every $item in nav:apps()?*[?abbrev != ""]
    satisfies contains($item?url, "/apps/" || $item?abbrev)
};

declare %test:assertTrue
function nav-test:app-entries-are-not-external() {
    every $item in nav:apps()?*[?abbrev != ""]
    satisfies $item?external = false()
};

(: ============================================================ :)
(:  <link> entries — Community and Source                       :)
(: ============================================================ :)

declare %test:assertTrue
function nav-test:community-link-present() {
    some $item in nav:apps()?*
    satisfies $item?title = "Community"
};

declare %test:assertTrue
function nav-test:source-link-present() {
    some $item in nav:apps()?*
    satisfies $item?title = "Source"
};

declare %test:assertTrue
function nav-test:source-link-is-external() {
    let $source := nav:apps()?*[?title = "Source"]
    return exists($source) and $source?external = true()
};

declare %test:assertTrue
function nav-test:source-link-points-to-github() {
    let $source := nav:apps()?*[?title = "Source"]
    return exists($source) and contains($source?url, "github.com")
};

declare %test:assertTrue
function nav-test:community-link-is-not-external() {
    let $community := nav:apps()?*[?title = "Community"]
    return exists($community) and $community?external = false()
};

declare %test:assertTrue
function nav-test:community-link-points-to-community-page() {
    let $community := nav:apps()?*[?title = "Community"]
    return exists($community) and contains($community?url, "exist-site-shell/community")
};

(: ============================================================ :)
(:  Scope selector filtering: link entries have empty abbrev    :)
(: ============================================================ :)

declare %test:assertTrue
function nav-test:link-entries-have-empty-abbrev() {
    let $links := nav:apps()?*[?title = ("Source", "Community")]
    return every $link in $links satisfies $link?abbrev = ""
};

declare %test:assertTrue
function nav-test:only-app-entries-have-non-empty-abbrev() {
    let $config := doc("/db/apps/exist-site-shell/data/nav-config.xml")/n:nav-config
    let $link-titles := $config/n:link/@title/string()
    return every $item in nav:apps()?*[?abbrev != ""]
           satisfies not($item?title = $link-titles)
};

(: ============================================================ :)
(:  Two-argument compat overload                                :)
(: ============================================================ :)

declare %test:assertTrue
function nav-test:two-arg-overload-returns-same-as-zero-arg() {
    let $zero-arg := nav:apps()
    let $two-arg  := nav:apps(array {}, "/exist/apps")
    return array:size($zero-arg) = array:size($two-arg)
};

declare %test:assertTrue
function nav-test:two-arg-overload-has-same-titles() {
    let $zero-titles := nav:apps()?*?title
    let $two-titles  := nav:apps(array {}, "/exist/apps")?*?title
    return deep-equal($zero-titles, $two-titles)
};
