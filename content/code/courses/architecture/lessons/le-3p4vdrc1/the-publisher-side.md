---
title: The publisher's side: confirms and returns
version: 1
---

Everything so far assumed the message reached the broker. A publisher has two ways to lose one before
any consumer is involved, and lesson 6 showed one of them happening: **a message published to an
exchange with no matching binding is dropped**, and by default nobody is told.

The other is the broker failing between receiving a message and storing it. A plain `basic_publish`
writes to a socket and returns; if the broker crashes a moment later, the publisher has already moved
on.

`publish.py` turns on two features that close both gaps:

| feature | what the publisher learns |
| --- | --- |
| **publisher confirms**, `confirm_delivery()` | the broker has taken responsibility for the message: stored in every queue it was routed to, on disk for a durable queue and a persistent message |
| **mandatory**, `mandatory=True` | the message matched no queue, and the broker is handing it back instead of dropping it |

With both, the client library waits for the broker's answer to each publish. A payment published with
the right key is confirmed; one published with a key nothing is bound to comes back as an error the
script can act on:

```
ana@vm:~/lab/delivery$ $R publish.py q-3 990 refunds
returned by the broker, no queue for key 'refunds': q-3
```

`q-3` was sent with the routing key `refunds`, which no queue is bound to on the `payments` exchange,
and the broker returned it. **The publisher now knows**, and can log it, alert, or store it to try
later, rather than believing a refund was on its way.

## What confirms cost

A confirm is a round trip per message, or per batch when the library confirms in batches, so a
confirmed publish is slower than an unconfirmed one. That is usually the right trade for anything that
matters, and it is still not enough on its own: confirms tell the publisher whether the broker has the
message, and nothing about whether the publisher's own database committed the change the message
announces. That gap is the subject of the next section.
