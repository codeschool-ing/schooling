---
title: A function app, and the four files it is made of
version: 1
---

The name suggests that the thing Azure runs is a function: one Python function, uploaded on its own,
called when something happens and gone afterwards. **What Azure runs is a function app**, and the
function is a part of it. A function app is one program, the Functions host, with your code loaded
into it; every function in the app is deployed with the others, shares their settings and their
plan, and scales with them. Microsoft's documentation calls the app "the unit of deployment and
management for your functions", and in Resource Manager it is the same resource type as an App
Service web app, `Microsoft.Web/sites`, which lesson 18 comes back to.

This lesson builds one for the shop, on the laptop, and the next two lessons reuse it: lesson 16
measures how long it takes to start, and lesson 17 adds Durable Functions to it. The shop takes
orders over HTTP with the order API, `shop`, that lessons 7 and 8 ran as a container. Here the
taking of an order moves into a function, and the work that follows it moves into a second one.

## The host, the worker and the storage account

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A function app drawn as one box. Inside it, the Functions host, Microsoft’s .NET process, holds the web server on port 80, the triggers and bindings, and the extensions from the bundle. Beside it, the Python worker runs function_app.py with take_order and make_receipt; the host sends it calls and receives results. Below the app, two storage connections, both used by the host: AzureWebJobsStorage for leases, keys and timers, and ShopStorage for the orders queue and the receipts.\"><defs><marker id=\"fa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"fa-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"510\" height=\"196\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">one function app: deployed, configured and scaled as one</text><rect x=\"40\" y=\"52\" width=\"240\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Functions host</text><text x=\"160\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Microsoft's code, a .NET process</text><rect x=\"56\" y=\"100\" width=\"208\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">web server, port 80</text><rect x=\"56\" y=\"132\" width=\"208\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">triggers and bindings</text><rect x=\"56\" y=\"164\" width=\"208\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">extensions from the bundle</text><rect x=\"360\" y=\"52\" width=\"150\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">Python worker</text><text x=\"435\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your code</text><text x=\"435\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">function_app.py</text><text x=\"435\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">take_order</text><text x=\"435\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">make_receipt</text><path d=\"M282 128 L356 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah)\"></path><path d=\"M358 160 L284 160\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah-a)\"></path><text x=\"320\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">calls</text><text x=\"320\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">results</text><rect x=\"40\" y=\"244\" width=\"240\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AzureWebJobsStorage</text><text x=\"160\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leases, keys, timers</text><rect x=\"300\" y=\"244\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ShopStorage</text><text x=\"415\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the orders queue, the receipts</text><path d=\"M160 204 L160 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah)\"></path><path d=\"M262 204 L380 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah)\"></path><text x=\"552\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The worker never touches storage:</text><text x=\"552\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every read and write in the</text><text x=\"552\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">picture is the host’s.</text></svg>", "caption": "What is inside a function app. The host is the program Azure runs and the one that does all the input and output; the worker only runs the functions it is handed. Both storage connections are the host’s, and only the second is the shop’s own data."}
```

Three parts, and only one of them is yours. **The Functions host** is a .NET program Microsoft
writes. It answers HTTP, watches queues, reads and writes blobs, keeps the logs and decides when a
function runs. **The language worker** is a Python process the host starts beside itself; it imports
your file and runs a function when the host sends it a call, then hands back what the function
returned. The worker never opens a connection to a queue or a blob container: everything your
function reads or writes arrives through the host, which is what the rest of this lesson is about.

The third part is outside the app. **A function app cannot start without a storage account**, named
by the setting `AzureWebJobsStorage`. The host keeps its own state there: a lease that decides which
copy of the app runs a timer, the keys that protect HTTP functions, and the bookkeeping some
triggers need. That is true even of an app whose functions never touch storage, and the next section
shows the lease being taken on the laptop, before any function has run. On the laptop the account is
Azurite, the emulator Microsoft publishes as an image.

## Four files

Microsoft's usual tool for starting a function app is Azure Functions Core Tools, the `func`
command, which writes these files for you and runs the same host on your machine. **This course does
without it.** The four files are short enough to write by hand, and the host already comes inside
Microsoft's container image, so what runs on the laptop is the image a container deployment would
ship. Make a directory for the app, with the one line of its dependencies:

```sh
mkdir -p ~/azure/shopfn
echo azure-functions > ~/azure/shopfn/requirements.txt
```

`azure-functions` is the library the code imports: the decorators that declare a function and the
types of what it is handed. It is not the host, and it is not an SDK for any Azure service.

The code is `~/azure/shopfn/function_app.py`. This first version has one function, which takes an
order and says it got it; the notes are not part of the file:

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport json\nimport logging\n\nimport azure.functions as func\n\napp = func.FunctionApp()\n\n\n", "note": "`func.FunctionApp()` is the app. The host loads this file once, when it starts, and finds every function registered on `app`; `function_app.py` is the file name the v2 model looks for."}, {"code": "@app.route(route='orders', methods=['POST'], auth_level=func.AuthLevel.ANONYMOUS)\n", "note": "**The trigger.** `route` and `methods` make the function `POST /api/orders`. `ANONYMOUS` asks for no key; without it the level is `FUNCTION`, which asks for a key the host keeps in its storage account, and Microsoft's documentation says keys are still required in a container on your own machine."}, {"code": "def take_order(req: func.HttpRequest) -> func.HttpResponse:\n    order = req.get_json()\n    logging.info('order %s for %d x %s', order['order'], order['qty'], order['sku'])\n", "note": "The Python name is the function's name in the app and in its log. `req` is what the trigger hands it, and a `logging` line goes to the host's log under that name."}, {"code": "    body = json.dumps({'received': order['order']})\n    return func.HttpResponse(body + '\\n', status_code=200, mimetype='application/json')\n", "note": "What it returns is the HTTP answer. Nothing checks that the body was JSON, which the section `triggers` uses."}]}
```

