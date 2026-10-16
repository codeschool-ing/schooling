---
title: Charged twice
version: 1
---

Ask for one payment, order `q-1` for 3,290 cents, and process it with the naive consumer, which keeps
no record of what it has handled, told to crash after charging and before acknowledging:

```
ana@vm:~/lab/delivery$ $R publish.py q-1 3290
confirmed by the broker: q-1
ana@vm:~/lab/delivery$ $R pay.py --naive --crash-after-charge
charged q-1: 3290 cents (redelivered: False)
crashing before the acknowledgement
```

The charge was committed, `redelivered: False` because this was the first delivery, and then the
process died. **RabbitMQ never received the acknowledgement**, so as far as the broker knows, the
message was never handled. It is still in the queue, marked as delivered once. Start the naive
consumer again, this time without the crash:

```
ana@vm:~/lab/delivery$ $R pay.py --naive
charged q-1: 3290 cents (redelivered: True)
ana@vm:~/lab/delivery$ $R pay.py --list
charged q-1 3290
charged q-1 3290
```

The same message came back, `redelivered: True`, and it was charged again. The list of charges has
**`q-1` twice: one customer, one order, 6,580 cents taken for a 3,290-cent basket.**

Every piece did its job. The broker kept a message nobody had acknowledged, which is exactly what at
least once promises. The consumer charged every message it was given. The duplicate is a property of
the combination, and the crash only had to land in the few microseconds between `commit` and
`basic_ack`. In production, with thousands of messages an hour and a deploy that stops consumers every
afternoon, that window is hit regularly.

## What the redelivered flag is not

RabbitMQ marks a message `redelivered` when it has been handed out before, and it is tempting to treat
that as "skip this one". **It is a hint, not an answer**: the flag is also set when the first consumer
crashed *before* doing the work, in which case skipping it loses the payment. The flag cannot tell the
two apart, because the broker cannot see the consumer's database. Only the consumer can.
