---
title: Two places to put it
version: 1
---

**Azure's WAF is a policy you attach to something that already receives HTTP**, and there are two such
things:

| | **Front Door** | **Application Gateway** |
|---|---|---|
| where it runs | Microsoft's global edge, close to the client | one region, inside your virtual network |
| what it fronts | anything with a public address: App Service, a storage website, another region | backends in the virtual network, private ones included |
| what it adds | caching, global load balancing, TLS at the edge | layer 7 routing inside a region, private backends |
| WAF policy type | `FrontDoorWebApplicationFirewallPolicies` | `ApplicationGatewayWebApplicationFirewallPolicies` |

The shop's customers reach it through **Front Door Premium**, which sends traffic to App Service in
`brazilsouth`; the WAF runs there, at the edge, and an attack is stopped before it crosses into the
region. Application Gateway is the answer where the backends must stay private and the edge is not
Azure's, and some architectures run both: Front Door at the edge for global traffic, Application Gateway
in the region for the internal routing.

Both policy types share the important parts: **managed rule sets**, maintained by Microsoft, that match
known attack patterns such as SQL injection and cross-site scripting; **custom rules**, written by you,
evaluated first; and a **mode**, *Detection* or *Prevention*. Neither was deployed for this course: there
is no Front Door and no gateway. The policies were written and compiled, which is the next two sections.

One thing the WAF does not do: **it does not fix the application.** A rule that blocks a SQL injection
pattern buys time; the parameterised query in the code is the fix. A WAF in front of vulnerable code is
a guard at a door with a broken lock.
