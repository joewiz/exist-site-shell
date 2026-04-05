/**
 * "Try Me" XQuery demo widget.
 *
 * Executes XQuery queries against the notebook app's eval API
 * and displays results in a compact pane. Uses jinn-codemirror
 * for syntax-highlighted source display and result output.
 */
const TryMe = {
    queries: [
        {
            title: "List the plays",
            description: "Retrieve all play titles from the Shakespeare collection.",
            query: `collection("data/shakespeare")/PLAY/TITLE/string()`
        },
        {
            title: "Find characters",
            description: "List all characters in Hamlet.",
            query: `doc("data/shakespeare/hamlet.xml")//PERSONA/string()`
        },
        {
            title: "Search for a word",
            description: "Find speeches containing the word \"love\" across all plays.",
            query: `for $speech in collection("data/shakespeare")//SPEECH
where contains($speech/LINE, "love")
return
    <match play="{$speech/ancestor::PLAY/TITLE}"
           speaker="{$speech/SPEAKER}">
        {$speech/LINE[contains(., "love")][1]}
    </match>`
        },
        {
            title: "Count speeches per play",
            description: "How many speeches does each play contain?",
            query: `for $play in collection("data/shakespeare")/PLAY
let $count := count($play//SPEECH)
order by $count descending
return
    $play/TITLE || ": " || $count || " speeches"`
        },
        {
            title: "Who speaks the most?",
            description: "Find the top 10 speakers by number of speeches across all plays.",
            query: `let $speeches := collection("data/shakespeare")//SPEECH
for $speaker in distinct-values($speeches/SPEAKER)
let $count := count($speeches[SPEAKER = $speaker])
order by $count descending
return
    ($speaker || ": " || $count || " speeches")
=> subsequence(1, 10)`
        }
    ],

    currentIndex: 0,
    container: null,
    evalEndpoint: null,
    sourceEditor: null,
    resultEditor: null,

    init(containerId) {
        this.container = document.getElementById(containerId);
        if (!this.container) return;

        this.evalEndpoint = this.container.dataset.evalEndpoint ||
            "/exist/apps/notebook/api/eval";

        this.render();
        this.initEditors();
    },

    render() {
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
                <p class="try-me-description"></p>
                <div class="try-me-editor">
                    <jinn-codemirror class="try-me-source" mode="xquery"></jinn-codemirror>
                    <button class="try-me-run">Run &#9654;</button>
                </div>
                <div class="try-me-output">
                    <jinn-codemirror class="try-me-result" mode="xml"></jinn-codemirror>
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
        this.resultEditor = this.container.querySelector(".try-me-result");

        this.showQuery(0);
    },

    showQuery(index) {
        this.currentIndex = index;
        const q = this.queries[index];
        const el = this.container;

        if (this.sourceEditor) {
            this.sourceEditor.content = q.query;
        }
        if (this.resultEditor) {
            this.resultEditor.content = 'Click "Run" to execute the query.';
            this.resultEditor.mode = "text";
        }

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
            // Read back from editor in case user edited the query
            q.query = this.sourceEditor.content || q.query;
        }

        if (this.resultEditor) {
            this.resultEditor.content = "Running...";
            this.resultEditor.mode = "text";
        }
        runBtn.disabled = true;

        try {
            const response = await fetch(this.evalEndpoint, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    query: q.query,
                    serialization: "adaptive",
                    baseUri: "/db/apps/notebook/content/getting-started"
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const data = await response.json();

            if (this.resultEditor) {
                if (data.error) {
                    this.resultEditor.content = data.error;
                    this.resultEditor.mode = "text";
                } else {
                    this.resultEditor.content = data.result;
                    // Detect result type for highlighting
                    const text = data.result || "";
                    if (/^\s*</.test(text)) {
                        this.resultEditor.mode = "xml";
                    } else if (/^\s*[\[{]/.test(text)) {
                        this.resultEditor.mode = "json";
                    } else {
                        this.resultEditor.mode = "text";
                    }
                }
            }
        } catch (err) {
            if (this.resultEditor) {
                this.resultEditor.content =
                    "Could not connect to the query service.\n" +
                    "Make sure the Notebook app is installed.";
                this.resultEditor.mode = "text";
            }
        } finally {
            runBtn.disabled = false;
        }
    }
};

document.addEventListener("DOMContentLoaded", () => TryMe.init("try-me"));
