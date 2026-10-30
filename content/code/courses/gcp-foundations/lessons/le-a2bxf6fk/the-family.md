---
title: The family of load balancers
version: 1
---

**Google Cloud has one load-balancing product and about a dozen load balancers**, and the names are the
hardest part. They sort along three questions, and every load balancer is one answer to each:

1. **What does it understand?** An **Application Load Balancer** reads HTTP and HTTPS: hosts, paths, headers,
   cookies. A **Network Load Balancer** sees TCP and UDP connections and nothing inside them.
2. **Who reaches it?** **External** ones have an address on the internet. **Internal** ones have an address
   inside a VPC network, for traffic that never leaves it.
3. **Where does it live?** **Global** ones have one address served from Google's edge all over the world.
   **Regional** ones live in one region, with an address there.

And one more for Network Load Balancers: **proxy** or **passthrough**. A proxy load balancer ends the
client's connection and opens a new one to the backend. A passthrough one hands the client's own packets to
the backend, which therefore sees the client's real address and answers it directly.

| | external | internal |
|---|---|---|
| **Application**, global | the planner's website: one address, served from the edge, TLS ended there | cross-region internal, for services several regions call |
| **Application**, regional | one region only, for data that must stay in it | services inside one region's network |
| **Network, proxy** | TCP with TLS ended by Google, for protocols that are not HTTP | regional, inside a network |
| **Network, passthrough** | regional, the client's packets untouched: games, VoIP, anything UDP | regional, the internal entry to a set of machines |

## What a global external load balancer buys

The planner's website uses the top-left one, and three things about it are worth knowing before the next
section builds it:

- **One address for the whole world.** The same IP is announced from Google's edge locations everywhere; a
  customer in Lisbon reaches an edge near Lisbon, and Google's own network carries the request to wherever
  the backends are. This is *anycast*, and it is why there is no DNS trick to route people to their
  nearest region.
- **TLS ends at the edge.** The certificate lives on the load balancer, the customer's handshake happens a
  few milliseconds away, and the backends receive plain HTTP over Google's network, or HTTPS again if the
  backend service is set to it.
- **It is where the edge features attach.** Cloud CDN caches responses at the edge, and Cloud Armor filters
  requests before they reach a backend. Both are settings of the backend service, the next section's
  fourth link.

None of the load balancers are machines the customer runs. The proxies are Google's, the health checks
come from Google's ranges `35.191.0.0/16` and `130.211.0.0/22`, and the only thing the planner's network
needs to know about them is lesson 16's rule that lets those ranges reach the backends.
