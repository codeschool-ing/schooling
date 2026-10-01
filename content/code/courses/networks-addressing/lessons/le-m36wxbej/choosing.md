---
title: Which model, and what it costs
version: 1
---

Neither model is the modern one. The web, e-mail and DNS are client-server and will stay so; file
distribution and some calls are peer to peer; and most real systems mix the two, with a server for
the part that has to live in one place. **The choice is a trade between control in one place and
dependence on that place.**

| | client-server | peer to peer |
|---|---|---|
| where the service lives | on the servers you run | spread across the peers |
| when one machine fails | the server down is the service down | one peer fewer, the rest carry on |
| cost as users grow | yours: more servers, more bandwidth | shared: each new peer also serves |
| finding the other side | a published address and port | a tracker, a DHT or a server to introduce peers |
| control, logging, updates | in one place | each peer runs its own copy |
| through NAT and firewalls | clients connect out, which is allowed | peers must also receive, which is not |

Each row is something this lesson showed or can now explain. The single point of failure is srv:
three connections and one machine under all of them. The cost row is why BitTorrent exists: a file
that one server sends to a thousand people leaves that server a thousand times, while between peers
each copy that arrives can be passed on. The last row is the refusal r1 gave isp.

For whoever runs the network, the two models also look different on the wire. **Client-server
traffic is predictable**: clients connect out to known ports, and a firewall rule can say "the office
may reach port 443 outside" and mean it. Peer-to-peer traffic comes and goes on ports the program
picks, between machines nobody listed in advance, which is why many companies block it at the edge
and why it is hard to account for where it is allowed.

Most services you will meet are hybrids, and the line they draw is worth reading:

- **a video call** is set up through the provider's servers and sends its media peer to peer when the
  networks allow it, through a relay when they do not;
- **BitTorrent** moves the file between peers and finds the peers through a tracker, which is a
  client-server lookup, or through the DHT;
- **an online game** keeps the state that decides the match on a server, so that no player's machine
  can declare itself the winner, even where players send each other voice directly.

So the question to ask of a service is which part of it has to be in one place. What must be trusted,
logged or kept consistent goes on a server. What is bulky and the same for everyone can be shared
between peers.
