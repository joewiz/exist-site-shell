---json
{
    "templating": {
        "extends": "templates/base-page.html"
    }
}
---
[% template title %][[ $page-title ]] -- [[ $site?name ]][% endtemplate %]

[% template head %]
<style>
.page-with-sidebar {
    display: grid;
    grid-template-columns: 1fr 280px;
    gap: 2rem;
    max-width: var(--site-max-width, 1200px);
    margin: 0 auto;
    padding: 1rem;
}
.page-with-sidebar .page-content {
    min-width: 0;
}
.page-sidebar {
    font-size: 0.9rem;
    padding-top: 1rem;
}
.fact-card {
    background: var(--site-footer-bg, #f8f9fa);
    border: 1px solid var(--site-border, #e0e0e0);
    border-radius: 8px;
    padding: 1.25rem;
    margin-bottom: 1rem;
}
.fact-card h3 {
    margin: 0 0 0.75rem;
    font-size: 1rem;
    border-bottom: 1px solid var(--site-border, #e0e0e0);
    padding-bottom: 0.5rem;
}
.fact-card dl {
    margin: 0;
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 0.3rem 0.75rem;
}
.fact-card dt {
    font-weight: 600;
    color: var(--site-muted, #666);
    white-space: nowrap;
}
.fact-card dd {
    margin: 0;
}
.fact-card dd a {
    word-break: break-all;
}
.fact-card ul {
    margin: 0;
    padding: 0;
    list-style: none;
}
.fact-card ul li {
    padding: 0.2rem 0;
}
@media (max-width: 768px) {
    .page-with-sidebar {
        grid-template-columns: 1fr;
    }
    .page-sidebar {
        order: -1;
    }
}
</style>
[% endtemplate %]

[% template content %]
[% if $page-title = 'About eXist-db' %]
<div class="page-with-sidebar">
    <article class="page-content">
        [[ $page-html ]]
    </article>
    <aside class="page-sidebar">
        <div class="fact-card">
            <h3>Quick Facts</h3>
            <dl>
                <dt>Type</dt>
                <dd>NoSQL document database</dd>
                <dt>Written in</dt>
                <dd>Java</dd>
                <dt>Created</dt>
                <dd>2000</dd>
                <dt>Creator</dt>
                <dd>Wolfgang Meier</dd>
                <dt>License</dt>
                <dd>LGPL 2.1</dd>
                <dt>Latest</dt>
                <dd>7.0.0 (in development)</dd>
            </dl>
        </div>
        <div class="fact-card">
            <h3>Standards</h3>
            <ul>
                <li>XQuery 4.0</li>
                <li>XQuery Update 3.0</li>
                <li>XQuery Full Text 3.0</li>
                <li>XSLT 3.0 / XPath 3.1</li>
                <li>XForms 1.1</li>
                <li>EXPath / EXQuery</li>
                <li>REST / WebDAV</li>
                <li>RESTXQ</li>
                <li>OpenAPI 3.0</li>
            </ul>
        </div>
        <div class="fact-card">
            <h3>Platforms</h3>
            <ul>
                <li>Linux</li>
                <li>macOS</li>
                <li>Windows</li>
                <li>Docker</li>
            </ul>
        </div>
        <div class="fact-card">
            <h3>Links</h3>
            <ul>
                <li><a href="https://github.com/eXist-db/exist">GitHub</a></li>
                <li><a href="https://exist-db.org">exist-db.org</a></li>
                <li><a href="https://exist-db.slack.com">Slack</a></li>
                <li><a href="https://fosstodon.org/@existdb">Mastodon</a></li>
                <li><a href="https://en.wikipedia.org/wiki/EXist">Wikipedia</a></li>
            </ul>
        </div>
    </aside>
</div>
[% else %]
<article class="page-content">
    [[ $page-html ]]
</article>
[% endif %]
[% endtemplate %]
