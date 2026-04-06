xquery version "3.1";

(:~
 : Post-install script.
 :
 : 1. Installs the exist-site Jinks profile from this app's profile/
 :    directory into the Jinks generator's profile collection
 : 2. Calls the Jinks generator to copy shared resources (base-page.html,
 :    nav.xqm, site-config.xqm, exist-site.css) into this app
 :
 : Required for autodeploy — when installed via Docker image startup,
 : there's no npm or curl to set up the profile or call the generator.
 :
 : If Jinks isn't installed, logs a warning. The app will work but
 : without the shared nav bar until Jinks is installed and the
 : generator is run.
 :)

declare variable $home external;
declare variable $dir external;
declare variable $target external;

(:~
 : Recursively copy a collection tree, storing .html files as binary
 : to preserve Jinks template directives.
 :)
declare function local:copy-collection($source as xs:string, $dest as xs:string) {
    if (not(xmldb:collection-available($dest))) then
        let $parent := replace($dest, "/[^/]+$", "")
        let $name := replace($dest, "^.*/", "")
        return xmldb:create-collection($parent, $name)
    else (),

    for $resource in xmldb:get-child-resources($source)
    let $src-path := $source || "/" || $resource
    return
        if (ends-with($resource, ".html") and doc-available($src-path)) then
            (: Store .html as binary to preserve Jinks directives :)
            let $content := serialize(doc($src-path))
            let $clean := if (starts-with($content, "<?xml")) then
                substring-after($content, "?>") else $content
            let $_ := if (doc-available($dest || "/" || $resource)) then
                xmldb:remove($dest, $resource) else ()
            return xmldb:store($dest, $resource, $clean, "application/octet-stream")
        else if (util:binary-doc-available($src-path)) then
            xmldb:store($dest, $resource, util:binary-doc($src-path), "application/octet-stream")
        else if (doc-available($src-path)) then
            xmldb:store($dest, $resource, doc($src-path))
        else (),

    for $child in xmldb:get-child-collections($source)
    return local:copy-collection($source || "/" || $child, $dest || "/" || $child)
};

(: --- Step 1: Install the exist-site profile into Jinks --- :)
let $profile-source := $target || "/profile"
let $profile-dest := "/db/apps/jinks/profiles/exist-site"
let $_ :=
    if (xmldb:collection-available("/db/apps/jinks") and
        xmldb:collection-available($profile-source)) then (
        util:log("INFO", "exist-site-shell: Installing exist-site profile into Jinks"),
        local:copy-collection($profile-source, $profile-dest)
    ) else if (not(xmldb:collection-available("/db/apps/jinks"))) then
        util:log("WARN", "exist-site-shell: Jinks not installed — skipping profile installation")
    else
        util:log("WARN", "exist-site-shell: No profile/ directory found in package")

(: --- Step 2: Run the Jinks generator --- :)
let $config := map {
    "label": "eXist-db Site Shell",
    "id": "http://exist-db.org/pkg/site-shell",
    "description": "Sitewide navigation shell, landing page, and search for eXist-db.org",
    "extends": array { "exist-site" },
    "pkg": map {
        "abbrev": "exist-site-shell",
        "version": "0.9.0-SNAPSHOT",
        "dependencies": array {
            map { "package": "http://tei-publisher.com/library/jinks-templates", "semver": "1" },
            map { "package": "http://exist-db.org/apps/markdown", "semver": "3" }
        }
    },
    "nav": map {
        "items": array {
            map { "abbrev": "dashboard", "title": "Dashboard" },
            map { "abbrev": "docs", "title": "Documentation" },
            map { "abbrev": "notebook", "title": "Notebook" },
            map { "abbrev": "blog", "title": "Blog" }
        }
    }
}

return
    if (util:binary-doc-available("/db/apps/jinks/modules/generator.xqm") or
        doc-available("/db/apps/jinks/modules/generator.xqm")) then
        try {
            let $_ := util:import-module(
                xs:anyURI("http://tei-publisher.com/library/generator"),
                "generator",
                xs:anyURI("/db/apps/jinks/modules/generator.xqm")
            )
            let $_ := util:eval('generator:process(map { "overwrite": () }, $config)', false(),
                    (xs:QName("config"), $config))
            (: Fix MIME type for .xqm modules — the generator stores them as
             : application/octet-stream but eXist needs application/xquery :)
            return
                for $mod in xmldb:get-child-resources($target || "/modules")
                where ends-with($mod, ".xqm")
                let $path := $target || "/modules/" || $mod
                where util:binary-doc-available($path) and
                      xmldb:get-mime-type(xs:anyURI($path)) != "application/xquery"
                let $content := util:binary-to-string(util:binary-doc($path))
                let $_ := xmldb:remove($target || "/modules", $mod)
                return xmldb:store($target || "/modules", $mod, $content, "application/xquery")
        } catch * {
            util:log("WARN", "exist-site-shell: Jinks generator failed: " || $err:description)
        }
    else
        util:log("WARN", "exist-site-shell: Jinks generator not available. Run the generator manually after installing Jinks.")
