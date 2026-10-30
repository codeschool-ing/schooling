---
title: Bindings, and why they are the point
version: 1
---

Read `make_receipt` again and count what it does not contain. **No storage client, no connection
string, no queue name in a call, no retry loop, no code that deletes a message once it is handled
and no code that writes a blob.** It has four lines of work: read the order, log it, work out the
price, hand over the receipt. Everything else in the last section, from the polling to the five
attempts to the poison queue, the host did, because two decorators said so. That is what a binding
is: **a declaration that the host does a piece of input or output for the function**, configured by
a name and a setting rather than written as code. A trigger is a binding too, the special input
binding that also starts the function, and Microsoft's documentation describes it exactly that way.

## Reading the declarations

The documentation's definition is short: bindings "either pass data into your function (an *input
binding*) or enable you to write data out from your function (an *output binding*)", a function may
have any number of them, and they are optional. In the v2 model each one is a decorator, and each
names a parameter of the function with `arg_name`:

| decorator | direction | the parameter | what the host does with it |
| --- | --- | --- | --- |
| `@app.route` | trigger | `req: func.HttpRequest` | turns the request into the object, and the returned `HttpResponse` into the answer |
| `@app.queue_output` | out | `queued: func.Out[str]` | writes what the function `set()` as a message on `orders` |
| `@app.queue_trigger` | trigger | `msg: func.QueueMessage` | polls `orders`, deletes the message on success, retries and moves it aside on failure |
| `@app.blob_output` | out | `receipt: func.Out[str]` | writes what the function `set()` as the blob at `path` |

`func.Out[str]` is a box the function puts one value in. The worker hands the value back with the
function's result, and the host does the write. And `connection='ShopStorage'` is not a connection
string: **it is the name of the setting that holds one**, which is why the container needed `-e
ShopStorage=…` and why the code never changes between the laptop and Azure.

The blob's path is `receipts/{order}.json`. **The braces are a binding expression**: because the
queue message is JSON, the host can read its properties, and `{order}` becomes the value of the
`order` field of the message that triggered the run. Expressions in percent signs, such as
`%RECEIPTS%`, are read from a setting instead. Here is what the binding wrote for the first order:

```
ana@laptop:~/azure$ az storage blob list -c receipts --only-show-errors --query "[].name" -o tsv
A-1001.json
ana@laptop:~/azure$ az storage blob download -c receipts -n A-1001.json -f A-1001.json --no-progress --only-show-errors -o none
ana@laptop:~/azure$ cat A-1001.json; echo
{"order": "A-1001", "qty": 2, "cents": 5980}
```

One receipt: `A-1001.json`, named from the message, with 2 × 2990 cents in it. There is none for
`A-1002`, whose function never reached `set()`.

## What was on the queue

The binding also decided the form of the message. The poisoned one is still in `orders-poison`, and
its `content` was not the JSON `take_order` wrote:

```
ana@laptop:~/azure$ az storage message peek -q orders-poison --only-show-errors --query "[0].content" -o tsv
ewogICJvcmRlciI6ICJBLTEwMDIiLAogICJza3UiOiAibGFtcCIsCiAgInF0eSI6IDEKfQ==
ana@laptop:~/azure$ az storage message peek -q orders-poison --only-show-errors --query "[0].content" -o tsv | base64 -d; echo
{
  "order": "A-1002",
  "sku": "lamp",
  "qty": 1
}
```

**The queue extension writes and reads its messages base64-encoded**; that is the `MessageEncoding:
Base64` the host printed in the last section, and the setting is `extensions.queues.messageEncoding`
in `host.json`, with `none` as the other value. Inside the encoding is the order as the host wrote
it, indented on the way; `take_order` had passed a compact string to `set()`. It matters the day
something other than a binding writes to the queue. The documentation puts it as "Functions expect a
*base64* encoded string", and leaves the encoding to the sender: a program putting orders on
`orders` has to encode them the same way, or both sides have to agree on `none`.

## The extension bundle

The host itself knows how to run two triggers, HTTP and timer. **Every other trigger and binding is
an extension**, a .NET package that teaches the host a new type. The extension bundle is how a
Python app gets them "without having to interact with .NET infrastructure", in the documentation's
words: a set of extensions, versioned together and tested together, which the host loads when
`host.json` asks for it. The range `[4.*, 5.0.0)` means the newest 4.x bundle available. In Azure,
new bundle versions are fetched from Microsoft's own download endpoint when the app is updated.
Microsoft's image carries one already:

