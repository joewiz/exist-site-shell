# About eXist-db

eXist-db is a high-performance open source native XML database — a NoSQL document database and application platform built entirely around XML technologies. It stores XML, JSON, HTML, and binary documents and provides XQuery for querying, transforming, and building full-stack web applications directly on your data.

Created in 2000 by Wolfgang Meier at TU Darmstadt, Germany, eXist-db has grown into a mature, production-grade platform used by organizations worldwide — from university research projects and digital humanities archives to government agencies and commercial publishers. It received InfoWorld's Best XML Database award in 2006.

## Key Features

### Query and Transform

- **XQuery 4.0** — full implementation of the latest W3C query language, with version gating for backward compatibility with XQuery 3.1
- **XQuery Update Facility 3.0** — W3C standard for in-place document updates
- **XSLT 3.0 and XPath 3.1** — via Saxon 12, for document transformation
- **JSON and CSV** — native JSON storage, `fn:json-doc`, `fn:json-to-xml`, CSV serialization, and the complete XQuery maps and arrays specification

### Search

- **XQuery Full Text 3.0** — W3C standard for linguistic full-text search with stemming, thesauri, stop words, and match scoring
- **Apache Lucene 10** — full-text indexing with facets, fields, custom analyzers, and range indexes
- **Semantic search** — vector embeddings and KNN (K-Nearest Neighbor) similarity search via Lucene's HNSW vector fields, with support for local ONNX models and remote embedding APIs

### Application Platform

- **XAR packages** — build and deploy self-contained web applications as installable packages
- **Built-in package management** — install, update, and remove packages via REST API, with dependency resolution
- **URL rewriting** — declarative routing via `controller.xql` or OpenAPI-based `controller.json`
- **RESTXQ** — annotation-based REST endpoint declarations directly in XQuery modules
- **Templating** — server-side HTML templating framework for building dynamic pages

### Database

- **Native XML storage** — documents stored in their natural hierarchical form with structural indexes
- **Fine-grained security** — Unix-style owner/group permissions with ACLs on collections and resources
- **Crash-safe storage** — write-ahead journaling with automatic recovery
- **REST and WebDAV** — standard interfaces for integration and drag-and-drop file management
- **Triggers** — collection-level event triggers for validation, indexing, and workflow automation

## Technology Stack

eXist-db 7.0 is built on modern foundations:

| Component | Version | Purpose |
|-----------|---------|---------|
| Java | 21 (LTS) | Runtime platform |
| Jetty | 12 | HTTP server, Jakarta Servlet 6.0 |
| Saxon | 12 | XSLT/XPath processing |
| Apache Lucene | 10 | Full-text and vector indexing |
| Bouncy Castle | 1.84 | Cryptographic operations |

## Community

eXist-db is developed by a global community of contributors.

- **Weekly community calls** — Mondays 19:30-20:30 CET, open to all
- **Slack** — [exist-db.slack.com](https://exist-db.slack.com) for real-time discussion
- **GitHub** — [eXist-db/exist](https://github.com/eXist-db/exist) for source, issues, and pull requests
- **Mastodon** — [@existdb@fosstodon.org](https://fosstodon.org/@existdb) for announcements

Commercial support is available from [eXist Solutions GmbH](https://www.existsolutions.com/) (Germany) and [Evolved Binary](https://www.evolvedbinary.com/) (UK).

## Publications

- *eXist: A NoSQL Document Database and Application Platform* (O'Reilly, 2014) by Erik Siegel and Adam Retter

## License

eXist-db is free software, released under the [GNU Lesser General Public License, version 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html) (LGPL-2.1).
