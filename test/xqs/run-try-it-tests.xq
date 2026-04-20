xquery version "3.1";
(:~
 : Runner for try-it smoke tests.
 : Verifies all landing page "Try eXist-db" queries return non-empty results.
 :)
import module namespace test = "http://exist-db.org/xquery/xqsuite"
    at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

test:suite(
    inspect:module-functions(xs:anyURI("/db/apps/exist-site-shell/test/xqs/try-it-smoke-test.xqm"))
)
