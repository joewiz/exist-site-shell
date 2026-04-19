/**
 * "Try Me" XQuery demo widget.
 *
 * Executes XQuery queries against the exist-api /api/eval endpoint
 * and displays results in a compact pane. Uses jinn-codemirror
 * for syntax-highlighted source display and result output.
 */
const TryMe = {
    queries: [
        // --- Shakespeare: Full-Text Search ---
        {
            title: "Simple full text query",
            description: "Full text query on the Shakespeare plays — find speeches about love.",
            query: `collection("/db/apps/notebook/data/getting-started/data/shakespeare")
    //SPEECH[ft:query(., 'love')]`
        },
        {
            title: "Full text phrase search",
            description: "Find speeches by the witches containing the phrase \"fenny snake\".",
            query: `collection("/db/apps/notebook/data/getting-started/data/shakespeare")
    //SPEECH[ngram:contains(SPEAKER, 'witch')]
            [ft:query(., '"fenny snake"')]`
        },
        {
            title: "Ordered by score",
            description: "Full text query with results ordered by relevance score.",
            query: `for $m in collection("/db/apps/notebook/data/getting-started/data/shakespeare")
    //SPEECH[ft:query(., "boil bubble")]
let $score := ft:score($m)
order by $score descending
return
    <m score="{$score}">{$m}</m>`
        },
        {
            title: "Show context of a match",
            description: "Group full text hits by play, act, and scene.",
            query: `let $plays := collection("/db/apps/notebook/data/getting-started/data/shakespeare")
let $query :=
    <query>
        <bool>
            <term occur="must">blood</term>
            <wildcard occur="should">murd*</wildcard>
        </bool>
    </query>
for $speech in $plays//SPEECH[ft:query(., $query)]
let $scene := $speech/ancestor::SCENE,
    $act := $scene/ancestor::ACT,
    $play := $scene/ancestor::PLAY
return
    <hit>
        <play title="{$play/TITLE}">
            <act title="{$act/TITLE}">
                <scene title="{$scene/TITLE}">{$speech}</scene>
            </act>
        </play>
    </hit>`
        },
        {
            title: "Group hits by play",
            description: "Count full text matches per play for a wildcard query.",
            query: `let $plays := collection("/db/apps/notebook/data/getting-started/data/shakespeare")
let $speeches := $plays//SPEECH[ft:query(., "passion*")]
for $play in $speeches/ancestor::PLAY
group by $title := $play/TITLE/string()
return
    <play title="{$title}" hits="{count($speeches[ancestor::PLAY/TITLE = $title])}"/>`
        },
        {
            title: "Table of contents",
            description: "Show table of contents for Macbeth with actors per scene.",
            query: `<toc>{
    for $act in collection("/db/apps/notebook/data/getting-started/data/shakespeare")
        //PLAY[contains(TITLE, "Macbeth")]/ACT
    return
        <act>
            {$act/TITLE}
            {
                for $scene in $act/SCENE return
                    <scene>
                        {$scene/TITLE}
                        <actors>{
                            for $speaker in distinct-values($scene//SPEAKER)
                            order by $speaker
                            return <actor>{$speaker}</actor>
                        }</actors>
                    </scene>
            }
        </act>
}</toc>`
        },
        {
            title: "Keywords in Context",
            description: "KWIC display for speeches containing \"hell\" in Shakespeare.",
            query: `import module namespace kwic="http://exist-db.org/xquery/kwic";

let $config := <config xmlns="" width="40" table="no"/>

for $hit in collection("/db/apps/notebook/data/getting-started/data/shakespeare")
    //SPEECH[ft:query(., "hell")]
let $matches := kwic:get-matches($hit)
for $ancestor in $matches/ancestor::SPEECH
return
    kwic:get-summary($ancestor, ($ancestor//exist:match)[1], $config)`
        },
        {
            title: "Highlighted search results",
            description: "Full text hits rendered as HTML with highlighted matches.",
            method: "html", "html-version": "5", render: true,
            query: `let $plays := collection("/db/apps/notebook/data/getting-started/data/shakespeare")
let $hits := $plays//SPEECH[ft:query(., "murder")]
return
    <div class="search-hits">{
        for $hit in subsequence($hits, 1, 10)
        let $expanded := util:expand($hit)
        return
            <div class="hit">
                <span class="speaker">{$hit/SPEAKER/string()}</span>
                {
                    for $line in $expanded/LINE
                    return
                        <span class="line">{
                            for $node in $line/node()
                            return
                                if ($node instance of element(exist:match))
                                then <mark>{$node/string()}</mark>
                                else $node/string()
                        }</span>
                }
            </div>
    }</div>`
        },
        // --- Semantic Search (Vector) ---
        {
            title: "Beyond keywords",
            description: "Semantic search finds speeches about guilt and remorse — even when those exact words never appear.",
            query: `import module namespace vector = "http://exist-db.org/xquery/vector";

let $plays := collection("/db/apps/notebook/data/getting-started/data/shakespeare")

(: Keyword search: only 2 speeches contain the word "remorse" :)
let $keyword-hits := $plays//SPEECH[ft:query(., "remorse")]

(: Semantic search: find speeches ABOUT remorse — guilt, regret, torment :)
let $query-vec := vector:embed(
    "guilt remorse conscience tormented by wrongdoing",
    "all-MiniLM-L6-v2"
)
let $semantic-hits :=
    for $hit in $plays//SPEECH[ft:query-field-vector("speech-vec", $query-vec, 5)]
    let $score := ft:score($hit)
    order by $score descending
    return $hit

return
    <comparison>
        <keyword-search term="remorse" matches="{count($keyword-hits)}"/>
        <semantic-search matches="{count($semantic-hits)}">{
            for $hit in $semantic-hits
            let $score := ft:score($hit)
            return
                <match score="{round($score * 100) div 100}"
                       play="{$hit/ancestor::PLAY/TITLE}"
                       speaker="{$hit/SPEAKER[1]}">
                    {substring(normalize-space(string-join($hit/LINE, " ")), 1, 120)}...
                </match>
        }</semantic-search>
    </comparison>`
        },
        {
            title: "Semantic discovery",
            description: "Find the witches — without searching for 'witch'. Ask for 'supernatural dark prophecy' instead.",
            method: "html", "html-version": "5", render: true,
            query: `import module namespace vector = "http://exist-db.org/xquery/vector";

let $plays := collection("/db/apps/notebook/data/getting-started/data/shakespeare")
let $query-vec := vector:embed(
    "supernatural dark prophecy fate doom",
    "all-MiniLM-L6-v2"
)
return
    <div class="search-hits">{
        for $hit in $plays//SPEECH[ft:query-field-vector("speech-vec", $query-vec, 8)]
        let $score := ft:score($hit)
        order by $score descending
        return
            <div class="hit">
                <span class="speaker">{$hit/ancestor::PLAY/TITLE/string()}
                    — {$hit/SPEAKER[1]/string()}
                    ({round($score * 100)}% match)</span>
                {
                    for $line in $hit/LINE
                    return <span class="line">{$line/string()}</span>
                }
            </div>
    }</div>`
        },
        // --- Mondial: Geographic Database ---
        {
            title: "Find a city",
            description: "Search the Mondial geographic database for cities matching a pattern.",
            query: `let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
for $city in $mondial//city
where starts-with($city/name, "Dur")
return
    <result>
        {$city/name}
        <country>{$city/ancestor::country/name/string()}</country>
        <province>{$city/ancestor::province/name/string()}</province>
    </result>`
        },
        {
            title: "Decreasing population",
            description: "Show countries with negative population growth.",
            query: `let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
for $c in $mondial//country
where $c/population_growth < 0
order by $c/name
return
    <country>
        {$c/name, $c/population_growth}
    </country>`
        },
        {
            title: "Top cities by population",
            description: "For each country, list the 3 cities with highest population.",
            query: `let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
for $country in $mondial/mondial/country
let $cities :=
    (for $city in $country//city[population]
    order by xs:integer($city/population[1]) descending
    return $city)
order by $country/name
return
    <country name="{$country/name}">
    {
        subsequence($cities, 1, 3)
    }
    </country>`
        },
        {
            title: "Germany's organizations",
            description: "List all organizations Germany is a member of.",
            query: `let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")/mondial
let $ids := tokenize($mondial/country[@car_code="D"]/@memberships)
for $org in $mondial/organization[@id = $ids]
order by $org/name
return
    $org/name`
        },
        {
            title: "Germany's neighbors",
            description: "Find all countries sharing a border with Germany.",
            query: `let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")/mondial
for $border in $mondial/country[@car_code="D"]/border
return
    $mondial/country[@car_code = $border/@country]/name`
        },
        {
            title: "Roman Catholic countries",
            description: "Show countries with the highest Roman Catholic population.",
            query: `let $mondial := doc("/db/apps/notebook/data/getting-started/data/mondial.xml")
for $c in $mondial//country
let $catholic := $c/religions[contains(., "Roman Catholic")]
where exists($catholic) and $catholic/@percentage > 50
order by number($catholic/@percentage) descending
return
    $c/name/string() || ": " || $catholic/@percentage || "% Roman Catholic"`
        },
        // --- XQuery Features ---
        {
            title: "Higher-order functions",
            description: "Use filter, for-each, and fold-left — XQuery's functional toolkit.",
            query: `(: Filter even numbers, square them, sum the result :)
let $numbers := 1 to 10
let $evens := filter($numbers, function($n) { $n mod 2 = 0 })
let $squared := for-each($evens, function($n) { $n * $n })
let $sum := fold-left($squared, 0, function($a, $b) { $a + $b })
return
    <result>
        <evens>{$evens}</evens>
        <squared>{$squared}</squared>
        <sum>{$sum}</sum>
    </result>`
        },
        {
            title: "Generate HTML",
            description: "Build a color-coded multiplication table entirely in XQuery.",
            method: "html", "html-version": "5", render: true,
            query: `<table border="1" style="border-collapse:collapse">{
    for $row in 1 to 8
    return
        <tr>{
            for $col in 1 to 8
            let $val := $row * $col
            let $bg := if ($row = $col) then "#bee3f8"
                       else if ($val mod 2 = 0) then "#f0f0f0"
                       else "#ffffff"
            return
                <td style="padding:4px 8px;text-align:right;background:{$bg}">
                    {$val}
                </td>
        }</tr>
}</table>`
        },
        {
            title: "System info",
            description: "Display eXist-db system properties.",
            query: `<system>
    <version>{util:system-property("product-version")}</version>
    <build>{util:system-property("product-build")}</build>
    <jvm>{
        util:system-property("java.vendor"),
        util:system-property("java.version")
    }</jvm>
</system>`
        }
    ],

    currentIndex: 0,
    container: null,
    apiBase: null,
    sourceEditor: null,

    init(containerId) {
        this.container = document.getElementById(containerId);
        if (!this.container) return;

        // Derive exist-api base from the servlet context path (/exist)
        const m = window.location.pathname.match(/^(\/exist)\//);
        const ctx = m ? m[1] : "/exist";
        this.apiBase = this.container.dataset.apiBase || (ctx + "/apps/exist-api");

        this.render();
        this.initEditors();
    },

    render() {
        const firstQuery = this.queries[0].query;
        const firstDesc = this.queries[0].description;
        this.container.innerHTML = `
            <div class="try-me">
                <div class="try-me-header">
                    <h3>Try eXist-db</h3>
                    <div class="try-me-nav">
                        <button class="try-me-prev" disabled>&larr; Prev</button>
                        <span class="try-me-counter">1 / ${this.queries.length}</span>
                        <button class="try-me-next">Next &rarr;</button>
                    </div>
                </div>
                <p class="try-me-description">${firstDesc}</p>
                <div class="try-me-editor">
                    <jinn-codemirror class="try-me-source" mode="xquery"
                        code="${firstQuery.replace(/"/g, '&quot;')}"></jinn-codemirror>
                    <button class="try-me-run">Run &#9654;</button>
                </div>
                <div class="try-me-output">
                    <pre class="try-me-result">Click "Run" to execute the query.</pre>
                </div>
            </div>
        `;

        this.container.querySelector(".try-me-prev")
            .addEventListener("click", () => this.prev());
        this.container.querySelector(".try-me-next")
            .addEventListener("click", () => this.next());
        this.container.querySelector(".try-me-run")
            .addEventListener("click", () => this.run());
    },

    async initEditors() {
        await customElements.whenDefined("jinn-codemirror");
        this.sourceEditor = this.container.querySelector(".try-me-source");
    },

    /** Set editor content with retry — waits for CM view to be ready */
    setEditorContent(editor, text) {
        if (!editor) return;
        const attempt = () => {
            if (editor._editor) {
                editor.content = text;
            } else {
                requestAnimationFrame(attempt);
            }
        };
        attempt();
    },

    showQuery(index) {
        this.currentIndex = index;
        const q = this.queries[index];
        const el = this.container;

        this.setEditorContent(this.sourceEditor, q.query);
        // Restore plain <pre> for result area
        const output = el.querySelector(".try-me-output");
        output.innerHTML = '<pre class="try-me-result">Click "Run" to execute the query.</pre>';

        el.querySelector(".try-me-description").textContent = q.description;
        el.querySelector(".try-me-counter").textContent =
            `${index + 1} / ${this.queries.length}`;

        el.querySelector(".try-me-prev").disabled = index === 0;
        el.querySelector(".try-me-next").disabled =
            index === this.queries.length - 1;
    },

    prev() {
        if (this.currentIndex > 0) this.showQuery(this.currentIndex - 1);
    },

    next() {
        if (this.currentIndex < this.queries.length - 1)
            this.showQuery(this.currentIndex + 1);
    },

    async run() {
        const q = this.queries[this.currentIndex];
        const runBtn = this.container.querySelector(".try-me-run");

        if (this.sourceEditor) {
            q.query = this.sourceEditor.content || q.query;
        }

        const output = this.container.querySelector(".try-me-output");
        output.innerHTML = '<pre class="try-me-result">Running...</pre>';
        const resultEl = output.querySelector(".try-me-result");
        runBtn.disabled = true;

        // Serialization params — same model as notebook cells:
        //   method:       "adaptive" (default), "xml", "json", "html", "text", etc.
        //   html-version: "5" for HTML5 (used with method: "html")
        //   indent:       "yes" (default) or "no"
        //   render:       true to display HTML output directly instead of as source
        // Any W3C serialization param can be set on the query object.
        const reserved = new Set(["title", "description", "query", "render"]);
        const serParams = { method: "adaptive", indent: "yes", "omit-xml-declaration": "yes", count: 50 };
        for (const [k, v] of Object.entries(q)) {
            if (!reserved.has(k)) serParams[k] = v;
        }
        serParams.query = q.query;

        try {
            const response = await fetch(`${this.apiBase}/api/eval`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                credentials: "same-origin",
                body: JSON.stringify(serParams)
            });

            const text = await response.text();

            if (!response.ok || text.startsWith("Error:")) {
                resultEl.textContent = text;
                resultEl.className = "try-me-result try-me-error";
                return;
            }

            // Render as live HTML if the query declares render: true
            if (q.render && text.length < 100000) {
                const rendered = document.createElement("div");
                rendered.className = "try-me-result try-me-html";
                rendered.innerHTML = text;
                output.innerHTML = "";
                output.appendChild(rendered);
                return;
            }

            // Syntax-highlighted source for XML/JSON/HTML
            const isXml  = /^\s*</.test(text);
            const isJson = /^\s*[\[{]/.test(text);
            const mode   = isXml ? "xml" : isJson ? "json" : null;

            if (mode && text.length < 50000) {
                const cm = document.createElement("jinn-codemirror");
                cm.className = "try-me-result-cm";
                cm.setAttribute("mode", mode);
                cm.setAttribute("code", text);
                output.innerHTML = "";
                output.appendChild(cm);
            } else {
                resultEl.textContent = text;
                resultEl.className = "try-me-result try-me-success";
            }
        } catch (err) {
            resultEl.textContent =
                "Could not connect to the query service.\n" +
                "Make sure exist-api is installed.";
            resultEl.className = "try-me-result try-me-error";
        } finally {
            runBtn.disabled = false;
        }
    }
};

document.addEventListener("DOMContentLoaded", () => TryMe.init("try-me"));
