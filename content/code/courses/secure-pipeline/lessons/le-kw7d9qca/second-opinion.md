---
title: A second opinion from Trivy, and why two tools disagree
version: 1
---

Two composition analysers pointed at the same project rarely print the same thing, and the first
reaction is to decide which one is wrong. **Usually neither is: they collected different lists of
packages, or looked them up in different databases, or counted differently.** Knowing which of the
three explains a difference is what makes a second tool useful rather than confusing.

Trivy is the second tool here. It is a general scanner that lesson 8 points at images and lesson 11
compares with others; `trivy fs` scans a directory. The previous section already ran it on lesson
1's `requirements.txt` and kept the JSON. Its findings, one line each:

```
ana@vm:~/linkbox$ jq -r ".Results[].Vulnerabilities[] | [.PkgName, .InstalledVersion, .VulnerabilityID, .Severity, .FixedVersion] | @tsv" /tmp/trivy.json
flask	3.0.0	CVE-2026-27205	LOW	3.1.3
gunicorn	21.2.0	CVE-2024-1135	HIGH	22.0.0
gunicorn	21.2.0	CVE-2024-6827	HIGH	22.0.0
jinja2	3.1.2	CVE-2024-22195	MEDIUM	3.1.3
jinja2	3.1.2	CVE-2024-34064	MEDIUM	3.1.4
jinja2	3.1.2	CVE-2024-56201	MEDIUM	3.1.5
jinja2	3.1.2	CVE-2024-56326	MEDIUM	3.1.5
jinja2	3.1.2	CVE-2025-27516	MEDIUM	3.1.6
werkzeug	3.0.1	CVE-2024-34069	HIGH	3.0.3
werkzeug	3.0.1	CVE-2024-49766	MEDIUM	3.0.6
werkzeug	3.0.1	CVE-2024-49767	MEDIUM	3.0.6
werkzeug	3.0.1	CVE-2025-66221	MEDIUM	3.1.4
werkzeug	3.0.1	CVE-2026-102598	MEDIUM	3.1.9
werkzeug	3.0.1	CVE-2026-21860	MEDIUM	3.1.5
werkzeug	3.0.1	CVE-2026-27199	MEDIUM	3.1.6
ana@vm:~/linkbox$ trivy fs -q --scanners vuln requirements-dev.txt

Report Summary

┌────────┬──────┬─────────────────┐
│ Target │ Type │ Vulnerabilities │
├────────┼──────┼─────────────────┤
│   -    │  -   │        -        │
└────────┴──────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

**Fifteen findings, the same fifteen CVEs pip-audit's twenty-nine rows came down to**, each with a
severity pip-audit does not print. On the question both tools were asked, they agree. The second
command is where they stop agreeing: Trivy did not scan `requirements-dev.txt` at all. Its summary
says `-`, not scanned, which is different from `0`, clean.

### Where the lists come from

The two tools disagree about pytest because they collect packages differently, and a file with one
line in it shows the difference most plainly:

```
ana@vm:~/linkbox$ mkdir -p /tmp/one && echo "flask==3.0.0" > /tmp/one/requirements.txt
ana@vm:~/linkbox$ pip-audit -r /tmp/one/requirements.txt -f json 2>/dev/null | jq -r ".dependencies[] | \"\(.name) \(.version)\""
flask 3.0.0
blinker 1.9.0
click 8.5.0
itsdangerous 2.2.0
jinja2 3.1.6
markupsafe 3.0.4
werkzeug 3.1.9
ana@vm:~/linkbox$ trivy fs -q --scanners vuln --list-all-pkgs -f json /tmp/one | jq -r ".Results[].Packages[] | \"\(.Name) \(.Version)\""
flask 3.0.0
```

pip-audit **resolved** the file: it asked pip what installing `flask==3.0.0` would install today,
and audited all seven packages, each transitive one at the newest version Flask 3.0.0 accepts.
Trivy **read** the file: one line, one package. Neither is wrong, and they answer two questions.

- **Trivy audits what the file says.** It is fast, needs no network to resolve anything, and
  reports only what is written down. It recognises files by name, which is why `requirements.txt`
  is read and `requirements-dev.txt` is not, and it cannot see a transitive package the file does
  not pin.
- **pip-audit audits what would be installed.** It sees every transitive package, but at the
  version the index offers today, so the same file can audit clean on Monday and dirty on
  Thursday, or the other way round, with no commit in between.

linkbox's requirements pin the transitive packages by hand, which is why the two agreed on the
service. A project that pins only its direct dependencies would get two very different answers,
and the cure is lesson 15's compiled lock file, where every package is written down with its
version and both tools read the same list.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l05-tools\" aria-label=\"Where each tool gets its list of packages and its advisories. pip-audit is given both requirements files with -r, resolves them with pip into what would be installed today, including transitive packages, and looks each one up on PyPI, which serves OSV's advisories. Trivy finds files by name, reads requirements.txt line by line, does not scan requirements-dev.txt, and looks the packages up in its own downloaded database.\"><defs><marker id=\"sp-l05-tools-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">pip-audit</text><rect x=\"20\" y=\"36\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">requirements*.txt</text><text x=\"95.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both files, given with -r</text><rect x=\"200\" y=\"36\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">resolved by pip</text><text x=\"285.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what would be installed today</text><rect x=\"400\" y=\"36\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">every package</text><text x=\"470.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">transitive ones included</text><rect x=\"570\" y=\"36\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PyPI</text><text x=\"635.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">serves OSV</text><path d=\"M170 64 L198 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M370 64 L398 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M540 64 L568 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">trivy fs</text><rect x=\"20\" y=\"142\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">requirements.txt</text><text x=\"95.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">found by name</text><rect x=\"200\" y=\"142\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">read line by line</text><text x=\"285.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the file says</text><rect x=\"400\" y=\"142\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the pinned lines</text><text x=\"470.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing else</text><rect x=\"570\" y=\"142\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">own database</text><text x=\"635.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">downloaded</text><path d=\"M170 170 L198 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M370 170 L398 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M540 170 L568 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><rect x=\"20\" y=\"210\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"150.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">requirements-dev.txt: not scanned</text></svg>", "caption": "The two tools agreed on linkbox's service because its file pins every transitive package; on a file that pins only the direct ones they would not."}
```

