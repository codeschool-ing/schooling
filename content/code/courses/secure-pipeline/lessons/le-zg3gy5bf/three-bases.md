---
title: Three base images, side by side
version: 1
---

linkbox's image has been built on `python:3.13` since lesson 1, because that is the image every
tutorial starts from. **The base image is most of what a scanner finds in yours**, so before
changing anything, count what each candidate brings with it. The filter from the last section
prints one line per part of each report:

```
ana@vm:~$ cd ~/scans
ana@vm:~/scans$ for f in full slim distroless; do echo "== $f"; jq -r -f count.jq $f.json; done
== full
debian: 3484 found (CRITICAL 24, HIGH 433, LOW 1659, MEDIUM 1288, UNKNOWN 80), 0 with a fix
python-pkg: 6 found (HIGH 4, MEDIUM 2), 6 with a fix
== slim
debian: 164 found (HIGH 44, LOW 61, MEDIUM 58, UNKNOWN 1), 0 with a fix
python-pkg: 6 found (HIGH 4, MEDIUM 2), 6 with a fix
== distroless
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
ana@vm:~/scans$ docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}" | grep -E "^(python|gcr.io)"
python:3.13-slim  177MB
python:3.13  1.61GB
gcr.io/distroless/python3-debian13:nonroot  90.5MB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"sp-l08-bases\" aria-label=\"Findings by base image, from this lesson's scans. python:3.13: 3484 Debian findings, none with a fix, 6 fixable findings in pip, 1.61 GB. python:3.13-slim: 164 Debian findings, none with a fix, the same 6 fixable in pip, 177 MB. The distroless Python image: 162 Debian findings, none with a fix, no pip and nothing fixable, 90.5 MB.\"><defs></defs><text x=\"160\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Debian findings (none with a fix)</text><text x=\"585\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fixable, in pip</text><text x=\"672\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">size</text><text x=\"150\" y=\"63\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">python:3.13</text><rect x=\"160\" y=\"48\" width=\"330\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3484</text><rect x=\"555\" y=\"48\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"672\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.61 GB</text><text x=\"150\" y=\"109\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">python:3.13-slim</text><rect x=\"160\" y=\"94\" width=\"16\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"184\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">164</text><rect x=\"555\" y=\"94\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"672\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">177 MB</text><text x=\"150\" y=\"155\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distroless/python3</text><rect x=\"160\" y=\"140\" width=\"15\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"183\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">162</text><rect x=\"555\" y=\"140\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"672\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">90.5 MB</text><line x1=\"160\" y1=\"40\" x2=\"160\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line></svg>", "caption": "The count falls twentyfold from full to slim and hardly at all from slim to distroless. What distroless removes shows in the second column."}
```

Three things in those lines deserve a second look, and the largest number is the least
interesting of them.

### The drop is from full to slim

**`python:3.13` brings 3484 findings and `python:3.13-slim` brings 164.** The full image is a
general-purpose Debian system with compilers, image libraries, database clients and a few hundred
packages a web service never calls; slim is Debian's minimal set plus Python. Twenty times fewer
findings, and a ninth of the size.

From slim to distroless, by contrast, the count barely moves: 164 to 162. Google's distroless image
is built from the same Debian release and keeps the same core libraries, glibc, OpenSSL, zlib and
Python itself, and those carry most of what is left. What distroless removes is a different kind of
thing: the shell, `apt`, `dpkg`'s own tools, pip. Those matter less to a scanner than to whoever
gets code running inside the container, and lesson 9 is about that. **Reading a count alone, the
two minimal images look the same, and they are not.**

### The column that matters is "with a fix"

Every Debian finding in all three images has **0 with a fix**: a newer version of the package does
not exist yet for this Debian release, and no rebuild can install one. The section after this one
explains why that is normal. The six findings of the `python-pkg` part are the opposite case.
**Every one of the six has a fixed version.** They are not linkbox's dependencies:

```
ana@vm:~/scans$ jq -r '.Results[] | select(.Type == "python-pkg") | .Vulnerabilities[] | "\(.PkgName) \(.InstalledVersion) \(.Severity) fixed in \(.FixedVersion)"' slim.json
msgpack 1.1.2 HIGH fixed in 1.2.1
setuptools 70.3.0 HIGH fixed in 78.1.1
setuptools 70.3.0 MEDIUM fixed in 83.0.0
urllib3 2.7.0 HIGH fixed in 2.8.0
urllib3 2.7.0 HIGH fixed in 2.8.0
urllib3 2.7.0 MEDIUM fixed in 2.8.0
ana@vm:~/scans$ jq -r '.Results[] | select(.Type == "python-pkg") | .Packages[] | "\(.Name) \(.Version)  \(.FilePath)"' slim.json
CacheControl 0.14.4  null
certifi 2026.10.19  null
distlib 0.4.2  null
distro 1.9.0  null
idna 3.18  null
msgpack 1.1.2  null
packaging 26.2  null
pip 26.2.2  usr/local/lib/python3.13/site-packages/pip-26.2.2.dist-info/METADATA
platformdirs 4.10.0  null
pygments 2.20.0  null
pyproject-hooks 1.2.0  null
requests 2.34.2  null
resolvelib 1.2.1  null
rich 14.2.0  null
setuptools 70.3.0  null
tomli 2.4.1  null
tomli-w 1.2.0  null
truststore 0.10.4  null
urllib3 2.7.0  null
```

They are pip and what pip carries. `msgpack` and `urllib3` are inside `pip/_vendor`, listed in the
`bom.cdx.json` of the last section, and the setuptools 70.3.0 entry is pip's vendored copy of
setuptools' `pkg_resources`; their `FilePath` is `null` because Trivy learnt about them from pip's
list rather than from a file of their own. Only pip itself has a `METADATA` file.

So the base images that include pip ship four high-severity vulnerabilities that a newer pip has
fixed, in a program linkbox never runs once the image is built. pip is needed to install the
dependencies and then it is dead weight. That is the case for the next section but one: **a build
whose final image carries the result of `pip install` and not pip.**

### What the gate would say

Lesson 7 settled the rule for the pipeline: break the build for what somebody can fix, warn about
the rest. For an image that means `--ignore-unfixed`, which keeps only findings whose status is
`fixed`, together with `--severity HIGH,CRITICAL`. `--exit-code 1` turns "found something" into a
failing exit status. Run on the three bases with the report thrown away, so only the verdict is
left:

```
ana@vm:~/scans$ for i in python:3.13 python:3.13-slim gcr.io/distroless/python3-debian13:nonroot; do trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --format json -o /dev/null $i; echo "$i: exit $?"; done
python:3.13: exit 1
python:3.13-slim: exit 1
gcr.io/distroless/python3-debian13:nonroot: exit 0
```

**Both images with pip in them fail; the distroless image passes.** The Debian findings did not
decide it: the 433 high findings of the full image are all without a fix, and the gate ignores
them by design. Four fixable findings in pip's vendored libraries decided it, in both cases.

That verdict is the right one. A team that wanted to stay on `python:3.13-slim` would have two
honest options: upgrade pip in the image, and accept that the next pip release will vendor the
next urllib3 and the next advisory with it, or remove pip from what ships. The second is the one
that stays fixed.

### Size is a security number too

The sizes in the listing are 1.61 GB, 177 MB and 90.5 MB. A smaller image downloads faster and
starts faster on a new node, which is an operational benefit. **The security benefit is in what the
size stands for**: every package in an image is a package somebody has to keep up to date, a
program that can be run by whoever gets a foothold, and a line in every future scan. The 469
packages of the full image are 469 things to answer for; the 38 of distroless are 38.
