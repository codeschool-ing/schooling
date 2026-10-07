---
title: SOC 2, read from the customer's side
version: 1
---

A SOC 2 report is an **attestation**: an independent CPA firm examines a service organisation's
controls against the AICPA's Trust Services Criteria and writes an opinion. It is not a certificate
and it has no pass mark. It is a long document written for the organisation's customers, and Vereda
is one of the gateway's customers.

Most companies Vereda's size never commission one. They receive them, from every supplier whose
system holds or moves their data, and **reading one is the threat-modelling skill**: a supplier's
report is a description of what happens on the far side of a trust boundary in your own diagram.

### What it covers

The criteria come in five categories. **Security** is always included, and its criteria, the common
criteria, are numbered CC1 to CC9: CC6, for example, is logical and physical access, where a second
factor would be tested. **Availability, processing integrity, confidentiality and privacy** are
added when the organisation chooses. The gateway's report covers security and availability, so
nothing in it was examined for confidentiality or privacy.

There are two types, and the difference is the one that matters:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l13-soc2-period\" aria-label=\"Two kinds of SOC 2 report on one timeline. A Type I report looks at the design of the controls on a single date. A Type II report tests whether they operated over a period: the gateway’s covers 1 July 2025 to 30 June 2026, and was delivered in August 2026. The months after the period are covered only by the gateway’s own bridge letter, which no auditor tested.\"><path d=\"M60.0 160.0 L680.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M128.9 160.0 L128.9 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"128.9\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jul 2025</text><path d=\"M232.2 160.0 L232.2 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"232.2\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Oct 2025</text><path d=\"M335.6 160.0 L335.6 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"335.6\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jan 2026</text><path d=\"M438.9 160.0 L438.9 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"438.9\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Apr 2026</text><path d=\"M542.2 160.0 L542.2 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"542.2\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jul 2026</text><path d=\"M645.6 160.0 L645.6 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"645.6\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Oct 2026</text><circle cx=\"128.9\" cy=\"45.0\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"140.9\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Type I: the design, on one date</text><rect x=\"128.9\" y=\"80.0\" width=\"413.3\" height=\"20.0\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"136.9\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Type II: tested over twelve months</text><rect x=\"542.2\" y=\"80.0\" width=\"103.3\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"546.2\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">bridge letter: the gateway’s word only</text><circle cx=\"576.7\" cy=\"140.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"566.7\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">report delivered</text></svg>", "caption": "A Type II report says the controls worked during its period, and says nothing about the months since."}
```

- A **Type I** report says the controls were suitably designed on one date. Nobody watched them work.
- A **Type II** report also tests whether they **operated effectively over a period**, usually six to
  twelve months, by sampling: so many access reviews, so many changes, so many incidents.

The gateway's report is Type II, for 1 July 2025 to 30 June 2026. It reached carla in August. For the
months since, the gateway sent a **bridge letter**, its own statement that nothing material changed.
No auditor tested that letter, and it should be read as what it is.

### Five things to read, in order

The gateway and its report are invented for this course, and the passages described below are
illustrative rather than quoted from any real report.

1. **The opinion.** An unqualified opinion says the description is fair and the controls were
   designed, and for Type II operated, as described. A qualified opinion names where they were not,
   and that paragraph is the most important one in the report.
2. **The system description.** Which services are in scope. The gateway's covers its card and Pix
   processing and its webhook delivery, which is the part Vereda depends on. A report that covered
   only card processing would say nothing about T01.
3. **The subservice organisations.** The gateway runs on a cloud provider and **carves it out**: the
   provider's controls are excluded, and the report assumes them. Vereda would need the provider's own
   report to close that gap.
4. **The exceptions.** Section 4 lists each test and its result. The gateway's has one exception: in
   two of 25 sampled access reviews, a leaver's account was removed late. That is not a failure of the
   report; it is information.
5. **The complementary user entity controls.** This is the part written to Vereda.

### Half a control

A service organisation's controls often work only if the customer does its part, and the report
lists those parts as **complementary user entity controls**, CUECs. The gateway's has three that
touch Vereda's portal:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-cuec\" aria-label=\"The gateway’s controls and the ones its report expects from customers, on either side of the trust boundary between Vereda and the gateway. The gateway signs every webhook it sends, protects its API, and keeps its keys; its auditor tested those. Its report then lists what customers must do for that to protect them: verify the webhook signature, which is Vereda’s R01 and control C3; keep the API key secret; and review who can use the gateway’s dashboard. The last two have no requirement in Vereda’s model.\"><defs><marker id=\"l13-cuec-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the gateway: tested by its auditor</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Vereda: complementary controls</text><rect x=\"40.0\" y=\"50.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">signs every webhook it sends</text><rect x=\"40.0\" y=\"110.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rate-limits and logs its API</text><rect x=\"40.0\" y=\"170.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rotates its signing keys</text><rect x=\"400.0\" y=\"50.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"414.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">verifies the signature</text><text x=\"668.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R01 · C3</text><rect x=\"400.0\" y=\"110.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"414.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">keeps the API key secret</text><text x=\"668.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">no requirement</text><rect x=\"400.0\" y=\"170.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"414.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reviews who uses the dashboard</text><text x=\"668.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">no requirement</text><path d=\"M360.0 40.0 L360.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"366.0\" y=\"244.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">trust boundary</text><path d=\"M320.0 70.0 L400.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-cuec-tm-ah-phosphor)\"></path></svg>", "caption": "A SOC 2 report is half a control. The other half is listed in it as the customer’s job, and only the customer can check that it is done."}
```

Put beside the model, they are a mapping in the other direction. The first, **verify the webhook
signature**, is R01 and control C3: the gateway signs every webhook, its auditor tested that, and none
of it protects Vereda until the portal checks the signature. **C3 is in phase 2 of the plan.** Until
it ships, the gateway's tested control is half a control.

The other two have no requirement in the model at all. Keeping the gateway's API key secret, and
reviewing which staff can sign in to the gateway's dashboard, are about an element the DFD drew as
one external entity and never looked inside. They are new questions, found by reading a supplier's
report against a trust boundary, and lesson 15 adds them to the model as the first thing that
happens when it is kept alive.
