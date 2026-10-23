---
title: What a running service says that its code does not
version: 1
---

A common picture of dynamic analysis is static analysis done later: the same bugs, found by a
second tool, a few minutes further down the pipeline. **The two read different things, so they
find different defects.** A static analyser reads the files in the repository. A dynamic analyser
reads none of them. It starts the service, sends it requests the way a browser would, and judges
what comes back.

That difference decides everything else in this lesson: what DAST finds, where in the pipeline it
can run, what it needs in order to run at all, and what it will never see.

### What only the running service can tell you

Some defects are not written on any line. Lesson 3's linkbox answers its home page, as the next
section captures, with a header that says `Server: gunicorn` and with none of the headers a browser
uses to protect the page. Three things in that answer come from outside `app.py`. The `Server`
header is added by the server the Dockerfile starts, which is not code the project wrote. The
headers that are **missing** are missing because no line sets them, and an absence is not
something a pattern over source code matches well: Bandit and Semgrep, as lesson 3 configured
them, raise nothing about it. And the fact that the service answers through gunicorn at all, and
not through Flask's debug server, is a property of the image, decided in a different file in a
different language.

**DAST reads the deployed thing, so it sees what deploying added and what deploying left out.**
Headers, cookie flags, error pages, redirects, what the server says about itself, whether a debug
page is reachable. All of those can be right in the code and wrong in the running service, or the
other way round.

### What only the code can tell you

The scanner sees what it reaches, and only that. In lesson 3, Bandit flagged the search's SQL
because it read the line that joined the text typed into the query. A dynamic scanner would find
that defect only by sending the search the right input and recognising the failure, and the scan
this lesson runs sends nothing built to provoke one. A route the scanner never finds, a branch
that needs a particular value, an endpoint behind a token: to DAST they do not exist.

And when it does find something, **a dynamic finding has no line number**. It names a URL, the
request it sent and the part of the response that triggered the rule. Finding the code responsible
is your work, which is cheap in a service of one short file and expensive in one of four hundred
files.

| | static analysis (lesson 3) | dynamic analysis (this lesson) |
|---|---|---|
| what it reads | the source files | HTTP responses from a running instance |
| needs | the repository | a built image, started somewhere it can be reached |
| sees | every line, reached or not | only the pages and parameters it finds |
| finds well | injection-prone code, dangerous calls, secrets in code | missing headers, cookie flags, server banners, error pages, configuration |
| cannot see | how the service is deployed and what the server adds | code it never reaches, and which line is to blame |
| a finding names | a file and a line | a URL and the evidence in the response |
| its false positives | a pattern that matched safe code | a heuristic that misread a response |

### Where each one runs

Static analysis needs nothing but the checkout, so it runs early, on every push, before the image
exists. Dynamic analysis needs something to talk to: the image built, a container started, the
service ready to answer. **It can only run after the build, against an instance made for it**,
and the figure puts the two on the same pipeline.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"sp-l04-reads\" aria-label=\"Static and dynamic analysis placed on the same pipeline. The source files are built into an image, which runs as a service in staging. Static analysis reads every line of the source files and cannot see the server, its headers or its configuration. Dynamic analysis sends requests to the running service and reads the answers, and cannot see code it never reaches or which line is to blame.\"><defs><marker id=\"sp-l04-reads-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l04-reads-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">static analysis</text><text x=\"120.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads every line</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dynamic analysis</text><text x=\"590.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sends requests, reads answers</text><rect x=\"20\" y=\"110\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">source files</text><text x=\"95.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the repository</text><rect x=\"210\" y=\"110\" width=\"110\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build</text><text x=\"265.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ci/build.sh</text><rect x=\"360\" y=\"110\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">image</text><text x=\"435.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:&lt;commit&gt;</text><rect x=\"550\" y=\"110\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">running service</text><text x=\"625.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in staging</text><path d=\"M170 138 L208 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-paper-dim)\"></path><path d=\"M320 138 L358 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-paper-dim)\"></path><path d=\"M510 138 L548 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-paper-dim)\"></path><path d=\"M95 70 L95 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-phosphor)\"></path><path d=\"M600 70 L600 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-phosphor)\"></path><path d=\"M650 108 L650 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-reads-ah-phosphor)\"></path><text x=\"588\" y=\"89\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">requests</text><text x=\"662\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">answers</text><rect x=\"20\" y=\"195\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cannot see</text><text x=\"170.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the server, its headers, its configuration</text><rect x=\"400\" y=\"195\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cannot see</text><text x=\"550.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">code it never reaches, the line to blame</text><line x1=\"95\" y1=\"166\" x2=\"95\" y2=\"195\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"625\" y1=\"166\" x2=\"625\" y2=\"195\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line></svg>", "caption": "Static analysis reads the files before anything is built; dynamic analysis needs the service built and running, and asks it from outside."}
```

The instance it runs against is the subject of the next section, because it is where most of the
mistakes with DAST are made. Pointed at a shared test server, a scan reports the state somebody
else left there. Pointed at production, a passive scan is harmless and the other kind, which the
last section of this lesson explains, is not.

### Why this pipeline needs both

The defects linkbox was handed over with split cleanly between the two. The SQL in the search and
the debug server were lines, and lesson 3 found them by reading. The headers are an absence in
every response, and this lesson finds them by asking. Neither tool would have found the other's.
A team that runs one and calls the job done has decided, without saying so, which half of its
defects it is willing not to know about.
