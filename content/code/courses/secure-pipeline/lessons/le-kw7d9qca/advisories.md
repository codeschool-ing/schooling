---
title: Advisories, and why one flaw has three names
version: 1
---

An **advisory** is a published statement about a package: these versions have this flaw, and this
version fixes it. It is the unit everything in composition analysis is built from. A scanner does
not find a flaw in Werkzeug by reading Werkzeug; it finds that the installed version falls inside a
range somebody already published.

That has a consequence worth stating before running anything: **SCA finds only what has been
disclosed.** A flaw nobody has reported, or one reported yesterday and not yet in the database,
passes every audit. The audit answers "is anything known to be wrong with these versions", which is
a narrower question than "is this code safe".

### The names

One flaw is usually published under several identifiers, by different organisations, in different
databases. Four matter for a Python project:

| identifier | who assigns it | what it is |
|---|---|---|
| CVE-2026-27205 | a CVE Numbering Authority, under the CVE Program | one identifier per flaw, across every language and product |
| GHSA-68rp-wp8r-4726 | GitHub, in the GitHub Advisory Database | an advisory reviewed for a package ecosystem, with the affected version ranges |
| PYSEC-2026-2151 | the Python Packaging Authority's advisory database | advisories for packages on PyPI, kept in the OSV format |
| OSV | the open-source vulnerability project, at osv.dev | a shared format, and a service that gathers GHSA, PYSEC and other databases and records which ids are the same flaw |

The CVE says *which* flaw. The GHSA and PYSEC records say *which versions of which package*, which
is what a scanner needs, and each lists the others as **aliases**.

### Where pip-audit gets them

`pip-audit` installs the requirements into a temporary environment of its own, so it knows every
package that would be installed, transitive ones included. Then it looks each package and version
up in a vulnerability service. The default is **PyPI itself**: every release's JSON description on
pypi.org carries the advisories that affect it, taken from OSV. `-s osv` asks osv.dev directly
instead; this course's machine cannot reach osv.dev, so every audit here uses the default.

Run it on lesson 1's pins:

```
ana@vm:~/linkbox$ pip-audit --version
pip-audit 2.10.1
ana@vm:~/linkbox$ pip-audit -r requirements.txt; echo "exit status $?"
Found 29 known vulnerabilities in 4 packages
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
flask    3.0.0   PYSEC-2026-2151 3.1.3
flask    3.0.0   PYSEC-2026-2151 3.1.3
werkzeug 3.0.1   PYSEC-2026-2043 3.0.3
werkzeug 3.0.1   PYSEC-2026-2045 3.0.6
werkzeug 3.0.1   PYSEC-2026-1860 3.0.6
werkzeug 3.0.1   PYSEC-2026-2046 3.1.4
werkzeug 3.0.1   PYSEC-2026-2044 3.1.5
werkzeug 3.0.1   PYSEC-2026-2320 3.1.6
werkzeug 3.0.1   PYSEC-2026-2045 3.0.6
werkzeug 3.0.1   PYSEC-2026-2046 3.1.4
werkzeug 3.0.1   PYSEC-2026-2044 3.1.5
werkzeug 3.0.1   PYSEC-2026-2043 3.0.3
werkzeug 3.0.1   PYSEC-2026-2320 3.1.6
werkzeug 3.0.1   PYSEC-2026-3417 3.0.6
werkzeug 3.0.1   PYSEC-2026-4312 3.1.9
jinja2   3.1.2   PYSEC-2026-1473 3.1.3
jinja2   3.1.2   PYSEC-2026-1474 3.1.4
jinja2   3.1.2   PYSEC-2026-1475 3.1.5
jinja2   3.1.2   PYSEC-2026-1472 3.1.5
jinja2   3.1.2   PYSEC-2026-1471 3.1.6
jinja2   3.1.2   PYSEC-2026-1473 3.1.3
jinja2   3.1.2   PYSEC-2026-1471 3.1.6
jinja2   3.1.2   PYSEC-2026-1474 3.1.4
jinja2   3.1.2   PYSEC-2026-1475 3.1.5
jinja2   3.1.2   PYSEC-2026-1472 3.1.5
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0
exit status 1
```

Exit status 1: something was found, and a pipeline stage running this command would break.

### Twenty-nine rows, fifteen flaws

