---
title: Client libraries
version: 1
---

**A client library is the API in your program's own language.** Google publishes one per language per
service: `google-cloud-pubsub` for Python, which lesson 1 installed into the lab's environment, and the same
service's libraries for Go, Java, Node.js and the rest. Underneath, each makes the requests the previous section
made by hand, over gRPC where it can, and adds what a program needs and `curl` does not: retries with backoff,
batching, pagination, and finding credentials on its own.

Save this as `~/gcp/publish.py`:

```schooling-example
{"language": "python", "file": "publish.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Publishes a few orders to the topic orders, with the client library.\n\n    python3 publish.py\n\nWhere the messages go is not in this file: the library reads\nPUBSUB_EMULATOR_HOST, and without it, Google.\n\"\"\"\n", "note": "What it does, and what it leaves out on purpose: no address and no credential. The library finds both, the next section's subject."}, {"code": "from google.cloud import pubsub_v1\n\npublisher = pubsub_v1.PublisherClient()\ntopic = publisher.topic_path('planner-dev', 'orders')\n\n", "note": "The publisher client, and the topic's full name built from the project and the topic id: the same `projects/planner-dev/topics/orders` the REST address carried."}, {"code": "futures = []\nfor n in (1001, 1002, 1003):\n    data = f'order {n}'.encode()\n    futures.append(publisher.publish(topic, data, source='web'))\n\n", "note": "Three messages, each a body of bytes and an attribute. `publish` does not wait: it hands back a future at once and the library batches and sends in the background, which is what makes a publisher fast."}, {"code": "for future in futures:\n    print('published', future.result())\n", "note": "Wait for each future. Its result is the message id the server assigned, and a failure to publish surfaces here, as an exception, rather than being lost."}]}
```

Run it, then read the messages back **without the library**, from the REST API, decoding each body from the
base64 the API carries it in:

```
ana@laptop:~/gcp$ python3 publish.py
published 1
published 2
published 3
ana@laptop:~/gcp$ curl -s -X POST http://localhost:8085/v1/projects/planner-dev/subscriptions/orders-sub:pull -H 'Content-Type: application/json' -d '{"maxMessages": 10}' | jq -c '.receivedMessages[].message | {id: .messageId, data: (.data | @base64d), attributes}'
{"id":"1","data":"order 1001","attributes":{"source":"web"}}
{"id":"2","data":"order 1002","attributes":{"source":"web"}}
{"id":"3","data":"order 1003","attributes":{"source":"web"}}
```

The three messages the library published, read by `curl` from the subscription the previous section made
by hand, with their attribute. **The library and the REST API are the same service**: neither knows or cares
which one the other side used.

The message ids are 1, 2 and 3 because this is the emulator, which counts. Google's are long numbers, unique
across the service, and a program should treat them as opaque strings either way.

## What the library adds

| | `curl` | the client library |
|---|---|---|
| retries | none; a `503` is the caller's problem | retried with backoff, for the errors that are worth retrying |
| batching | one request per call | many messages per request, sent in the background |
| pagination | the caller follows `nextPageToken` | a loop over results that fetches pages as it goes |
| credentials | a header the caller writes | found by the library, the next section |
| the protocol | REST and JSON | gRPC where available, REST otherwise |

That table is the case for the library in a program, and the case for `curl` in a shell: when the question is
*what exactly does the API say*, nothing is in the way.
