---
title: Retries, and the same event twice
version: 1
---

A webhook is one HTTP request, and requests fail: the receiver is restarting, the network drops a
packet, the answer takes too long. **So senders retry.** The lab's router tries up to four times,
waiting 1, 2 and 4 seconds between attempts, whenever it does not get a 2xx. When nobody is
listening at all, bringing the link back up produces this:

```
ana@ctl:~$ python link.py edge1 eth2 up
edge1 eth2: up
ana@ctl:~$ python deliveries.py
edge1-1790682864-1 attempt 1 at 08:54:45 -> 204
edge1-1790682864-2 attempt 1 at 08:54:46 -> None
edge1-1790682864-2 attempt 2 at 08:54:47 -> None
edge1-1790682864-2 attempt 3 at 08:54:49 -> None
edge1-1790682864-2 attempt 4 at 08:54:53 -> None
```

`deliveries.py` reads the router's own log of what it tried:

```schooling-example
{
  "language": "python",
  "file": "deliveries.py",
  "parts": [
    {
      "code": "from devapi import Device\n"
    },
    {
      "code": "edge1 = Device(\"edge1\")\nhook = edge1.request(\"GET\", \"/webhooks\")[\"results\"][0]\nfor d in edge1.all(f\"/webhooks/{hook['id']}/deliveries\"):\n    print(d[\"delivery\"], \"attempt\", d[\"attempt\"], \"at\", d[\"time\"][11:19], \"->\", d[\"status\"])",
      "note": "**The sender's own record of what it tried**: one line per attempt, with the status the receiver answered, or `None` when nothing answered at all."
    }
  ]
}
```

The first delivery, the `down` event, was answered `204`. The second, the `up` event, was tried
four times at growing intervals and never answered, `None`, and then **the router gave up**. That
event is lost: nothing will ever tell the receiver the link came back. A sender that retries
forever would fill its memory. One that gives up means **a receiver that was down for a minute has
a hole in what it knows**, and something else, a periodic check or a subscription to state as in
lesson 4, has to fill it.

Retries have a second consequence, and it is the one that causes incidents. **A retry can deliver
an event the receiver already acted on.** That happens whenever the receiver did the work but the
answer did not reach the sender: a timeout, a crash just after the database write, or, in this demo,
a receiver told to answer `500` once on purpose after doing its work:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"One event, delivered twice and acted on once. edge1 posts interface.up, signed, to the receiver on ctl. The receiver checks the signature, resolves the ticket on the service desk, and answers 500. After one second edge1 sends the same delivery id again; the receiver recognises it, does nothing, and answers 204, and edge1 stops.\"><defs><marker id=\"wh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge1</text><path d=\"M110 36 L110 346\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">receiver on ctl</text><path d=\"M360 36 L360 346\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">service desk</text><path d=\"M610 36 L610 346\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M112 60 L356 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST interface.up  #4</text><text x=\"372\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signature checked</text><path d=\"M362 116 L606 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"484\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resolve INC-1001</text><path d=\"M606 150 L364 164\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><path d=\"M356 188 L114 202\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">500</text><text x=\"100\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wait 1 s</text><path d=\"M112 256 L356 272\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the same delivery #4</text><text x=\"372\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">already handled: nothing to do</text><path d=\"M356 316 L114 330\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">204</text></svg>", "caption": "The receiver acted on the first delivery and failed to say so. The delivery id is what makes the second one harmless."}
```

```
ana@ctl:~$ python link.py edge1 eth2 up
edge1 eth2: up
```

```
ana@ctl:~$ python receiver.py 2 --fail-once
edge1-1790682864-4: interface.up edge1 eth2
   INC-1001: resolved
edge1-1790682864-4: answering 500 on purpose
edge1-1790682864-4: already handled, ignored
```

```
ana@ctl:~$ python deliveries.py | tail -2
edge1-1790682864-4 attempt 1 at 08:55:02 -> 500
edge1-1790682864-4 attempt 2 at 08:55:03 -> 204
```

The first attempt resolved the ticket and was answered `500`. One second later the router sent
**the same delivery**, with the same id, and the receiver found it in `SEEN` and did nothing. Without
that check the ticket would have been resolved twice, or, for a `down` event, opened twice.

**A receiver must be idempotent: the same delivery twice has the effect of once.** The delivery id
is what makes it possible, and a receiver that keeps its `SEEN` set in memory, as this one does,
loses it on restart. A production receiver keeps it in a database with the date, and forgets ids
after the sender's retry window has passed.
