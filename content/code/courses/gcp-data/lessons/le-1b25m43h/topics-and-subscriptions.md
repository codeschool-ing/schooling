---
title: A topic, and a subscription for each reader
version: 1
---

**A Pub/Sub topic is not a queue, and it keeps nothing for anybody.** A publisher sends a message to
a topic; the topic hands a copy to every **subscription** attached to it, and the subscription is
where the message waits until a reader says it has dealt with it. Two services that need the same
events each get a subscription of their own, and each sees every message, at its own pace, with its
own record of what it has finished. One service running on several machines shares a single
subscription, and Pub/Sub spreads the messages across the machines. That is the whole model, and
every setting in this lesson belongs to one of the two halves.

Quitanda's app sends events as customers use it: a product viewed, a cart filled, a payment made.
Two services read them. **Billing** needs the payments and nothing else, within seconds, because a
payment that is not recorded is an order that is not packed. **Analytics** wants everything, and
feeds the warehouse of lessons 13 to 18. One topic, two subscriptions.

## The emulator, in a terminal of its own

Google ships a Pub/Sub emulator as a component of the command line, and lesson 1 installed it. Open
a terminal for it and start it:

```sh
cd ~/gcp
export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud beta emulators pubsub start --project=planner-dev --host-port=localhost:8085
```

It is a Java program, takes a few seconds to start, and prints a few lines for every request it
answers. Leave it running. **It keeps everything in memory**, so `Ctrl+C` empties it, and this
lesson starts from an empty one. You type into the terminal from lesson 1, with the lines of "Every
time you open a terminal" already in it: `CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB` sends `gcloud
pubsub` to port 8085, and `PUBSUB_EMULATOR_HOST` does the same for the Python library.

## One topic, two subscriptions

```
ana@laptop:~/gcp$ gcloud pubsub topics create app-events
Created topic [projects/planner-dev/topics/app-events].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create billing --topic=app-events --message-filter='attributes.type = "payment"'
Created subscription [projects/planner-dev/subscriptions/billing].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create analytics --topic=app-events
Created subscription [projects/planner-dev/subscriptions/analytics].
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe analytics
ackDeadlineSeconds: 10
messageRetentionDuration: 604800s
name: projects/planner-dev/subscriptions/analytics
pushConfig: {}
topic: projects/planner-dev/topics/app-events
```

**Every name is a path inside the project**, `projects/planner-dev/topics/app-events`, and that is
how the emulator accepted `planner-dev` with no account behind it. The description holds the two
defaults this lesson and the next one turn on. `ackDeadlineSeconds: 10` is how long a reader has to
acknowledge a message before Pub/Sub gives it to somebody again, which is lesson 20's subject.
`messageRetentionDuration: 604800s` is seven days, how long an unacknowledged message waits in the
subscription before it is thrown away. `pushConfig: {}` says nothing is pushed: this is a **pull**
subscription, where the reader asks.

The events come from a short program. Save it as `~/gcp/events.py` with the button on the block:

```schooling-example
{"language": "python", "file": "events.py", "parts": [{"code": "import json\n\nfrom google.cloud import pubsub_v1\n\npublisher = pubsub_v1.PublisherClient()\ntopic = publisher.topic_path('planner-dev', 'app-events')\n\n", "note": "`PublisherClient` finds the emulator through `PUBSUB_EMULATOR_HOST`, which the terminal exported, and sends no credentials to it. `topic_path` only builds the name `projects/planner-dev/topics/app-events`; it asks the server nothing."}, {"code": "EVENTS = [\n    ('c-17', 'view', {'product': 'banana-prata'}),\n    ('c-02', 'view', {'product': 'tomate'}),\n    ('c-17', 'add_to_cart', {'product': 'banana-prata', 'qty': 6}),\n    ('c-17', 'payment', {'order_id': 'o-301', 'cents': 4590}),\n    ('c-05', 'search', {'text': 'manga'}),\n    ('c-02', 'add_to_cart', {'product': 'tomate', 'qty': 2}),\n    ('c-02', 'payment', {'order_id': 'o-302', 'cents': 12800}),\n    ('c-05', 'view', {'product': 'manga-palmer'}),\n]\n\n", "note": "Eight events from Quitanda's app: what three customers looked at, put in a cart and paid for. Two of them are payments, which is what the billing service cares about."}, {"code": "futures = []\nfor customer, kind, body in EVENTS:\n    data = json.dumps(body).encode()\n    futures.append(publisher.publish(topic, data, type=kind, customer_id=customer))\n\n", "note": "**The body is bytes and the attributes are strings.** Pub/Sub never looks inside `data`; the keyword arguments become attributes, which it does read, and a filter can select on them. `publish` returns at once with a future, because the client gathers messages into batches before sending them."}, {"code": "for (customer, kind, _), future in zip(EVENTS, futures):\n    print(f'id {future.result():>3}  {kind:<12} {customer}')\n", "note": "`result()` waits for the server's answer, which is the **message id** it assigned. A message is published once that id comes back, and not before."}]}
```

```
ana@laptop:~/gcp$ python3 events.py
id   1  view         c-17
id   2  view         c-02
id   3  add_to_cart  c-17
id   4  payment      c-17
id   5  search       c-05
id   6  add_to_cart  c-02
id   7  payment      c-02
id   8  view         c-05
```

**The emulator numbers its messages 1, 2, 3, and Google does not.** On the real service a message id
is a long string of digits, unique within the topic, and nothing about it is in order. Code that
sorts by message id, or reads one as a count, works here and nowhere else.

Now each subscription is read once. `--auto-ack` acknowledges what it pulls, and `--format` keeps
three columns of the wide table `gcloud` prints by default:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull analytics --auto-ack --limit=20 --format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,message.attributes.customer_id:label=CUSTOMER)'
ID  TYPE         CUSTOMER
1   view         c-17
2   view         c-02
3   add_to_cart  c-17
4   payment      c-17
5   search       c-05
6   add_to_cart  c-02
7   payment      c-02
8   view         c-05
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull billing --auto-ack --limit=20 --format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,message.attributes.customer_id:label=CUSTOMER)'
ID  TYPE     CUSTOMER
4   payment  c-17
7   payment  c-02
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull analytics --auto-ack --limit=20
Listed 0 items.
```

