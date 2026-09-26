---
title: When to pass it on
version: 1
---

Support is usually organised in levels, and a ticket moves between them in two different directions:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three levels of support, left to right. Level 1, the service desk: first contact and known fixes. Level 2, specialists in systems, network and applications. Level 3, the owners: developers and the vendor. Passing a ticket along these is functional escalation, to who knows more. Above them, management, reached by hierarchical escalation, to who can decide, when it is about time, money or people.\"><defs><marker id=\"tr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"160\" y=\"16\" width=\"400\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"176\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">management: when it is about time, money or people</text><rect x=\"20\" y=\"110\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">level 1</text><text x=\"32\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">service desk: first contact</text><path d=\"M222 140 L258 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-ah)\"></path><rect x=\"260\" y=\"110\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">level 2</text><text x=\"272\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">specialists: systems, network, applications</text><path d=\"M462 140 L498 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-ah)\"></path><rect x=\"500\" y=\"110\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">level 3</text><text x=\"512\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">owners: developers, the vendor</text><path d=\"M100 108 L190 58\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"260\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">functional: to who knows more</text><text x=\"200\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">hierarchical: to who can decide</text></svg>", "caption": "Two directions. Functional escalation goes to whoever knows more about the fault; hierarchical escalation goes to whoever can decide something the technician cannot, such as a priority, an expense or an exception."}
```

Escalate when one of these is true, and write which one in the ticket:

- **It needs access you do not have**, or should not have: another team's server, a vendor's system.
- **It needs knowledge you do not have**, and your time-box for finding it has run out. Setting that
  box at the start, *if I have no cause in 30 minutes, it goes to level 2*, is what stops an afternoon
  disappearing into one ticket while the others wait.
- **It needs a decision above yours**: a purchase, an exception to a rule, a priority that someone is
  disputing. That is hierarchical escalation.
- **It is bigger than one person**: many users, a whole service down, or anything that looks like a
  security incident. These go up immediately, before any time-box.

**Not escalating is also a decision**, and the usual reason is pride. A ticket that sits with a level 1
technician for a day, when level 2 would have solved it in ten minutes, is a worse service than an early
handover.
