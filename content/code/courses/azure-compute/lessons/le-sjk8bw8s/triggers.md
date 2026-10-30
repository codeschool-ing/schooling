---
title: "Triggers: what starts a function, and what happens when it fails"
version: 1
---

**A function has exactly one trigger**, and the trigger decides three things: what makes the
function run, what it is handed when it does, and what a failure means. The last of the three is the
one that changes how the code has to be written. An HTTP trigger answers somebody who is waiting, so
a failure is an error they receive and nothing is tried again. A queue trigger answers nobody: the
host takes a message, runs the function, and **if the function fails the message goes back on the
queue and is tried again, five times in all, before the host moves it aside**. Both are practised in
this section, on the laptop.

It is easy to picture a trigger as something that calls your code. For HTTP that is roughly true:
the host's web server receives a request and runs the function for it. For a queue it is not.
Nothing pushes a message at the function; **the host polls the queue**, waiting a little longer
after each empty look, up to a minute by default, and runs the function for each message it finds.
The function is the same Python either way. What surrounds it is not.

## An HTTP trigger, failing

The app from the last section is still running, and `take_order` assumes its body is JSON. Send it
something that is not:

```
ana@laptop:~/azure$ curl -s -i -XPOST localhost:8080/api/orders -d 'hello'
HTTP/1.1 500 Internal Server Error
Content-Length: 0
Date: Fri, 30 Oct 2026 18:40:27 GMT
Server: Kestrel

ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep "Executed 'Functions"
      Executed 'Functions.take_order' (Succeeded, Id=f55efa35-8e2c-47b9-828b-e5d6a4d816f5, Duration=117ms)
      Executed 'Functions.take_order' (Failed, Id=385b2b08-23c7-4352-afaa-cab31412f94e, Duration=59ms)
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -E '^ +Exception: '
      Exception: ValueError: HTTP request does not contain valid JSON data
```

`req.get_json()` raised, nothing caught it, and the host answered `500` with an empty body. The
traceback went to the log, where the client cannot see it. **Nothing was retried**: the request is
over, and whether to send it again is the caller's decision.

## The second version: a queue between the two halves

