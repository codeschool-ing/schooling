---
title: Pull, push, and the acknowledgement
version: 1
---

**A message stays in a subscription until it is acknowledged, and reading it is not acknowledging
it.** Pulling a message lends it to the reader for the ack deadline, ten seconds by default. If the
reader acks within that time, the subscription forgets the message; if it does not, the message goes
back to the subscription and is delivered again. Pub/Sub has two ways to deliver, and they differ
in who opens the connection. In a **pull** subscription the reader asks for messages. In a **push**
subscription Pub/Sub sends each message as an HTTP request to an address the subscription names,
and the answer is the ack.

## Pulling, and acknowledging by hand

`--auto-ack` hid the acknowledgement in the last section. Without it, `gcloud` prints the **ack id**
of each message, the handle that acknowledges this delivery of it:

```
ana@laptop:~/gcp$ python3 events.py > /dev/null
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull analytics --limit=2 --format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,ackId)'
ID  TYPE  ACK_ID
9   view  projects/planner-dev/subscriptions/analytics:11
10  view  projects/planner-dev/subscriptions/analytics:12
ana@laptop:~/gcp$ gcloud pubsub subscriptions ack analytics --ack-ids=projects/planner-dev/subscriptions/analytics:11
Acked the messages with the following ackIds: [projects/planner-dev/subscriptions/analytics:11]
{}
```

**Message 9 is acknowledged, and message 10 is only lent.** An ack id names one delivery, not the
message: if message 10 is delivered again it comes with a new one, and the old handle no longer
acknowledges anything. The emulator's ack ids end in a counter; on the real service they are long
opaque strings. Lesson 20 lets a deadline run out on purpose and follows what comes back.

## A streaming pull

`gcloud` asks once and prints what it got, which is right for looking and wrong for a service. A
consumer keeps a connection open and has messages sent down it as they arrive, a **streaming
pull**, and the client library does the work. Save it as `~/gcp/subscriber.py`:

```schooling-example
{"language": "python", "file": "subscriber.py", "parts": [{"code": "import sys\nimport threading\nfrom concurrent.futures import TimeoutError\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', sys.argv[1])\nlock = threading.Lock()\n\n", "note": "The subscription comes from the command line, so the same program reads `analytics` here and anything else later."}, {"code": "def callback(message):\n    kind = message.attributes.get('type', '-')\n    with lock:\n        print(f'id {message.message_id:>3}  {kind:<12} {message.data.decode()}')\n    message.ack()\n\n\n", "note": "**The callback runs once per message, on a pool of threads**, which is why the printing takes a lock: without it two lines can land on one. `ack()` tells Pub/Sub this subscription is done with the message."}, {"code": "future = subscriber.subscribe(path, callback=callback)\nwith subscriber:\n    try:\n        future.result(timeout=5)\n    except TimeoutError:\n        future.cancel()\n        future.result()\n", "note": "`subscribe` opens a **streaming pull**: one long connection down which the server sends messages as they arrive. A real consumer waits on `future.result()` for ever; this one stops after five seconds so that it can be run and read."}]}
```

```
ana@laptop:~/gcp$ python3 subscriber.py analytics
id  11  add_to_cart  {"product": "banana-prata", "qty": 6}
id  12  payment      {"order_id": "o-301", "cents": 4590}
id  13  search       {"text": "manga"}
id  16  view         {"product": "manga-palmer"}
id  15  payment      {"order_id": "o-302", "cents": 12800}
id  14  add_to_cart  {"product": "tomate", "qty": 2}
```

**Six of the eight came, and message 10 did not**: it was still lent to the `gcloud` pull above,
whose deadline had not run out when the program started. Nothing promises the order of the six
either. Callbacks run on several threads, so a run can print 16 before 14, and the next section is
about the one setting that gives order back. The client library also does a thing `gcloud` does not:
**while a callback is still working on a message, the library extends its deadline on its own**,
and by default it goes on doing so for up to an hour. A slow callback therefore does not cause a
redelivery; a dead process does, which is what lesson 20 stages.

