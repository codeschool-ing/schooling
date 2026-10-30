---
title: Wiring the budget to a function
version: 1
---

**Each message on the budget's topic has three attributes and a JSON body.** The attributes are `billingAccountId`,
`budgetId` and `schemaVersion`. The body carries, among other fields, `costAmount` (spent so far this period),
`budgetAmount` and `currencyCode`, and `alertThresholdExceeded` once a threshold rule has been passed. Google's own
samples for budget functions read only `costAmount` and `budgetAmount`, and so does the function here.

What runs on your computer is the whole path except its first step. **Billing does not publish to an emulator**, so you
publish the messages yourself, in that format, into the Pub/Sub emulator; from there everything is what would run on
Google Cloud: a push subscription delivering each message to a function, and the function publishing what it decided.

## The function

It runs with the **Functions Framework**, the library Cloud Run functions use to call your code, which serves a
function over HTTP on your computer. Install it, and the Pub/Sub client library the function publishes with, into the
lab's virtual environment:

```sh
pip install -q 'functions-framework==3.10.2' 'google-cloud-pubsub==2.43.0'
```

The function, in `~/gcp/budget/main.py`:

```python
# budget/main.py
"""main.py: what the shop does when a budget notification arrives.

Billing publishes to the topic at regular intervals, whether or not a
threshold was crossed, so the same state arrives many times. This acts once
per budget, per band, per month, and records what it did in seen.json; on
Google Cloud that record would be a Firestore document, since a function's
disk does not outlive it.
"""
import base64
import datetime as dt
import json
import pathlib

import functions_framework
from google.cloud import pubsub_v1

# budget id -> (name, [(share of the budget, action)]), highest share first
POLICY = {
    "b-shop": ("shop", [(1.0, "page"), (0.8, "ticket")]),
    "b-sandbox": ("sandbox", [(1.0, "stop-sandbox")]),
}
SEEN = pathlib.Path("seen.json")
ACTIONS = "projects/planner-dev/topics/ops-actions"
publisher = pubsub_v1.PublisherClient()


def month():
    # budget periods start at midnight Pacific Time, UTC-8
    return dt.datetime.now(dt.timezone(dt.timedelta(hours=-8))).strftime("%Y-%m")


@functions_framework.cloud_event
def on_budget(event):
    message = event.data["message"]
    budget_id = message["attributes"]["budgetId"]
    data = json.loads(base64.b64decode(message["data"]))
    share = data["costAmount"] / data["budgetAmount"]
    name, bands = POLICY.get(budget_id, (budget_id, []))
    print(f"{name}: {data['costAmount']} of {data['budgetAmount']} {data['currencyCode']} ({share:.0%})")

    action = next((a for limit, a in bands if share >= limit), None)
    if action is None:
        return
    seen = json.loads(SEEN.read_text()) if SEEN.exists() else {}
    key = f"{budget_id}/{month()}/{action}"
    if key in seen:
        print(f"{name}: {action} already done this month")
        return
    publisher.publish(ACTIONS, json.dumps(data).encode(), action=action, budget=name).result()
    seen[key] = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    SEEN.write_text(json.dumps(seen, indent=1))
    print(f"{name}: {action}")
```

Three decisions are in it:

- **Which budget is which** comes from the `budgetId` attribute. On Google Cloud that is an id Google assigns, which
  Terraform reports after an apply; here the two are `b-shop` and `b-sandbox`.
- **The shop's budget never stops anything.** At 80% it opens a ticket and at 100% it pages. Only the sandbox budget
  has an action that changes resources, and the next section is about why.
- **It acts once per band per month**, because the same state arrives many times. Without `seen.json` the 82% message
  would open a second ticket, and every update until the 1st would open another.

## Running it

Start the function in `~/gcp/budget`, in a terminal where the eight lines of lesson 1 were typed, since it reads
`PUBSUB_EMULATOR_HOST` to find the emulator. The `&` runs it in the background, and what it prints goes to `ff.log`:

```sh
functions-framework --target on_budget --port 8080 > ff.log 2>&1 &
```

The emulator runs in a container, so it reaches your computer through Docker's bridge, and the push endpoint has to
name that address rather than `localhost`. Then two topics, one push subscription that delivers the budget's messages
to the function, and one pull subscription to read what it did:

```
ana@laptop:~/gcp/budget$ docker network inspect bridge --format "{{(index .IPAM.Config 0).Gateway}}"
172.17.0.1
ana@laptop:~/gcp/budget$ gcloud pubsub topics create budget-alerts ops-actions
Created topic [projects/planner-dev/topics/budget-alerts].
Created topic [projects/planner-dev/topics/ops-actions].
ana@laptop:~/gcp/budget$ gcloud pubsub subscriptions create budget-act --topic budget-alerts --push-endpoint http://172.17.0.1:8080/
Created subscription [projects/planner-dev/subscriptions/budget-act].
ana@laptop:~/gcp/budget$ gcloud pubsub subscriptions create ops-read --topic ops-actions
Created subscription [projects/planner-dev/subscriptions/ops-read].
```

Now five updates, as Billing would send them over a month, the third one only a few dollars past the second. Each
publish prints a message id, which is left out here:

```
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 385.12, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 566.40, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 571.93, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-sandbox,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 40.85, "budgetAmount": 40, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 703.18, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ cat ff.log
shop: 385.12 of 700 USD (55%)
shop: 566.4 of 700 USD (81%)
shop: ticket
shop: 571.93 of 700 USD (82%)
shop: ticket already done this month
sandbox: 40.85 of 40 USD (102%)
sandbox: stop-sandbox
shop: 703.18 of 700 USD (100%)
shop: page
ana@laptop:~/gcp/budget$ gcloud pubsub subscriptions pull ops-read --auto-ack --limit 10 --format "table(message.attributes.budget, message.attributes.action)"
BUDGET   ACTION
shop     ticket
sandbox  stop-sandbox
shop     page
ana@laptop:~/gcp/budget$ cat seen.json
{
 "b-shop/2026-10/ticket": "2026-10-30T21:54:38+00:00",
 "b-sandbox/2026-10/stop-sandbox": "2026-10-30T21:54:44+00:00",
 "b-shop/2026-10/page": "2026-10-30T21:54:47+00:00"
}
```

**Five messages, three actions.** The 55% was below every band. The 82% was the same band as the 81% before it, and
`seen.json` stopped a second ticket. On Google Cloud the same lines go to Cloud Logging, where lesson 10's log metrics can count them.
