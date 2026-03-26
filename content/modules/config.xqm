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

(: Cache of installed package URIs for link resolution :)
declare variable $config:installed-packages := repo:list();

(: Resolve the shell's package root from the module load path.
 : system:get-module-load-path() returns the directory of this file,
 : which is content/modules/ — strip that suffix to get the package root. :)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
            substring($rawPath, 36)
        else if (starts-with($rawPath, "xmldb:exist://")) then
            substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/content/modules");

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

(:~
 : Resolve a cross-app link. If the target app is installed locally,
 : return a local path. Otherwise fall back to exist-db.org.
 :
 : @param $app package name URI (e.g., "http://exist-db.org/apps/fundocs")
 : @param $path path within the app (e.g., "/index.html")
 : @return the resolved URL string
 :)
declare function config:resolve-link($app as xs:string, $path as xs:string) as xs:string {
    if ($config:installed-packages = $app) then
        (: App is installed locally — resolve to local path :)
        let $pkg-meta :=
            try {
                let $raw := repo:get-resource($app, "expath-pkg.xml")
                return
                    if (exists($raw)) then parse-xml(util:binary-to-string($raw))
                    else ()
            } catch * { () }
        let $abbrev := $pkg-meta/expath:package/@abbrev/string()
        return
            if ($abbrev) then
                request:get-context-path() || "/apps/" || $abbrev || $path
            else
                "https://exist-db.org/exist/apps" || $path
    else
        (: App not installed — fall back to exist-db.org :)
        "https://exist-db.org/exist/apps" || $path
};
