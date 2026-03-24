xquery version "3.1";

(:~
 : Site configuration module.
 :
 : Provides site-wide settings: name, logo URL, navigation items,
 : and the shell's base path for resolving static resources.
 :)
module namespace config = "http://exist-db.org/site/config";

declare namespace expath = "http://expath.org/ns/pkg";
declare namespace repo = "http://exist-db.org/xquery/repo";

(: Resolve the shell's installed path from its package descriptor :)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        if (starts-with($rawPath, "xmldb:exist://")) then
            substring-after($rawPath, "xmldb:exist://")
        else
            $rawPath;

declare variable $config:shell-base :=
    request:get-context-path() || "/apps/exist-site-shell";

declare variable $config:site-name := "eXist-db";

declare variable $config:site-logo :=
    $config:shell-base || "/resources/images/exist-logo.svg";

(:~
 : Return the base rendering context for the shell template.
 :
 : @return map with shell-base, site-name, site-logo, and current user
 :)
declare function config:context() as map(*) {
    let $user := (session:get-attribute("user"), sm:id()//sm:real/sm:username/string())[1]
    return map {
        "shell-base": $config:shell-base,
        "site-name": $config:site-name,
        "site-logo": $config:site-logo,
        "user": $user
    }
};
