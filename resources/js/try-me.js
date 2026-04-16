/**
 * "Try Me" XQuery demo widget.
 *
 * Executes XQuery queries against the exist-api /api/eval endpoint
 * and displays results in a compact pane. Uses jinn-codemirror
 * for syntax-highlighted source display and result output.
 */
const TryMe = {
    queries: [
        {
            title: "Hello XQuery",
            description: "Your first query — construct XML with a timestamp.",
            query: `let $msg := "Hello XQuery!"
return
    <greeting timestamp="{current-dateTime()}">
        {$msg}
    </greeting>`
        },
        {
            title: "List the plays",
            description: "Retrieve all play titles from the Shakespeare collection.",
            query: `collection("/db/apps/notebook/data/shakespeare")/PLAY/TITLE/string()`
        },
        {
            title: "Find characters",
            description: "List all characters in Hamlet.",
            query: `doc("/db/apps/notebook/data/shakespeare/hamlet.xml")//PERSONA/string()`
        },
        {
            title: "Search for a word",
            description: "Find speeches containing \"love\" across all plays.",
            query: `for $speech in collection("/db/apps/notebook/data/shakespeare")//SPEECH
where contains($speech/LINE, "love")
return
    <match play="{$speech/ancestor::PLAY/TITLE}"
           speaker="{$speech/SPEAKER}">
        {$speech/LINE[contains(., "love")][1]}
    </match>`
        },
        {
            title: "Who speaks the most?",
            description: "Top 10 speakers by number of speeches across all plays.",
            query: `let $speeches := collection("/db/apps/notebook/data/shakespeare")//SPEECH
for $speaker in distinct-values($speeches/SPEAKER)
let $count := count($speeches[SPEAKER = $speaker])
order by $count descending
return
    ($speaker || ": " || $count || " speeches")
=> subsequence(1, 10)`
        },
        {
            title: "Group by speaker",
            description: "Group all speeches mentioning \"king\" by who said them.",
            query: `for $speech in collection("/db/apps/notebook/data/shakespeare")//SPEECH
where contains($speech/LINE, "king")
group by $speaker := $speech/SPEAKER/string()
order by count($speech) descending
return
    <speaker name="{$speaker}" mentions="{count($speech)}"/>`
        },
        {
            title: "World cities",
            description: "Top 10 most populous cities in the Mondial geographic database.",
            query: `for $city in doc("/db/apps/notebook/data/mondial.xml")//city
let $pop := $city/population[last()]
where exists($pop)
order by number($pop) descending
return
    ($city/name/string() || ": " || format-number(number($pop), "#,###"))
=> subsequence(1, 10)`
        },
        {
            title: "Countries and religions",
            description: "Find countries where Buddhism is practiced by more than 50% of the population.",
            query: `for $country in doc("/db/apps/notebook/data/mondial.xml")//country
let $buddhism := $country/religions[contains(., "Buddhist")]
where number($buddhism/@percentage) > 50
order by number($buddhism/@percentage) descending
return
    $country/name/string() || ": " || $buddhism/@percentage || "% Buddhist"`
        },
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
        }
    ],

    currentIndex: 0,
    container: null,
    apiBase: null,
    sourceEditor: null,

    init(containerId) {
        this.container = document.getElementById(containerId);
        if (!this.container) return;

        // Derive exist-api base from the current page context path
        const m = window.location.pathname.match(/(.*\/exist)/);
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
                    <h3>Try XQuery</h3>
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

        try {
            const response = await fetch(`${this.apiBase}/api/eval`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                credentials: "same-origin",
                body: JSON.stringify({
                    query: q.query,
                    method: "adaptive",
                    indent: "yes",
                    "omit-xml-declaration": "yes",
                    count: 50
                })
            });

            const text = await response.text();

            if (!response.ok || text.startsWith("Error:")) {
                resultEl.textContent = text;
                resultEl.className = "try-me-result try-me-error";
                return;
            }

            // Detect content type for syntax highlighting
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
