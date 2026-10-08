---
title: Why map at all
version: 1
---

In the first week of October 2026, three documents reached Vereda, and none of them mentioned a
threat. **A health insurer** that sends patients to the clinics wants to renew its contract, and
attached a questionnaire of 60 questions numbered after ISO/IEC 27001. **The owners** asked daniel
for one page on where security stands, and their accountant suggested the shape of the NIST
Cybersecurity Framework. **The payment gateway**, asked by carla whether its webhooks could be
trusted, sent its SOC 2 Type II report.

Each one is asking about the same eleven controls the model chose in lesson 11. Each one asks in its
own vocabulary, with its own numbers, and expects the answer filed under them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-one-control\" aria-label=\"One control answering three questions. On the left, the chain the model built: threat T03, a receptionist phished with no second factor, gives requirement R05, a second factor at every staff sign-in, which control C1 implements. On the right, three documents ask about the same control in their own terms: the insurer’s questionnaire, question 14, do staff use a second factor; ISO 27001 Annex A control 8.5, secure authentication; and NIST CSF outcome PR.AA-03, users, services and hardware are authenticated.\"><defs><marker id=\"l13-one-control-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-one-control-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"18.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">T03</text><text x=\"90.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">staff phished</text><rect x=\"30.0\" y=\"88.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">R05</text><text x=\"90.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">second factor, always</text><rect x=\"30.0\" y=\"158.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">C1</text><text x=\"90.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">second factor for staff</text><path d=\"M140.0 62.0 L140.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-paper-dim)\"></path><path d=\"M140.0 132.0 L140.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-paper-dim)\"></path><rect x=\"420.0\" y=\"24.0\" width=\"280.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"434.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">insurer, question 14</text><text x=\"434.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">“Do staff use a second factor?”</text><rect x=\"420.0\" y=\"99.0\" width=\"280.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"434.0\" y=\"115.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ISO 27001, Annex A</text><text x=\"434.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8.5 secure authentication</text><rect x=\"420.0\" y=\"174.0\" width=\"280.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"434.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NIST CSF 2.0</text><text x=\"434.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PR.AA-03 users are authenticated</text><path d=\"M250.0 180.0 L330.0 180.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M330.0 50.0 L330.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M330.0 50.0 L420.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-phosphor)\"></path><path d=\"M330.0 125.0 L420.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-phosphor)\"></path><path d=\"M330.0 200.0 L420.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-phosphor)\"></path></svg>", "caption": "The model already decided C1, for a threat it can name. The mapping only says where each framework files that decision."}
```

### The work is the model; the mapping is a translation

There are two ways to answer a questionnaire like the insurer's. One is to read it question by
question and invent an answer for each, which is how a company ends up with sixty promises nobody
connected to anything. The other is to start from what already exists, **a threat, a requirement, a
control, a cost**, and say where each framework files it.

The second is a **control mapping**: a table from each of your controls to the references it
satisfies in each framework. It is done once and read many times. When the insurer asks question 14,
"do staff use a second factor?", the answer is C1, with R05 as the requirement, a test as the
evidence, and T03 as the reason it exists. When the owners ask where Vereda stands on authentication,
the answer is the same C1, filed under PR.AA-03.

### What a mapping is not

A mapping does not decide anything. It does not make a control necessary, and it does not make one
exist. The decisions were made in lessons 9 to 12, on expected losses and on daniel's signature, and
a framework reference adds no weight to them.

It also does not replace reading the frameworks. `security-fundamentals` lessons 13 to 15 teach what
an auditor wants, what ISO 27001 and 27002 contain and how the NIST CSF is organised. This lesson
assumes them and asks a narrower question: **given a threat model, how do you show it to somebody
who thinks in one of these frameworks, without losing what the model knows?**

### Three frameworks, three different things

The three are not alternatives. They are different kinds of document:

| | what it is | who checks it | what you get |
|---|---|---|---|
| **ISO/IEC 27001** | a standard for a management system, with 93 reference controls in Annex A | an accredited certification body | a certificate |
| **NIST CSF 2.0** | a voluntary framework of outcomes, in six functions | nobody, unless a contract says so | a profile, current and target |
| **SOC 2** | an attestation report on a service organisation's controls | an independent CPA firm | a report, Type I or Type II |

Vereda will not seek any of the three. It answers a questionnaire built on the first, reports to its
owners in the shape of the second, and reads a supplier's copy of the third. That is the most common
position for a company of its size, and it is the one this lesson takes.