**One publish, two deliveries.** `analytics` received all eight events and `billing` received the
two payments, the same messages with the same ids 4 and 7. Acknowledging them in `analytics` removed
them from `analytics` only, which is why the third pull came back empty while the payments had
already left `billing` on their own account. Neither subscription knows the other exists.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"The publisher events.py sends eight messages to the topic app-events. The topic gives a copy to each of two subscriptions. billing has the filter attributes.type = &quot;payment&quot; and receives ids 4 and 7; analytics has no filter and receives ids 1 to 8. The billing service reads billing and the analytics job reads analytics, and acknowledging in one subscription leaves the other untouched.\" data-fig=\"l19-fanout\"><rect x=\"20.0\" y=\"95.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.py</text><text x=\"75.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">publisher</text><line x1=\"132.0\" y1=\"115.0\" x2=\"182.0\" y2=\"115.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,115.0 182.0,118.0 182.0,112.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"190.0\" y=\"95.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-events</text><text x=\"250.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">topic</text><line x1=\"312.0\" y1=\"108.0\" x2=\"392.9\" y2=\"58.1\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,55.0 394.5,60.7 391.3,55.6\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"312.0\" y1=\"122.0\" x2=\"392.9\" y2=\"171.9\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,175.0 391.3,174.4 394.5,169.3\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"400.0\" y=\"30.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">billing</text><text x=\"470.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ids 4, 7</text><text x=\"470.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">attributes.type = &quot;payment&quot;</text><rect x=\"400.0\" y=\"150.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">analytics</text><text x=\"470.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ids 1 to 8</text><line x1=\"542.0\" y1=\"55.0\" x2=\"582.0\" y2=\"55.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"588.0,55.0 582.0,58.0 582.0,52.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"542.0\" y1=\"175.0\" x2=\"582.0\" y2=\"175.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"588.0,175.0 582.0,178.0 582.0,172.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"590.0\" y=\"35.0\" width=\"115.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">billing service</text><rect x=\"590.0\" y=\"155.0\" width=\"115.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">analytics job</text><text x=\"470.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">two subscriptions</text><text x=\"470.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">each keeps its own copy until acked</text><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">acking in one subscription leaves the other untouched</text></svg>", "caption": "One topic, one copy per subscription, and a filter deciding what a subscription is given."}
```

## A filter decides what a subscription is given

`billing` was created with `--message-filter='attributes.type = "payment"'`, and the six events that
were not payments never reached it. **A filter reads attributes, never the body.** Pub/Sub does not
parse `data`, so the publisher has to put whatever a reader might select on into the attributes,
which is why `events.py` sends `type` and `customer_id` there. The language is small: `=` and `!=`
on an attribute, `:` for "has this attribute", `hasPrefix()`, and `AND`, `OR` and `NOT` to combine
them. `attributes.type = "payment" OR attributes.type = "refund"` is a filter billing might grow
into.

**A filter is written when the subscription is created.** `gcloud pubsub subscriptions update` has
no flag for it, and the emulator refuses the API call outright, in a message that names itself:
"Updating the filter field is currently unsupported in the Pub/Sub Emulator". Changing what billing
reads means a new subscription and a cut-over from the old one. And a message a filter turns away
is not free: Google's pricing page says Pub/Sub acknowledges it automatically and still charges the
delivery, which the last section of this lesson puts a number on.

## A subscription starts when it is created

A fraud check, added a week after launch, wants the app's events too:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions create fraud --topic=app-events
Created subscription [projects/planner-dev/subscriptions/fraud].
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull fraud --auto-ack --limit=20
Listed 0 items.
ana@laptop:~/gcp$ gcloud pubsub subscriptions delete fraud
Deleted subscription [projects/planner-dev/subscriptions/fraud].
```

**A new subscription receives what is published after it exists, and nothing from before.** The
eight events were already delivered to the two subscriptions that existed then, and the topic itself
kept none of them, so there was nothing to give `fraud`. A message published to a topic with no
subscription at all is accepted, given an id, and kept by nobody. The fourth section shows the
setting that changes this, topic retention, and the emulator's own reading of it is in the fifth.
`fraud` is deleted, because a subscription nobody reads keeps collecting messages for seven days and
then throws them away, and on the real service, Google documents, one that nobody reads for 31 days
is deleted by itself unless its expiration is set to `never`.
