---
title: An alert a program can act on
version: 1
---

**An e-mail at 90% is read by a person, eventually. A Pub/Sub message at 90% is read by a program, at
once.** That is what the budget's `all_updates_rule` is for: every few hours, Google publishes the budget's
state to the topic as a JSON message, and whatever subscribes decides what to do. This is the one part of
billing the lab can run, because the topic is Pub/Sub, and Pub/Sub is what the emulator answers.

## The topic, the subscription, and a message

Create the topic the budget names, and a subscription to read it from:

```
ana@laptop:~/gcp$ gcloud pubsub topics create budget-alerts
Created topic [projects/planner-dev/topics/budget-alerts].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create budget-alerts-sub --topic=budget-alerts
Created subscription [projects/planner-dev/subscriptions/budget-alerts-sub].
```

Google would now publish to `budget-alerts`. In the lab nobody does, so **the messages below were written by
this course**, in the format Google's billing documentation gives for budget notifications, and published
with `gcloud` in Google's place. The fields and attributes are Google's; the numbers are the planner's
invented month. Three moments of it: early in the month, after the 90% threshold, and past the budget.

```
ana@laptop:~/gcp$ gcloud pubsub topics publish budget-alerts --attribute=billingAccountId=012345-6789AB-CDEF01,budgetId=planner-monthly,schemaVersion=1.0 --message='{"budgetDisplayName": "planner monthly", "costAmount": 84.17, "costIntervalStart": "2026-11-01T07:00:00Z", "budgetAmount": 300.0, "budgetAmountType": "SPECIFIED_AMOUNT", "currencyCode": "USD"}'
messageIds:
- '1'
```

## A program that reads them

The program below pulls from the subscription, reads each message and prints what it would do. It uses
Google's client library from lesson 1's virtual environment, and because `PUBSUB_EMULATOR_HOST` is set by
`env.sh`, the library talks to the emulator without being told. Save it as `~/gcp/on_budget.py`:

```schooling-example
{"language": "python", "file": "on_budget.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Reads budget notifications and decides what to do about each one.\n\n    python3 on_budget.py\n\nPulls what is waiting on the subscription budget-alerts-sub, prints a\ndecision for each message and acknowledges it.\n\"\"\"\nimport json\n\nfrom google.cloud import pubsub_v1\n\nPROJECT = 'planner-dev'\nSUBSCRIPTION = 'budget-alerts-sub'\n\n", "note": "The subscription to read, by name. Nothing here says where Pub/Sub is: the library reads `PUBSUB_EMULATOR_HOST` from the environment, and against Google the same file would read the real subscription."}, {"code": "subscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path(PROJECT, SUBSCRIPTION)\nresponse = subscriber.pull(request={'subscription': path, 'max_messages': 10}, timeout=10)\n\n", "note": "One synchronous pull: ask for up to ten messages and take what is there. A service that runs all day would use the streaming pull instead; a pull is enough to read one message at a time."}, {"code": "for received in response.received_messages:\n    data = json.loads(received.message.data)\n    spent, budget = data['costAmount'], data['budgetAmount']\n    share = spent / budget\n    print(f\"{data['budgetDisplayName']}: {spent:.2f} of {budget:.2f} {data['currencyCode']} ({share:.0%})\")\n", "note": "The message body is the JSON Google documents. `costAmount` is the month's spend so far, `budgetAmount` the budget, and the share is computed here rather than trusted from a threshold field, which is absent until one is crossed."}, {"code": "    if share >= 1:\n        print('  over budget: this is where billing would be disabled')\n    elif 'alertThresholdExceeded' in data:\n        print(f\"  crossed {data['alertThresholdExceeded']:.0%}: tell the team\")\n    else:\n        print('  no threshold crossed: nothing to do')\n    subscriber.acknowledge(request={'subscription': path, 'ack_ids': [received.ack_id]})\n", "note": "The decision. Past the budget, a real version would call the Cloud Billing API to unlink the project, lesson 11's switch; this one says so and does nothing. Acknowledging tells Pub/Sub the message was handled, so it is not delivered again."}]}
```

Run it now, and again after each of the next two messages:

```
ana@laptop:~/gcp$ python3 on_budget.py
planner monthly: 84.17 of 300.00 USD (28%)
  no threshold crossed: nothing to do
ana@laptop:~/gcp$ gcloud pubsub topics publish budget-alerts --attribute=billingAccountId=012345-6789AB-CDEF01,budgetId=planner-monthly,schemaVersion=1.0 --message='{"budgetDisplayName": "planner monthly", "alertThresholdExceeded": 0.9, "costAmount": 273.40, "costIntervalStart": "2026-11-01T07:00:00Z", "budgetAmount": 300.0, "budgetAmountType": "SPECIFIED_AMOUNT", "currencyCode": "USD"}'
messageIds:
- '2'
ana@laptop:~/gcp$ python3 on_budget.py
planner monthly: 273.40 of 300.00 USD (91%)
  crossed 90%: tell the team
ana@laptop:~/gcp$ gcloud pubsub topics publish budget-alerts --attribute=billingAccountId=012345-6789AB-CDEF01,budgetId=planner-monthly,schemaVersion=1.0 --message='{"budgetDisplayName": "planner monthly", "alertThresholdExceeded": 1.0, "costAmount": 318.92, "costIntervalStart": "2026-11-01T07:00:00Z", "budgetAmount": 300.0, "budgetAmountType": "SPECIFIED_AMOUNT", "currencyCode": "USD"}'
messageIds:
- '3'
ana@laptop:~/gcp$ python3 on_budget.py
planner monthly: 318.92 of 300.00 USD (106%)
  over budget: this is where billing would be disabled
```

Between the runs, the transcript publishes the next moment of the month: 273.40 dollars, when Google
would add `alertThresholdExceeded: 0.9`, and then 318.92, past the budget.

**The third message is the one a cap is made of.** At 106% the program would disable billing on the
projects in the budget, and the spending would stop: everything in lesson 11's section on unlinking would
then happen to them. Google's billing documentation gives exactly this arrangement as the way to cap costs,
with a Cloud Run function in the subscriber's place, and warns in the same breath that it may delete
resources. **That is the trade a cap makes**, and it is why most production projects stop at the e-mail and
the person.

Every line of output above is the lab's: the emulator delivered the messages and the program decided. What
the lab cannot show is Google publishing them, or the unlink the third one asks for.
