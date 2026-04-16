xquery version "3.1";
(:~
 : Runner for all exist-site-shell XQSuite tests.
 :)
import module namespace test = "http://exist-db.org/xquery/xqsuite"
    at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

test:suite((
    inspect:module-functions(xs:anyURI("/db/apps/exist-site-shell/test/xqs/site-config-test.xqm")),
    inspect:module-functions(xs:anyURI("/db/apps/exist-site-shell/test/xqs/nav-test.xqm")),
    inspect:module-functions(xs:anyURI("/db/apps/exist-site-shell/test/xqs/nav-smoke-test.xqm")),
    inspect:module-functions(xs:anyURI("/db/apps/exist-site-shell/test/xqs/search-test.xqm"))
))
