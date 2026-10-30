---
title: "Topics, sessions and duplicates"
version: 1
---

When an order is paid, billing needs to know and so does shipping. The first design that comes to
mind is one queue that both of them read. **A queue gives each message to one consumer**, so billing
and shipping would split the orders between them, each seeing about half and neither noticing. What
they need is a **topic**. A sender sends to a topic exactly as it sends to a queue, but nobody
receives from the topic itself: each **subscription** of the topic is a queue of its own that gets a
copy of every message, with its own lock, its own delivery count and its own dead-letter subqueue.
This section uses the topic, the session queue and the duplicate-detecting queue that `Config.json`
declared in the last section; the emulator from there is still running.

## One message, a copy per subscription

The topic is `order-paid`, and it has two subscriptions. `billing` has no rule, which gives it the
default one: a filter that is always true, so it receives everything. `shipping` has a rule named
`physical-only` whose filter is `kind = 'physical'`, because a digital product has nothing to ship.

Ana's publisher puts the kind of each order in an **application property**, a name and value carried
beside the body, because that is what a filter reads; the body is opaque to the broker. Save it as
`~/azure/publish.py`:

```python
# publish.py
import json
import os
import sys

from azure.servicebus import ServiceBusClient, ServiceBusMessage

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client, client.get_topic_sender("order-paid") as sender:
    for arg in sys.argv[1:]:
        order, kind = arg.split(":")
        body = json.dumps({"order": int(order), "kind": kind})
        msg = ServiceBusMessage(body, message_id=f"order-{order}-paid", application_properties={"kind": kind})
        sender.send_messages(msg)
        print(f"published order {order} ({kind})")
```

And a reader that drains one subscription, named on the command line, as `~/azure/read.py`:

```python
# read.py
import os
import sys

from azure.servicebus import ServiceBusClient

subscription = sys.argv[1]
client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client, client.get_subscription_receiver("order-paid", subscription) as receiver:
    for msg in receiver.receive_messages(max_message_count=10, max_wait_time=2):
        print(f"{subscription}: {msg}")
        receiver.complete_message(msg)
```

Two orders are paid, one physical and one digital:

```
ana@laptop:~/azure$ messaging/bin/python publish.py 42:physical 43:digital
published order 42 (physical)
published order 43 (digital)
ana@laptop:~/azure$ messaging/bin/python read.py billing
billing: {"order": 42, "kind": "physical"}
billing: {"order": 43, "kind": "digital"}
ana@laptop:~/azure$ messaging/bin/python read.py shipping
shipping: {"order": 42, "kind": "physical"}
```

**Billing got both and shipping got one.** The broker evaluated the rule when the message arrived and
never put the digital order in `shipping` at all, so no consumer had to receive it and throw it
away. Each subscription was drained separately: completing a message in `billing` did nothing to its
copy in `shipping`.

The filter language is a subset of SQL. It reads application properties by name and the broker's
own properties with the prefix `sys.`, as in `sys.MessageId LIKE 'order-%'`, and it has `AND`, `OR`, `NOT`,
comparisons, `EXISTS` and `LIKE`. A **correlation filter** is the other common kind: a set of
properties that must all be equal, with no expression to evaluate. A subscription with several rules
receives one copy if any of them matches. A rule can also carry an **action** that changes the
copy's properties, and then each matching rule with an action produces a copy of its own; this
lesson uses none.

## Order per key: sessions

A queue hands messages out in roughly the order they arrived, but with several consumers taking from
it, the steps of one order can be handled side by side or out of order: `shipped` processed before
`packed` finished. Service Bus's answer is a **session**. Every message carries a session id, here
the order's. A receiver accepts a whole session at a time and holds an exclusive lock on it, so the
messages of one session go to one receiver, in order, while other receivers take other sessions. The queue `order-steps` was declared with `RequiresSession`. Save this as
`~/azure/steps.py`:

