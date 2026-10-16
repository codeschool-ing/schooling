---
title: Fitness functions
version: 1
---

A record explains a decision; it does not enforce it. ADR 4 says no `SELECT *` under `app/`, and a year
later a hurried change adds one, and nothing notices until a page is slow. The strongest defence of a
decision is to make the build check it.

Neal Ford, Rebecca Parsons and Patrick Kua called such checks **fitness functions**, in *Building
Evolutionary Architectures*: an automated test of an architectural property, run as often as the code
changes. The lab's is `check.sh`. Run it against the catalogue code, which was written before ADR 4:

```
ana@vm:~/lab/adr$ bash check.sh; echo "exit status $?"
app/catalogue.py:2:    return db.execute("SELECT * FROM products ORDER BY id").fetchall()
ADR 4: name the columns; SELECT * is not allowed under app/
exit status 1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A decision, ADR 4, no SELECT star in application code, is turned into a check, check.sh, which runs in CI on every change. A change that adds SELECT star under app fails the check and cannot be merged; a change that names its columns passes.\"><defs><marker id=\"l20-fitness-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-fitness-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ADR 4</text><rect x=\"270\" y=\"80\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">check.sh in CI</text><path d=\"M192 105 L268 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-fitness-ah-phosphor)\"></path><text x=\"230\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">becomes</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">SELECT * under app/</text><text x=\"600\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fails: not merged</text><rect x=\"510\" y=\"130\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">columns named</text><text x=\"600\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">passes</text><path d=\"M432 95 L508 65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-fitness-ah-amber)\"></path><path d=\"M432 115 L508 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-fitness-ah-phosphor)\"></path></svg>", "caption": "A fitness function makes a decision executable: the build defends it on every change, long after the people who made it have moved on."}
```

It found the line and failed, with a message that names the record, so the person whose change it
stopped can read why. Fix the query the way ADR 4 asks, and run it again:

```
ana@vm:~/lab/adr$ sed -i 's/SELECT \* FROM products/SELECT id, name, cents FROM products/' app/catalogue.py
ana@vm:~/lab/adr$ bash check.sh; echo "exit status $?"
ADR 4: ok
exit status 0
```

In a real repository `check.sh` runs in CI on every pull request, and a change that breaks ADR 4 cannot
be merged. Fitness functions come in many sizes:

| decision | the check |
| --- | --- |
| modules do not reach into each other's tables | a test that reads the imports or the SQL and fails on a forbidden one (ArchUnit in Java, `import-linter` in Python) |
| the checkout page answers in under 300 ms | a performance test in the pipeline with a threshold |
| every service exposes `/health` | a test against each service's deployment |
| no service calls another synchronously from a message consumer | a static check on the consumer code |

Not every decision can be checked, and a check that cries wolf gets switched off. But each one that
can be checked stops depending on somebody remembering the record, which is the one thing a record
cannot guarantee.
