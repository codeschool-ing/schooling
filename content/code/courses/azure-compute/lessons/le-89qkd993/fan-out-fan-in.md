---
title: "Fan-out, fan-in: many activities, one yield"
version: 1
---

An order with six lines needs six reservations, and the first version of `order_flow` would make
them one after another, a second each. The obvious fix is threads, or `asyncio.gather`, inside the
orchestrator. **Neither is allowed, and neither is needed.** An orchestrator does not run the work;
it asks for it. Asking for six activities and waiting once for all six is one line each, and the
six run wherever the host has room for them, on as many instances as the plan gives the app. This
is **fan-out**, scheduling many activities, and **fan-in**, waiting for all of them and collecting
their results.

## The code

The order now carries a list of `lines`, and the reservation becomes one activity per line. Replace
`~/azure/shopfn/function_app.py` again; the starter and the last two activities do not change:

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport logging\nimport time\n\nimport azure.functions as func\nimport azure.durable_functions as df\n\napp = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)\n\n\n"}, {"code": "@app.route(route='orders', methods=['POST'])\n@app.durable_client_input(client_name='client')\nasync def start_order(req: func.HttpRequest, client: df.DurableOrchestrationClient) -> func.HttpResponse:\n    order = req.get_json()\n    instance_id = await client.start_new('order_flow', order['order'], order)\n    logging.info('started %s', instance_id)\n    return client.create_check_status_response(req, instance_id)\n\n\n"}, {"code": "@app.orchestration_trigger(context_name='context')\ndef order_flow(context: df.DurableOrchestrationContext):\n    order = context.get_input()\n    started = context.current_utc_datetime\n", "note": "The order now has `lines`, and the orchestrator notes the time it started from `context`, never from the machine's clock."}, {"code": "    tasks = [context.call_activity('reserve_line', line) for line in order['lines']]\n    reserved = yield context.task_all(tasks)\n", "note": "**The fan-out is the line without `yield`.** `call_activity` returns a task and schedules nothing yet; the list holds one per line. **The fan-in is `task_all`**: one `yield` for all of them, which resumes the orchestrator when the last one is done, with the results in the order of the list."}, {"code": "    seconds = (context.current_utc_datetime - started).total_seconds()\n    charged = yield context.call_activity('charge', order)\n    shipped = yield context.call_activity('ship', order)\n    return {'reserved': reserved, 'reserve_s': seconds, 'then': [charged, shipped]}\n\n\n", "note": "`reserve_s` is how long the reservations took as the orchestration saw it, from the start to the moment it resumed. Then the same two steps as before, one after the other."}, {"code": "@app.activity_trigger(input_name='line')\ndef reserve_line(line: dict) -> str:\n    time.sleep(1)\n    return f\"reserved {line['qty']} x {line['sku']}\"\n\n\n", "note": "One line of the order per call, a second each, as `reserve_stock` was for the whole order."}, {"code": "@app.activity_trigger(input_name='order')\ndef charge(order: dict) -> str:\n    time.sleep(1)\n    return f\"charged {order['order']}\"\n\n\n@app.activity_trigger(input_name='order')\ndef ship(order: dict) -> str:\n    time.sleep(1)\n    return f\"shipped {order['order']}\"\n"}]}
```

**A `call_activity` without a `yield` schedules nothing yet.** It returns a task, and the list holds
six of them. The one `yield` hands the whole list to the extension, which writes six requests to the
work-item queue in a single checkpoint and wakes the orchestrator again only when the sixth has
answered. The results come back in the order of the list, not the order the activities finished in.

`reserve_s` measures the reservations with the orchestration's own clock, from the start to the run
that found all of them done. It is replay-safe for the reason the previous section gave: both values
come from the history.

## One line, and six

Build it, replace the container, and send a one-line order and a six-line one:

```
ana@laptop:~/azure$ docker build -q -t shopfn:df2 shopfn
sha256:a98e3a0f5d02e973bbcfba021120cd726248c5452dbb7b555561fd51454baca9
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df2
2632ad6e0c11c6712d59592af97da8c65490ff727041a23e264b55a033e2d1af
ana@laptop:~/azure$ S4=$(curl -s -XPOST localhost:8080/api/orders -d '{"order": "A-1004", "lines": [{"sku": "mug", "qty": 2}]}' | jq -r .statusQueryGetUri)
ana@laptop:~/azure$ curl -s "$S4" | jq -c .output
{"reserved":["reserved 2 x mug"],"reserve_s":1.377018,"then":["charged A-1004","shipped A-1004"]}
ana@laptop:~/azure$ S5=$(curl -s -XPOST localhost:8080/api/orders -d '{"order": "A-1005", "lines": [{"sku": "mug", "qty": 2}, {"sku": "tee", "qty": 1}, {"sku": "lamp", "qty": 1}, {"sku": "cap", "qty": 3}, {"sku": "pen", "qty": 10}, {"sku": "bag", "qty": 1}]}' | jq -r .statusQueryGetUri)
ana@laptop:~/azure$ curl -s "$S5" | jq .output
{
  "reserved": [
    "reserved 2 x mug",
    "reserved 1 x tee",
    "reserved 1 x lamp",
    "reserved 3 x cap",
    "reserved 10 x pen",
    "reserved 1 x bag"
  ],
  "reserve_s": 1.122941,
  "then": [
    "charged A-1005",
    "shipped A-1005"
  ]
}
```

**Six reservations took about as long as one**, roughly a second and a little more, since each
activity sleeps for a second. The first version needed a second and a bit per step in the host's
log, one after another, so six lines in sequence would have been six of those. The fan-out bought
the difference with no change to `reserve_line` and no thread anywhere in the code.

`then` shows the rest of the order going on as before: `charge` waits for every reservation, then
`ship` waits for `charge`. A fan-out is a step in the sequence, not a change to it.

## Sixty lines, and the limit

Sixty lines is a big order for a shop and a fair test of what the host does with more work than it
has room for. Write the order with a short Python line, send it, and read the result:

```
ana@laptop:~/azure$ python3 -c "import json; print(json.dumps({'order': 'A-1006', 'lines': [{'sku': f'item-{n}', 'qty': 1} for n in range(60)]}))" > a1006.json
ana@laptop:~/azure$ S6=$(curl -s -XPOST localhost:8080/api/orders -d @a1006.json | jq -r .statusQueryGetUri)
ana@laptop:~/azure$ curl -s "$S6" | jq -c '.output | {reserve_s, lines: (.reserved | length)}'
{"reserve_s":2.532364,"lines":60}
```

Sixty one-second reservations, done in a few seconds rather than one. The log says why. The host
logs a line when each activity starts, and `docker logs -t` puts a time on it. The `awk` program
turns each time into whole seconds after the first start, and `uniq -c` counts them:

```
ana@laptop:~/azure$ docker logs -t shopfn 2>&1 | grep "A-1006: Function 'reserve_line (Activity)' started" | awk -F'[T:Z]' '{s = $2 * 3600 + $3 * 60 + $4; if (NR == 1) first = s; print int(s - first)}' | uniq -c
     40 0
     20 1
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o '"maxConcurrentActivityFunctions":[0-9]*'
"maxConcurrentActivityFunctions":40
ana@laptop:~/azure$ docker exec shopfn nproc
4
```

**Forty started at once and the rest waited for a slot.** The cap is a setting of the extension,
`maxConcurrentActivityFunctions`, and the host printed its value in its configuration at start-up.
The documentation gives its default as 10 times the number of processors on a Premium or Dedicated
plan, and 10 on Consumption; the container saw four processors, and four times ten is forty. It is
**per instance of the host**: on a plan that adds instances, the waiting activities can go to
another one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Sixty reserve_line activities of order A-1006 drawn as squares. Forty start in the first second, the limit of ten per processor on four processors; the other twenty start as slots free up.\"><rect x=\"40\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"40\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"66\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"92\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"118\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"144\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"170\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"196\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"222\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"70\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"96\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"122\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"148\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"380\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"406\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"432\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"458\" y=\"174\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"141.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">second 1: forty start</text><text x=\"429.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">then the other twenty</text><text x=\"141.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">maxConcurrentActivityFunctions = 10 × 4 processors</text><text x=\"429.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each waits for one of the forty to finish</text><path d=\"M40 244 L650 244\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M650 239 L660 244 L650 249 z\" fill=\"var(--wire)\"></path><text x=\"668\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><text x=\"40\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one square = one reserve_line, one second of work</text></svg>", "caption": "Sixty activities, one host. The extension starts as many as its limit allows and queues the rest on the work-item queue, where another instance of the app could take them."}
```

