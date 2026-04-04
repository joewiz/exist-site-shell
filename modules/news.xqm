xquery version "3.1";

(:~
 : News feed module.
 :
 : Fetches recent blog posts from the exist-blog app if installed,
 : falling back to basic release information.
 :
 : Returns entries as maps with: title, date, snippet, url
 :)
module namespace news = "http://exist-db.org/site/news";

(:~ Blog posts collection :)
declare variable $news:BLOG_ROOT := "/db/apps/blog/data/posts";

(:~ Blog app base URL :)
declare variable $news:BLOG_BASE := request:get-context-path() || "/apps/blog";

(:~
 : Fetch the latest N news entries.
 :
 : If the blog app is installed, reads its Markdown posts and extracts
 : front matter. Otherwise returns basic eXist release info.
 :
 : @param $limit maximum number of entries to return
 : @return array of maps with title, date, snippet, url
 :)
declare function news:latest($limit as xs:integer) as array(*) {
    let $blog-entries :=
        if (xmldb:collection-available($news:BLOG_ROOT)) then
            news:blog-entries($limit)
        else
            ()
    return
        if (exists($blog-entries)) then
            array { subsequence($blog-entries, 1, $limit) }
        else
            (: Fallback: current eXist version as a release entry :)
            let $version := system:get-version()
            let $build := system:get-build()
            return array {
                map {
                    "title": "eXist-db " || $version || " available",
                    "date": format-date(current-date(), "[MNn] [D], [Y]"),
                    "snippet": "The current running instance is eXist-db " || $version || " (build " || $build || ").",
                    "url": "https://github.com/eXist-db/exist/releases"
                }
            }
};

(:~
 : Read blog posts and return them as news entries, sorted by date descending.
 :)
declare %private function news:blog-entries($limit as xs:integer) as map(*)* {
    let $files := news:find-md-files($news:BLOG_ROOT)
    let $entries :=
        for $path in $files
        let $source :=
            try { unparsed-text($path) }
            catch * { () }
        where exists($source)
        let $meta := news:parse-front-matter($source)
        where $meta?status = ("published", "")
        order by $meta?date descending
        return map {
            "title": ($meta?title, "Untitled")[1],
            "date": $meta?date,
            "snippet": ($meta?summary, "")[1],
            "url": $news:BLOG_BASE || "/" || news:slug-from-path($path)
        }
    return subsequence($entries, 1, $limit)
};

(:~
 : Recursively find .md files, excluding wiki-import.
 :)
declare %private function news:find-md-files($collection as xs:string) as xs:string* {
    (
        for $resource in xmldb:get-child-resources($collection)
        where ends-with($resource, ".md")
        return $collection || "/" || $resource,

        for $child in xmldb:get-child-collections($collection)
        where $child ne "wiki-import"
        return news:find-md-files($collection || "/" || $child)
    )
};

(:~
 : Extract a URL slug from a file path.
 : /db/apps/blog/data/posts/2026/03-exist-7-preview.md → 2026/03-exist-7-preview
 :)
declare %private function news:slug-from-path($path as xs:string) as xs:string {
    let $rel := substring-after($path, $news:BLOG_ROOT || "/")
    return replace($rel, "\.md$", "")
};

(:~
 : Parse YAML front matter from a Markdown string.
 : Lightweight version — extracts title, date, summary, status.
 :)
declare %private function news:parse-front-matter($markdown as xs:string) as map(*) {
    let $lines := tokenize($markdown, "\n")
    return
        if (not(matches($lines[1], "^---\s*$"))) then
            map { "title": "", "date": "", "summary": "", "status": "published" }
        else
            let $end-idx :=
                (for $i in 2 to count($lines)
                 where matches($lines[$i], "^---\s*$")
                 return $i)[1]
            let $yaml-lines := subsequence($lines, 2, $end-idx - 2)
            return map:merge(
                for $line in $yaml-lines
                let $trimmed := normalize-space($line)
                where contains($trimmed, ":")
                let $key := normalize-space(substring-before($trimmed, ":"))
                let $raw := normalize-space(substring-after($trimmed, ":"))
                let $value :=
                    if (matches($raw, '^".*"$') or matches($raw, "^'.*'$")) then
                        substring($raw, 2, string-length($raw) - 2)
                    else
                        $raw
                where $key = ("title", "date", "summary", "status")
                return map { $key: $value }
            )
};
