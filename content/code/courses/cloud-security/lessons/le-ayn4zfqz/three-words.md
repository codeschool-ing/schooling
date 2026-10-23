---
title: Compliance, residency and sovereignty are three different questions
version: 1
---

**Three words get used as if they meant the same thing, and each one answers a different question.
Residency asks where the data is. Sovereignty asks whose law can reach it. Compliance asks whether
you meet a set of rules, and whether you can prove it.** A clinic can get one right and the other two
wrong in the same afternoon.

The usual wrong picture is a single switch: choose the São Paulo region and the data is Brazilian,
legal and protected. Choosing `sa-east-1` settles the first question for the copies you put there.
It says nothing about the backup somebody made in another region, nothing about which governments
can compel the provider to hand data over, and nothing about whether the clinic can show an auditor
that it knows any of this.

| | the question | what answers it | where this lesson treats it |
|---|---|---|---|
| **residency** | in which country is each copy stored and processed? | the region of every resource, read from the API | the section on finding the data, and the guardrail after it |
| **sovereignty** | whose laws, and whose courts, can demand access to it? | where the data is **and** who the provider is | the last section |
| **compliance** | does the clinic meet the rules that apply to it, such as the LGPD, and can it prove so? | evidence: inventories, logs, policies, reports | the next section and the last |

## Why they come apart

**Residency is a fact about a resource.** A bucket is in exactly one region, and the API will tell
you which. It is the one of the three you can check with a command, and lesson 16's scanner could
carry it as a rule.

**Sovereignty is a fact about a relationship.** The clinic's records can sit in São Paulo, on disks
in Brazil, and still be held by a company incorporated in the United States, which United States law
can order to produce what it controls. Where the bytes are and who answers for them are separate
things, and the second one does not move when you pick a region.

**Compliance is a fact about evidence.** A rule nobody can show being followed is, to an auditor,
a rule that is not followed. The provider's certificates prove its half of lesson 2's line; the
clinic's half is proved by the clinic, and the course has been producing that evidence all along —
an inventory in lesson 1, a credential report in lesson 6, a scan in lesson 16.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l17-reach\" aria-label=\"Residency against sovereignty, for the clinic. Two regions: São Paulo, sa-east-1, holds clinic-records and clinic-exports; Northern Virginia, us-east-1, holds clinic-backups-us. Residency is where each copy is: two in Brazil, one in the United States. Sovereignty is whose law reaches them. Brazilian law, the LGPD, reaches the clinic and so every copy it controls. United States law, through the CLOUD Act, reaches the provider, a United States company, and so every copy it holds, in both regions.\"><rect x=\"40.0\" y=\"20.0\" width=\"640.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Brazilian law (LGPD): reaches the clinic, so every copy it controls</text><rect x=\"40.0\" y=\"64.0\" width=\"640.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">United States law (CLOUD Act): reaches the provider, so every copy it holds</text><rect x=\"40.0\" y=\"128.0\" width=\"300.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"190.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo — Brazil</text><text x=\"190.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"80.0\" y=\"182.0\" width=\"220.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"190.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clinic-records</text><rect x=\"80.0\" y=\"220.0\" width=\"220.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"190.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clinic-exports</text><rect x=\"380.0\" y=\"128.0\" width=\"300.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"530.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Northern Virginia — United States</text><text x=\"530.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">us-east-1</text><rect x=\"420.0\" y=\"182.0\" width=\"220.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"530.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">clinic-backups-us</text><text x=\"360.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">residency: where each copy is — two in Brazil, one abroad</text></svg>", "caption": "Picking a region decides residency, the bottom of the drawing. It does not decide the top: both laws reach the copy in São Paulo, because one follows the clinic and the other follows the provider."}
```

The `security-fundamentals` course's lesson 17 set out what the LGPD protects and why health data
is *sensitive*. This lesson takes the one part of it the cloud makes urgent: data that leaves the
country, sometimes without anybody deciding that it should.
