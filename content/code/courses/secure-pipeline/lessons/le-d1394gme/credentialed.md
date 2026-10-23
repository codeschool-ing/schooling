---
title: Unauthenticated, credentialed and agent scans
version: 1
---

A network scanner can look at a host in three ways, and the choice between them changes what it
finds more than the choice of product does. **None of the three was run for this course.** Nessus
and Qualys need a licence or a registered account, OpenVAS needs a machine of its own, and all
three are meant for hosts on a network, which a student's laptop running linkbox is not. What
follows comes from the vendors' documentation, and there is no transcript or screenshot of any of
them in this lesson.

### Unauthenticated: a stranger at the door

An unauthenticated scan, also called a remote or uncredentialed scan, connects to the host the
way any client would. It learns which ports answer, what each service says about itself, which
protocol versions and TLS ciphers it accepts, and what the default pages look like. From those
answers it infers software and versions, and from the versions, advisories.

That inference is the weak point, in both directions:

- **False negatives**, where the version is not advertised. The last section showed one: linkbox
  answers `Server: gunicorn` with no number, so there is nothing to match.
- **False positives**, where the version is advertised but is not the whole truth. Debian, Ubuntu
  and Red Hat fix a vulnerability by **backporting** the patch into the version they already ship,
  without changing the upstream version number. A banner that still reads like the old version
  matches an advisory the package no longer has.

An unauthenticated scan is still worth running. It sees exactly what an outsider sees, which is
the right question for anything facing the internet, and it is the only scan that finds a service
nobody knew was listening.

### Credentialed: a scanner with an account

A credentialed scan, which some documentation calls authenticated, gives the scanner an account
on the host: an SSH key for Linux, a Windows account for the services Windows exposes to
administrators. The scanner logs in and reads what the host itself knows. That is the package
database, the patch level, configuration files, the kernel version. **It is the same kind of
reading Trivy does on an image, done on a live machine.**

It finds more, because it sees packages that no listening port reveals, such as a vulnerable
library used by a scheduled job. And it is wrong less often, because it reads the distribution's
exact package version, backport included, instead of a banner. Tenable, Greenbone and Qualys all
document credentialed scanning as the more accurate kind, for that reason.

The cost is an account on every host, held by a tool that reaches every host. **The scanner's
credential is one of the most valuable secrets in the organisation**, and it is treated like one. It gets a dedicated account rather than somebody's own, the least privilege each vendor documents for its
checks, kept in the scanner's own credential store or a vault, and rotated. Lesson 17 returns to
how a machine holds a secret.

### Agents: the scanner moves in

An agent is a small program installed on each host (Tenable sells Nessus Agents, Qualys the Qualys
Cloud Agent) that collects the same local information a credentialed scan reads and sends it to
the vendor's platform. Nothing has to reach the host from outside, so an agent works on a laptop
that is never on the office network when the scan runs, and on a cloud instance that lives for an
hour. The price is software running on every machine, which has to be deployed, updated and
trusted like any other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l11-vantage\" aria-label=\"Three ways a network scanner looks at a host. Unauthenticated, from outside, it can only ask the open ports what they are. Credentialed, it logs in over SSH and reads the host's package database and configuration. An agent runs inside the host, reads the same records and sends them out to the vendor's platform.\"><defs><marker id=\"sp-l11-vantage-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l11-vantage-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l11-vantage-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"300\" y=\"20\" width=\"400\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a host</text><rect x=\"255\" y=\"60\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">open ports</text><rect x=\"380\" y=\"60\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">services</text><rect x=\"380\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">package database</text><rect x=\"540\" y=\"130\" width=\"145\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"612.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">configuration files</text><rect x=\"540\" y=\"210\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"612.5\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">agent</text><text x=\"612.5\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">installed on the host</text><rect x=\"20\" y=\"60\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">unauthenticated</text><text x=\"105.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">asks the ports</text><path d=\"M190 80 L253 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-vantage-ah-paper-dim)\"></path><rect x=\"20\" y=\"140\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">credentialed</text><text x=\"105.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">logs in, reads records</text><path d=\"M190 160 L378 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-vantage-ah-phosphor)\"></path><text x=\"240\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">ssh</text><rect x=\"20\" y=\"220\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vendor's platform</text><path d=\"M538 240 L192 240\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l11-vantage-ah-amber)\"></path><text x=\"400\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">reports out</text><path d=\"M612 208 L612 172\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-vantage-ah-amber)\"></path></svg>", "caption": "Only the unauthenticated scan stays outside. The other two read what the host itself records, which is why they know exact versions."}
```

| | unauthenticated | credentialed | agent |
|---|---|---|---|
| what it needs | network reach | network reach and an account | software on the host |
| reads | what services answer | the host's own records | the host's own records |
| version accuracy | inferred from banners | exact, backports included | exact, backports included |
| finds an unlisted host | yes | yes, and logs in where it can | no, only hosts with an agent |
| main risk | false positives and blind spots | the scanner's credential | one more program everywhere |

### And the containers?

A credentialed scan of a Kubernetes node reads the node's packages: its kernel, its container
runtime, its operating system. The packages inside each image are a separate question, because
they live in image layers rather than in the node's package database. The commercial platforms
sell container and registry scanning as products of their own. This course answers that question
with an artefact scanner instead, in the pipeline, before the image exists anywhere else.
