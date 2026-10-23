---
title: Four architecture domains
version: 1
---

**TOGAF describes an enterprise in four architecture domains: business, data, application and
technology.** Each answers a different question, and a change to the enterprise usually touches all
four. People abbreviate them BDAT.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l08-domains\" aria-label=\"TOGAF's four architecture domains as stacked layers, each with Carcará's contents. Business: selling online and at 26 counters, boarding at the bus door, running the fleet. Data: passengers, bookings, tickets, trips, buses, payments. Application: ticketing, boarding app, station back office, Frota, finance package. Technology: one cloud region, drivers' phones, station PCs and printers, station internet links. Data and application are bracketed together as the information systems architectures.\"><rect x=\"130.0\" y=\"20.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Business</text><text x=\"145.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">selling online and at 26 counters · boarding at the door · running the fleet</text><rect x=\"130.0\" y=\"86.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Data</text><text x=\"145.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passengers · bookings · tickets · trips · buses · payments</text><rect x=\"130.0\" y=\"152.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Application</text><text x=\"145.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ticketing · boarding app · station back office · Frota · finance</text><rect x=\"130.0\" y=\"218.0\" width=\"560.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"145.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Technology</text><text x=\"145.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cloud region · drivers' phones · station PCs and printers · links</text><path d=\"M118 92 L108 92 L108 206 L118 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"98.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">information</text><text x=\"98.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">systems</text></svg>", "caption": "The business layer on top is what C4 does not draw. The other three are where the systems of lessons 2 and 3 live."}
```

| domain | the question | Carcará, today |
| --- | --- | --- |
| **business architecture** | what does the organisation do, how is it organised, and which processes and capabilities matter? | selling tickets online and at 26 station counters; boarding at the bus door; running the fleet |
| **data architecture** | what information does it hold, how is it structured, and who owns it? | passengers, bookings, tickets, trips, buses, drivers, payments |
| **application architecture** | which applications exist, what does each do, and how do they interact? | ticketing, boarding app, station back office, Frota, the finance package |
| **technology architecture** | what infrastructure runs it all: hardware, networks, platforms? | one cloud region, drivers' phones, station PCs and receipt printers, station internet links |

The middle two are grouped by TOGAF as the **information systems architectures**, because data and
applications are usually designed together.

## Why four layers

The layers separate **what the business does** from **how it is supported**. That separation is what
lets an enterprise architect ask the questions that cross systems:

- *Which business capabilities depend on the station back office?* If the answer is *selling to
  cash customers* and *cash refunds*, retiring the back office is a business change, not only an IT
  one.
- *Which applications hold passenger data?* Ticketing, the back office and the finance package do,
  which matters for the LGPD and for the erasure requests a privacy policy promises.
- *What technology does boarding depend on?* The drivers' phones and the sync, which is why the
  phone replacement cycle is an architecture concern.

## The layers in lesson 3's terms

The C4 model from lesson 3 lives almost entirely in the **application** and **technology** domains:
its context and container diagrams are application architecture, its deployment diagrams technology
architecture. What C4 does not draw is the business layer above them, the capabilities and
processes, and that is the part enterprise architecture adds. **A C4 system context answers *what
does this system touch?*; a business architecture answers *what does the company do, and which
systems does each part of it need?***