The shop does not want the customer waiting while a receipt is worked out. So `take_order` checks
the order, writes it to a queue called `orders` and answers at once, and a second function,
`make_receipt`, takes it from the queue and does the work. Replace `~/azure/shopfn/function_app.py`
with this. The lines that start with `@app.queue_output` and `@app.blob_output` are bindings, the
next section's subject; for now, read them as "write to the queue" and "write a receipt":

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport json\nimport logging\n\nimport azure.functions as func\n\napp = func.FunctionApp()\n\nPRICES = {'mug': 2990, 'tee': 5900, 'cap': 4500}\n\n\n", "note": "The same start, and the shop's three products with their prices in cents. A real shop keeps its prices elsewhere; here they keep the example to one file."}, {"code": "@app.route(route='orders', methods=['POST'], auth_level=func.AuthLevel.ANONYMOUS)\n@app.queue_output(arg_name='queued', queue_name='orders', connection='ShopStorage')\ndef take_order(req: func.HttpRequest, queued: func.Out[str]) -> func.HttpResponse:\n", "note": "The same trigger, and below it an output binding to the queue `orders`. Its `arg_name` is the second parameter: `queued` is where the function puts the message."}, {"code": "    try:\n        order = req.get_json()\n        ok = isinstance(order.get('order'), str) and isinstance(order.get('qty'), int)\n    except (ValueError, AttributeError):\n        ok = False\n    if not ok:\n        return func.HttpResponse('{\"error\": \"not an order\"}\\n', status_code=400,\n                                 mimetype='application/json')\n", "note": "Now the body is checked: an order needs a text `order` and a whole-number `qty`. Anything else gets a `400` the code chose, instead of the host's `500`. The product is not checked here."}, {"code": "    queued.set(json.dumps(order))\n    body = json.dumps({'accepted': order['order']})\n    return func.HttpResponse(body + '\\n', status_code=202, mimetype='application/json')\n\n\n", "note": "`set()` hands the order to the binding, and the host writes it to the queue. `202` tells the client the order was accepted and is not finished."}, {"code": "@app.queue_trigger(arg_name='msg', queue_name='orders', connection='ShopStorage')\n@app.blob_output(arg_name='receipt', path='receipts/{order}.json', connection='ShopStorage')\ndef make_receipt(msg: func.QueueMessage, receipt: func.Out[str]) -> None:\n", "note": "**The second function.** Its trigger is the same queue, and its output is a blob whose name comes from the message, `receipts/{order}.json`."}, {"code": "    order = json.loads(msg.get_body())\n    logging.info('order %s, attempt %d', order['order'], msg.dequeue_count)\n    cents = PRICES[order['sku']] * order['qty']\n    receipt.set(json.dumps({'order': order['order'], 'qty': order['qty'], 'cents': cents}))\n", "note": "`msg.get_body()` is the message, and `dequeue_count` is how many times the host has taken it from the queue. A product with no price raises `KeyError`, and nothing catches it."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The path of one order. A client posts it; the HTTP trigger runs take_order, whose queue output writes it to the orders queue. The host polls that queue, and the queue trigger runs make_receipt, whose blob output writes receipts/A-1001.json. A message that fails five times goes to orders-poison instead. The two functions are drawn as your code; every arrow is the host’s work.\"><defs><marker id=\"op-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"op-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a client</text><rect x=\"210\" y=\"40\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">take_order</text><rect x=\"440\" y=\"40\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"510\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><path d=\"M132 60 L206 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"170\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP trigger</text><path d=\"M352 60 L436 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"394\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">queue output</text><rect x=\"440\" y=\"160\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">make_receipt</text><path d=\"M510 82 L510 156\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"522\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">queue trigger:</text><text x=\"522\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the host polls</text><rect x=\"170\" y=\"160\" width=\"190\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"265\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">receipts/A-1001.json</text><path d=\"M438 180 L364 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"401\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">blob output</text><rect x=\"440\" y=\"270\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"510\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-poison</text><path d=\"M510 202 L510 266\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#op-ah-a)\"></path><text x=\"522\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">after five</text><text x=\"522\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">failed attempts</text><rect x=\"20\" y=\"252\" width=\"22\" height=\"14\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"259\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your code</text><path d=\"M20 288 L42 288\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#op-ah)\"></path><text x=\"50\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the host’s work</text></svg>", "caption": "One order through the two functions of this section. The code is the two amber boxes; every arrow between them, including the five attempts and the move to the poison queue, is the host’s."}
```

Build it as a second image, replace the container, and give it the second setting it now names:

```
ana@laptop:~/azure$ docker build -q -t shopfn:2 shopfn
sha256:5815df7545d3f903ceea40142f0ac9bff14d3244769c09e579c3c0fb42c604d8
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e ShopStorage="$FN_STORAGE" shopfn:2
68ea96a372f6f321ac057cb1798bf8912db70e122bfb84b9cc1ec40e00b58e0d
```

`ShopStorage` points at the same Azurite as `AzureWebJobsStorage` here. Keeping it a separate
setting costs one `-e` on the laptop and pays for itself in Azure, as the next section explains.

## A queue trigger, succeeding

```
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}'
{"accepted": "A-1001"}
HTTP 202
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d 'hello'
{"error": "not an order"}
HTTP 400
```

The first order was accepted with `202`, the HTTP code for "accepted, not yet done", and the body
that was not an order got a `400` from the code instead of a `500` from the host. A moment later the
host found the message on the queue:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E 'Trigger Details|order A-|Executed .Functions.make_receipt'
      Trigger Details: MessageId: 1541566d-ea27-47c0-b5e8-537b06fa6ce0, DequeueCount: 1, InsertedOn: 2026-10-30T18:40:41.000+00:00
      order A-1001, attempt 1
      Executed 'Functions.make_receipt' (Succeeded, Id=4a3f5024-24c7-483c-bbfb-62ac1bec7beb, Duration=579ms)
```

`Trigger Details` is the host describing the message before the function sees it: its id, how many
times it has been taken from the queue, and when it was put there. The function's own line reads the
same `dequeue_count` from the message it was handed.

**What each trigger hands the function is a typed object**, documented per trigger. These are the
two this app uses:

| trigger | type | what it carries |
| --- | --- | --- |
| HTTP | `func.HttpRequest` | `method`, `url`, `headers`, `params` (the query string), `route_params`, `get_body()` and `get_json()` |
| queue | `func.QueueMessage` | `get_body()`, `id`, `dequeue_count`, `insertion_time`, `expiration_time`, `time_next_visible`, `pop_receipt` |

## A queue trigger, failing five times

The second order names a product the shop does not sell. `take_order` does not check products, so it
accepts the order; `make_receipt` looks the price up and fails:

