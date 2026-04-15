xquery version "3.1";
(:~
 : Runner for site-config XQSuite tests.
 :)
import module namespace test = "http://exist-db.org/xquery/xqsuite"
    at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

test:suite(
    inspect:module-functions(xs:anyURI("/db/apps/exist-site-shell/test/xqs/site-config-test.xqm"))
)
