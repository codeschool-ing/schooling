---
title: Stages 4 and 5, threats and weaknesses
version: 1
---

The middle stages take the attacker's view. Stage 4 asks **who would want to hurt this system,
and how have systems like it been hurt before**. Stage 5 asks **where this particular system is
weak**, and joins the two.

### Stage 4: threat analysis

STRIDE produced fourteen threats from the drawing. Stage 4 adds what the drawing cannot know: the
world outside. Its inputs are **threat intelligence** (reports of what is happening to similar
organisations), the system's own logs and incidents, and the list of actors who might act.

For a chain of physiotherapy clinics in Brazil, carla's summary of stage 4 had three lines:

- **Health providers are a common target for extortion.** Criminal groups encrypt or steal patient
  data and demand payment; the more sensitive the data, the stronger their position. Every sector
  report carla read in the last two years put healthcare near the top.
- **Credential stuffing hits every consumer login.** Passwords leaked from other sites are tried
  automatically against any sign-in page that answers. The portal's own sign-in log shows bursts
  of failed logins from unfamiliar addresses most weeks.
- **Insiders exist, and are usually careless rather than malicious.** A receptionist looking up a
  neighbour's record is the classic case in health data, and it needs nothing technical at all.

None of these is a new threat on the list. What stage 4 adds is **which of the fourteen have
somebody actively trying them**: T02 (credential stuffing) and the T03, T12, T09 chain (a phished
staff account reaching records) move up. T14 (a crafted PDF) is possible, but nobody in carla's
reports was doing it to clinics.

### Stage 5: weakness and vulnerability analysis

Stage 5 maps each threat to a **weakness**: a specific shortcoming in this system that would let
the threat happen. Weaknesses are named with **CWE**, MITRE's Common Weakness Enumeration, so
that a finding in the model, a finding from a code scanner and a line in a pentest report can be
joined by the same identifier. Known vulnerabilities in the software Vereda runs, named with CVE,
join the same table when there are any.

| threat | weakness at Vereda | CWE |
|---|---|---|
| T01 | the webhook handler does not verify the gateway's signature | CWE-345, insufficient verification of data authenticity |
| T03 | staff sign in with a password alone | CWE-308, use of single-factor authentication |
| T05 | edits to clinical notes are not logged | CWE-778, insufficient logging |
| T07 | the download looks up an exam by the number in the address, without checking its owner | CWE-639, authorisation bypass through user-controlled key |
| T10 | uploads have no size limit | CWE-770, allocation of resources without limits or throttling |
| T13 | the worker connects with the owner's account | CWE-250, execution with unnecessary privileges |

**The join is the point.** When a scanner run in the `secure-pipeline` course reports CWE-639 on
the download route, this table says which threat it confirms and which business objective it puts
at risk. Without stage 5, the scanner's finding and the model's threat are two documents that
nobody connects.

A threat with no weakness found is not closed by that. It means nobody has found one yet, and
stage 5 records it as "no known weakness" with the date it was checked.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-cwe-join\" aria-label=\"Stage 5 names a weakness for each threat with a CWE id, so findings from different sources join. T01, the forged webhook, is CWE-345. T07, other patients’ PDFs, is CWE-639. T10, uploads with no limit, is CWE-770. T13, the worker as owner, is CWE-250. A scanner’s finding or a pentest report naming the same CWE lands on the same threat.\"><defs><marker id=\"l04-cwe-join-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T01</text><text x=\"76.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">forged webhook</text><rect x=\"330.0\" y=\"20.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-345</text><path d=\"M280.0 39.0 L330.0 39.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"70.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T07</text><text x=\"76.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">other patients’ PDFs</text><rect x=\"330.0\" y=\"70.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-639</text><path d=\"M280.0 89.0 L330.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"120.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T10</text><text x=\"76.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uploads with no limit</text><rect x=\"330.0\" y=\"120.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-770</text><path d=\"M280.0 139.0 L330.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"170.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T13</text><text x=\"76.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker as owner</text><rect x=\"330.0\" y=\"170.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-250</text><path d=\"M280.0 189.0 L330.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"530.0\" y=\"60.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a scanner’s finding</text><path d=\"M530.0 80.0 L450.0 39.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-cwe-join-tm-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"140.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a pentest report</text><path d=\"M530.0 160.0 L450.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-cwe-join-tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the CWE id is the join, as an opaque id is everywhere else</text></svg>", "caption": "Three sources of findings, one vocabulary. Without the id, the same weakness found three ways is three tickets."}
```
