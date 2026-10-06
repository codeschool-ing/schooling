---
title: Certification
version: 1
---

An organisation does not certify itself. A **certification body**, accredited for 27001 by a national
accreditation body (in Brazil, Inmetro's general accreditation coordination, the Cgcre), audits the
ISMS and, if it conforms, issues a certificate. The process has a standard shape:

```schooling-figure
{"svg": "<svg id=\"sf-cert-cycle\" viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"The certification cycle over three years. Before the certificate: stage 1, documentation, then stage 2, implementation. Year 1 and year 2: a surveillance audit each. Year 3: recertification, and a new cycle begins.\"><defs><marker id=\"sf-cert-cycle-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 90 L700 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sf-cert-cycle-ah-paper-dim)\"></path><circle cx=\"70\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><text x=\"70\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stage 1</text><text x=\"70\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">documents</text><circle cx=\"190\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"190\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">stage 2</text><text x=\"190\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">certificate</text><circle cx=\"340\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><text x=\"340\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">year 1</text><text x=\"340\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surveillance</text><circle cx=\"490\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><text x=\"490\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">year 2</text><text x=\"490\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surveillance</text><circle cx=\"640\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"640\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">year 3</text><text x=\"640\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recertification</text><text x=\"415\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a three-year certificate</text><path d=\"M190 140 L640 140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Valid for three years, visited every year."}
```

| step | what is examined | typical result |
|---|---|---|
| **stage 1** | the documentation and readiness: scope, policy, risk method, SoA, whether the ISMS is ready to be audited | a list of things to fix before stage 2 |
| **stage 2** | whether the ISMS actually runs: interviews, samples, evidence that controls operate and the cycle of clauses 9 and 10 turns | findings; certification if no major nonconformity is open |
| **surveillance audits** | each year, a sample of the ISMS, always including the improvement cycle | the certificate is maintained, or suspended |
| **recertification** | in the third year, a fuller audit of the whole ISMS | a new three-year certificate |

So a certificate is **valid for three years and visited every year**. That rhythm is the management
system idea from section 03 in practice: the certificate is evidence that the cycle keeps turning, not
that the organisation was right on one day.

### What it costs a small shop

Certification takes effort that scales less than proportionally with size. A nine-person shop still
needs a scope, a policy, a risk assessment, an SoA, records, an internal audit and a management review.
Much of it this course has already produced, but writing it into a coherent ISMS takes months, and the
audits themselves cost money every year.

The honest advice for an organisation the shop's size is in two steps. First, **use 27001 and 27002
without certifying**: the clauses as a checklist for running security properly, Annex A as a catalogue
to check the controls against. That captures most of the value. Second, certify **when somebody needs
the certificate**: a customer's contract, a tender, a market that expects it. Then the scope should be
the part of the shop that customer cares about, and no larger.

### Reading somebody else's certificate

Three things to check when a supplier sends one: that the **scope** covers the service you are buying;
that the certificate is **current** (the issue and expiry dates, and that it is against the 2022
edition); and that the certification body is **accredited**, which can be checked with the accreditation
body that names it. A certificate from an unaccredited body is a document, not an assurance.
