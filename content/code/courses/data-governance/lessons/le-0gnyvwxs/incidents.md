---
title: When it goes wrong — incidents
version: 1
---

**Article 46** requires security, technical and administrative measures able to protect personal
data from unauthorised access and from accidental or unlawful destruction, loss, alteration,
communication or dissemination. Lessons 1 to 5 were that article. **Article 48** is what happens
when the measures fail.

## What must be communicated, and when

The controller must notify **the ANPD and the data subjects** of a security incident that **may cause
relevant risk or damage** to the people involved. The communication contains, at least (art. 48,
§1):

1. the nature of the personal data affected;
2. information on the data subjects involved;
3. the technical and security measures used to protect the data;
4. the risks related to the incident;
5. the reasons for any delay, if the communication was not immediate;
6. the measures taken, or to be taken, to reverse or mitigate the effects.

The article says "within a reasonable time, as defined by the national authority". The ANPD defined
it in **Resolução CD/ANPD nº 15/2024**, the incident communication regulation:

- **three working days** to notify the ANPD, counted from when the controller learns that the
  incident affected personal data — and the same three to tell the people affected;
- **twenty working days** to complete the information, when not everything was known at first;
- an incident has **relevant risk** when it can significantly affect the people's interests or
  rights *and* involves at least one of: sensitive data, data of children, adolescents or the
  elderly, financial data, authentication data, data protected by secrecy, or data at large scale;
- **every incident is recorded**, communicated or not, and the record is kept for **at least five
  years**.

Small processing agents, as Resolução CD/ANPD nº 2/2022 defines them, get the deadlines doubled. That
resolution withholds part of its relief from high-risk processing, which a pharmacy's prescriptions
are likely to be, so Ipê plans on three days.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l7-incident\" aria-label=\"A timeline of an incident. Day zero is when the controller learns that personal data was affected. Within three working days it notifies the ANPD and the people affected. Within twenty working days it completes the information. The record of the incident is kept for at least five years, whether or not it was communicated.\"><path d=\"M40.0 110.0 L690.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"105.0\" cy=\"110.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"105.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">day 0</text><text x=\"105.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the controller learns</text><text x=\"105.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">personal data was affected</text><circle cx=\"275.0\" cy=\"110.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"275.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3 working days</text><text x=\"275.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">notify the ANPD</text><text x=\"275.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and the people affected</text><circle cx=\"450.0\" cy=\"110.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"450.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">20 working days</text><text x=\"450.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">complete the</text><text x=\"450.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">information</text><circle cx=\"625.0\" cy=\"110.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"625.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">5 years</text><text x=\"625.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keep the record,</text><text x=\"625.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">communicated or not</text><rect x=\"40.0\" y=\"185.0\" width=\"640.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">investigation goes on throughout; what is not known yet is said to be not known yet</text></svg>", "caption": "Resolução CD/ANPD nº 15/2024: the clock starts when the controller knows, not when the investigation ends."}
```

## Three days start before anybody is sure

The clock runs from the moment the controller **knows personal data was affected**, not from the end
of the investigation. That is why the communication can be completed later, and why the reasons for
any delay are one of its six items. Three things decide whether three days is enough, and all of
them are prepared in a quiet week:

- **knowing what the data is.** "Which tables did the leaked credential read?" is answered in
  minutes with lesson 6's classification and lesson 2's grants, and in days without them. The second
  item of the list — who the data subjects are — is the export query of section 9 run in reverse.
- **knowing what happened.** The audit log of lesson 4's OpenBao, and the logs lesson 10 keeps, are
  the evidence. A log that was never written cannot be read on the day.
- **knowing who decides.** The DPO, the person who can speak for the company, and the person who can
  revoke a credential at 23:00 on a Saturday — named in advance, with their phones.

## The record

Every incident goes into a register, including the ones judged not to carry relevant risk, with the
reasoning. In a database team's terms: an append-only table, with the date the incident was known,
the date it was contained, the data and the people affected, the risk assessment and its reasons,
and whether and when the ANPD and the people were told. The judgement "not relevant" is the one an
inspector will want to read, five years later.
