---
title: Findings nobody can fix yet, and findings counted four times
version: 1
---

The distroless image is the best of the three candidates and its report still says 162. Somebody
reading that number for the first time wants to know which of them to fix this week. **The answer
is none of them, and the report says why if it is read by column rather than by total.** Two
columns decide it: the status of each finding, and the package it was found in.

### The status column

```
ana@vm:~/scans$ jq -r '[.Results[].Vulnerabilities[].Status] | group_by(.) | map("\(length) \(.[0])")[]' distroless.json
149 affected
1 fix_deferred
12 will_not_fix
ana@vm:~/scans$ jq -r '.Results[].Vulnerabilities[] | select(.Status != "affected") | "\(.Status)  \(.PkgName)  \(.VulnerabilityID)  \(.Severity)"' distroless.json | sort | head -n 13
fix_deferred  libexpat1  CVE-2025-66382  MEDIUM
will_not_fix  libpython3.13-minimal  CVE-2025-12781  MEDIUM
will_not_fix  libpython3.13-minimal  CVE-2025-15366  MEDIUM
will_not_fix  libpython3.13-minimal  CVE-2025-15367  MEDIUM
will_not_fix  libpython3.13-stdlib  CVE-2025-12781  MEDIUM
will_not_fix  libpython3.13-stdlib  CVE-2025-15366  MEDIUM
will_not_fix  libpython3.13-stdlib  CVE-2025-15367  MEDIUM
will_not_fix  python3.13-minimal  CVE-2025-12781  MEDIUM
will_not_fix  python3.13-minimal  CVE-2025-15366  MEDIUM
will_not_fix  python3.13-minimal  CVE-2025-15367  MEDIUM
will_not_fix  python3.13-venv  CVE-2025-12781  MEDIUM
will_not_fix  python3.13-venv  CVE-2025-15366  MEDIUM
will_not_fix  python3.13-venv  CVE-2025-15367  MEDIUM
```

A distribution does not publish a fixed package the day an advisory appears. It decides, per
release, whether and when to fix, and Trivy records that decision in the status of each finding:

| status | what the distribution has said | what a rebuild can do |
|---|---|---|
| `fixed` | a newer version of the package carries the fix | pick it up: the next build on a base image that carries it |
| `affected` | the package is vulnerable and no fix is published for this release yet | nothing until the fix is published |
| `fix_deferred` | a fix is planned and postponed, usually to the next point release | nothing until then |
| `will_not_fix` | it will not be fixed in this release, usually because the impact is small | nothing, ever, on this release |

**149 of the 162 are `affected`, and not one is `fixed`.** That is what a current, maintained base
looks like. A distribution's security team ships fixes for what is serious and exploitable in the
ordinary use of a package, and leaves much of the rest for the next release; the tracker lists both
with equal weight. The thirteen lines that are not `affected` are one deferred fix in `libexpat1`
and three advisories about Python 3.13, each reported against four packages. A gate that broke
the build on any of them could stay red until Debian 14, whatever anybody did, and lesson 7 named
what happens to a gate that cannot be satisfied: it gets switched off.

### One CVE, four packages

The same CVE appearing on four lines is not four vulnerabilities:

```
ana@vm:~/scans$ jq "[.Results[].Vulnerabilities[].VulnerabilityID] | unique | length" distroless.json
64
ana@vm:~/scans$ jq -r '.Results[].Vulnerabilities[] | select(.VulnerabilityID == "CVE-2024-26458") | "\(.PkgName) \(.InstalledVersion) \(.Status)"' distroless.json
libgssapi-krb5-2 1.21.3-5+deb13u1 affected
libk5crypto3 1.21.3-5+deb13u1 affected
libkrb5-3 1.21.3-5+deb13u1 affected
libkrb5support0 1.21.3-5+deb13u1 affected
ana@vm:~/scans$ jq -r '.Results[].Packages[] | select(.SrcName == "krb5") | "\(.Name) is built from \(.SrcName)"' distroless.json
libgssapi-krb5-2 is built from krb5
libk5crypto3 is built from krb5
libkrb5-3 is built from krb5
libkrb5support0 is built from krb5
ana@vm:~/scans$ jq -r '(.Results[0].Packages | map({(.Name): .SrcName}) | add) as $src | [.Results[0].Vulnerabilities[] | $src[.PkgName]] | group_by(.) | map("\(length) \(.[0])")[]' distroless.json | sort -rn
68 python3.13
42 glibc
24 krb5
8 gcc-14
6 util-linux
4 sqlite3
4 ncurses
2 zlib
2 libtirpc
1 expat
1 bzip2
```

