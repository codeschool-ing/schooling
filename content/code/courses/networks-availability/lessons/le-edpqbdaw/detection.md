---
title: Failover is noticing, then switching
version: 1
---

The picture most people carry of failover is a switch that flips the instant something breaks. **Nothing
knows that a machine has failed.** A dead machine sends no message saying so; the others have to notice
that it has stopped saying something. So every failover is built on a **heartbeat**, a small message
sent at a fixed interval, and on a rule for how many may go missing before the sender is declared dead.

The time between the failure and the service coming back is therefore made of pieces, one after
another, and each has its own cause:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A time axis from 0 to 6 seconds. Heartbeats arrive at 0, 1 and 2 seconds. The master fails at about 2.4 seconds, and the heartbeats due at 3, 4 and 5 seconds never come. The backup takes over at about 5.6 seconds, three intervals plus a skew after the last heartbeat it heard, and traffic flows again a moment later. A bracket from the failure to that moment marks what the client lives through.\"><defs><marker id=\"ha-tl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40 120 L700 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ha-tl-ah)\"></path><text x=\"700\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><text x=\"50\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"140\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">1 s</text><text x=\"230\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2 s</text><text x=\"320\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">3 s</text><text x=\"410\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">4 s</text><text x=\"500\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">5 s</text><text x=\"590\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">6 s</text><circle cx=\"50\" cy=\"120\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"140\" cy=\"120\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"230\" cy=\"120\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"320\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><circle cx=\"410\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><circle cx=\"500\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><path d=\"M266.0 50 L266.0 112\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"266.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the master fails</text><path d=\"M554.9000000000001 50 L554.9000000000001 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"554.9000000000001\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the backup takes over</text><path d=\"M590.0 72 L590.0 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"596.0\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">traffic again</text><path d=\"M230 160 L230 166 L554.9000000000001 166 L554.9000000000001 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"392.45000000000005\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">silence long enough: 3 intervals plus a skew</text><path d=\"M266.0 200 L266.0 206 L590.0 206 L590.0 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"428.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">what the client lives through</text><circle cx=\"26\" cy=\"250\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><text x=\"38\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">heartbeat heard</text><circle cx=\"206\" cy=\"250\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><text x=\"218\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">heartbeat that never comes</text></svg>", "caption": "A failover on a clock, with one heartbeat a second as in VRRP. The backup counts from the last heartbeat it heard, not from the failure, so the same timers give a shorter or longer outage depending on when in the interval the master died."}
```

| piece | what sets its length | in lesson 15 |
|---|---|---|
| detection | the heartbeat interval times the misses allowed | an advertisement every second, three missed plus a fraction |
| decision | an election, a vote, a script | the backup with the highest priority wins |
| switching | moving an address and announcing where it went | the new router answers for `192.168.10.1` |
| clients catching up | caches, TCP retransmissions, reconnects | the laptop's ARP entry changes to the new router |

Lesson 15 measured all four together with a ping every 0.2 seconds: **15 replies missing, 3.26 seconds
from the last reply before the failure to the first one after it**. Lesson 16 measured 2.694 seconds for a
balancer whose own health check failed. Neither number is the time to repair anything. Both are the time
it took the machines to agree that something was broken.

## Faster is not free

Shorter timers find a failure sooner. They also find failures that are not there. **A heartbeat lost to
a busy processor or a congested link looks exactly like a dead machine**, and a backup that takes over
after one missing packet will take over on an ordinary afternoon for no reason at all. The same
over-eager rule then hands control back when the next heartbeat arrives, and the pair **flaps**: the
service moves back and forth, and each move costs a few seconds of the very outage it was meant to
prevent.

The defence is hysteresis: asking for more evidence to change state than to stay in it. HAProxy's server
checks in lesson 16 are written `check inter 1s fall 2 rise 2`, which means a check every second, two
failures in a row to mark a server down, and two successes in a row to bring it back. **One failed check changes nothing.** Many systems also wait before handing control back
to a machine that has just recovered, or never hand it back on their own; lesson 15 shows that choice,
called preemption.

The numbers to choose are a trade between two costs. Detection of three seconds is harmless for a router
and an eternity for a stock exchange. Detection of 100 milliseconds is right on a quiet dedicated link and
a source of false alarms on a busy shared one. **Set the timers from the link that carries the
heartbeats, not from how fast you would like the failover to be.**
