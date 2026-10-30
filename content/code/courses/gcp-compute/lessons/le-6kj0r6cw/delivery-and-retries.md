---
title: Delivery, retries and the duplicate you will get
version: 1
---

The comfortable assumption is that an event arrives once. **Eventarc and Pub/Sub promise the
opposite: at least once.** An event is delivered until the destination acknowledges it, and a
delivery can arrive twice even when nothing failed, because an acknowledgement can be lost on the
way back. Code that reacts to events is written for the second arrival from the start.

## Watching a retry happen

Lesson 17 said that an exception means failure and that failure means delivery again.
Here is what "again" looks like when nothing slows it down. **Save this as
`~/gcp/flaky/main.py`**, a function that fails every time, as one does when its database is down:

```python
# flaky/main.py
import functions_framework


@functions_framework.cloud_event
def flaky(event):
    print(f"delivery of message {event['id']}", flush=True)
    raise RuntimeError('database unavailable')
```

Start it in the second terminal, this time with its output going to a file, because you are about
to count lines in it:

```
ana@laptop:~/gcp/flaky$ functions-framework --target flaky --signature-type cloudevent > ~/gcp/flaky.log 2>&1
```

Then, in the first terminal, start the Pub/Sub emulator as in lesson 17 and push one message to
the function:

```
ana@laptop:~/gcp$ docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev
b2fc243cd6c56d662906eb384ef27f0ddcc2162ad519e14031b3f92dc280ce0b
ana@laptop:~/gcp$ python3 pubsub.py topic orders
projects/planner-dev/topics/orders
ana@laptop:~/gcp$ python3 pubsub.py push flaky orders http://localhost:8080/
projects/planner-dev/subscriptions/flaky -> http://localhost:8080/
ana@laptop:~/gcp$ python3 pubsub.py publish orders 1042
message 1
```

Wait ten seconds, then count the deliveries. Each one wrote its line, then the framework's error
and a traceback:

```
ana@laptop:~/gcp$ grep -c 'delivery of message 1' flaky.log
10
ana@laptop:~/gcp$ grep -m 3 -A 1 'delivery of message 1' flaky.log
delivery of message 1
[2026-10-30 15:25:47,569] ERROR in app: Exception on / [POST]
--
delivery of message 1
[2026-10-30 15:25:48,590] ERROR in app: Exception on / [POST]
--
delivery of message 1
[2026-10-30 15:25:49,598] ERROR in app: Exception on / [POST]
```

**One message, delivered again roughly every second**, for as long as the function keeps failing.
The emulator retries with no delay to speak of, which is what makes the problem visible on a
laptop. Google Cloud is gentler and the problem is the same: with a retry policy on the
subscription, Pub/Sub waits between 10 seconds and 10 minutes between attempts, growing the wait
each time, and keeps trying until the message expires. Eventarc's subscriptions keep a message for
24 hours, so a function broken for a day sees the same event more than a hundred times.

Stop it with `docker rm -f pubsub` and Ctrl+C in the function's terminal.

## Three defences

**Make the work idempotent.** Processing the same event twice must leave the world as processing it
once did. The CloudEvent's `id` is unique per source, so the simplest guard is a table of ids
already handled, checked and written in the same transaction as the work. Making a thumbnail is
idempotent by nature, since writing the same file twice gives the same file. Sending an email is
not, and a customer who receives four order confirmations knows exactly which kind of code you
wrote.

**Separate the failures you can retry from the ones you cannot.** A database that is down is worth
retrying; an event whose data is malformed will be malformed on the thousandth attempt too. For the
second kind, log it, return normally, and let it go: raising would only buy a day of identical
failures.

**Give the poison somewhere to go.** A Pub/Sub subscription can carry a **dead-letter topic** and a
maximum number of delivery attempts, between 5 and 100. After the last attempt the message moves to
that topic instead of being retried, and something, or someone, looks at it there. For an Eventarc
trigger that is set on the subscription Eventarc created, which Google's documentation shows how to
find.

## Retries on functions you deploy

For a function deployed with an event trigger, retrying is **off by default**: a failed event is
dropped after one attempt. Turning it on is a choice you make per function, with
`--retry` on `gcloud functions deploy` or `retry_policy = "RETRY_POLICY_RETRY"` in Terraform, and
it is the right choice exactly when the three defences above are in place. Off, a failure is lost
quietly. On, without idempotence, a failure is repeated loudly. Neither is safe by itself.
