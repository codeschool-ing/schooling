---
title: An orchestrator, its activities, and the function that starts them
version: 1
---

The name suggests a function that runs for a long time: an order starts it, and it stays up until
the parcel ships. **Nothing in Durable Functions runs for long.** An order becomes an
**orchestration instance**, which is a record in the storage account, and a few short functions
that each run for a moment and stop. The record says how far the order has got. The functions read
it, do the next step, and write it back. That is what lets an order last a week on a plan that
gives a function five minutes.

Durable Functions is an extension of the Functions host, and it works through three kinds of
function in the same app. A **client function** starts an instance and can ask about it; here it is
the HTTP function that takes an order. An **orchestrator function** says, in ordinary Python, which
steps the order goes through and in what order. **Activity functions** do the steps: reserve the
stock, charge the customer, ship the parcel. The orchestrator never does a step itself, and an
activity never knows what comes after it.

Lesson 15 split the same work across a queue: one function took the order and a second picked it up.
That works for one hand-off. With three steps it becomes three queues and three functions, and
nothing in the app knows where a given order is. Lesson 16 gave the other reason: **an HTTP function
has 230 seconds to answer**, and the documentation sends longer work to a queue or to Durable
Functions. This section builds the shop's order flow both ways round, as code and as a record, and
runs it on the laptop with lesson 15's setup.

## One more line in requirements.txt

The Python side is a package, `azure-functions-durable`. Add it to lesson 15's file, pinned to the
version these transcripts were recorded with:

```sh
echo azure-functions-durable==1.7.0 >> ~/azure/shopfn/requirements.txt
```

```
ana@laptop:~/azure$ cat shopfn/requirements.txt
azure-functions
azure-functions-durable==1.7.0
```

1.7.0 was the version `pip` installed on 2026-10-30. The documentation asks for 1.2.2 or later, with
the extension bundle at version 4 or later, which `host.json` already says. **The other half is the
extension, and it is already in the image**: Durable Functions for Python, like every non-.NET
language, gets the extension from the bundle lesson 15 looked inside, and `host.json` does not
change. Nor does the `Dockerfile`.

## The code