```
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "lamp", "qty": 1}'
{"accepted": "A-1002"}
HTTP 202
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E 'order A-1002|reached MaxDequeueCount'
      order A-1002, attempt 1
      order A-1002, attempt 2
      order A-1002, attempt 3
      order A-1002, attempt 4
      order A-1002, attempt 5
      Message has reached MaxDequeueCount of 5. Moving message to queue 'orders-poison'.
```

**Five attempts, one after another, and then the message was moved to `orders-poison`.** The host
made those attempts, not the code: each time the function raised, the host put the message back,
took it again, and counted. The host's own lines show one success, the first order, and five
failures with the same cause:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep "Executed 'Functions.make_receipt'"
      Executed 'Functions.make_receipt' (Succeeded, Id=4a3f5024-24c7-483c-bbfb-62ac1bec7beb, Duration=579ms)
      Executed 'Functions.make_receipt' (Failed, Id=17acea7e-796c-4716-a19d-abebfd270b4e, Duration=50ms)
      Executed 'Functions.make_receipt' (Failed, Id=24ad1b7e-3e38-45a5-a3e4-b7da7ceab7f5, Duration=14ms)
      Executed 'Functions.make_receipt' (Failed, Id=56a98279-60cf-409c-b258-34538154c3ba, Duration=5ms)
      Executed 'Functions.make_receipt' (Failed, Id=c33cd194-af50-45a1-912c-f4df94945df9, Duration=5ms)
      Executed 'Functions.make_receipt' (Failed, Id=9429da22-74f0-44e2-9b2c-40b5ca4a2656, Duration=8ms)
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -E '^ +Exception: '
      Exception: KeyError: 'lamp'
```

The queue `orders-poison` is named after the original with `-poison` added, and it holds the message
the function could not handle, so that a person can look at it, or another function can be triggered
by it and raise an alarm:

```
ana@laptop:~/azure$ az storage queue list --only-show-errors --query "[].name" -o tsv
orders
orders-poison
ana@laptop:~/azure$ az storage message peek -q orders-poison --only-show-errors
[
  {
    "content": "ewogICJvcmRlciI6ICJBLTEwMDIiLAogICJza3UiOiAibGFtcCIsCiAgInF0eSI6IDEKfQ==",
    "dequeueCount": 0,
    "expirationTime": "2026-11-06T18:40:44+00:00",
    "id": "941a8280-30d8-4e06-8de4-0361cb1c7700",
    "insertionTime": "2026-10-30T18:40:44+00:00",
    "popReceipt": null,
    "timeNextVisible": null
  }
]
```

The message keeps its content, which the next section reads. Nothing in the app will remove it from
`orders-poison`: it stays until somebody deletes it or it expires, a week after it was put there by
the dates above.

## The settings behind that behaviour

The five and the burst are settings of the queue extension, and the host prints them when it starts:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -A8 '^      QueuesOptions'
      QueuesOptions
      {
        "BatchSize": 16,
        "NewBatchThreshold": 32,
        "MaxPollingInterval": "00:01:00",
        "MaxDequeueCount": 5,
        "VisibilityTimeout": "00:00:00",
        "MessageEncoding": "Base64"
      }
ana@laptop:~/azure$ docker exec shopfn nproc
4
```

`MaxDequeueCount` is the five. `VisibilityTimeout` of zero is why the attempts came in a burst: **a
failed message is visible again immediately**, so a cause that clears in a few seconds, a database
restarting, say, can use up all five attempts before it clears. `BatchSize` is how many messages the
host takes from the queue at once, and the host fetches more when the messages still being worked on
fall to `NewBatchThreshold`. The documentation gives its default as N × `BatchSize` / 2, where N is
the number of vCPUs on App Service and Premium plans and 1 on the Consumption plan. The 32 here
matches 16 × 4 / 2 for the four processors `nproc` reported. `MaxPollingInterval` is the longest the
host waits between looks at an empty queue, and `MessageEncoding` is the next section's.

Each of them is set in `host.json`, under `extensions.queues`. To wait thirty seconds between
attempts and give up after three, the file would carry an `extensions` block like this one next to
its `extensionBundle`. It is shown alone here, and this lesson does not use it:

```json
{
  "version": "2.0",
  "extensions": {
    "queues": {
      "maxDequeueCount": 3,
      "visibilityTimeout": "00:00:30"
    }
  }
}
```

**The retry is for causes that go away, and the poison queue is for the ones that do not.** An
unknown product will fail on every attempt, and nothing about trying again helps. A function that
can tell the two apart is better off refusing the bad message itself, logging why, and returning
normally, which deletes it from the queue. What `make_receipt` does instead, raising for a missing
price, spends five attempts on an answer it could have had from the first.