**The decorators are the whole configuration of a function.** Nothing else says that `take_order`
answers `POST /api/orders`; the host reads them when it loads the file. Older Python function apps
put the same facts in a `function.json` beside each function, which is the v1 programming model. The
decorators are v2, the model Microsoft recommends for new apps and the one this course uses.

Then `~/azure/shopfn/host.json`, the settings of the host itself, which apply to every function in
the app:

```json
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  }
}
```

`"version": "2.0"` is the version of this file's own format, and it is `2.0` for every current host.
The `extensionBundle` block asks for the bindings this app will need, at any version from 4.0 up to
but not including 5.0. The section `bindings` shows what is in that bundle and what happens without
it.

And `~/azure/shopfn/Dockerfile`:

```dockerfile
# Dockerfile
FROM mcr.microsoft.com/azure-functions/python:4-python3.12
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
COPY requirements.txt /
RUN pip install -r /requirements.txt
COPY . /home/site/wwwroot
```

The base image is Microsoft's: version 4 of the host, with the Python 3.12 worker beside it, the two
halves of its tag. The first `ENV` line tells the host where the app is, `/home/site/wwwroot`. The
second turns on logging to the console, which is how `docker logs` will see what the host does.
**Its name is a path into `host.json` written with double underscores**: any setting called
`AzureFunctionsJobHost__a__b` overrides the value at `a.b` in that file, which is how one deployment
can change a host setting without a new build. The last three lines install the dependencies and
copy the app into place.

The directory now holds the whole app:

```
ana@laptop:~/azure$ ls shopfn
Dockerfile
function_app.py
host.json
requirements.txt
```

## Settings, and where they come from

The app also reads settings that are not in any of the four files: `AzureWebJobsStorage` above, and
the connections the next sections add. In Azure they are the function app's **application
settings**, edited with the portal or `az functionapp config appsettings set`. The documentation
says what they are underneath: "These settings are accessed as environment variables." Core Tools
reads them from a file called `local.settings.json` on your machine. Here they are given to the
container with `docker run -e`, which is the same thing by the shortest route, and it keeps the
connection strings out of the image.
