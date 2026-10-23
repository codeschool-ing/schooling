---
title: What a known vulnerability is
version: 1
---

A **known vulnerability** is a flaw in a specific version of a package that has been reported,
confirmed and published, usually with the version that fixes it. Publishing is what makes it
"known", and it cuts both ways: the people who run the affected version can find out and update,
and so can everybody else. **The window between publication and your update is the window that
matters**, which is why checking is worth automating.

### The identifiers

The same flaw is listed in more than one database, under more than one name. pip-audit prints one
and the others are aliases of it:

| identifier | who assigns it | example shape |
|---|---|---|
| **CVE** | the CVE Program, through authorities such as GitHub and many vendors | `CVE-2024-56201` |
| **GHSA** | GitHub's advisory database | `GHSA-gmj6-6f8f-6699` |
| **PYSEC** | the Python Packaging Advisory Database, read by PyPI | `PYSEC-2026-1472` |

**OSV**, the Open Source Vulnerabilities format, is the common shape most of these databases
publish in, and it is what lets one tool read all of them. PyPI shows the advisories for a version
on the package's own page, and answers them through its API, which is where pip-audit asks by
default.

### What an entry tells you

An advisory carries three facts a developer needs, and you rarely need more to act:

- the affected range: which versions have the flaw;
- the fixed version: the first release without it, the number you move the pin to;
- a severity, often as a CVSS score, which helps order the work when there are many.

What an advisory does not tell you is **whether your application uses the affected part** of the
package. Sometimes it plainly does not, and the update can wait for the next routine one. Deciding
that is legitimate, and it is a decision: it is written down, with the reason and a date to look
again, the way lesson 18 asks of a review. Leaving an advisory unanswered is not the same decision
taken quietly; it is no decision at all.
