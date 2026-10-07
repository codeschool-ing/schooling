---
title: The map
version: 1
---

Security is not one job. It is a family of jobs that share the vocabulary of this course and differ
in what they do all day. Five families cover most of the field, and each grows out of particular lessons:

```schooling-figure
{"svg": "<svg id=\"sf-career-map\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The five families of security work, around this course as their shared foundation. SOC and incident response, taught by soc-response. Offensive security, taught by pentest. Governance, risk and compliance, taught by threat-modeling. Forensics, in soc-response. Application security, taught by secure-code and threat-modeling.\"><defs><marker id=\"sf-career-map-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"260\" y=\"120\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">this course</text><text x=\"360\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">security-fundamentals</text><rect x=\"20\" y=\"20\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SOC and response</text><text x=\"120\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">soc-response</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">offensive security</text><text x=\"600\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pentest</text><rect x=\"20\" y=\"222\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">GRC</text><text x=\"120\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">threat-modeling</text><rect x=\"500\" y=\"222\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">AppSec</text><text x=\"600\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">secure-code</text><rect x=\"260\" y=\"222\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">forensics</text><text x=\"360\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">soc-response</text><path d=\"M260 130 L220 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M460 130 L500 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M260 168 L220 222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M460 168 L500 222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M360 176 L360 222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path></svg>", "caption": "One foundation, five directions. The course names under each family are where the catalogue teaches it."}
```

| family | what it does | grew from lessons | the course that teaches it |
|---|---|---|---|
| **SOC and incident response** | watches for attacks, triages alerts, responds | 10, 11, 12 | `soc-response` |
| **offensive security** (pentest, red team) | attacks systems, with permission, to show what an attacker could do | 4, 8, 10 | `pentest` |
| **GRC** (governance, risk and compliance) | manages risk, policy and evidence; works with auditors | 3, 13, 14, 15, 16, 17 | `threat-modeling` |
| **forensics** | reconstructs what happened after an incident, from evidence | 10, 12 | `soc-response` lessons 16 to 18 |
| **AppSec** (application security) | makes software secure before and while it ships | 6, 8 | `secure-code`, `threat-modeling` |

The boundaries are soft. A SOC analyst who does a forensic investigation, a pentester who moves into
AppSec, a GRC specialist who used to run firewalls: people move between them, and the shared foundation is
what makes that possible. The foundation is this course.

::: track security
On the security track you are at the start of this map, and the track's courses follow it. `networks`,
`cryptography` and `attacks-threats` lay the ground every family stands on; `secure-code`,
`networks-security` and `defense-hardening` are the defender's craft; `soc-response`, `cloud-security` and
`pentest` take you into the first two families. The outcome the track names is information security
analyst, a role that begins in the SOC and can grow in any of the five directions.
:::

::: track devsecops
On the DevSecOps track, security is part of building and shipping software, which points at the last row
of the map. After `networks`, `cryptography` and `attacks-threats` come `secure-code` and
`threat-modeling`, then containers, `testing-cicd` and `secure-pipeline`, where the checks of lesson 16 run
automatically on every change. `cloud-security` and `soc-response` close the track, because whoever ships
the system also has to watch it.
:::

::: track qa
On the QA track, this course sits beside testing, and `testing-cicd` comes next. A tester who understands
lesson 8 is the person who tries `/payslips/bruno` while logged in as ana, before a customer does. Security
testing is a natural specialisation for QA, and it leads to the offensive and AppSec families: a
penetration test is, among other things, a very thorough test plan.
:::

::: track dba
On the database administration track, the data you will administer is the asset most of this course
protects, and `cryptography` comes next. Least privilege on database accounts (lesson 6), backups and
restore tests (lesson 12) and the LGPD (lesson 17) are part of a DBA's ordinary work, and a DBA who knows
them is the person the GRC and incident response teams call first.
:::

::: track *
In this catalogue, the `security` track follows this map from its first course, and the `devsecops` track
follows its AppSec row. Either is a way in; so is arriving from development, infrastructure or support,
which is how many people in the field arrived. The vocabulary of this course is what all of those routes
share.
:::

The next sections take the families one at a time: what the work is, what a day looks like, and what the
first job usually is.