### Where the advisories come from

pip-audit looked each package up on PyPI, which serves advisories from OSV. Trivy looks them up in
**its own database**, built from GitHub's advisories, the NVD, Linux distributions' feeds and
others, and downloaded to the machine. On this machine the database was downloaded once on the day
of the recording, so every Trivy number in the course comes from the same one. On yours it is at
most a day old, and the counts you see will not be these.

The two sources usually agree on whether a version is affected, as they did here, and often
disagree on everything around it: the severity, the fixed version when a fix arrived in two
branches, the day a new advisory appears. A flaw published this morning can be in one database by
lunch and the other by tomorrow.

### Two counts for one finding

| | pip-audit | Trivy |
|---|---|---|
| what it collects | the packages pip would install, resolved now | the lines of files it recognises by name |
| transitive packages not in the file | audited, at today's versions | not seen |
| `requirements-dev.txt` | audited, because it was named with `-r` | not scanned |
| advisories from | PyPI, which serves OSV | its own database, downloaded |
| one flaw published twice | two rows | one row |
| severity | not printed | printed, from a chosen source |

### What to do with two tools

Running both on every push buys little: two gates, two sets of exceptions and twice the noise for
mostly the same answer. **This pipeline gates on one**, pip-audit, because it audits what will
actually be installed and it reads both files. Trivy earns its place where it sees what pip-audit
cannot: the operating system's packages inside an image, which lesson 8 scans. A second tool is
worth running now and then on the same input, as this section did, because the differences are
where a blind spot shows: here, a file one tool never opened.
