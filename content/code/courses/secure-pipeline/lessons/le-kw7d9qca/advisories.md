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

@@CAPTURE audit@@

Exit status 1: something was found, and a pipeline stage running this command would break.

### Twenty-nine rows, fifteen flaws

**Most flaws are in that table twice**, and that is not a fault in the project. PyPI publishes
two records for most flaws, the GHSA one and the PYSEC one, and pip-audit prints a row for each
record, naming both by the PYSEC id. Ask PyPI about Flask 3.0.0 directly and the two records are
there, each naming the other as an alias, and each saying it came from OSV:

@@CAPTURE pypi@@

So the count a tool prints is a count of records, not of problems. Counting the distinct CVE ids
gives the number of flaws. `-f json -o` writes the report as JSON for `jq` to read:

@@CAPTURE count@@

**Fifteen flaws in four packages**: one in Flask, seven in Werkzeug, five in Jinja and two in
gunicorn. The list of CVE ids in `/tmp/cves.txt` is used again in the section on scores.

@@FIGURE names@@

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