```python
# steps.py
import os

from azure.servicebus import NEXT_AVAILABLE_SESSION, ServiceBusClient, ServiceBusMessage

STEPS = [("order-42", "paid"), ("order-43", "paid"), ("order-42", "packed"),
         ("order-43", "packed"), ("order-42", "shipped")]

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client:
    with client.get_queue_sender("order-steps") as sender:
        for order, step in STEPS:
            sender.send_messages(ServiceBusMessage(step, session_id=order))
    for _ in range(2):
        receiver = client.get_queue_receiver("order-steps", session_id=NEXT_AVAILABLE_SESSION, max_wait_time=2)
        with receiver:
            msgs = receiver.receive_messages(max_message_count=10, max_wait_time=2)
            print(receiver.session.session_id, [str(m) for m in msgs])
            for m in msgs:
                receiver.complete_message(m)
```

The five steps go in interleaved, and each receiver takes whichever session is free next. Which of
the two comes first can differ between runs; the order inside each cannot. The last command sends to
the same queue without a session id:

```
ana@laptop:~/azure$ messaging/bin/python steps.py
order-42 ['paid', 'packed', 'shipped']
order-43 ['paid', 'packed']
ana@laptop:~/azure$ messaging/bin/python -c 'import os; from azure.servicebus import *; c = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"]); c.get_queue_sender("order-steps").send_messages(ServiceBusMessage("paid"))' 2>&1 | grep -o "ServiceBusError: [^.]*\."
ServiceBusError: The SessionId was not set on a message, and it cannot be sent to the entity.
```

**On a session queue, a message without a session id is refused**, and once sessions are on, every
sender and receiver of that queue has to use them. Service Bus defines no start or end for a session:
Microsoft's documentation says a message with the same id a year later belongs to the same one, so
where an order's story ends is the application's to say. The Basic tier has no sessions, and no
duplicate detection either.

## Duplicates the queue drops

A sender that sends, loses the connection before the answer comes back and sends again has put the
same message in the queue twice, and it cannot know that it did. With **duplicate detection** on, the
queue remembers every `MessageId` it has accepted for a window and silently drops a later message with
the same id; the send still reports success. The queue `payments` has a one-minute window. Save this
as `~/azure/pay.py`, which sends the same charge twice and then reads the queue:

```python
# pay.py
import os

from azure.servicebus import ServiceBusClient, ServiceBusMessage

client = ServiceBusClient.from_connection_string(os.environ["SERVICEBUS"])
with client:
    with client.get_queue_sender("payments") as sender:
        for charge in ["charge-42", "charge-42", "charge-43"]:
            sender.send_messages(ServiceBusMessage(charge, message_id=charge))
            print(f"sent {charge}")
    with client.get_queue_receiver("payments", max_wait_time=2) as receiver:
        for msg in receiver.receive_messages(max_message_count=10, max_wait_time=2):
            print(f"received {msg.message_id}")
            receiver.complete_message(msg)
```

```
ana@laptop:~/azure$ messaging/bin/python pay.py
sent charge-42
sent charge-42
sent charge-43
received charge-42
received charge-43
```

Three sends were accepted, and two messages arrived. **Only the `MessageId` is compared**, never the
body, which is why it has to come from the business, `charge-42`, rather than be a random id the
library makes up on each send: a retry would get a new one, and nothing would match. The window
defaults to ten minutes and can be set from 20 seconds to 7 days; a longer one costs throughput,
because every new id is checked against all the ids remembered.

Duplicate detection covers the sender's half and nothing else. A consumer that charges the card and
then crashes before completing the message gets it again when the lock runs out, with the same id,
and the queue has nothing to drop: the message was only ever sent once. That half belongs to the
consumer, and the last section of this lesson comes back to it.

Stop the emulator now. The Event Hubs emulator uses the same port, and `down` removes both containers
and the network Compose made:

```
ana@laptop:~/azure$ docker compose -f servicebus/compose.yaml down
 Container servicebus-emulator Stopping 
 Container servicebus-emulator Stopped 
 Container servicebus-emulator Removing 
 Container servicebus-emulator Removed 
 Container mssql Stopping 
 Container mssql Stopped 
 Container mssql Removing 
 Container mssql Removed 
 Network servicebus_default Removing 
 Network servicebus_default Removed 
```
