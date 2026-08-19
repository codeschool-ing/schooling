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

[object Object]
