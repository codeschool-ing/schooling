---
title: What static analysis reads, and what it cannot
version: 1
---

Static analysis is often sold as a machine that reads code and finds the vulnerabilities in it.
What it actually does is narrower and more useful once it is understood: **it matches the code
against rules somebody wrote, without running it.** Each rule describes a shape that is usually a
mistake, such as text from a request reaching a database query, and the tool reports every place
the shape occurs. It finds what it has rules for, in the code it was given, and nothing else.

That is the whole of SAST, static application security testing. The rest of this lesson is two
tools of that kind on linkbox: Bandit, with the rules it ships with, and Semgrep, with two rules
written for this project. The stage that runs both takes 3 seconds on linkbox in this lesson's
recording, well inside the budget of a push from lesson 2.

### Sources, sinks and the path between them

Most security rules are about a flow. A **source** is where data enters that somebody outside
controls: a request's parameters, its headers, a form, a file that was uploaded. A **sink** is a
call that does something dangerous with whatever it is given: run SQL, run a shell command, write
a file, render HTML without escaping. The defect is a path from a source to a sink with nothing in
between that makes the data safe.

linkbox has one such path, in its search, and you saw it in lesson 1:

```python
q = request.args.get("q", "")
rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l03-flow\" aria-label=\"Two versions of linkbox's search. In lesson 1 the search text from request.args is formatted into the SQL text with an f-string, and the one string reaches execute(), where SQLite reads all of it as SQL: code and data in one channel. In lesson 3 the SQL text is fixed, with a question mark where the value goes, and the search text travels separately as a parameter; SQLite never reads it as SQL.\"><defs><marker id=\"sp-l03-flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l03-flow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l03-flow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">lesson 1: one string</text><text x=\"70\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">source</text><rect x=\"15\" y=\"54\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">request.args[\"q\"]</text><text x=\"90.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the user typed</text><rect x=\"215\" y=\"54\" width=\"250\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">f\"...LIKE '%{q}%'\"</text><text x=\"340.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">formatted into the SQL</text><text x=\"610\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sink</text><rect x=\"515\" y=\"54\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execute(sql)</text><text x=\"610.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read as SQL</text><path d=\"M165 82 L213 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-amber)\"></path><path d=\"M465 82 L513 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-amber)\"></path><line x1=\"15\" y1=\"140\" x2=\"705\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">lesson 3: two channels</text><rect x=\"215\" y=\"176\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">\"...LIKE ?\"</text><text x=\"340\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fixed SQL text</text><rect x=\"15\" y=\"236\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">request.args[\"q\"]</text><text x=\"90.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the user typed</text><rect x=\"215\" y=\"244\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">(f\"%{q}%\",)</text><text x=\"340\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a parameter</text><rect x=\"515\" y=\"205\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execute(sql, params)</text><text x=\"610.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read as a value</text><path d=\"M165 264 L213 264\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-phosphor)\"></path><path d=\"M465 198 L490 198 L490 225 L513 225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-paper-dim)\"></path><path d=\"M465 266 L490 266 L490 241 L513 241\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-phosphor)\"></path></svg>", "caption": "The defect is a path from a source to a sink with nothing between them that keeps data out of the code."}
```

The text typed into the search box becomes part of the SQL itself. A quote in it ends the string
the query meant to compare against, and whatever follows the quote is read by SQLite as more SQL.
**That is SQL injection, and the reason it is possible is that code and data travel in one
string.** The fix keeps them apart: the query is written with a `?` where the value goes, and the
value is passed separately, so the database never reads it as SQL. `secure-code` lesson 5 is the
whole subject; this lesson is about how a pipeline finds it and keeps it found.

### How much of the path a tool follows

Tools differ in how far they follow the data, and the difference decides what they can miss.

| what the tool does | what it sees | linkbox's search |
|---|---|---|
| matches one line or one call | a query built from a string, wherever it is | found, from the f-string alone |
| follows values inside one function | that `q` came from `request.args` | found, and it knows why |
| follows values across functions and files | a source in one module reaching a sink in another | found; needed when the query is built in a helper |

Bandit works at the first level. It flags a query built by formatting a string whatever the string
holds, which makes it fast and simple. It is also why the same rule fires on a query built from a
constant, which section 04 shows. Semgrep's open-source engine matches patterns, with some flow inside a function; deeper
cross-file tracking is in commercial engines, including Semgrep's own paid tier, and was not used
here.

### What it cannot see

Static analysis reads code. **Anything that only exists when the program runs is outside it**, and
the list is long:

- **the configuration it runs with**: an environment variable that turns debugging on, a
  permissive setting in the web server in front of it;
- **the responses it sends**: a missing security header is a property of the HTTP answer, which is
  lesson 4's dynamic analysis;
- **the code it did not write**: a flaw in Flask itself is in a dependency, which is lesson 5;
- **the design**: a route that should not exist at all, or one that trusts the wrong party, is
  correct code doing the wrong thing, and that is what threat modelling is for.

So a clean static analysis run means one thing: **none of the rules that ran found its shape in
the code that was scanned.** It is a strong statement about a few known mistakes and no statement
at all about everything else. The next sections make that concrete, starting with what Bandit
reports on the code you inherited.