Replace `~/azure/shopfn/function_app.py` with this file. Lesson 15's two functions leave the app: the
order now goes through an orchestration instead of a queue.

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport logging\nimport time\n\nimport azure.functions as func\nimport azure.durable_functions as df\n\napp = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)\n\n\n", "note": "`df.DFApp` is lesson 15's `func.FunctionApp` with the Durable Functions decorators added to it, from the package `azure.durable_functions`. `http_auth_level` is the level every HTTP function in the app gets unless it says otherwise; `ANONYMOUS` asks for no key, as in lesson 15."}, {"code": "@app.route(route='orders', methods=['POST'])\n@app.durable_client_input(client_name='client')\nasync def start_order(req: func.HttpRequest, client: df.DurableOrchestrationClient) -> func.HttpResponse:\n    order = req.get_json()\n    instance_id = await client.start_new('order_flow', order['order'], order)\n    logging.info('started %s', instance_id)\n    return client.create_check_status_response(req, instance_id)\n\n\n", "note": "**The client function.** It is an ordinary HTTP function with one more decorator, `durable_client_input`, which hands it a client for the task hub. `start_new` names the orchestrator, gives the instance an id, here the order's own number, and passes the order as input. It returns as soon as the start is recorded, before any step has run, and `create_check_status_response` answers 202 with the addresses for asking about the instance."}, {"code": "@app.orchestration_trigger(context_name='context')\ndef order_flow(context: df.DurableOrchestrationContext):\n    order = context.get_input()\n    logging.info('order_flow for %s, replaying=%s', order['order'], context.is_replaying)\n", "note": "**The orchestrator.** A generator, not an `async` function: the documentation forbids coroutines here. It gets nothing but `context`, and the input comes out of it. The log line is there for the section `replay`, which explains why it is printed more than once."}, {"code": "    reserved = yield context.call_activity('reserve_stock', order)\n    charged = yield context.call_activity('charge', order)\n    shipped = yield context.call_activity('ship', order)\n    return [reserved, charged, shipped]\n\n\n", "note": "Each `yield` hands a request back to the extension: run this activity, with this input. The orchestrator stops there, and the next line runs only when the result is in. Three yields, three steps in order, and what `return` gives becomes the instance's output."}, {"code": "@app.activity_trigger(input_name='order')\ndef reserve_stock(order: dict) -> str:\n    time.sleep(1)\n    return f\"reserved {order['qty']} x {order['sku']}\"\n\n\n", "note": "**An activity** is where the work is: here a second of sleep stands in for a call to the stock service. `input_name` names the parameter that receives the input. What it returns is written into the instance's history, which is why an activity returns something small and JSON-shaped."}, {"code": "@app.activity_trigger(input_name='order')\ndef charge(order: dict) -> str:\n    time.sleep(1)\n    return f\"charged {order['order']}\"\n\n\n@app.activity_trigger(input_name='order')\ndef ship(order: dict) -> str:\n    time.sleep(1)\n    return f\"shipped {order['order']}\"\n", "note": "The other two steps, of the same shape. Neither knows it is part of an orchestration."}]}
```

**An orchestrator is a list of steps written as code, and each `yield` is a place where it stops.**
The steps are activities called by name; what they return comes back as the value of the `yield`.
Nothing in the file says where the state is kept. That is the extension's job, and the next section
reads what it wrote.

## Starting it

The same commands as lesson 15, with a new tag. If lesson 15's containers are still running, remove
them first with `docker rm -f shopfn azurite`. Start from an empty Azurite:

```
ana@laptop:~/azure$ source storage.sh
ana@laptop:~/azure$ docker network create functions
87504a6dca9b7913198e6f6ba622c911173ae1a943901ba8b105c375c10028eb
ana@laptop:~/azure$ docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
4d296a6d66d7596e311f20be950cb642c0f74a1eb1fec60959c0be8c688b028f
ana@laptop:~/azure$ docker build -q -t shopfn:df1 shopfn
sha256:c90ef17f875b69fd1239fbf5bf03193a2cb1e024c5182896d159bf36d7d1a2ed
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" shopfn:df1
a06840800a293e55475b6dc0be8082fbc7d497202e2dc4dc5e4e8ff978767e2c
```

The host found five functions, and the Durable Functions extension is in the bundle, in several
pieces:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -A6 "Found the following functions"
      Found the following functions:
      Host.Functions.charge
      Host.Functions.order_flow
      Host.Functions.reserve_stock
      Host.Functions.ship
      Host.Functions.start_order
      
ana@laptop:~/azure$ docker exec shopfn sh -c "ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin" | grep -E "^(DurableTask\.(AzureStorage|Netherite|SqlServer)|Microsoft\.Azure\.WebJobs\.Extensions\.DurableTask(\.AzureManaged)?)\.dll"
DurableTask.AzureStorage.dll
DurableTask.Netherite.dll
DurableTask.SqlServer.dll
Microsoft.Azure.WebJobs.Extensions.DurableTask.AzureManaged.dll
Microsoft.Azure.WebJobs.Extensions.DurableTask.dll
```

`DurableTask.AzureStorage` is the storage provider this lesson uses, the one that keeps instances in
a storage account. The `Netherite`, `SqlServer` and `AzureManaged` files are the other three
providers, which the next section reads about. All four come with the bundle, and `host.json` chooses
between them; with nothing said, it is Azure Storage.

## A setting Azure sets for you

Now send an order:

```
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}'
HTTP 500
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o 'Webhooks are not configured[^)]*)'
Webhooks are not configured. This may occur if the environment variable `WEBSITE_HOSTNAME` is not set (should be automatically set for Azure Functions)
```

**The order was refused, and the reason is a setting this machine does not have.** The client
function's answer carries addresses for asking about the instance, and to write them the extension
needs the app's own host name. In Azure the platform sets `WEBSITE_HOSTNAME` on every app, and the
App Service documentation lists it as read-only. In a container on a laptop nobody does, so give it
the address your terminal uses, `localhost:8080`. Give the app a host id at the same time:

```
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df1
4ac19378b6a36743e8d477654b80deae70012bf37204b919c97ca6cf3d104cec
```

`AzureFunctionsWebHost__hostid` is the second setting. Lesson 15 showed that, on a laptop, the host's
id begins with the container's id, so every new container is a new host. In Azure the id comes from
the app's name and stays put. It matters here because the host keeps its keys under that id, and the
addresses the client function returns carry one of them; with a fixed id they keep working after
the container is replaced, which the section `timers-and-events` depends on.

