---
title: Shield Standard, which every account already has
version: 1
---

A **distributed denial-of-service** attack, DDoS, sends a service more traffic than it can answer, from
many machines at once, so that real customers cannot get through. Nothing is stolen and nothing is
broken into; the service is simply full. The attacks come in two families, and they are stopped in
different places.

**Network and transport attacks**, layers 3 and 4, flood the connection itself: SYN packets that open
connections and never finish them, UDP packets reflected off misconfigured servers elsewhere on the
internet and multiplied on the way. They are large, measured in gigabits or packets per second, and
they never reach the application at all; they fill the road to it.

**Application attacks**, layer 7, send requests that look like real ones: a page fetched, a search run,
a login tried, thousands of times a second. They are small by comparison and expensive to answer,
because each one makes the application do work.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two rows. Network and transport attacks at layers 3 and 4, such as SYN floods and UDP reflection, measured in gigabits a second, are stopped by Shield Standard at the edge and the load balancer, automatically and at no charge. Application attacks at layer 7, requests that look real and are expensive to answer, are stopped by WAF rate rules and CloudFront, configured by the team as in lesson 15, or by the automatic rules of Shield Advanced.\"><defs><marker id=\"lay-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the attack</text><text x=\"530\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">where it is stopped</text><rect x=\"20\" y=\"44\" width=\"220\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layers 3 and 4</text><text x=\"130.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN floods, UDP reflection</text><text x=\"130.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gigabits a second</text><path d=\"M242 82 L368 82\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lay-ah)\"></path><rect x=\"370\" y=\"44\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shield Standard</text><text x=\"535.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">at the edge and the load balancer,</text><text x=\"535.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">automatic, at no charge</text><rect x=\"20\" y=\"146\" width=\"220\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layer 7</text><text x=\"130.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">requests that look real</text><text x=\"130.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">expensive to answer</text><path d=\"M242 184 L368 184\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lay-ah)\"></path><rect x=\"370\" y=\"146\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WAF rate rules and CloudFront</text><text x=\"535.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lesson 15, configured by the team;</text><text x=\"535.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">or Shield Advanced's automatic rules</text></svg>", "caption": "Standard stops the floods that fill the road. The requests that look real are layer 7, and that layer is the team's to configure."}
```

## What Standard does, and does not

**AWS Shield Standard is on for every account, at no charge, with nothing to configure.** It inspects
traffic to CloudFront, Route 53 and Global Accelerator at AWS's edge, and to load balancers and Elastic
IP addresses in the region, and it absorbs or drops the common layer 3 and 4 attacks there, before they
reach the resources. There is no command for it, nothing to see in the console and no line on the bill,
which is why people forget it exists, and also why the lab has nothing to show about it.

What Standard does **not** do is read HTTP. A flood of perfectly formed `GET /search?q=…` requests is
ordinary traffic at layer 4, and Standard lets it through. That family is lesson 15's: a rate-based rule
on the paths that are expensive to answer, a managed rule group, and CloudFront in front, which caches
what can be cached so a flood of identical requests is answered at the edge rather than by the shop.

**For most small and medium services, Standard plus WAF plus CloudFront is the answer**, and it costs
only what lesson 15 priced. The next section is about what costs more, and when that is worth it.
