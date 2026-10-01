---
title: The parts of a Zero Trust decision
version: 1
---

Every access decision in a Zero Trust design has the same parts, whatever the product that implements
them:

| part | what it is | in this lesson's lab |
|---|---|---|
| **subject** | the user or machine making the request | the proxy, `www` |
| **resource** | what it wants to reach | the application on `app` |
| **identity** | something the subject proves, not something it claims | a client certificate from the company's CA |
| **policy decision point** (PDP) | where the rules are evaluated | the TLS configuration on `app`: which CA, which name |
| **policy enforcement point** (PEP) | what lets the request through or stops it | the TLS listener in front of the application |
| **signals** | what else the decision may consider | certificate validity; in products, the device's health, the time, the risk |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A Zero Trust decision in the lab. The subject, www, presents its client certificate to the policy enforcement point, the TLS listener on app port 8443. The enforcement point asks the policy decision: is the certificate valid, signed by the company&#x27;s CA, unexpired, and is its name www-client? If yes, the request reaches the resource, the application on 8080. laptop, inside the network but with no certificate, is stopped at the enforcement point.\"><defs><marker id=\"zt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"zt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"zt-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"30\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subject: CN=www-client</text><rect x=\"20\" y=\"150\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no certificate</text><rect x=\"270\" y=\"90\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app :8443</text><text x=\"280\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">enforcement point</text><rect x=\"560\" y=\"90\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app :8080</text><text x=\"570\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the resource</text><path d=\"M170 55 L270 105\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#zt-ah-phosphor)\"></path><path d=\"M170 172 L270 125\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#zt-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"180\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">400: no certificate</text><path d=\"M450 113 L560 113\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#zt-ah-phosphor)\"></path><text x=\"505\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">allowed</text><rect x=\"270\" y=\"170\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decision: valid, our CA,</text><text x=\"280\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">unexpired, name www-client</text><path d=\"M360 136 L360 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "The network lets both packets arrive. Identity decides which one goes further."}
```

Three consequences follow from putting identity in the middle:

- **every connection is authenticated**, including between servers that sit on the same segment;
  *inside* stops being a reason;
- **authorisation is per resource**, so a valid identity for one service does not open another;
- **decisions are logged with the identity**, so the question *who did this* has an answer that is not
  just an address.

The network does not disappear. The firewall still limits what can reach what, and lesson 21 narrows it
further. What changes is that passing the firewall is **necessary and no longer sufficient**.
