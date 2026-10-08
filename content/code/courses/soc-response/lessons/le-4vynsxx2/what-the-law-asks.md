---
title: What the LGPD asks
version: 1
---

Everything so far has been about systems. This lesson is about **people**: the ones whose data was on the file
server, and what the company owes them now. In Brazil that is set by the **LGPD**, the general data protection law
(Lei 13.709/2018), and by the rules of the **ANPD**, the national data protection authority that enforces it. What
follows is how a SOC analyst should understand those rules, so as to hand the right facts to the people who apply
them. **The decisions in this lesson belong to the DPO and the lawyer**, and nothing here is legal advice for a real
case.

Four parts of the law matter for an incident:

| where | what it says |
|---|---|
| **art. 46** | the company that decides how personal data is used, the **controller**, must protect it with security measures |
| **art. 48** | the controller must tell the ANPD and the people concerned of a security incident **that may cause them relevant risk or damage** |
| **art. 41** | the controller names an **encarregado**, the DPO, who is the channel to the ANPD and to the people whose data it holds |
| **art. 52** | the ANPD's sanctions, from a warning to a fine of up to 2% of the company's revenue in Brazil, capped at R$ 50 million per infraction |

Article 48 left the details to the ANPD, which set them out in **Resolution CD/ANPD nº 15 of 2024**, the
*Regulamento de Comunicação de Incidente de Segurança*, usually called the **RCIS**. It says when an incident must be
communicated, by when, what the communication contains, and what must be recorded whether or not it is.

The decision the rest of this lesson follows has three questions, in order:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A decision path from top to bottom. Did the incident involve personal data? If no, record it and stop. If yes or possibly: may it cause relevant risk or damage to the people it concerns? If no, record it, with the reasoning, and keep the record for five years. If yes: communicate to the ANPD and to the people affected within three business days of knowing, complement within twenty, and record it as well.\"><rect x=\"160\" y=\"10\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">personal data involved?</text><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">yes, or possibly</text><path d=\"M360 60 L360 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 90 L364.0 82.0 L356.0 82.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"160\" y=\"90\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">relevant risk or damage to people?</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RCIS criteria</text><path d=\"M560 35 L600 35\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 35 L592.0 31.0 L592.0 39.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"610\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no: record</text><path d=\"M560 115 L600 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 115 L592.0 111.0 L592.0 119.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"610\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no: record why</text><path d=\"M360 140 L360 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 170 L364.0 162.0 L356.0 162.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"160\" y=\"170\" width=\"400\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">communicate: ANPD and the people</text><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 business days; complement within 20</text><rect x=\"10\" y=\"246\" width=\"700\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the record of incidents: every branch, kept for five years</text></svg>", "caption": "Every branch ends in the record. Only one of them also ends in a communication."}
```

Notice the last box. **Every branch ends in the record**, including "no personal data" and "no relevant risk". A
decision not to communicate is still a decision, and it has to be written down with its reasons.
