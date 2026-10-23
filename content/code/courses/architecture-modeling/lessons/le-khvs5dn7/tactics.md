---
title: Tactics: the moves that serve one quality
version: 1
---

**A tactic is a design decision that influences one quality attribute's response**: a known move,
smaller than a pattern, with a known effect and a known cost. Len Bass, Paul Clements and Rick Kazman
catalogued them in *Software Architecture in Practice*, and the catalogue is the bridge between a
scenario and a design: given what the scenario demands, which moves are available?

## A few from the catalogue

| attribute | tactic | what it does | the cost it usually brings |
| --- | --- | --- | --- |
| availability | **redundancy** | a second copy takes over when the first fails | more to run, and keeping the copies in step |
| availability | **local fallback** | a degraded answer from local data when the remote one is unreachable | the local data may be stale |
| performance | **caching** | keep a computed answer close to where it is needed | staleness, and memory |
| performance | **introduce concurrency** | do independent work at the same time | complexity, ordering problems |
| performance | **limit demand** | queue, throttle or shed requests above capacity | some requests wait or are refused |
| modifiability | **use an intermediary** | put an interface or adapter between two parts | one more hop and one more thing to name |
| modifiability | **encapsulate** | hide a decision behind an interface | the interface has to be designed well |
| security | **audit** | record who did what, immutably | storage, and protecting the log itself |

The cost column is the reason the catalogue matters: **every tactic pays for one quality with
another**, and naming the tactic names the payment.

## From scenario to tactics at Carcará

- **QS-02, offline boarding**, uses *local fallback*: each phone holds the trip's ticket list. Its
  cost is staleness: a ticket sold after the last sync is not on the list. The design adds a second
  tactic for that case, an **online check** when signal exists, and a rule for when it does not: the
  driver accepts a ticket the app does not know if the passenger shows the purchase e-mail, and the
  scan is uploaded later for checking.
- **QS-01, peak purchases**, uses *limit demand* at the edge, a queue in front of the purchase when
  load passes 2,500 a minute, and *caching* of trip search results for thirty seconds.
- **QS-04, a new payment method in ten days**, uses *use an intermediary*: the payment adapter and
  its `PaymentPort` interface from lesson 2. A new method is a new adapter behind the same port.

## The trade-offs, made visible

Writing the tactics down shows where qualities collide, which is the conversation `architecture-role`
lesson 13 called the centre of the architect's job. Offline boarding and fast refusal of cancelled
tickets are the example from the start of this lesson:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-tradeoff\" aria-label=\"A chart with two lines against the sync interval of the drivers' phones, from 5 to 60 minutes. The longest a cancelled ticket can still be accepted at the door rises in a straight line with the interval, from 5 to 60 minutes. The number of syncs per phone in a ten-hour day falls as the interval grows: 120 at 5 minutes, 40 at 15, 10 at 60. Celeste's choice, 15 minutes, is marked.\"><path d=\"M80.0 250.0 L640.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M640.0 250.0 L640.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">5</text><path d=\"M181.8 250.0 L181.8 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"181.8\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">15</text><path d=\"M334.5 250.0 L334.5 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"334.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">30</text><path d=\"M487.3 250.0 L487.3 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"487.3\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">45</text><path d=\"M640.0 250.0 L640.0 255.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">60</text><text x=\"360.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sync interval, minutes</text><text x=\"72.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">0</text><text x=\"72.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">20</text><text x=\"72.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">40</text><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">60</text><text x=\"648.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">0</text><text x=\"648.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">40</text><text x=\"648.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">80</text><text x=\"648.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">120</text><path d=\"M80.0 232.5 L640.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M80.0 40.0 L90.2 75.0 L100.4 100.0 L110.5 118.8 L120.7 133.3 L130.9 145.0 L141.1 154.5 L151.3 162.5 L161.5 169.2 L171.6 175.0 L181.8 180.0 L192.0 184.4 L202.2 188.2 L212.4 191.7 L222.5 194.7 L232.7 197.5 L242.9 200.0 L253.1 202.3 L263.3 204.3 L273.5 206.2 L283.6 208.0 L293.8 209.6 L304.0 211.1 L314.2 212.5 L324.4 213.8 L334.5 215.0 L344.7 216.1 L354.9 217.2 L365.1 218.2 L375.3 219.1 L385.5 220.0 L395.6 220.8 L405.8 221.6 L416.0 222.4 L426.2 223.1 L436.4 223.8 L446.5 224.4 L456.7 225.0 L466.9 225.6 L477.1 226.1 L487.3 226.7 L497.5 227.2 L507.6 227.7 L517.8 228.1 L528.0 228.6 L538.2 229.0 L548.4 229.4 L558.5 229.8 L568.7 230.2 L578.9 230.6 L589.1 230.9 L599.3 231.2 L609.5 231.6 L619.6 231.9 L629.8 232.2 L640.0 232.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M181.8 250.0 L181.8 40.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"181.8\" cy=\"197.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"181.8\" cy=\"180.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"187.8\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Celeste: 15 min</text><text x=\"456.7\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cancelled ticket still accepted, worst case (min)</text><text x=\"334.5\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">syncs per phone, 10-hour day</text></svg>", "caption": "Both lines are arithmetic, not measurement: the worst case equals the interval, and a ten-hour day holds 600 minutes divided by it. Where to sit on them is a business decision."}
```

The more often the phones sync, the sooner a cancelled ticket is refused, and the more mobile data
and battery the drivers' phones spend. Celeste chose **sync every 15 minutes while the bus is in a
station or has signal**, accepting that a ticket cancelled in the last quarter of an hour may still
be accepted at the door. That choice is a decision record, and the scenario that it trades against
is named in it.
