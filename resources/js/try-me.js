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
        const resultEl = this.container.querySelector(".try-me-result");
        if (resultEl) {
            resultEl.textContent = 'Click "Run" to execute the query.';
            resultEl.className = "try-me-result";
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

        const resultEl = this.container.querySelector(".try-me-result");
        resultEl.textContent = "Running...";
        resultEl.className = "try-me-result";
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

            if (data.error) {
                resultEl.textContent = data.error;
                resultEl.className = "try-me-result try-me-error";
            } else {
                resultEl.textContent = data.result;
                resultEl.className = "try-me-result try-me-success";
            }
        } catch (err) {
            resultEl.textContent =
                "Could not connect to the query service.\n" +
                "Make sure the Notebook app is installed.";
            resultEl.className = "try-me-result try-me-error";
        } finally {
            runBtn.disabled = false;
        }
    }
};

document.addEventListener("DOMContentLoaded", () => TryMe.init("try-me"));
