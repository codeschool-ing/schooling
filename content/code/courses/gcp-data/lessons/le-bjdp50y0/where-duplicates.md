---
title: Where the duplicates come from
version: 1
---

**A duplicate is not a fault in Pub/Sub; it is what a correct retry produces.** Five places make them
in the pipelines of this course, and each one is doing the right thing when it does. One is on the
publisher's side and gives the copy a new message id; the other four are on the delivering side and
keep the old one, and that difference decides what can catch them.

The lab is the one from lesson 19: the Pub/Sub emulator in a terminal of its own, started with the
command of lesson 19's first section, and this terminal with the lines of lesson 1's "Every time you
open a terminal". Restart the emulator, so that it is empty; message ids below start from 1.

## The publisher that retries

A publisher sends a message and waits for the id. If the answer is lost, because the connection
dropped or the call timed out, the publisher cannot tell a message that was never stored from one
that was stored and whose answer went missing. The only safe move is to send it again, and if the
first one had been stored, the topic now has it twice. Google's client libraries retry a failed
publish on their own, so this happens without a line of the publisher's code asking for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A publisher and Pub/Sub over time. The publisher publishes the payment o-301; Pub/Sub stores it as message id 1 and answers, and the answer is lost on the way back. The publisher times out, cannot tell whether the message was stored, and publishes it again; Pub/Sub stores it as message id 2 and this answer arrives. The topic now holds o-301 twice, under two message ids.\" data-fig=\"l20-retry\"><text x=\"160.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">publisher</text><text x=\"560.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Pub/Sub</text><line x1=\"160.0\" y1=\"30.0\" x2=\"160.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"560.0\" y1=\"30.0\" x2=\"560.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"160.0\" y1=\"50.0\" x2=\"554.0\" y2=\"69.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"560.0,70.0 553.9,72.7 554.2,66.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">publish o-301</text><rect x=\"570.0\" y=\"60.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stored: id 1</text><line x1=\"560.0\" y1=\"90.0\" x2=\"380.0\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"380.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">answer lost</text><rect x=\"10.0\" y=\"120.0\" width=\"140.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"80.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">timeout: stored or not?</text><line x1=\"160.0\" y1=\"160.0\" x2=\"554.0\" y2=\"179.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"560.0,180.0 553.9,182.7 554.2,176.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">publish o-301</text><text x=\"290.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the same payment, again</text><rect x=\"570.0\" y=\"170.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">stored: id 2</text><line x1=\"560.0\" y1=\"200.0\" x2=\"166.0\" y2=\"219.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,220.0 165.8,216.7 166.1,222.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"190.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id 2 returned</text></svg>", "caption": "A lost answer and a correct retry: one payment, two messages."}
```

The emulator never loses an answer, so the lab cannot make the timeout happen. It can show the
result, which is the same as publishing one payment twice:

```
ana@laptop:~/gcp$ gcloud pubsub topics create retries
Created topic [projects/planner-dev/topics/retries].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create retries --topic=retries
Created subscription [projects/planner-dev/subscriptions/retries].
ana@laptop:~/gcp$ gcloud pubsub topics publish retries --message='{"order_id": "o-301", "cents": 4590}' --attribute=order_id=o-301
messageIds:
- '1'
ana@laptop:~/gcp$ gcloud pubsub topics publish retries --message='{"order_id": "o-301", "cents": 4590}' --attribute=order_id=o-301
messageIds:
- '2'
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull retries --limit=10 --format='table(message.messageId:label=ID,message.attributes.order_id:label=ORDER,ackId)'
ID  ORDER  ACK_ID
1   o-301  projects/planner-dev/subscriptions/retries:1
2   o-301  projects/planner-dev/subscriptions/retries:2
```

**Two messages, two ids, identical data.** Pub/Sub does not compare messages and has no way to know
the second is a copy: to the topic they are two events. That settles which key catches this
duplicate. The message id cannot, because the copy got a new one; only something inside the message,
put there by the publisher, can. That is an **idempotency key**, and for a payment it is the order
id, because an order is paid once. `pay.py` in the next section sends it as an attribute.

## The ack deadline that runs out

The two messages above were pulled and not acknowledged. Each was lent to this terminal for the
subscription's ack deadline, ten seconds, and a second pull asks for them again:

```
ana@laptop:~/gcp$ time gcloud pubsub subscriptions pull retries --limit=10 --format='table(message.messageId:label=ID,message.attributes.order_id:label=ORDER,ackId)'
ID  ORDER  ACK_ID
1   o-301  projects/planner-dev/subscriptions/retries:3
2   o-301  projects/planner-dev/subscriptions/retries:4

real	0m9.792s
user	0m0.649s
sys	0m0.079s
ana@laptop:~/gcp$ gcloud pubsub subscriptions modify-message-ack-deadline retries --ack-ids=projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4 --ack-deadline=60
Set ackDeadlineSeconds to [60] for messages with ackId [projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4]] for subscription [projects/planner-dev/subscriptions/retries]
{}
ana@laptop:~/gcp$ timeout 20 gcloud pubsub subscriptions pull retries --limit=10 --format='table(message.messageId:label=ID,message.attributes.order_id:label=ORDER,ackId)'; echo "exit $?"
exit 124
ana@laptop:~/gcp$ gcloud pubsub subscriptions ack retries --ack-ids=projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4
Acked the messages with the following ackIds: [projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4]
{}
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull retries --limit=10
Listed 0 items.
```

**The second pull waited, and got the same two messages back when their deadline ran out**, about ten
seconds after the first, under new ack ids 3 and 4. A consumer that takes longer than its deadline,
or dies holding a message, produces exactly this: the same message ids, delivered again. The
`modify-message-ack-deadline` line is the remedy for a consumer that is slow rather than dead. It
extended the two leases to sixty seconds, and the next pull found nothing for twenty seconds and was
stopped by `timeout`, exit code 124. Acked, they are gone. The Python client's streaming pull does
this extension by itself while a callback runs, as lesson 19 said, so a slow callback is safe and a
dead process is not.

**An ack id belongs to one delivery.** After the redelivery, the ack ids 1 and 2 of the first pull
refer to nothing. On an ordinary subscription an ack with an expired id is accepted without an error,
and nothing says whether it did anything; this lesson's last section shows it. The Python library's
own documentation calls acknowledgements best effort on such a subscription for this reason.

## The consumer that crashes

A consumer that does the work and then acks dies between the two, and every message it had pulled
and not acked comes back after the deadline. That is the replay of the next section, made on
purpose. **These duplicates keep their message ids**, because they are the same messages delivered
twice, which makes them easier to catch than the publisher's.

## The service that retries for you

A push endpoint that answers 503, or answers too slowly, gets the message again, and lesson 19's
`receiver.py` received message 17 three times. An endpoint that did the work and then failed to
answer in time does it again on the retry. And an ordered subscription, Google documents, redelivers
a nacked message together with every later message of its key, including ones already acknowledged:
there the duplicates are the price of the order.

## Two that are not duplicates

**A second event that looks like the first is not a duplicate.** Two orders by `c-17` for the same
amount on the same day are two orders; a key built from customer, amount and day would merge them and
lose money in the other direction. The idempotency key has to identify the event, not describe it,
which is why it is an id the publisher assigns once, when the event happens, and never derives later.

And **a message out of order is not a duplicate either**. Without an ordering key, Pub/Sub delivers in
no particular order, and lesson 19 showed the emulator breaking even a key's order after a nack. A
dedupe removes copies and does nothing about order; a consumer that cares about both needs the
idempotency key for the copies and a version or timestamp in the data for the order, which this
lesson's last section comes back to.
