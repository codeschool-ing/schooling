---
title: Asking the SBOM questions with jq
version: 1
---

An SBOM is JSON, so the tool for asking it questions is the one already on your machine: `jq`. The
queries below run against the CycloneDX file, because its shape is the simpler of the two; each one
has an SPDX twin that walks `packages` instead of `components`.

### How many things are in it?

```
ana@vm:~/linkbox$ jq ".components | length" ~/sbom/linkbox.cdx.json
2190
ana@vm:~/linkbox$ jq "[.components[].type] | group_by(.) | map({(.[0]): length}) | add" ~/sbom/linkbox.cdx.json
{
  "file": 2142,
  "library": 47,
  "operating-system": 1
}
ana@vm:~/linkbox$ jq ".packages | length" ~/sbom/linkbox.spdx.json
48
```

**2190 components, and only 47 of them are packages.** The 2142 of type `file` are the files syft
found in the image that it could tie to no package, plus the files it records as evidence. The one
`operating-system` is Debian 13.7. SPDX counts the 48 packages, the operating system included, and
keeps the files elsewhere. So "how many components does linkbox have" has three honest answers
depending on what is counted, and a report that quotes one should say which.

### Which Python packages, in which versions?

The purl tells components of different ecosystems apart without guessing: everything from PyPI starts
with `pkg:pypi/`.

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.purl // \"\" | startswith(\"pkg:pypi/\")) | \"\(.name) \(.version)\"" ~/sbom/linkbox.cdx.json
blinker 1.9.0
click 8.1.7
flask 3.1.3
gunicorn 22.0.0
itsdangerous 2.2.0
jinja2 3.1.6
markupsafe 2.1.3
packaging 26.3
werkzeug 3.1.9
```

### Under which licences?

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.purl // \"\" | startswith(\"pkg:pypi/\")) | \"\(.name): \([.licenses[]? | .license.id // .license.name // .expression] | join(\", \"))\"" ~/sbom/linkbox.cdx.json
blinker: MIT
click: BSD-3-Clause
flask: BSD-3-Clause
gunicorn: MIT
itsdangerous: BSD-3-Clause
jinja2: 
markupsafe: BSD-3-Clause
packaging: Apache-2.0 OR BSD-2-Clause
werkzeug: BSD-3-Clause
ana@vm:~/linkbox$ jq "[.components[] | .licenses[]? | .license.id // .license.name // .expression] | unique | length" ~/sbom/linkbox.cdx.json
84
```

The Python side is short and permissive: BSD, MIT, and Apache-2.0 or BSD for packaging. One line is blank: syft recorded no licence for jinja2, and **a blank in an SBOM is not a licence**, it is a question somebody has to answer by reading the package. The whole image, with the Debian packages, carries 84 distinct licence names, among them the GPL family that comes with any Debian system, and
some entries that are a file hash rather than a name, where syft found licence text it could not
identify. A licence review starts from that list, not from `requirements.txt`, which knows nothing
about the base image. Whether shipping a GPL-licensed system library inside a container creates an
obligation is a legal question for the people who answer those; the SBOM's job is to make sure they
are asked about all of them.

### The package nobody pinned

`requirements.txt` has eight lines, and the image has nine Python packages. The one too many:

```
ana@vm:~/linkbox$ grep -c packaging requirements.txt
0
ana@vm:~/linkbox$ jq -r ".components[] | select(.name == \"packaging\") | .properties[] | select(.name | endswith(\":path\")) | .value" ~/sbom/linkbox.cdx.json
/packages/packaging-26.3.dist-info/METADATA
/packages/packaging-26.3.dist-info/RECORD
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 localhost:5000/linkbox:main -c "from importlib.metadata import requires; print(requires(\"gunicorn\")[0])"
packaging
```

`grep -c` counts zero lines naming it in `requirements.txt`. The SBOM says where it is: a
`dist-info` directory under `/packages`, installed by the same `pip install --target` that installed
the rest. And the image itself says why, when you ask its own Python which packages gunicorn
declares it requires: the first is `packaging`.

**gunicorn 22 depends on packaging, so pip installed it**, at whatever version was newest on the day
of the build, because nothing pinned it. That is the transitive dependency lesson 5 named, made
concrete: a package in production that no file in the repository mentions, at a version nobody chose.
It is harmless today, and it is exactly the kind of package that turns up in an advisory nobody on
the team recognises. Lesson 15 compiles the requirements into a lock that pins it, and moves gunicorn
to 26, which no longer needs it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" data-fig=\"sp-l13-packaging\" aria-label=\"What requirements.txt asks for against what the image contains. requirements.txt pins eight packages: flask, werkzeug, jinja2, markupsafe, itsdangerous, click, blinker and gunicorn. The image has those eight and a ninth, packaging 26.3, which gunicorn 22.0.0 requires and which pip installed at the newest version on the day of the build.\"><defs><marker id=\"sp-l13-packaging-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l13-packaging-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">requirements.txt: 8 pins</text><text x=\"470\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the image: 9 Python packages</text><rect x=\"20\" y=\"32\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flask 3.1.3</text><rect x=\"380\" y=\"32\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flask 3.1.3</text><path d=\"M200 43 L378 43\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"60\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">werkzeug 3.1.9</text><rect x=\"380\" y=\"60\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">werkzeug 3.1.9</text><path d=\"M200 71 L378 71\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"88\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jinja2 3.1.6</text><rect x=\"380\" y=\"88\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jinja2 3.1.6</text><path d=\"M200 99 L378 99\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"116\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">markupsafe 2.1.3</text><rect x=\"380\" y=\"116\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">markupsafe 2.1.3</text><path d=\"M200 127 L378 127\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"144\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">itsdangerous 2.2.0</text><rect x=\"380\" y=\"144\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">itsdangerous 2.2.0</text><path d=\"M200 155 L378 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"172\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">click 8.1.7</text><rect x=\"380\" y=\"172\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">click 8.1.7</text><path d=\"M200 183 L378 183\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"200\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">blinker 1.9.0</text><rect x=\"380\" y=\"200\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">blinker 1.9.0</text><path d=\"M200 211 L378 211\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"228\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gunicorn 22.0.0</text><rect x=\"380\" y=\"228\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gunicorn 22.0.0</text><path d=\"M200 239 L378 239\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"380\" y=\"268\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"281.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">packaging 26.3</text><path d=\"M560 239 L600 239 L600 281 L562 281\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-amber)\"></path><text x=\"610\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">gunicorn requires it</text><text x=\"290\" y=\"281\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pinned by nobody</text></svg>", "caption": "Eight lines in the repository, nine packages in the image. The ninth came in through gunicorn, at whatever version was newest that day."}
```

### Are we affected?

The question of the first section, asked of this file. Say an advisory is published for glibc, the
GNU C library. Debian ships it as several binary packages under other names, and the purl's
`upstream` qualifier records which source each came from:

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.name == \"glibc\" or (.purl // \"\" | contains(\"upstream=glibc\"))) | \"\(.name) \(.version)\"" ~/sbom/linkbox.cdx.json
libc-bin 2.41-12+deb13u4
libc6 2.41-12+deb13u4
```

Two packages, one version, an answer in a second, and it would be the same second for a hundred
images, one file each. **That is the morning-of-the-advisory query**, and it only works because
somebody wrote the file before the morning came.
