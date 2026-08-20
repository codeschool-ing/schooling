---
title: DNS: translating a name into an address
---

**DNS** is the service that answers "what is the IP of `codeschool.ing`?". It is hierarchical: the question climbs to whoever knows, and the answer comes back down being cached along the way.

The record types you use every week:

- `A` — points the name at an IPv4. `AAAA` does the same for IPv6.
- `CNAME` — says "this name is an alias of that one". It cannot exist at the domain root.
- `MX` — where this domain's e-mail goes.
- `TXT` — free text; it is where proofs of ownership and the anti-fraud e-mail rules live (SPF, DKIM).

The `CNAME`-at-the-root restriction is the one that shows up most in practice: to point `codeschool.ing` (without `www`) at a hosted service, either you use `A` with fixed IPs, or the provider offers an `ALIAS`/`ANAME`, which is a non-standard extension.

```schooling-figure
{
  "svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"The question climbs from the browser to the resolver, and from the resolver to the root, TLD and authoritative servers; the answer comes back down being cached\"><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".55\"><rect x=\"8\" y=\"60\" width=\"118\" height=\"46\" rx=\"4\"/><rect x=\"176\" y=\"60\" width=\"128\" height=\"46\" rx=\"4\"/><rect x=\"354\" y=\"16\" width=\"120\" height=\"38\" rx=\"4\"/><rect x=\"354\" y=\"72\" width=\"120\" height=\"38\" rx=\"4\"/><rect x=\"354\" y=\"128\" width=\"120\" height=\"38\" rx=\"4\"/></g><g fill=\"currentColor\" font-family=\"IBM Plex Mono, monospace\" font-size=\"11\"><text x=\"67\" y=\"80\" text-anchor=\"middle\">browser</text><text x=\"67\" y=\"95\" text-anchor=\"middle\" opacity=\".6\">has a cache</text><text x=\"240\" y=\"80\" text-anchor=\"middle\">resolver</text><text x=\"240\" y=\"95\" text-anchor=\"middle\" opacity=\".6\">your provider's</text><text x=\"414\" y=\"40\" text-anchor=\"middle\">root  .</text><text x=\"414\" y=\"96\" text-anchor=\"middle\">TLD  .ing</text><text x=\"414\" y=\"152\" text-anchor=\"middle\">authoritative</text></g><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.4\" opacity=\".8\"><path d=\"M126 78h42\" marker-end=\"url(#pt)\"/><path d=\"M304 76l44-38\" marker-end=\"url(#pt)\"/><path d=\"M304 83h42\" marker-end=\"url(#pt)\"/><path d=\"M304 90l44 38\" marker-end=\"url(#pt)\"/></g><defs><marker id=\"pt\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"6\" markerHeight=\"6\" orient=\"auto\"><path d=\"M0 0l8 4-8 4z\" fill=\"currentColor\"/></marker></defs><g font-family=\"IBM Plex Mono, monospace\" font-size=\"10\" opacity=\".55\" fill=\"currentColor\"><text x=\"500\" y=\"96\">every answer comes back down</text><text x=\"500\" y=\"112\">kept for TTL seconds</text></g></svg>",
  "caption": "The question climbs to whoever knows; the answer comes back down being cached along the way. It is that cache along the path that makes propagation take time."
}
```