The documentation's page on performance has a warning for Python: that a Python app can run only
one function at a time on one machine, so nine of ten fanned-out activities would sit waiting.
**That is not what this laptop showed**: forty ran at once in one Python worker. Measure it on the
instance size you deploy before relying on either number, and if the activities are slow, the same
page's advice is to set the cap to what the worker really runs.

## What the history pays for it

Every activity is two events in the history, its request and its result:

```
ana@laptop:~/azure$ az storage entity query -t TestHubNameHistory --filter "PartitionKey eq 'A-1006'" --query 'length(items)'
171
```

A hundred and seventy-one rows for one order. Every later run of the orchestrator reads all of them
back before it can take its next step, so an orchestration that fans out to thousands of items
makes every replay slow and every instance's memory large. The documentation's answers are three:
keep what activities return small (a reference to a blob rather than the blob), lower the
concurrency, or split the work into **sub-orchestrations**, orchestrators called with
`context.call_sub_orchestrator`, each with a history of its own. Not run here.

A failure inside a fan-out ends the whole `task_all`: the documentation says that in Python the
first activity to fail makes the task complete with an error, which the orchestrator catches with
`try` and `except` like any exception. An activity can also be called with
`context.call_activity_with_retry` and a `df.RetryOptions` saying how long to wait before the first
retry and how many attempts to make. A retry is the second run of an activity for the same input,
which is why the previous section asked that activities be safe to run twice. Neither was run here.

## On the plans of lesson 16

Not run in this course: it needs a subscription.

Orchestrators and activities scale differently, and the documentation is explicit about both. **An
activity is stateless and can run on any instance**: every instance of the app competes for the
work-item queue, so fanned-out activities spread across whatever instances the plan has added.
**An instance's orchestrator runs on one host at a time**, the one holding the lease on its
control queue. The Azure Storage provider has four partitions by default and at most
sixteen, so at most sixteen instances of the app run orchestrators
at once. The advice is to keep orchestrators light and put the heavy work in activities, which have
no such ceiling.

On the plans themselves:

- **Flex Consumption** scales all of an app's Durable functions together as one group, which lesson
  16 named. For Durable Functions on the Azure Storage provider, the documentation recommends one
  always-ready instance for the `durable` group and a queue polling interval of ten seconds or less,
  because a plan that scales to zero hears about new work by polling.
- **Consumption** has the default of 10 activities per instance, and bills every replay as an
  execution.
- **Premium and Dedicated** run 10 per processor by default, and never stop.

None of them changes the code. The plan decides how many hosts there are; the orchestration decides
what work exists.