```
ana@laptop:~/azure$ docker exec shopfn ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle
4.39.1
ana@laptop:~/azure$ docker exec shopfn sh -c 'ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin' | grep -c '^Microsoft.Azure.WebJobs.Extensions'
21
ana@laptop:~/azure$ docker exec shopfn sh -c 'ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin' | grep '^Microsoft.Azure.WebJobs.Extensions.Storage'
Microsoft.Azure.WebJobs.Extensions.Storage.Blobs.dll
Microsoft.Azure.WebJobs.Extensions.Storage.Queues.dll
```

Bundle 4.39.1 was the one in this copy of the image, with 21 extension libraries in it. The two
storage ones are the queue and the blob bindings this app uses; the same directory holds Service
Bus, Event Hubs, Cosmos DB, Durable Task and more. To see what the bundle is for, take it away. Copy
the app, remove the block from the copy's `host.json`, and start it beside the real one:

```
ana@laptop:~/azure$ cp -r shopfn nobundle
ana@laptop:~/azure$ jq 'del(.extensionBundle)' shopfn/host.json > nobundle/host.json
ana@laptop:~/azure$ cat nobundle/host.json
{
  "version": "2.0"
}
ana@laptop:~/azure$ docker build -q -t shopfn:nobundle nobundle
sha256:2e9a89cc8c486930c4322620517fae27e90acfcfa18c80a9483fa790f085cb82
ana@laptop:~/azure$ docker run -d --name nobundle --network functions -p 8081:80 -e AzureWebJobsStorage="$FN_STORAGE" -e ShopStorage="$FN_STORAGE" shopfn:nobundle
385a6a91006d820f5aa41283211ca9f6a72ca7911ab8ccaea14c692d96c800c7
ana@laptop:~/azure$ docker logs nobundle 2>&1 | grep 'is in error'
      The 'make_receipt' function is in error: The binding type(s) 'queueTrigger, blob' are not registered. Please ensure the type is correct and the binding extension is installed.
      The 'take_order' function is in error: The binding type(s) 'queue' are not registered. Please ensure the type is correct and the binding extension is installed.
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8081/api/orders -d '{"order": "A-1003", "sku": "tee", "qty": 1}'
HTTP 404
```

The host started, and refused both functions. `make_receipt` uses two types it no longer knows, and
**`take_order` failed too, although HTTP is built in**, because its queue output is not: a function
is loaded with all its bindings or not at all. The route was never mapped, so the request got `404`,
which would be a confusing answer to debug from the client's side.

## Why bindings are the point

The code is short because the host does the parts that go wrong. Those parts are also what an
operator wants to configure without a new build: how many attempts, how long between them, how many
messages at once, which account. They are host settings, in `host.json` or in application settings,
and the same image runs with different ones. **And the host knows what each function is waiting
for**, which is what lets Azure add instances when the `orders` queue grows; lesson 16 takes that up
with the plans.

Two costs come with it. A binding offers what its extension offers and nothing more. The code "can't
access the underlying clients used by your binding extensions", in the documentation's words, so a
write the binding cannot express is done with the Azure SDK, created and configured by the function
itself. And the shape of the code, decorators naming Azure's services, belongs to Azure Functions;
lesson 22 counts that kind of lock-in against the others.

## Connections in Azure, not run here

On the laptop each connection is a connection string with an account key. In Azure the documented
way is an identity: the function app's managed identity, which `azure-foundations` lesson 8
introduced, granted roles on the storage account. A setting name then becomes a prefix for several
settings, joined to it with a double underscore. For the host's own storage, two settings replace
the string, the account's name and the kind of credential:

```sh
az functionapp config appsettings set --name shop-fn --resource-group shop-rg --settings AzureWebJobsStorage__accountName=shopfnstore AzureWebJobsStorage__credential=managedidentity
```

For `ShopStorage`, the service addresses and the kind of credential:

```sh
az functionapp config appsettings set --name shop-fn --resource-group shop-rg --settings ShopStorage__queueServiceUri=https://shopdata.queue.core.windows.net ShopStorage__blobServiceUri=https://shopdata.blob.core.windows.net ShopStorage__credential=managedidentity
```

Neither was run in this course. **With managed identities, the documentation asks for a separate
connection like `ShopStorage` for anything that is not the host itself**, even where the host's own
connection would reach the same account. That is why the code never named `AzureWebJobsStorage`. The
roles are granted per binding, with RBAC as `azure-foundations` lesson 9 taught it. The
documentation's table lists them: Storage Blob Data Owner for the host's connection, Storage Queue
Data Reader with Storage Queue Data Message Processor for a queue trigger, Storage Queue Data
Contributor for a queue output, and Storage Blob Data Owner for a blob output.

To stop the lab, remove the containers and the network; lessons 16 and 17 start them again from
`storage.sh` and the four files:

```sh
docker rm -f shopfn nobundle azurite
docker network rm functions
```
