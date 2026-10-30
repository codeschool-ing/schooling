---
title: Event functions and the CloudEvent
version: 1
---

An HTTP function is called by somebody who wants an answer. **An event function is called because
something happened, and nobody is waiting for what it returns.** A file landed in a bucket, a
message arrived on a topic, a row changed. The function's job is to react, and its only answer is
whether it succeeded.

## The shape of an event

Google delivers every event to a function in one format: a **CloudEvent**, an open specification
from the Cloud Native Computing Foundation. A CloudEvent is a small set of attributes about what
happened plus the data itself:

| attribute | what it says | an example |
|---|---|---|
| `id` | this event, unique for its source | `7f3e-1042` |
| `source` | what produced it | `//shop/web` |
| `type` | what kind of thing happened | `shop.order.created` |
| `specversion` | the version of the specification | `1.0` |
| `time`, `subject` | optional: when, and about what | |

Over HTTP the attributes travel as headers named `ce-` plus the attribute, and the data is the
body. That is the **binary content mode**, and it is the one Google's event delivery uses.

## A function that receives one

**Create `~/gcp/notify` and save this as `main.py` in it:**

```python
# notify/main.py
import functions_framework


@functions_framework.cloud_event
def on_event(event):
    print(f"{event['type']} from {event['source']}, id {event['id']}", flush=True)
    print(f'data: {event.data}', flush=True)
```

The decorator is `cloud_event` this time, and the function takes the event and returns nothing.
`flush=True` makes each line reach the terminal at once; on Google Cloud each line becomes a log
entry. Start it in the second terminal, stopping the quote function first if it is still running:

```
ana@laptop:~/gcp/notify$ functions-framework --target on_event --signature-type cloudevent
```

Nothing on your laptop produces Google's events, so in the first terminal **`curl` stands in for
the sender**: it posts the headers and the body that a delivery carries. It is curl, not Google,
and the event type is one the shop made up:

```
ana@laptop:~/gcp/notify$ curl -s -w ' %{http_code}\n' localhost:8080 -H 'ce-specversion: 1.0' -H 'ce-type: shop.order.created' -H 'ce-source: //shop/web' -H 'ce-id: 7f3e-1042' -H 'content-type: application/json' -d '{"order": 1042, "total_cents": 14900}'
OK 200
ana@laptop:~/gcp/notify$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080 -H 'ce-specversion: 1.0' -H 'ce-type: shop.order.created' -H 'ce-source: //shop/web' -H 'content-type: application/json' -d '{"order": 1043}'
400
```

The first call carried every attribute, and the sender got `OK` and a 200, which is all a sender
ever learns. The second left out `ce-id`, and got a 400 with an HTML page explaining that no
CloudEvent could be read from the request; `-o /dev/null` hides the page and keeps the status. What
the function did shows only in its own terminal:

```
shop.order.created from //shop/web, id 7f3e-1042
data: {'order': 1042, 'total_cents': 14900}
```

The first event arrived whole: the type, the source and the id from the headers, the body parsed
as JSON because the content type said so. **The second request never reached your code**: without
an id it is not a CloudEvent, and the framework refused it before calling the function, which is
why its terminal shows one event and not two. That refusal is
what you want: a function that guessed a missing id would process the same delivery twice the
first time the sender retried, and lesson 18 shows how often a sender retries.

## Success is not raising

For an event function, **returning normally means success and raising an exception means
failure**. The framework turns the first into a 2xx and the second into a 500, and on Google Cloud
that status is what decides whether the event is delivered again. Section 04 of this lesson and
all of lesson 18 rest on that one rule, so it is worth stating plainly: catch an error you have
handled, and let one you have not escape.
