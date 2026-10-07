---
title: LINDDUN, threats to privacy
version: 1
---

STRIDE asks whether an attacker can break a property. Privacy harm often needs no attacker at all:
the system does exactly what it was designed to do, and that is the problem. T08, the reminder SMS
that tells anybody holding the phone that its owner is in treatment, is a privacy threat that
STRIDE found almost by accident. **LINDDUN** is built to find that kind on purpose.

It comes from the DistriNet research group at KU Leuven in Belgium, and it works like STRIDE: a
category per letter, applied to the elements and flows of a DFD.

| | category | the question at the portal |
|---|---|---|
| **L** | **linking** | can records from different places be joined to learn more about a person than any one shows? |
| **I** | **identifying** | can a person be singled out from data meant to be anonymous? |
| **N** | **non-repudiation** | can a patient be unable to deny something they would rightly want to keep to themselves? |
| **D** | **detecting** | can somebody tell that a person is a patient at all, without reading anything? |
| **D** | **data disclosure** | does the system collect, keep or share more personal data than it needs? |
| **U** | **unawareness and unintervenability** | does the patient know what happens to their data, and can they do anything about it? |
| **N** | **non-compliance** | does the processing break the law or the policy Vereda published? |

Two letters read the opposite way from STRIDE, and they are the clearest sign that privacy is a
different question. In STRIDE, non-repudiation is a property you *want*: proof of who did what. In
LINDDUN it is a threat *to the patient*: a record that proves they visited a physiotherapist, kept
where they did not expect it. Detecting is similar: the fact that a reminder arrives at all tells
something, even if its text is encrypted.

### Applied to the flows that leave Vereda

The most productive place to start is every flow that carries personal data out of Vereda's
control, and every store that keeps it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-linddun-flows\" aria-label=\"The flows that carry personal data out of Vereda, with the LINDDUN categories each one raised. To the SMS provider: the patient’s phone, name, time and clinic; detecting, data disclosure, unawareness. To the payment gateway: name, CPF and amount; linking, data disclosure. Into the records database: every booking and note, kept with no end date; identifying, non-compliance.\"><defs><marker id=\"l05-linddun-flows-tm-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><circle cx=\"130.0\" cy=\"145.0\" r=\"50\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"130.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Vereda</text><rect x=\"230.0\" y=\"32.0\" width=\"140.0\" height=\"36.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SMS provider</text><path d=\"M160.0 70.0 L228.0 50.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-linddun-flows-tm-ah-paper)\"></path><text x=\"300.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">phone, name, time, clinic</text><rect x=\"390.0\" y=\"37.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"443.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Detecting</text><rect x=\"500.0\" y=\"37.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Data disclosure</text><rect x=\"610.0\" y=\"37.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"663.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Unawareness</text><rect x=\"230.0\" y=\"127.0\" width=\"140.0\" height=\"36.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Payment gateway</text><path d=\"M180.0 145.0 L228.0 145.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-linddun-flows-tm-ah-paper)\"></path><text x=\"300.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">name, CPF, amount</text><rect x=\"390.0\" y=\"132.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"443.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Linking</text><rect x=\"500.0\" y=\"132.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Data disclosure</text><rect x=\"230.0\" y=\"225.0\" width=\"140.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M230.0 225.0 L370.0 225.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M230.0 255.0 L370.0 255.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"300.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Records database</text><path d=\"M160.0 220.0 L228.0 240.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-linddun-flows-tm-ah-paper)\"></path><text x=\"300.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every booking and note, no end date</text><rect x=\"390.0\" y=\"227.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"443.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Identifying</text><rect x=\"500.0\" y=\"227.0\" width=\"106.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">Non-compliance</text></svg>", "caption": "STRIDE asked whether an attacker could read these flows. LINDDUN asks whether they should carry what they carry, and whether the patient knows."}
```

- **To the SMS provider** goes a phone number, a first name, a time and the clinic's name. That is
  **detecting** (a message from a physiotherapy clinic says the person is a patient) and **data
  disclosure** (the provider receives more than a reminder needs). And the privacy notice the
  patient accepted does not name the provider at all: **unawareness**.
- **To the payment gateway** goes the patient's name, CPF and the amount. The gateway needs the
  amount and a reference; the CPF lets the gateway **link** this payment to everything else it
  knows about that person.
- **Into the records database** go every booking and every note, and nothing ever leaves.
  Keeping health data with no retention period is a **non-compliance** question under the LGPD,
  which allows processing only for as long as its purpose lasts. And old bookings make a person
  **identifiable** long after they stopped being a patient.

None of these needs an attacker. Each one is fixed by a design decision. A reminder says "you have a
session tomorrow at 10:00, reply C to cancel"; a payment request carries a booking reference and no
CPF; and a retention rule removes bookings after the period the law and the clinical council
require. The `security-fundamentals` course (lesson 17) introduced the LGPD; LINDDUN is how the
law's principles become questions about a specific DFD.

### Where to go next with it

The LINDDUN team publishes two practical forms: **LINDDUN GO**, a deck of cards for a lightweight
session, and **LINDDUN PRO**, a systematic version that walks every flow. For a team that already
does STRIDE, an hour with LINDDUN GO on the flows that leave the company is the cheapest
privacy review there is.
