<div class="landing">

    <section class="hero">
        <h1>The Open Source Native XML Database</h1>
        <p class="hero-tagline">Store, query, and build applications — all with XML and XQuery.</p>
        <div class="hero-actions">
            <a href="https://github.com/eXist-db/exist/releases" class="btn btn-primary">Download eXist-db</a>
            <a href="[[ $shell-base ]]/about" class="btn btn-secondary">Learn More</a>
        </div>
    </section>

    <section class="features">
        <h2>Why eXist-db?</h2>
        <div class="feature-grid">
            <div class="feature">
                <h3>XQuery 3.1</h3>
                <p>Full implementation of the W3C query language. Write queries, transforms, and complete applications in one language.</p>
            </div>
            <div class="feature">
                <h3>Full-Text Search</h3>
                <p>Apache Lucene-powered indexing with facets, fields, and analyzers. Fast search across millions of documents.</p>
            </div>
            <div class="feature">
                <h3>Application Platform</h3>
                <p>Build and deploy web applications as self-contained XAR packages. No external app server needed.</p>
            </div>
            <div class="feature">
                <h3>Open Standards</h3>
                <p>REST, WebDAV, XQuery, XSLT, XForms. Use the tools you already know.</p>
            </div>
            <div class="feature">
                <h3>Package Ecosystem</h3>
                <p>50+ community packages for templating, markdown, security, monitoring, and more.</p>
            </div>
            <div class="feature">
                <h3>One Step Install</h3>
                <p>Download, unzip, run. No complex setup, no external dependencies. Java is all you need.</p>
            </div>
        </div>
    </section>

    [% if count($testimonials?*) > 0 %]
    <section class="testimonials">
        <h2>What People Say</h2>
        <div class="testimonial-list">
            [% for $t in $testimonials?* %]
            <blockquote class="testimonial">
                <p>[[ $t?quote ]]</p>
                <footer>
                    <strong>[[ $t?author ]]</strong>, [[ $t?role ]], [[ $t?org ]]
                </footer>
            </blockquote>
            [% endfor %]
        </div>
    </section>
    [% endif %]

    [% if count($news-items?*) > 0 %]
    <section class="news">
        <h2>Latest News</h2>
        <ul class="news-list">
            [% for $item in $news-items?* %]
            <li>
                <span class="news-date">[[ $item?date ]]</span>
                <a href="[[ $item?url ]]">[[ $item?title ]]</a>
                <p>[[ $item?snippet ]]</p>
            </li>
            [% endfor %]
        </ul>
    </section>
    [% endif %]

    <section class="community">
        <h2>Join the Community</h2>
        <div class="community-links">
            <a href="https://github.com/eXist-db/exist">GitHub</a>
            <a href="https://exist-db.slack.com">Slack</a>
            <a href="https://fosstodon.org/@existdb">Mastodon</a>
            <a href="[[ $shell-base ]]/community">Get Involved</a>
        </div>
    </section>
</div>
