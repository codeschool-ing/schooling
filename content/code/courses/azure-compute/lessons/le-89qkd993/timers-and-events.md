---
title: "Waiting: a durable timer, an external event and terminate"
version: 1
---

A shop that takes Pix sends the customer a code and then waits, for minutes or for a day, until the
bank says the money has arrived. Long-running orchestration sounds as if something has to stay up
for all that time. **Nothing does.** A waiting instance is a row in the Instances table and, if it
set a timer, a queue message that stays invisible until the timer's moment. No process of yours runs
while it waits, and on the Consumption plan the documentation says the wait is not billed. Durable
Functions has two ways to end a wait, and this section uses both at once: a **durable timer**, which
a clock ends, and an **external event**, which somebody outside the app raises.

## The code

The order now waits for its payment between the reservations and the charge, for as many seconds as
the order's `pay_within_s` says. Replace `~/azure/shopfn/function_app.py` once more:

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport logging\nimport time\nfrom datetime import timedelta\n\nimport azure.functions as func\nimport azure.durable_functions as df\n\napp = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)\n\n\n", "note": "`timedelta` is new: the deadline is a time computed from `context`."}, {"code": "@app.route(route='orders', methods=['POST'])\n@app.durable_client_input(client_name='client')\nasync def start_order(req: func.HttpRequest, client: df.DurableOrchestrationClient) -> func.HttpResponse:\n    order = req.get_json()\n    instance_id = await client.start_new('order_flow', order['order'], order)\n    logging.info('started %s', instance_id)\n    return client.create_check_status_response(req, instance_id)\n\n\n"}, {"code": "@app.orchestration_trigger(context_name='context')\ndef order_flow(context: df.DurableOrchestrationContext):\n    order = context.get_input()\n    tasks = [context.call_activity('reserve_line', line) for line in order['lines']]\n    reserved = yield context.task_all(tasks)\n\n", "note": "The fan-out of the previous section, unchanged."}, {"code": "    context.set_custom_status('waiting for payment')\n    deadline = context.current_utc_datetime + timedelta(seconds=order['pay_within_s'])\n    timeout = context.create_timer(deadline)\n    paid = context.wait_for_external_event('PaymentConfirmed')\n    winner = yield context.task_any([paid, timeout])\n", "note": "**Two tasks and one `yield`.** `create_timer` is a durable timer that fires at `deadline`; `wait_for_external_event` is a task that completes when somebody raises the event `PaymentConfirmed` for this instance. `task_any` resumes on whichever finishes first. `set_custom_status` puts a word in the status JSON for whoever polls it."}, {"code": "    if winner == timeout:\n        context.set_custom_status('expired')\n        released = yield context.call_activity('release_stock', order)\n        return {'status': 'expired', 'reserved': reserved, 'then': [released]}\n    timeout.cancel()\n\n", "note": "If the clock won, the status says so, the reservations are undone and the instance ends. If the payment won, the timer is cancelled: the documentation says an instance is not marked `Completed` while a timer it created is still outstanding."}, {"code": "    context.set_custom_status('paid')\n    charged = yield context.call_activity('charge', {'order': order['order'], 'payment': paid.result})\n    shipped = yield context.call_activity('ship', order)\n    return {'status': 'shipped', 'reserved': reserved, 'then': [charged, shipped]}\n\n\n", "note": "`paid.result` is the body the event carried, and it goes to `charge` as part of its input."}, {"code": "@app.activity_trigger(input_name='line')\ndef reserve_line(line: dict) -> str:\n    time.sleep(1)\n    return f\"reserved {line['qty']} x {line['sku']}\"\n\n\n@app.activity_trigger(input_name='order')\ndef release_stock(order: dict) -> str:\n    logging.info('releasing the stock of %s', order['order'])\n    return f\"released {order['order']}\"\n\n\n", "note": "`release_stock` is the compensation for a payment that never came, and it logs a line so the transcript can show it ran."}, {"code": "@app.activity_trigger(input_name='payment')\ndef charge(payment: dict) -> str:\n    time.sleep(1)\n    return f\"charged {payment['order']} with {payment['payment']['pix']}\"\n\n\n", "note": "`charge` now receives the order number and the payment together."}, {"code": "@app.activity_trigger(input_name='order')\ndef ship(order: dict) -> str:\n    time.sleep(1)\n    return f\"shipped {order['order']}\"\n"}]}
```

**The wait is a race between two tasks.** `task_any` resumes the orchestrator with whichever finishes
first, and the code asks which one it was. Neither task is a sleep: `create_timer` writes a message
that becomes visible at `deadline`, and `wait_for_external_event` writes nothing at all until the
event arrives. The deadline comes from `context.current_utc_datetime`, as the section `replay`
required, so every replay computes the same moment.

## Three orders

Build, replace the container, and send three orders: two that will wait ten minutes and one that
will wait twenty seconds:

```
ana@laptop:~/azure$ docker build -q -t shopfn:df3 shopfn
sha256:7b6bfb9da8351ce95a1acebd93a2f3b0d77cfa68a7524c3d0b5eb11902db4247
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df3
7155a7f5390862059f533476b13ba532515e826b44e4d9837386b71794aac872
ana@laptop:~/azure$ curl -s -o a1007.json -XPOST localhost:8080/api/orders -d '{"order": "A-1007", "lines": [{"sku": "mug", "qty": 2}], "pay_within_s": 600}'
ana@laptop:~/azure$ curl -s -o a1008.json -XPOST localhost:8080/api/orders -d '{"order": "A-1008", "lines": [{"sku": "tee", "qty": 1}], "pay_within_s": 20}'
ana@laptop:~/azure$ curl -s -o a1009.json -XPOST localhost:8080/api/orders -d '{"order": "A-1009", "lines": [{"sku": "lamp", "qty": 1}], "pay_within_s": 600}'
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1007.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Running","customStatus":"waiting for payment","output":null}
```

`customStatus` is the word the orchestrator set before it started waiting. **Anybody polling the
status address can see why the instance is `Running` with nothing running**, which a bare status
cannot say.

## The payment arrives: raising an event

The address for raising an event came in the start's answer, with `{eventName}` in it for the name
the orchestrator waits for:

```
ana@laptop:~/azure$ jq -r .sendEventPostUri a1007.json | cut -c1-110
http://localhost:8080/runtime/webhooks/durabletask/instances/A-1007/raiseEvent/{eventName}?taskHub=TestHubName
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1007.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1234"}'
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1007.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Completed","customStatus":"paid","output":{"status":"shipped","reserved":["reserved 2 x mug"],"then":["charged A-1007 with E1234","shipped A-1007"]}}
```

The bank's side of the conversation is played by `curl`. The body is the event's data, and it has to
be JSON with a JSON content type; the documentation lists 400 for anything else. The 202 means the
event was queued, not that anything used it. A-1007 then charged and shipped, and `charge` got the
Pix id out of `paid.result`.

Three details from the documentation, none of them run here. **An event raised before the
orchestrator waits for it is not lost**: it is kept, and the wait completes as soon as the code gets
there. An event raised for an instance id that does not exist is discarded without an error, which
is the case to watch for when the id comes from a webhook. And **events are delivered at least
once**: after a restart or a scale-out the same event can arrive twice, so a payment confirmation
that can be repeated must be safe to repeat.

## The payment never comes: the timer

A-1008 was given twenty seconds:

```
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1008.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Completed","customStatus":"expired","output":{"status":"expired","reserved":["reserved 1 x tee"],"then":["released A-1008"]}}
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E -o "A-1008: Function 'order_flow \(Orchestrator\)' was resumed by a timer scheduled for '[^']*'|releasing the stock of A-1008"
A-1008: Function 'order_flow (Orchestrator)' was resumed by a timer scheduled for '2026-10-30T20:40:28.6951970Z'
releasing the stock of A-1008
```

**The timer won**, and the log names the moment it was set for, in UTC. `release_stock` undid the
reservation and the instance completed with the status `expired`. Nobody had to remember A-1008:
the deadline was written down when the instance started waiting, and it is the provider's queue that
woke the orchestrator.

The documentation's limits on timers are two. **In Python a durable timer can be at most six days
long**; a longer wait is a loop of shorter timers, each checking whether the deadline has come. And
a timer that loses the race must be cancelled, which `order_flow` does with `timeout.cancel()`. The
documentation says the instance is not marked `Completed` while any timer it created is still
pending, so A-1007, paid in a second, would have stayed `Running` for its whole ten minutes.

A timer can also be the step itself, with no race: `yield context.create_timer(when)` is the
orchestrator's `sleep`, and the only one it may use.

## The customer cancels: terminate

The third order is stopped from outside:

```
ana@laptop:~/azure$ URL=$(jq -r .terminatePostUri a1009.json | sed 's/{text}/customer+cancelled/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL"
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1009.json)" | jq -c '{runtimeStatus, customStatus, output}'
{"runtimeStatus":"Terminated","customStatus":"waiting for payment","output":"customer cancelled"}
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1009.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1235"}'
HTTP 410
```

`terminate` takes a reason, here `customer cancelled`, which becomes the instance's output. **A
terminated instance is finished**: the payment that turned up afterwards was refused with 410 Gone,
the documentation's answer for an instance that has completed or failed. Terminating also runs no
code of yours, so A-1009's reserved lamp was not released. In a real shop the cancellation would be
an event the orchestrator waits for, so that it can undo what it did; `terminate` is for an
instance that has gone wrong.

## A restart, with an order waiting

An instance that waits for days will live through restarts of the host. Start one more order, restart
the container while it waits, and pay it afterwards:

```
ana@laptop:~/azure$ curl -s -o a1010.json -XPOST localhost:8080/api/orders -d '{"order": "A-1010", "lines": [{"sku": "cap", "qty": 1}], "pay_within_s": 600}'
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1010.json)" | jq -c '{runtimeStatus, customStatus}'
{"runtimeStatus":"Running","customStatus":"waiting for payment"}
ana@laptop:~/azure$ docker restart shopfn
shopfn
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1010.json)" | jq -c '{runtimeStatus, customStatus}'
{"runtimeStatus":"Running","customStatus":"waiting for payment"}
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1010.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1236"}'
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1010.json)" | jq -c '{runtimeStatus, output}'
{"runtimeStatus":"Completed","output":{"status":"shipped","reserved":["reserved 1 x cap"],"then":["charged A-1010 with E1236","shipped A-1010"]}}
```

**The instance was waiting before the restart and still waiting after it**, and the payment finished
it. The process that started A-1010 was gone; what survived was the instance's row and history in
Azurite, and the host that came back read them. The address still worked because the host id was
fixed in the first section: the key is kept under it.

## A deployment, with an order waiting

A restart runs the same code. A deployment does not. Suppose the shop decides to send the customer
the Pix code from an activity, just before the wait. Start A-1011 first, and let it wait. Then add the
line to `order_flow`, under `reserved = yield context.task_all(tasks)`:

```python
    yield context.call_activity('send_pix_code', order)