## An order, from start to end

`-D -` prints the answer's headers and `-o` saves its body. `grep` keeps three of the headers, and
`sed` takes the key out of the address, for the reason given below:

```
ana@laptop:~/azure$ curl -s -D - -o a1001.json -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}' | grep -E '^(HTTP|Location|Retry-After)' | sed -E 's/&code[^&[:space:]]*//'
HTTP/1.1 202 Accepted
Location: http://localhost:8080/runtime/webhooks/durabletask/instances/A-1001?taskHub=TestHubName&connection=Storage
Retry-After: 10
ana@laptop:~/azure$ STATUS=$(jq -r .statusQueryGetUri a1001.json)
ana@laptop:~/azure$ for i in $(seq 30); do curl -s "$STATUS" | jq -r .runtimeStatus; sleep 1; done | uniq -c
     14 Pending
      3 Running
     13 Completed
```

**The answer came back at once, with 202 Accepted, before any step had run.** `Location` is where to
ask about the instance and `Retry-After` how many seconds to wait before asking. That is the
documentation's asynchronous HTTP pattern: the client polls the `Location` address, which answers 202
while the instance runs and 200 when it has finished. The loop asked once a second and counted each
status in a row; the first order after the host started waited in `Pending` for fourteen of the thirty polls
before the extension picked it up, then ran its three steps in about a second each.

The body holds the instance's id, which is the order number because the code passed it, and a set
of addresses:

```
ana@laptop:~/azure$ jq -r 'keys[]' a1001.json
id
purgeHistoryDeleteUri
restartPostUri
resumePostUri
rewindPostUri
sendEventPostUri
statusQueryGetUri
suspendPostUri
terminatePostUri
ana@laptop:~/azure$ echo "$STATUS" | sed -E "s/&code[^&]*//"
http://localhost:8080/runtime/webhooks/durabletask/instances/A-1001?taskHub=TestHubName&connection=Storage
```

They are the extension's HTTP management API, one address per thing you can do to an instance. This
lesson uses three of them: the status, raising an event and terminating. Every address carries the
task hub, `TestHubName`, the connection, and a parameter `code` holding a **system key** that grants
every operation in that API on every instance. **Treat the key as a secret**: anybody holding these
addresses can stop any order. The documentation's advice is to keep it out of anything a customer's
browser sees, and these transcripts never print it: `sed` deletes the parameter first. Do the same
before pasting an address into a ticket or a chat.

When the instance has finished:

```
ana@laptop:~/azure$ curl -s "$STATUS" | jq .
{
  "name": "order_flow",
  "instanceId": "A-1001",
  "runtimeStatus": "Completed",
  "input": "{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}",
  "customStatus": null,
  "output": [
    "reserved 2 x mug",
    "charged A-1001",
    "shipped A-1001"
  ],
  "createdTime": "2026-10-30T20:37:52Z",
  "lastUpdatedTime": "2026-10-30T20:38:09Z"
}
```

`output` is what `order_flow` returned, the three results in order. `input` is the order the client
passed, stored as the instance's input. Without the setting `showHistory=true` in the address, the
status leaves the history out; the next section reads it from the table instead.

## One instance per order

The order number is the instance id, and **an id is unique within the task hub**. Send the same
order twice, quickly:

```
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "tee", "qty": 1}'
HTTP 202
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "tee", "qty": 1}'
HTTP 500
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o 'An Orchestration instance with the status [A-Za-z]* already exists'
An Orchestration instance with the status Running already exists
```

The second start was refused while the first was still `Pending`. Using the order number as the id
is what the documentation suggests when an instance maps one to one onto something of the
business's, such as a purchase order. It turns a client's retry of the same order into an error
instead of a second charge. The guard lasts only while the instance runs:

```
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1002", "sku": "tee", "qty": 1}'
HTTP 202
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -m1 -o '"overridableExistingInstanceStates":"[A-Za-z]*"'
"overridableExistingInstanceStates":"NonRunningStates"
```

Once A-1002 had completed, the same start was accepted and the order ran again from the beginning.
The extension's configuration says which states may be started over, and on this host it is
`NonRunningStates`. So a duplicate that arrives after the first copy has finished is not caught by
the id, and the activities are where it has to be caught, which is one of the rules the section
`fan-out-fan-in` comes back to.
