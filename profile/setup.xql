xquery version "3.1";

module namespace site="https://exist-db.org/jinks/exist-site/setup";

import module namespace cpy="http://tei-publisher.com/library/generator/copy";
import module namespace path="http://tei-publisher.com/jinks/path";

declare namespace generator="http://tei-publisher.com/library/generator";

(:~
 : Copy profile files to the target app using default behavior.
 :)
declare
    %generator:write
function site:setup($context as map(*)) {
    cpy:copy-collection($context)
};

(:~
 : After all files are written:
 : 1. Re-store .html templates as binary (prevents XML corruption of Jinks directives)
 : 2. Re-store .xqm modules with application/xquery MIME type (the default copy
 :    stores them as application/octet-stream which eXist won't load as XQuery)
 :)
declare
    %generator:after-write
function site:fix-files($context as map(*), $target as xs:string) {
    (: Fix .html templates — store as binary from profile source :)
    let $tmpl-source := path:resolve-path($context?source, "templates")
    let $tmpl-target := $target || "/templates"
    let $_ :=
        if (xmldb:collection-available($tmpl-source)) then
            for $resource in xmldb:get-child-resources($tmpl-source)
            where ends-with($resource, ".html")
            let $source-path := $tmpl-source || "/" || $resource
            where util:binary-doc-available($source-path)
            let $content := util:binary-doc($source-path)
            let $_ := if (doc-available($tmpl-target || "/" || $resource)) then
                xmldb:remove($tmpl-target, $resource) else ()
            return (
                path:mkcol($context, "templates"),
                xmldb:store($tmpl-target, $resource, $content, "application/octet-stream")
            )
        else ()

    (: Fix .xqm modules — ensure application/xquery MIME type :)
    let $mod-target := $target || "/modules"
    return
        if (xmldb:collection-available($mod-target)) then
            for $resource in xmldb:get-child-resources($mod-target)
            where ends-with($resource, ".xqm")
            let $path := $mod-target || "/" || $resource
            where util:binary-doc-available($path) and
                  xmldb:get-mime-type(xs:anyURI($path)) != "application/xquery"
            let $content := util:binary-to-string(util:binary-doc($path))
            let $_ := xmldb:remove($mod-target, $resource)
            return xmldb:store($mod-target, $resource, $content, "application/xquery")
        else ()
};
