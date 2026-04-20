xquery version "3.1";

(:~
 : Smoke tests for the "Try eXist-db" queries on the landing page.
 : Each test runs a query locally (same as what the eval endpoint does)
 : and verifies a non-empty, non-error result.
 :)
module namespace tt = "http://exist-db.org/apps/exist-site-shell/test/try-it";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

(: --- Shakespeare: Full-Text Search --- :)

declare
    %test:assertTrue
function tt:shakespeare-ft-love() {
    count(collection("/db/apps/notebook/data/getting-started/data/shakespeare")
        //SPEECH[ft:query(., "love")]) > 0
};

declare
    %test:assertTrue
function tt:shakespeare-ft-boil-bubble() {
    count(collection("/db/apps/notebook/data/getting-started/data/shakespeare")
        //SPEECH[ft:query(., "boil bubble")]) > 0
};

declare
    %test:assertTrue
function tt:shakespeare-ft-passion() {
    count(collection("/db/apps/notebook/data/getting-started/data/shakespeare")
        //SPEECH[ft:query(., "passion*")]) > 0
};

declare
    %test:assertTrue
function tt:shakespeare-macbeth-toc() {
    count(collection("/db/apps/notebook/data/getting-started/data/shakespeare")
        //PLAY[contains(TITLE, "Macbeth")]/ACT) > 0
};

declare
    %test:assertTrue
function tt:shakespeare-kwic-hell() {
    count(collection("/db/apps/notebook/data/getting-started/data/shakespeare")
        //SPEECH[ft:query(., "hell")]) > 0
};

declare
    %test:assertTrue
function tt:shakespeare-ft-murder() {
    count(collection("/db/apps/notebook/data/getting-started/data/shakespeare")
        //SPEECH[ft:query(., "murder")]) > 0
};

(: --- Mondial: Geographic Database --- :)

declare
    %test:assertTrue
function tt:mondial-find-city() {
    count(doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
        //city[starts-with(name, "Dur")]) > 0
};

declare
    %test:assertTrue
function tt:mondial-negative-growth() {
    count(doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
        //country[population_growth < 0]) > 0
};

declare
    %test:assertTrue
function tt:mondial-top-cities() {
    count(doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
        /mondial/country[.//city/population]) > 0
};

declare
    %test:assertTrue
function tt:mondial-germany-orgs() {
    let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")/mondial
    let $ids := tokenize($mondial/country[@car_code="D"]/@memberships)
    return count($mondial/organization[@id = $ids]) > 0
};

declare
    %test:assertTrue
function tt:mondial-germany-neighbors() {
    let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")/mondial
    return count($mondial/country[@car_code="D"]/border) > 0
};

declare
    %test:assertTrue
function tt:mondial-roman-catholic() {
    let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
    return count($mondial//country[religions[contains(., "Roman Catholic")]/@percentage > 50]) > 0
};

(: --- XQuery Features --- :)

declare
    %test:assertEquals(220)
function tt:higher-order-functions() {
    let $numbers := 1 to 10
    let $evens := filter($numbers, function($n) { $n mod 2 = 0 })
    let $squared := for-each($evens, function($n) { $n * $n })
    return fold-left($squared, 0, function($a, $b) { $a + $b })
};

declare
    %test:assertTrue
function tt:system-info() {
    string-length(util:system-property("product-version")) > 0
};
