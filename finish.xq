xquery version "3.1";

(:~
 : Post-install script.
 :
 : Calls the Jinks generator to copy profile files (base-page.html,
 : nav.xqm, site-config.xqm, exist-site.css, etc.) into this app.
 : Required for autodeploy — when installed via Docker image startup,
 : there's no npm or curl to call the generator API.
 :
 : If Jinks isn't installed, logs a warning and continues. The app
 : will work but without the shared nav bar (templates must be
 : installed manually via the Jinks generator API).
 :)

declare variable $home external;
declare variable $dir external;
declare variable $target external;

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
            let $generator := util:import-module(
                xs:anyURI("http://tei-publisher.com/library/generator"),
                "generator",
                xs:anyURI("/db/apps/jinks/modules/generator.xqm")
            )
            return
                util:eval('generator:process(map { "overwrite": "all" }, $config)', false(),
                    (xs:QName("config"), $config))
        } catch * {
            util:log("WARN", "exist-site-shell: Jinks generator failed: " || $err:description)
        }
    else
        util:log("WARN", "exist-site-shell: Jinks not installed. Profile files must be installed via the Jinks generator API.")
