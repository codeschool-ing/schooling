---
title: A DAST scan, and how to read its report
version: 1
---

pip-audit reads a list of packages. A **DAST** scanner, the dynamic analysis of lesson 16's table,
reads nothing of yours at all: it talks to the running application over HTTP, the way a browser
does, and reports what the answers give away. The free one most teams meet first is **OWASP ZAP**,
the Zed Attack Proxy, now published simply as ZAP, and its gentlest mode is the one to start with.

## Permission first

A DAST scan sends hundreds or thousands of requests, and some of its modes send requests designed
to make an application misbehave. **Pointing one at a system you do not own, without the owner's
written permission, is illegal**, in Brazil under article 154-A of the Penal Code and elsewhere
under laws like the ones lesson 16 named, however harmless the intent. At work it is pointed at a
staging copy that you are authorised to test, never at production unless the scope says so in
writing, and never at the services your system calls.

## The baseline scan

ZAP's **baseline scan** is built to be safe to run often. It crawls the site for a minute, from
the address it is given, and runs only **passive** rules: it looks at the requests and answers that
the crawl produced and attacks nothing. It is what a pipeline runs against staging after each
deployment. ZAP publishes it as a container image, and the usual line is:

```sh
docker run --rm -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.boxoffice.example
```

**This was not run for this course**, because the recording computer cannot reach ZAP's image, and
so no output is shown here: an invented report would teach you to read a report that does not
exist. What follows is what a report contains, so that you can read your own.

Its passive rules look for the same kind of thing lesson 19 checked by hand on `account.py`:
security headers that are missing, cookies without their flags, an error page that shows a stack
trace, a `Server` header naming the software and its version, and information left in comments
and pages. The **full scan** adds active rules that send probing requests, and is for an
authorised test of an environment that can afford to be disturbed.

## Reading the report

ZAP groups what it found into **alerts**, one per kind of problem, and each alert carries three
things that have to be read together.

| field | what it says | how to use it |
|---|---|---|
| **risk** | High, Medium, Low or Informational: how bad it would be if it is real | the first sort, never the verdict |
| **confidence** | how sure the rule is that it is real, from Low to High | a high risk with low confidence is a question to answer, not a fire |
| **instances** | every URL where it was seen | one cause behind fifty pages is one fix, not fifty findings |

Each alert also names a **CWE**, the kind of weakness in a shared catalogue, a description, a
suggested solution and references. The same habits as the dependency report apply, with one
difference: here the scanner has seen your application's real answers, so a finding is evidence
about this deployment rather than about a library.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l21-alert\" aria-label=\"A grid with a DAST alert's risk down the side, High, Medium and Low, and the rule's confidence across the top, Low, Medium and High. In the top right, high risk and high confidence: confirm it and fix it before release. Along the high-confidence column the urgency falls with the risk. Along the low-confidence column every cell says confirm by hand first. Informational alerts sit below the grid: read, not filed.\"><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">risk and confidence are read together</text><text x=\"425.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">confidence</text><text x=\"70.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">risk</text><text x=\"255.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Low</text><text x=\"425.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Medium</text><text x=\"595.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">High</text><text x=\"158.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">High</text><rect x=\"172.0\" y=\"72.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"255.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirm by hand first</text><rect x=\"342.0\" y=\"72.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"425.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirm, then fix</text><rect x=\"512.0\" y=\"72.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"595.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fix before release</text><text x=\"158.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Medium</text><rect x=\"172.0\" y=\"122.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"255.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirm by hand first</text><rect x=\"342.0\" y=\"122.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"425.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirm, then plan</text><rect x=\"512.0\" y=\"122.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"595.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">plan the fix</text><text x=\"158.0\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Low</text><rect x=\"172.0\" y=\"172.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"255.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirm by hand first</text><rect x=\"342.0\" y=\"172.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"425.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">note it</text><rect x=\"512.0\" y=\"172.0\" width=\"166.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"595.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fix when convenient</text><rect x=\"172.0\" y=\"234.0\" width=\"506.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"425.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Informational: read, not filed</text></svg>", "caption": "An alert's risk says how bad it would be; its confidence says how sure the rule is. Neither decides alone."}
```

**Count causes, not lines.** A missing header on every page shows as one alert with as many
instances as the crawl visited; fixed once in the code that sends headers, all of them go. A report
of forty alerts is often six causes.

**Confirm before you file.** Ask for the URL the instance names, yourself, and look at what came
back. A rule that flagged a page for showing an error may have matched a word in the text. Whether
it was a true positive or a false one is the vocabulary of `security-fundamentals` lesson 11. A
false positive is recorded as such, with the reason, in the scan's rule configuration, the way
`audit.sh` records an accepted risk, so that the next scan does not ask again.

**Then rate it in your own context**, as for any finding, and the rule from lesson 1 applies at
release: no high or critical left open.

What a DAST scan cannot tell you is whose booking a customer may read. It sees answers; it does not
know that a `200` for somebody else's booking is wrong, which is why lessons 16 and 17 wrote those
tests by hand.
