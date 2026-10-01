---
title: 802.11k, v and r, a roam made fast
version: 1
---

A roam has three costs, paid in sequence while the client is between access points.

1. Finding a candidate. Without help the client scans, leaving its channel to listen on each of the
   others in turn. At 5 GHz that can be more than twenty channels.
2. Joining it. Authentication and reassociation frames with the new AP.
3. Keys. The four-way handshake of lesson 8 again. On an 802.1X network, without anything better,
   the whole EAP exchange with the RADIUS server as well, TLS tunnel included.

With a passphrase, the third step is two round trips over the air. With 802.1X it is many round trips, some
of them to a RADIUS server that may be in another building, and **a full 802.1X reauthentication can take
hundreds of milliseconds**. A web page shrugs that off. A voice call does not: a commonly quoted target for
voice is a roam under 50 ms, a rule of thumb from vendors' voice design guides rather than a number in any
standard.

Three amendments to 802.11 attack the three costs, one each:

| amendment | what it adds | which cost it cuts |
|---|---|---|
| 802.11k (2008) | **neighbour reports**: the AP tells the client which APs are nearby and on which channels | finding a candidate: scan three channels instead of twenty |
| 802.11v (2011) | **BSS transition management**: the AP suggests a better AP, or warns that it is about to drop the client | the decision, which comes sooner and better informed |
| 802.11r (2008) | **fast BSS transition**, FT: keys prepared in advance for every AP in a mobility domain | the keys: no new EAP exchange, and the handshake folded into the join |

All three are part of the current 802.11 standard, and all three are **offers**. A client that does not
implement 802.11v ignores the suggestion; one that implements it may still decline. The client decides,
again.

## How 802.11r saves the keys

On the first join, the client does the full authentication once, and from its result a key hierarchy is
derived for the whole **mobility domain**, the set of APs that share it. When the client moves, the new AP
already has, or fetches from its peers or its controller, the key it needs for that client. The key
exchange travels inside the authentication and reassociation frames the client was going to send anyway,
so **the roam costs the join and nothing more**.

Two older mechanisms do part of the same job. **PMK caching**, in the standard since 802.11i, skips the EAP
exchange when a client returns to an AP it used before. **Opportunistic key caching**, which is not in the
standard but is widely implemented, lets the APs of one controller share the PMK so the first visit to a
new AP skips it too. Neither saves the four-way handshake.

## The compatibility trap

802.11r changes what the AP advertises, and **some older clients fail to join a network that advertises
it**, instead of ignoring what they do not understand. Vendors answer with a mixed mode that offers FT to
clients that ask for it and the ordinary join to the rest. Whatever the data sheets say, the test that
counts is the real devices on the real SSID: the barcode scanners, the handsets, the laptop with the
oldest driver.
