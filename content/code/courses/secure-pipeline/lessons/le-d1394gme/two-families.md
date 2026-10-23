---
title: Two families of scanner, and where each one stands
version: 1
---

"Vulnerability scanner" sounds like one kind of tool, so a common plan is to buy one and point it
at everything. A team that owns Nessus asks why it also needs Trivy; a team that runs Trivy in its
pipeline assumes the servers are covered too. **The two names belong to two families that answer
different questions, from different places.** Neither one sees what the other sees.

- **Network and host scanners** (Nessus, OpenVAS, Qualys) are pointed at addresses. They reach a
  running machine over the network, ask its open ports what they are, and, when they are given an
  account, log in and read what is installed. They answer *what is running out there, and what is
  wrong with it*, including the machine nobody remembered to list.
- **Artefact scanners** (Trivy, Grype) are pointed at a file: an image, a directory, a lockfile, a
  Kubernetes manifest. They read it before it runs. They answer *what is inside this thing we are
  about to ship*, and know nothing about where it ends up or who can reach it.

### The same service, from outside and from inside

linkbox makes the difference concrete. First the image has to be the one main's head builds. Run the pipeline on the laptop, as lesson 2 did, with the branch set so that the push stage also
moves the tag `main`:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ CI_COMMIT=$(git rev-parse --short=7 HEAD) CI_BRANCH=main ci/pipeline.sh
secrets: passed in 1s
test: passed in 2s
sast: passed in 3s
sca: passed in 11s
build: passed in 1s
image: passed in 1s
push: passed in 0s
pipeline passed with 0 warning(s)
```

Now look at linkbox the way a network scanner does, from outside: start the image, and ask the
port what it is. A scanner sends many more questions than this one, but every answer it gets has
this shape.

```
ana@vm:~/linkbox$ docker run -d --rm --name linkbox-scan -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=scan-only localhost:5000/linkbox:main
ef9adb3a945cb7d2757e44fe6d5b126ab33a1bcbc76faf802ba180b5d51b56ff
ana@vm:~/linkbox$ curl -sI "http://127.0.0.1:8000/search?q=x"
HTTP/1.1 200 OK
Server: gunicorn
Date: Fri, 23 Oct 2026 11:52:46 GMT
Connection: close
Content-Type: text/html; charset=utf-8
Content-Length: 128
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY

ana@vm:~/linkbox$ docker rm -f linkbox-scan
linkbox-scan
```

**From outside, the service says it is gunicorn and does not say which version.** The headers
lesson 4 added are there, and so is a server name, but no number. A scanner that matches versions
against advisories has nothing to match here. It can report "gunicorn, version unknown", or guess
from other behaviour, which is where false positives come from. Gunicorn 21.2.0, which has two
published advisories you will meet in the last section, would answer exactly the same.

Now the same image from inside, the way an artefact scanner reads it:

```
ana@vm:~/linkbox$ trivy image -q --table-mode summary localhost:5000/linkbox:main

Report Summary

┌────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                     Target                     │    Type    │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ localhost:5000/linkbox:main (debian 13.7)      │   debian   │       162       │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/blinker-1.9.0.dist-info/METADATA      │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/click-8.1.7.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/flask-3.1.3.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/gunicorn-22.0.0.dist-info/METADATA    │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/itsdangerous-2.2.0.dist-info/METADATA │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/jinja2-3.1.6.dist-info/METADATA       │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/markupsafe-2.1.3.dist-info/METADATA   │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/packaging-26.3.dist-info/METADATA     │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/werkzeug-3.1.9.dist-info/METADATA     │ python-pkg │        0        │    -    │
└────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

**From inside, every version is a fact read from a file**: `gunicorn-22.0.0.dist-info/METADATA`
is the package's own record of itself, and the 162 come from Debian's package database in the
base image. Lesson 8 already counted them. Nothing here was guessed, and nothing here says whether
port 8000 is reachable from the internet.

### Where each family sits in the routine

The difference in vantage point becomes a difference in schedule. An artefact scanner runs where
the artefact is made, so it belongs in the pipeline, on every push, before anything ships. A
network scanner runs against an environment that already exists, so it runs on a calendar: weekly
or monthly across the estate, and after a change to it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l11-life\" aria-label=\"The life of linkbox from source to a running host, and where each family of scanner reads it. Artefact scanners read the repository and the image before anything runs: trivy fs and trivy config on the repository, trivy image on the image. Network and host scanners reach the deployed host while it runs: from outside, logged in, or through an agent.\"><defs><marker id=\"sp-l11-life-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l11-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l11-life-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">repository</text><rect x=\"160\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build</text><path d=\"M140 115 L158 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"300\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">image</text><path d=\"M280 115 L298 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"440\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">registry</text><path d=\"M420 115 L438 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"580\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">running host</text><path d=\"M560 115 L578 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"15\" y=\"20\" width=\"550\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"25\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">artefact scanners: read files, before it runs</text><text x=\"25\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the pipeline, every push</text><text x=\"80\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">trivy fs · config</text><path d=\"M80 152 L80 142\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-phosphor)\"></path><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">trivy image</text><path d=\"M360 152 L360 142\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-phosphor)\"></path><rect x=\"330\" y=\"185\" width=\"375\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">network and host scanners: reach addresses, while it runs</text><text x=\"340\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Nessus, OpenVAS, Qualys · a calendar, across the estate</text><path d=\"M640 185 L640 142\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-amber)\"></path></svg>", "caption": "The two families meet the same software at different points of its life, and on different schedules."}
```

| | network and host scanners | artefact scanners |
|---|---|---|
| pointed at | addresses: a range, a list of hosts | files: an image, a directory, a manifest |
| when | on a schedule, against what is running | in the pipeline, before it ships |
| sees | open ports, banners, TLS, and with an account the installed packages | the exact packages and versions inside the file |
| cannot see | what is not running, or a version nobody advertises | where the file is deployed, or what reaches it |
| finds best | the forgotten server, the open port nobody meant to open | the vulnerable library in tomorrow's release |

**A pipeline that scans every image says nothing about the virtual machine somebody set up by
hand three years ago.** That machine never went through a pipeline, and only a scan of the
network finds it. The reverse is just as true: a monthly network scan finds the vulnerable library
a month after it shipped, if the version shows from outside at all. Most organisations need both
families, owned by different people. This course is about the pipeline, so it uses the second
family for real and teaches the first from its documentation, in the next two sections.