```

and the activity at the end of the file:

```python
@app.activity_trigger(input_name='order')
def send_pix_code(order: dict) -> str:
    return f"sent a Pix code for {order['order']}"
```

Build the new version, replace the container and pay A-1011:

```
ana@laptop:~/azure$ curl -s -o a1011.json -XPOST localhost:8080/api/orders -d '{"order": "A-1011", "lines": [{"sku": "pen", "qty": 5}], "pay_within_s": 600}'
ana@laptop:~/azure$ grep -n send_pix_code shopfn/function_app.py
26:    yield context.call_activity('send_pix_code', order)
70:def send_pix_code(order: dict) -> str:
ana@laptop:~/azure$ docker build -q -t shopfn:df4 shopfn
sha256:aa2f9a049ecab552ce6f41bdbd62c403e13b1ae65746b683391131b5491573a4
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df4
647c3355d7022e6e3cf4b144ac67489a94a5447dee150bcd31f0b4a18a8870df
ana@laptop:~/azure$ URL=$(jq -r .sendEventPostUri a1011.json | sed 's/{eventName}/PaymentConfirmed/')
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST "$URL" -H 'Content-Type: application/json' -d '{"pix": "E1237"}'
HTTP 202
ana@laptop:~/azure$ curl -s "$(jq -r .statusQueryGetUri a1011.json)" | jq -r '.runtimeStatus, .output'
Failed
Non-Deterministic workflow detected: A previous execution of this orchestration scheduled a timer task with sequence number 1 named but the current orchestration replay instead produced a ScheduleTaskOrchestratorAction action with this sequence number. Was a change made to the orchestrator code after this instance had already started running?
```

**A-1011 failed, and the message says why.** Its history said the step after the reservations was
a timer; the new code, replayed over that history, asked for an activity there instead. Nothing was
wrong with the new code, and orders started after the deployment would run it without trouble. What
broke is that the old instance's history was written by the old code.

Not run in this course: the documentation's ways out. A change that adds, removes or reorders calls
to activities, timers or events in an orchestrator is a **breaking change** for every instance in
flight. The recommended answer is **orchestration versioning**: set `defaultVersion` in `host.json`,
and each new instance carries that version for life, so the orchestrator can branch on
`context.version` and keep the old path for old instances. For Python it needs the extension bundle
at 4.30.0 or later. The other two are a **side-by-side deployment**, the new code in a new app or on
a new task hub while the old one drains, and, only for development, stopping every instance in
flight.

## When this is the tool, and when it is not

Not run in this course: it needs a subscription.

Durable Functions is code. The orchestration lives in `function_app.py`, is tested and reviewed like
any other Python, and runs on the plans of lesson 16 with no extra resource on the default provider.
A timer that fires on an app scaled to zero wakes it up: the documentation says the timer message
becoming visible is what activates the app again. The price is the rules of the section `replay`
and the versioning above, which no linter checks for you.

The alternatives make a different trade. Lesson 15's queue between two functions is simpler for a
single hand-off and has no history to replay. **Logic Apps, lesson 19, writes the workflow as a
document instead of code**, with connectors for other services and a designer, and does its own
waiting. A sequence of a few steps in
code, owned by developers, with waits and fan-outs, is what Durable Functions is for.
