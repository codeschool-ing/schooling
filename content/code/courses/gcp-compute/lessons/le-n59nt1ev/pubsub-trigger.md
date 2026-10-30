---
title: A Pub/Sub trigger, end to end
version: 1
---

A Pub/Sub trigger sounds as though the function listens to the topic. **It does not: Pub/Sub pushes
each message to the function over HTTP**, through a push subscription that Google creates for you
when you deploy a function with that trigger. The function is an HTTP endpoint the whole time, and
the trigger is a subscription pointed at it. Once that is clear, the whole chain runs on your
laptop with Google's own Pub/Sub emulator.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A message travels left to right. The publisher, pubsub.py, sends data and attributes to the topic orders. The topic keeps one copy for each subscription. The push subscription orders-fn sends its copy as an HTTP POST to the endpoint. There, the Functions Framework turns the push body into a CloudEvent and calls on_order with it. The topic and the subscription sit inside the Pub/Sub emulator.\"><defs><marker id=\"f17chain-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"178\" y=\"22\" width=\"336\" height=\"188\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"346\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the Pub/Sub emulator</text><rect x=\"12\" y=\"60\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">publisher</text><text x=\"82\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">pubsub.py</text><text x=\"82\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">data and</text><text x=\"82\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">attributes</text><rect x=\"190\" y=\"60\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">topic</text><text x=\"260\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">orders</text><text x=\"260\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one copy for each</text><text x=\"260\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">subscription</text><rect x=\"362\" y=\"60\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"432\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">push subscription</text><text x=\"432\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">orders-fn</text><text x=\"432\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a POST to the</text><text x=\"432\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">endpoint</text><rect x=\"540\" y=\"60\" width=\"168\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"624\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Functions Framework</text><rect x=\"552\" y=\"98\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"624\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the push body</text><text x=\"624\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">becomes a CloudEvent</text><rect x=\"552\" y=\"148\" width=\"144\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"624\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">on_order(event)</text><path d=\"M152 125 L188 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f17chain-phosphor)\"></path><path d=\"M330 125 L360 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f17chain-phosphor)\"></path><path d=\"M502 125 L538 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f17chain-phosphor)\"></path></svg>", "caption": "Nothing listens to the topic. The subscription pushes each message to the function over HTTP, and the framework turns the push into the CloudEvent your code receives."}
```

## Starting the emulator

The emulator is in the image you pulled in lesson 1. **Start it in the background**, on your
machine's own network so that it can reach a function on `localhost`:

```
ana@laptop:~/gcp$ docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev
3bdd3d2bec700689b7c8152f38c65b2ac598aa1666add1bb03f8cb03a94dafb5
```

The long hexadecimal line is the container's id, and yours will differ. The emulator takes a few
seconds to start; `docker logs pubsub` shows `Server started, listening on 8085` once it is ready.
It keeps everything in memory, so `docker rm -f pubsub` empties it, which is how every lesson that
uses it starts.

## Talking to it

gcloud refuses every `pubsub` command without an account, emulator or not, so the course uses a
short program built on Google's client library instead. **Save it as `~/gcp/pubsub.py`**; lessons
18 and 20 use it too:

```schooling-example
{"language": "python", "file": "pubsub.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"A small command line for the Pub/Sub emulator, for lessons 17, 18 and 20.\n\ngcloud refuses every Pub/Sub command without an account, emulator or not, so\nthis does the same few things with Google's own client library, which talks\nto whatever PUBSUB_EMULATOR_HOST names and needs no credentials there.\n\n    python3 pubsub.py topic NAME\n    python3 pubsub.py push NAME TOPIC URL     # a push subscription\n    python3 pubsub.py sub NAME TOPIC          # a pull subscription\n    python3 pubsub.py publish TOPIC DATA [KEY=VALUE ...]\n    python3 pubsub.py pull NAME               # print and acknowledge\n\"\"\"\n", "note": "The docstring says why this exists: gcloud will not talk to the emulator without an account, and Google's client library will, with no credentials at all."}, {"code": "import os\nimport sys\n\nfrom google.cloud import pubsub_v1\n\nPROJECT = os.environ.get('CLOUDSDK_CORE_PROJECT', 'planner-dev')\n\n", "note": "Google's Pub/Sub library, installed in lesson 1. The project comes from the variable every terminal of the course sets."}, {"code": "def main():\n    if 'PUBSUB_EMULATOR_HOST' not in os.environ:\n        sys.exit('PUBSUB_EMULATOR_HOST is not set: this would talk to the real Pub/Sub')\n    cmd, args = sys.argv[1], sys.argv[2:]\n    pub, sub = pubsub_v1.PublisherClient(), pubsub_v1.SubscriberClient()\n    topic = lambda name: pub.topic_path(PROJECT, name)\n", "note": "The guard. Without `PUBSUB_EMULATOR_HOST` the same library would go to the real Pub/Sub, so the program refuses to run at all."}, {"code": "    if cmd == 'topic':\n        print(pub.create_topic(name=topic(args[0])).name)\n    elif cmd in ('push', 'sub'):\n        push = {'push_endpoint': args[2]} if cmd == 'push' else None\n        s = sub.create_subscription(name=sub.subscription_path(PROJECT, args[0]),\n                                    topic=topic(args[1]), push_config=push)\n        print(s.name, '->', s.push_config.push_endpoint or 'pull')\n", "note": "A topic is a name. A subscription is a name, a topic and either a push endpoint or nothing, which makes it a pull subscription."}, {"code": "    elif cmd == 'publish':\n        attrs = dict(a.split('=', 1) for a in args[2:])\n        print('message', pub.publish(topic(args[0]), args[1].encode(), **attrs).result())\n", "note": "Publishing: the data is bytes, and anything after it in the form `KEY=VALUE` becomes an attribute of the message. `.result()` waits for the message id."}, {"code": "    elif cmd == 'pull':\n        path = sub.subscription_path(PROJECT, args[0])\n        got = sub.pull(subscription=path, max_messages=10, timeout=5).received_messages\n        for m in got:\n            print(m.message.message_id, m.message.data.decode(), dict(m.message.attributes))\n        if got:\n            sub.acknowledge(subscription=path, ack_ids=[m.ack_id for m in got])\n        print(len(got), 'message(s)')\n\nif __name__ == '__main__':\n    main()\n", "note": "Pulling: up to ten messages, printed with their attributes, then acknowledged so they are not delivered again."}]}
```

The library looks for one variable, and that variable is what keeps all of this on your laptop.
**Export it in the terminal you use for the emulator**:

```sh
export PUBSUB_EMULATOR_HOST=localhost:8085
```

## The function

A Pub/Sub message arrives inside the CloudEvent's data, under `message`, with its payload encoded
in base64 and its attributes beside it. **Create `~/gcp/orders-events` and save this as `main.py`
in it:**

```python
# orders-events/main.py
import base64

import functions_framework


@functions_framework.cloud_event
def on_order(event):
    message = event.data['message']
    order = base64.b64decode(message['data']).decode()
    source = message.get('attributes', {}).get('source', '?')
    print(f'order {order} from {source}, event {event["id"]}', flush=True)
```

Start it in the second terminal:

```
ana@laptop:~/gcp/orders-events$ functions-framework --target on_order --signature-type cloudevent
```

## The chain

In the first terminal, a topic, a push subscription pointed at the function, and a message:

```
ana@laptop:~/gcp$ python3 pubsub.py topic orders
projects/planner-dev/topics/orders
ana@laptop:~/gcp$ python3 pubsub.py push orders-fn orders http://localhost:8080/
projects/planner-dev/subscriptions/orders-fn -> http://localhost:8080/
ana@laptop:~/gcp$ python3 pubsub.py publish orders 1042 source=web
message 1
```

And in the function's terminal, a moment later:

```
order 1042 from web, event 1
```

**Nothing called the function directly.** The message went to the topic, the push subscription
delivered it as an HTTP `POST`, and the framework recognised a Pub/Sub push and handed your code a
CloudEvent with the attribute you set. On Google Cloud the delivery has one more step, an identity
token that proves the caller is Pub/Sub, and the topic, the subscription and the function each
live in your project rather than in a container. The shape is the one you just ran.

When you are done, `docker rm -f pubsub` stops the emulator and forgets the topic.
