---
title: The Risk Management Framework
version: 1
---

The second NIST document is different in kind. The **Risk Management Framework (RMF)**, described in
**NIST SP 800-37** (revision 2, from December 2018), is a step-by-step process for managing the
security and privacy risk of **one information system** through its whole life. It is mandatory for US
federal agencies and their contractors, and widely borrowed elsewhere for its structure.

It has **seven steps**:

```schooling-figure
{"svg": "<svg id=\"sf-rmf-steps\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The seven steps of the NIST Risk Management Framework. Prepare comes first. Then a cycle: categorize, select, implement, assess, authorize and monitor, with monitor leading back to categorize when the system or its risks change.\"><defs><marker id=\"sf-rmf-steps-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">prepare</text><rect x=\"160\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">categorize</text><rect x=\"330\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">select</text><rect x=\"500\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">implement</text><rect x=\"500\" y=\"150\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">assess</text><rect x=\"330\" y=\"150\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">authorize</text><rect x=\"160\" y=\"150\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">monitor</text><path d=\"M120 110 L225 70\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M290 50 L330 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M460 50 L500 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M565 70 L565 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M500 170 L460 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M330 170 L290 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M225 150 L225 70\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><text x=\"235\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">when things change</text></svg>", "caption": "Prepare once; then the cycle runs for the whole life of the system."}
```

| step | what happens | the shop's portal, as if it were run this way |
|---|---|---|
| **Prepare** | set up the context: roles, risk strategy, common controls | the owners' appetite; who is authorising official |
| **Categorize** | rate the system by the impact of losing confidentiality, integrity and availability | payslips: high confidentiality impact, moderate integrity, low availability |
| **Select** | choose the controls the categorisation calls for, and tailor them | login with MFA, permission checks, logging, segmentation |
| **Implement** | put the controls in place and document how | lessons 5 to 9, written down |
| **Assess** | test that the controls work as intended | the lab tests of lessons 4, 7 and 8; a purple exercise |
| **Authorize** | a senior official accepts the remaining risk and allows the system to run | bruno, as owner of the risk, signs |
| **Monitor** | keep watching the controls and the risk, and reassess when things change | the log and alerts; review when the portal changes |

Two steps are worth dwelling on.

**Categorize** is lesson 1's triad, made formal. The RMF uses a standard called FIPS 199 to rate each
of confidentiality, integrity and availability as low, moderate or high impact, and the highest of the
three sets how demanding the controls must be. The point is that the controls follow from what the
system holds, not from a generic checklist.

**Authorize** is lesson 3's acceptance, made formal. A named senior person, the **authorizing official**,
reviews the assessment and the residual risk and signs an **authorization to operate**. Without it, the
system may not go into production. It puts the decision exactly where lesson 3 put it: with somebody who
owns the risk, not with the engineers who built the system.

### The controls the RMF selects from

The **Select** step draws on **NIST SP 800-53**, NIST's catalogue of security and privacy controls,
organised into twenty families (access control, audit and accountability, incident response and so on).
It is far more detailed than ISO 27001's Annex A and is written for US federal systems; outside that
world it is mostly used as a reference library when a control needs specifying in detail.
