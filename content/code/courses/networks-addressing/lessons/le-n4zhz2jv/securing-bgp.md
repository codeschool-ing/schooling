---
title: Securing BGP: filters, signatures and watching
version: 1
---

**BGP believes what it is told.** Nothing in the protocol itself checks that the AS announcing a prefix
has any right to it. A mistake, or a deliberate false announcement of somebody else's block, travels as far
as the neighbours that do not filter it, and longest-prefix matching from lesson 14 makes a more specific
false announcement win over the true one wherever it is accepted. The defences are layers, each added by
the networks that care, and this section describes them as a network operator applies and checks them.
**None of it was run in the lab**: there is no validator in it, and documentation addresses have no real
records to validate against.

## Filters built from registries

The provider-side filter of the previous section has to come from somewhere. In practice it is built from
**Internet Routing Registries** (IRR), databases where networks publish *route objects* saying which AS
originates which prefix. A provider generates its customers' filters from those objects, so a customer that
announces something it never registered is refused at the first hop. The weakness is that a registry entry
is only as good as whoever wrote it, and old entries are rarely cleaned up.

## RPKI and route origin validation

**RPKI** (*Resource Public Key Infrastructure*) ties address blocks to cryptographic certificates issued down
the same chain that allocates the addresses: from the regional registry to the holder. The holder signs a
**ROA** (*Route Origin Authorisation*): *AS 64500 may originate 203.0.113.0/24, up to a maximum length of
/24*. Software called a validator collects and checks every ROA, and routers ask it about each route they
receive. That is **route origin validation**, and it gives each route one of three states:

| state | meaning |
|---|---|
| **valid** | a ROA covers the prefix, the origin AS matches, and the length is within the maximum |
| **invalid** | a ROA covers the prefix, but the origin AS or the length does not match |
| **not found** | no ROA covers the prefix at all |

The policy most networks that validate apply is simple: **drop invalid, accept the rest**. Every `show ip
bgp` in this lesson printed `RPKI validation codes: V valid, I invalid, N Not found` in its legend and no
code beside any route, because FRR knows the states and this lab gives it no validator to ask.

Two limits are worth knowing. Origin validation checks only the **last AS in the path**, so an announcement
that forges the right origin passes it; work on validating the rest of the path continues. And a ROA with a
maximum length longer than the holder really announces leaves room for a valid-looking more specific, so
**a ROA's maximum length should match what is actually announced**.

## Securing the session and watching the result

- **The session itself** can be protected with TCP authentication between the two routers, and with a TTL
  check that refuses BGP packets that did not come from a directly connected neighbour.
- **`maximum-prefix`**, as in the previous section, limits the damage of a neighbour that suddenly sends
  far more than usual.
- **Monitoring from outside**: public route collectors and looking glasses show how other networks see
  your prefixes, and alerting services warn when your block appears with an origin that is not yours. A
  network that never looks from outside learns about a problem from its customers.

**MANRS** (*Mutually Agreed Norms for Routing Security*) gathers these into a short list networks commit to:
filter what you announce and accept, prevent spoofed source addresses, keep contact details current so
others can reach you during an incident, and publish your routing intentions in an IRR and in RPKI so that
others can filter you. For the company in this lab, that means three checks: a ROA for 203.0.113.0/24 with
origin 64500 and maximum length /24, an outbound filter like `TO-PROVIDER`, and providers that filter what
they accept from it.