## Push

A push subscription needs an address Pub/Sub can reach. On Google that is an HTTPS address on the
internet, most often a Cloud Run service; here it is a small server on port 8099 of the same
laptop. Save it as `~/gcp/receiver.py`:

```schooling-example
{"language": "python", "file": "receiver.py", "parts": [{"code": "import base64\nimport json\nimport time\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\nFAIL_FIRST = 2\ncalls = []\n\n\n", "note": "An HTTP endpoint from Python's standard library, standing in for the service Quitanda would run behind a public address. `FAIL_FIRST` makes it answer the first two requests with an error, the way a service does while it restarts."}, {"code": "class Push(BaseHTTPRequestHandler):\n    def do_POST(self):\n        body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))\n        message = body['message']\n", "note": "**A push request is a POST whose body wraps the message in JSON**, with the subscription's name beside it."}, {"code": "        calls.append(time.time())\n        status = 503 if len(calls) <= FAIL_FIRST else 204\n        data = base64.b64decode(message['data']).decode()\n        print(f\"+{calls[-1] - calls[0]:4.1f}s  {status}  id {message['messageId']}  {data}\", flush=True)\n        self.send_response(status)\n        self.end_headers()\n\n", "note": "The status code is the acknowledgement. **A 2xx answer acks the message; anything else, or no answer in time, is a nack**, and Pub/Sub sends it again. The data arrives in base64, as it does in every JSON form of a message."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nHTTPServer(('localhost', 8099), Push).serve_forever()\n", "note": "`log_message` silences the server's own line per request, so that only the program's line is printed."}]}
```

The `&` at the end of the second line runs the receiver in the background of this same terminal, and
`push.log` collects what it prints:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions create pushed --topic=app-events --push-endpoint=http://localhost:8099/
Created subscription [projects/planner-dev/subscriptions/pushed].
ana@laptop:~/gcp$ python3 receiver.py > push.log 2>&1 &
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message='{"order_id": "o-303", "cents": 990}' --attribute=type=payment,customer_id=c-17
messageIds:
- '17'
ana@laptop:~/gcp$ cat push.log
+ 0.0s  503  id 17  {"order_id": "o-303", "cents": 990}
+ 1.0s  503  id 17  {"order_id": "o-303", "cents": 990}
+ 2.0s  204  id 17  {"order_id": "o-303", "cents": 990}
ana@laptop:~/gcp$ gcloud pubsub subscriptions delete pushed
Deleted subscription [projects/planner-dev/subscriptions/pushed].
```

**The receiver answered 503 twice, and Pub/Sub sent the same message a second and a third time**,
the same id 17 each time, until a 204 acknowledged it. Nothing in `receiver.py` asked for the
retries; the status code was the whole conversation. The emulator retried about once a second.
Google documents that the service backs off instead, sending less often while an endpoint keeps
failing, and a push subscription's retry policy sets the bounds of that backoff. Type `kill %1` to
stop the receiver once the subscription is deleted.

**The choice between them is about who holds the connection.** Pull suits a worker that runs all the
time and decides its own pace, and it is the only kind that can be read by `gcloud`, by a batch job
or by Dataflow in lesson 21. Push suits a service that already answers HTTP and should not keep a
process waiting on a subscription, and it hands the scaling to whatever runs the endpoint. On the
real service a push subscription can sign each request with a token for a service account, the
`--push-auth-service-account` flag in `gcloud`'s help, and the endpoint then checks it. The emulator
signs nothing, so that part of push is not practised here.

There are two more kinds, which deliver into a Google product rather than to code of yours: a
**BigQuery subscription** writes each message as a row of a table, and a **Cloud Storage
subscription** gathers messages into files in a bucket. They are the way Quitanda's analytics events
could reach the warehouse with no consumer at all. The emulator accepts both and delivers into
neither, as the last section shows.
