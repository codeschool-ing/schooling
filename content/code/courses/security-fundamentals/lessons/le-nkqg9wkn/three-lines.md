---
title: Who checks whom: the three lines
version: 1
---

An organisation needs somebody to do the work of security, somebody to watch over how it is done, and
somebody to check, independently, that both are working. The **Three Lines Model**, published by the
Institute of Internal Auditors in 2020 as an update of its earlier "three lines of defence", is the
common way of describing those roles:

```schooling-figure
{"svg": "<svg id=\"sf-three-lines\" viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The Three Lines Model. At the top, the governing body, accountable to stakeholders. Below it, management with the first line, which owns and manages risk, and the second line, which gives expertise, support and challenge. Beside them, internal audit, the third line, independent, reporting directly to the governing body. Outside, external assurance providers such as external auditors and regulators.\"><defs><marker id=\"sf-three-lines-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sf-three-lines-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"160\" y=\"14\" width=\"400\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">governing body: the owners</text><rect x=\"20\" y=\"90\" width=\"460\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">management</text><rect x=\"40\" y=\"120\" width=\"200\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">first line</text><text x=\"140\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">owns and runs</text><text x=\"140\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the risks and controls</text><rect x=\"260\" y=\"120\" width=\"200\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">second line</text><text x=\"360\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">expertise, monitoring,</text><text x=\"360\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">challenge</text><rect x=\"500\" y=\"120\" width=\"200\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">third line</text><text x=\"600\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">internal audit:</text><text x=\"600\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">independent assurance</text><path d=\"M250 90 L300 58\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-three-lines-ah-wire)\" marker-start=\"url(#sf-three-lines-ah-wire)\"></path><path d=\"M600 120 L520 58\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#sf-three-lines-ah-amber)\"></path><text x=\"620\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">reports directly</text><text x=\"20\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outside: external auditors and regulators</text></svg>", "caption": "Doing, overseeing and checking, kept apart so that nobody audits their own work."}
```

| line | who | what they do | at the shop |
|---|---|---|---|
| **first line** | the managers and teams who run the business and its systems | own the risks and operate the controls | ana runs IT; bruno runs finance; each owns their area's risks |
| **second line** | specialist functions for risk, compliance and security | set the framework, advise, monitor, challenge the first line | in a large company, a security or compliance team; at the shop, an external consultant twice a year |
| **third line** | internal audit | gives independent assurance to the governing body that the first two lines work | at the shop, the owners commission an external review yearly |

Above the three lines sits the **governing body**, the board or, at the shop, the owners, who set the
risk appetite of lesson 3 and are accountable for the outcome. Outside the organisation sit
**external auditors and regulators**, who give assurance to people beyond it.

### Why the separation matters

The model exists to stop one failure: **people checking their own work.** If ana configured the
firewall and ana also audits it, her blind spots are in both places, which is lesson 4's "two layers
that are really one" applied to people. The second line gives an expert view from outside the daily
work; the third line reports to the governing body directly, so that what it finds cannot be
softened by the managers it is about.

In a small organisation the lines are thin and sometimes the same person wears two hats. The
principle survives anyway, in the same form lesson 6 gave separation of duties: if the shop cannot
afford a second person to review a change before it happens, it can afford somebody to look at the
record of changes afterwards. Independence is a matter of degree, and a little of it is far better
than none.

### Where security people fit

Most security jobs sit in the first or second line. An administrator hardening servers is first line.
A security team writing policy, monitoring alerts across the company and challenging risky decisions
is second line. A security specialist in an audit team is third line. Lesson 18's GRC careers live
mostly in the second and third.
