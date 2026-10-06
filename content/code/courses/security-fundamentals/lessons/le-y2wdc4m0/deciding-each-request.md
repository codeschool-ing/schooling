---
title: Deciding each request
version: 1
---

If every request has to be judged, something has to do the judging. SP 800-207 splits that job into
two parts, and the split is the core of a Zero Trust architecture:

```schooling-figure
{"svg": "<svg id=\"sf-pdp-pep\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The Zero Trust decision. On the left, the subject: a user on a device. A request goes to the policy enforcement point, which stands in front of the resource on the right. The enforcement point asks the policy decision point above it, made of a policy engine and a policy administrator. The decision point reads signals from an identity provider, device management and activity logs, and answers allow or deny.\"><defs><marker id=\"sf-pdp-pep-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-pdp-pep-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"200\" y=\"14\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identity</text><text x=\"255\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provider</text><path d=\"M255 58 L255 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><rect x=\"320\" y=\"14\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"375\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">device</text><text x=\"375\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">management</text><path d=\"M375 58 L375 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><rect x=\"440\" y=\"14\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">activity</text><text x=\"495\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">logs</text><path d=\"M495 58 L495 84\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><rect x=\"190\" y=\"84\" width=\"360\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">policy decision point (PDP)</text><text x=\"280\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">policy engine</text><text x=\"460\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">policy administrator</text><rect x=\"20\" y=\"196\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">subject</text><text x=\"90\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana on the laptop</text><rect x=\"300\" y=\"200\" width=\"140\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">PEP</text><rect x=\"570\" y=\"196\" width=\"130\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">resource</text><text x=\"635\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the payroll</text><path d=\"M160 226 L300 226\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><text x=\"230\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">request</text><path d=\"M440 226 L570 226\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-phosphor)\"></path><text x=\"505\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">if allowed</text><path d=\"M350 200 L350 148\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-wire)\"></path><path d=\"M390 148 L390 200\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-pdp-pep-ah-phosphor)\"></path><text x=\"340\" y=\"176.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">asks</text><text x=\"400\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">allow / deny</text><text x=\"370\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">policy enforcement point, in front of the resource</text></svg>", "caption": "The enforcement point asks; the decision point decides from identity, device and context."}
```

The **policy enforcement point (PEP)** sits in front of the resource and every request passes through
it. It does not decide anything itself. It collects what the request presents, asks, and then either
opens the connection or refuses it. In practice a PEP is a gateway, a reverse proxy in front of an
application, an agent on a server, or the login layer of the application itself.

The **policy decision point (PDP)** is where the decision is made. NIST divides it again into a
**policy engine**, which evaluates the request against the policy, and a **policy administrator**,
which tells the PEP the result. For a beginner the important part is what the PDP reads:

| signal | the question it answers | at the shop |
|---|---|---|
| identity | who is this, and did they prove it strongly? | ana, with password and a second factor |
| device | is the machine managed, patched, encrypted? | the office laptop, updated last week |
| resource | how sensitive is what they want? | the handbook, or the payroll file |
| context | is this request normal for them? | a weekday afternoon, from São Paulo |
| policy | what is allowed for this combination? | staff may read the handbook from a managed device |

The decision can be more than yes or no. A request that is a little unusual, like ana's account at
3 a.m. from a new country, can be asked for a second factor again; one that is very unusual can be
refused and raise an alert for a person to look at.

### Why the two are separate

Splitting enforcement from decision means **one policy can be enforced in many places.** The shop
could put a PEP in front of the portal, another in front of the file server and another on the
database, and all three ask the same PDP. Change the policy once, and every resource follows it.
It also means the PEPs can be simple and close to the resources, while the decision, which needs
the most information, lives in one place where that information is gathered.

The signals in the table come from other systems: an **identity provider** that knows the users and
their factors, a **device management** system that knows which machines are the company's and their
state, and logs that say what is normal. Most of the effort of adopting Zero Trust goes into those
systems rather than into the decision itself, which is one reason lesson 8, on identity, comes
straight after this one.