**Most flaws are in that table twice**, and that is not a fault in the project. PyPI publishes
two records for most flaws, the GHSA one and the PYSEC one, and pip-audit prints a row for each
record, naming both by the PYSEC id. Ask PyPI about Flask 3.0.0 directly and the two records are
there, each naming the other as an alias, and each saying it came from OSV:

```
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/flask/3.0.0/json | jq ".vulnerabilities[] | {id, aliases, fixed_in, source}"
{
  "id": "GHSA-68rp-wp8r-4726",
  "aliases": [
    "CVE-2026-27205",
    "PYSEC-2026-2151"
  ],
  "fixed_in": [
    "3.1.3"
  ],
  "source": "osv"
}
{
  "id": "PYSEC-2026-2151",
  "aliases": [
    "CVE-2026-27205",
    "GHSA-68rp-wp8r-4726"
  ],
  "fixed_in": [
    "3.1.3"
  ],
  "source": "osv"
}
```

So the count a tool prints is a count of records, not of problems. Counting the distinct CVE ids
gives the number of flaws. `-f json -o` writes the report as JSON for `jq` to read:

```
ana@vm:~/linkbox$ pip-audit -r requirements.txt -f json -o /tmp/audit.json
Found 29 known vulnerabilities in 4 packages
ana@vm:~/linkbox$ jq "[.dependencies[].vulns[]] | length" /tmp/audit.json
29
ana@vm:~/linkbox$ jq -r "[.dependencies[].vulns[].aliases[] | select(startswith(\"CVE-\"))] | unique[]" /tmp/audit.json > /tmp/cves.txt
ana@vm:~/linkbox$ wc -l < /tmp/cves.txt
15
```

**Fifteen flaws in four packages**: one in Flask, seven in Werkzeug, five in Jinja and two in
gunicorn. The list of CVE ids in `/tmp/cves.txt` is used again in the section on scores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l05-names\" aria-label=\"One flaw in Flask 3.0.0 under its names. CVE-2026-27205 identifies the flaw. It is published twice, as GHSA-68rp-wp8r-4726 in GitHub's advisory database and as PYSEC-2026-2151 in the Python Packaging Authority's, each listing the other as an alias. osv.dev gathers both; PyPI's JSON for the release serves both records; pip-audit prints a row for each, so one flaw becomes two rows.\"><defs><marker id=\"sp-l05-names-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l05-names-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l05-names-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">CVE-2026-27205</text><text x=\"95.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the flaw</text><rect x=\"210\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GHSA-68rp-wp8r-4726</text><text x=\"305.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">GitHub Advisory Database</text><rect x=\"210\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">PYSEC-2026-2151</text><text x=\"305.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PyPA advisory database</text><path d=\"M170 115 L190 115 L190 55 L208 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-phosphor)\"></path><path d=\"M170 135 L190 135 L190 195 L208 195\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-phosphor)\"></path><line x1=\"305\" y1=\"80\" x2=\"305\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"312\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aliases of each other</text><rect x=\"440\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">osv.dev</text><text x=\"495.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gathers both</text><path d=\"M400 55 L420 55 L420 115 L438 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-paper-dim)\"></path><path d=\"M400 195 L420 195 L420 135 L438 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-paper-dim)\"></path><rect x=\"575\" y=\"30\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pypi.org</text><text x=\"640.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two records</text><path d=\"M550 115 L565 115 L565 55 L573 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-paper-dim)\"></path><rect x=\"575\" y=\"170\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pip-audit</text><text x=\"640.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two rows, one flaw</text><path d=\"M640 80 L640 168\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-amber)\"></path></svg>", "caption": "Count CVE ids, not rows: the same flaw reaches the audit twice."}
```

### What the table does not say

The table has a package, a version, an id and a fixed version. It has no severity, no description
and no word about whether linkbox does anything the flaw needs. Fifteen rows that look the same are
not fifteen problems of the same size, and treating them as such is how a team either panics or
stops reading. The next section reads one advisory in full and then the other fourteen, against
what linkbox actually does.

Two habits follow from all this. **Quote the CVE** when you talk about a finding, because it is
the id every other tool and every other team will recognise. And **count flaws, not rows**, before
a number goes into a report: lesson 20 measures the pipeline's findings, and a count that doubles
because a database published twice is a measurement of the database.