**162 findings are 64 distinct CVEs.** Debian builds several binary packages from one source
package: the Kerberos library `krb5` becomes `libgssapi-krb5-2`, `libk5crypto3`, `libkrb5-3` and
`libkrb5support0`, and an advisory against the source is reported against all four. When Debian
fixes it, one upload fixes all four, and when it does not, none of them changes. The last command
groups the 162 findings by source: **eleven source packages, and two of them, Python and glibc,
hold 110 of the findings.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l08-dupes\" aria-label=\"One advisory, CVE-2024-26458, reported four times: against libgssapi-krb5-2, libk5crypto3, libkrb5-3 and libkrb5support0, four binary packages Debian builds from one source package, krb5. One fix in krb5 fixes all four. Across the distroless image, 162 findings are 64 distinct CVEs in 11 source packages.\"><defs><marker id=\"sp-l08-dupes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l08-dupes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CVE-2024-26458</text><text x=\"100.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one advisory</text><rect x=\"250\" y=\"20\" width=\"450\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"264\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source package</text><text x=\"380\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">krb5</text><rect x=\"270\" y=\"58\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"367.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libgssapi-krb5-2</text><rect x=\"485\" y=\"58\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"582.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libk5crypto3</text><rect x=\"270\" y=\"118\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"367.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libkrb5-3</text><rect x=\"485\" y=\"118\" width=\"195\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"582.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">libkrb5support0</text><path d=\"M180 108 L248 108\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-dupes-ah-amber)\"></path><text x=\"475\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">one upload of krb5 fixes all four</text><rect x=\"60\" y=\"222\" width=\"160\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">162</text><text x=\"140.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">findings (rows)</text><rect x=\"280\" y=\"222\" width=\"160\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">64</text><text x=\"360.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">distinct CVEs</text><path d=\"M222 248 L278 248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-dupes-ah-paper-dim)\"></path><rect x=\"500\" y=\"222\" width=\"160\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">11</text><text x=\"580.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source packages</text><path d=\"M442 248 L498 248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-dupes-ah-paper-dim)\"></path></svg>", "caption": "A row in the report is a pair of an advisory and a package, so one advisory against a source package counts once per package built from it."}
```

Counting rows overstates the work by a factor of about two and a half here, and it misleads in a
second way: a report that drops from 162 to 158 might have fixed one CVE, not four. When a metric
built from these reports matters (lesson 20 builds several), count distinct CVEs per source
package, not rows.

### What the gate does with all of this

The image stage this lesson adds breaks the build on a high or critical finding with a fixed
version, and only counts the rest. That rule follows from the table above and from lesson 7's
judgement: **a finding that a rebuild can fix is the author's to fix now; a finding that no rebuild
can fix is a fact about the base image, and it belongs to whoever chooses the base.**

Counting them is not ignoring them. The stage writes the total into the log of every run, so a
change in the base image that adds fifty findings shows up as a number that moved. And three kinds
of event turn a count back into work:

- **a status changes to `fixed`**: Debian published the package, the base image's maintainers
  rebuild their image with it, and linkbox's next build on the new base installs it. The last
  section of this lesson is about making sure that build happens;
- **an advisory is known to be exploited**, which is the CISA KEV question of lesson 5. A
  `will_not_fix` on a library linkbox loads, with exploitation in the wild, is a reason to change
  base image or to patch, whatever the gate says;
- **the base image stops being maintained.** `affected` on a supported release means a fix may
  come. On a release past its end of life nothing comes, and Trivy reports the operating system
  itself as no longer supported.

Read the advisory before deciding that a count is harmless, which is the reachability question of
lesson 5 asked about the operating system rather than about PyPI. Of the three Python ones above,
two are about `imaplib` and `poplib`, which nothing in linkbox imports. The third is about
`base64.b64decode()` accepting `+` and `/` when it was told to use other characters, and that one
needs more than a glance: `base64` is imported by a good part of PyPI, `itsdangerous`, one of
Flask's dependencies, among them.
