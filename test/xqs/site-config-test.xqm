xquery version "3.1";

(:~
 : XQSuite tests for site-config:resolve() and site-config:app-url().
 :
 : These tests assume:
 :   - exist-site-shell is installed at /db/apps/exist-site-shell
 :   - At least one profile app (docs or blog) is installed locally
 :   - "no-such-app" is NOT in the registry and NOT installed
 :
 : NOTE: This module imports site-config from test/modules/site-config-isolated.xqm,
 : a copy that uses a unique namespace URI to avoid eXist-db's persistent
 : module-pool conflict when multiple profile apps (docs, blog, notebook) have
 : each deployed site-config under their own /db/apps/{app}/modules/ path.
 :)
module namespace sc-test = "http://exist-db.org/apps/exist-site-shell/test/site-config-suite";

import module namespace site-config = "http://exist-db.org/apps/exist-site-shell/test/site-config"
    at "xmldb:exist:///db/apps/exist-site-shell/test/modules/site-config-isolated.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

(: ============================================================ :)
(:  resolve() — pass-through for non-reference strings          :)
(: ============================================================ :)

declare %test:assertEquals("not-a-ref")
function sc-test:resolve-passthrough-plain() {
    site-config:resolve("not-a-ref")
};

declare %test:assertEquals("https://example.com/foo")
function sc-test:resolve-passthrough-url() {
    site-config:resolve("https://example.com/foo")
};

declare %test:assertEquals("#anchor")
function sc-test:resolve-passthrough-fragment() {
    site-config:resolve("#anchor")
};

declare %test:assertEquals("../sibling")
function sc-test:resolve-passthrough-relative() {
    site-config:resolve("../sibling")
};

(: ============================================================ :)
(:  resolve() — installed app → local URL                       :)
(: ============================================================ :)

declare %test:assertTrue
function sc-test:resolve-installed-app-root() {
    contains(site-config:resolve("{docs}"), "/apps/docs")
};

declare %test:assertTrue
function sc-test:resolve-installed-app-with-path() {
    contains(site-config:resolve("{docs/articles/repo}"), "/apps/docs/articles/repo")
};

declare %test:assertTrue
function sc-test:resolve-installed-app-with-fragment() {
    let $url := site-config:resolve("{docs/articles/repo#how-to}")
    return contains($url, "/apps/docs/articles/repo#how-to")
};

declare %test:assertTrue
function sc-test:resolve-installed-app-function-url() {
    contains(site-config:resolve("{docs/functions/fn/string-join#3}"),
             "/apps/docs/functions/fn/string-join#3")
};

declare %test:assertTrue
function sc-test:resolve-installed-app-path-only-no-double-slash() {
    not(contains(site-config:resolve("{docs/articles/repo}"), "//apps"))
};

(: ============================================================ :)
(:  resolve() — uninstalled app in registry → fallback URL      :)
(: ============================================================ :)

declare %test:assertTrue
function sc-test:resolve-uninstalled-uses-registry-fallback() {
    let $registry := doc("/db/apps/exist-site-shell/data/app-registry.xml")
    let $uninstalled :=
        $registry//*:app[not(xmldb:collection-available("/db/apps/" || @abbrev))][1]
    return
        if (empty($uninstalled)) then
            true()  (: all apps installed on this instance — skip :)
        else
            let $url := site-config:resolve("{" || string($uninstalled/@abbrev) || "}")
            return starts-with($url, "https://")
};

declare %test:assertTrue
function sc-test:resolve-uninstalled-with-path-appended-to-fallback() {
    let $registry := doc("/db/apps/exist-site-shell/data/app-registry.xml")
    let $uninstalled :=
        $registry//*:app[not(xmldb:collection-available("/db/apps/" || @abbrev))][1]
    return
        if (empty($uninstalled)) then
            true()
        else
            let $abbrev   := string($uninstalled/@abbrev)
            let $fallback := string($uninstalled/@fallback)
            let $url      := site-config:resolve("{" || $abbrev || "/some/path}")
            return $url = $fallback || "/some/path"
};

(: ============================================================ :)
(:  resolve() — unknown app → #unresolved marker                :)
(: ============================================================ :)

declare %test:assertEquals("#unresolved-no-such-app")
function sc-test:resolve-unknown-app-root() {
    site-config:resolve("{no-such-app}")
};

declare %test:assertTrue
function sc-test:resolve-unknown-app-with-path-starts-with-marker() {
    starts-with(site-config:resolve("{no-such-app/foo/bar}"), "#unresolved-no-such-app")
};

(: ============================================================ :)
(:  app-url() convenience wrapper                               :)
(: ============================================================ :)

declare %test:assertTrue
function sc-test:app-url-installed-contains-app-path() {
    contains(site-config:app-url("docs"), "/apps/docs")
};

declare %test:assertEquals("#unresolved-no-such-app")
function sc-test:app-url-unknown-returns-marker() {
    site-config:app-url("no-such-app")
};

(: ============================================================ :)
(:  Registry integrity                                          :)
(: ============================================================ :)

declare %test:assertTrue
function sc-test:registry-every-app-has-https-fallback() {
    every $app in doc("/db/apps/exist-site-shell/data/app-registry.xml")//*:app
    satisfies starts-with(string($app/@fallback), "https://")
};

declare %test:assertTrue
function sc-test:registry-every-fallback-contains-abbrev() {
    every $app in doc("/db/apps/exist-site-shell/data/app-registry.xml")//*:app
    satisfies contains(string($app/@fallback), string($app/@abbrev))
};
