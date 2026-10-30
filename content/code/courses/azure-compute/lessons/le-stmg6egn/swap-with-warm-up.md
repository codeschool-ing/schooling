---
title: The swap, and the warm-up before it switches
version: 1
---

A swap is easy to picture as a copy: the files in staging are copied over production, and
production restarts with them. If that were so, every swap would be a restart of production, and
the customers in the middle of an order would see it. **A swap prepares the staging slot until it
can serve as production, and then exchanges the two slots' routing.** Production keeps answering
with the old version throughout, and the documentation states the consequence: the target slot
stays online while the source is prepared and warmed up, whether the swap succeeds or fails. The
swap itself is read here from Microsoft's documentation, because it needs a subscription. What is
practised is the reason for its longest step: a version of the shop that takes a while to be
ready, run on the laptop and asked until it is.

## Five steps, all but one on staging

Swapping `staging` into `production`, App Service does this:

1. It applies production's sticky settings to every instance of staging, with its continuous
   deployment and authentication settings if it has them. That is a configuration change, and it
   restarts every staging instance. The new code is now running with the settings it will have in
   production, at staging's address;
2. It waits for every instance to finish restarting. If any instance fails, the swap undoes its
   changes to staging and stops;
3. It warms each instance up: a request to each one, and an instance that answers counts as warm;
4. It switches the routing once every instance is warm. From this moment production's address
   reaches what was staging, and the slots have traded content;
5. It does the same to the other side: the old production content, now in staging, gets
   staging's sticky settings and restarts.

With local cache enabled there is one more request and one more restart between the second and
the third; the documentation says local cache is not supported in containerised apps, so the shop
never has it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 375\" role=\"img\" aria-label=\"A timeline from left to right with two lanes. The production lane shows shop:1.0 answering every request until the routing switch, and shop:1.1 answering after it. The staging lane shows the steps: one, production's sticky settings are applied to staging and every staging instance restarts, and swap with preview pauses here; two, the swap waits for every instance to restart, with start-up pings until a listed status; three, a warm-up request on each instance, where a status not in the list stops the swap; four, the routing is switched and the two slots trade content; five, the old content is restarted with staging's settings. A note: rollback is the same swap again.\"><defs><marker id=\"l18w-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18w-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">production</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">staging</text><rect x=\"110\" y=\"25\" width=\"410\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop:1.0 answers every request</text><rect x=\"520\" y=\"25\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop:1.1 answers</text><rect x=\"110\" y=\"75\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">1  production's sticky settings applied to staging</text><text x=\"142\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every staging instance restarts</text><rect x=\"110\" y=\"135\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">2  wait for every instance to restart</text><text x=\"142\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">start-up pings until a listed status</text><rect x=\"110\" y=\"195\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">3  warm-up request on each instance</text><text x=\"142\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a status not in the list stops the swap</text><rect x=\"110\" y=\"255\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">4  routing switched</text><text x=\"142\" y=\"287\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the two slots trade content</text><rect x=\"110\" y=\"315\" width=\"400\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"124\" y=\"331\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">5  old content restarted</text><text x=\"142\" y=\"347\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">with staging's settings</text><path d=\"M310 121 L310 133\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M310 181 L310 193\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M310 241 L310 253\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M310 301 L310 313\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-wire)\"></path><path d=\"M520 25 L520 368\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M510 278 L518 278\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18w-amber)\"></path><text x=\"530\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">swap with preview pauses here</text><path d=\"M528 98 L512 98\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"530\" y=\"350\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">rollback: the same swap again</text></svg>", "caption": "Everything before the switch happens to the staging slot; production keeps answering with the old version until the routing changes, and if any step fails it never changes at all."}
```

**Step 3 is where the defaults are generous.** With no warm-up configured, the request goes to the
application's root, `/`, and the documentation says what counts: if an instance returns any HTTP
response, it is considered warmed up. Any response includes a 503. The step waits up to 90 seconds
for each request and retries up to five times; only a timeout on every try stops the swap.

Two app settings change that. `WEBSITE_SWAP_WARMUP_PING_PATH` names the path, and
`WEBSITE_SWAP_WARMUP_PING_STATUSES` lists the status codes that count, separated by commas. **A
status that is not in the list stops the swap**, and production is untouched, because nothing has
reached it yet. The documentation also names an element, `applicationInitialization`, for the same
job; it lives in a `Web.config` file, which is IIS on Windows, and a Python container has none.

On Linux there is also an earlier wait, and step 2's restarts go through it, because restarting a
container is starting one. Every time App Service starts a container, it asks it for `WEBSITE_WARMUP_PATH`, by default
`/robots933456.txt`, again and again until it answers, and only then sends it traffic. Here too
**any status counts unless `WEBSITE_WARMUP_STATUSES` lists some**, and with a list it keeps asking
until a listed one arrives or `WEBSITES_CONTAINER_START_TIME_LIMIT` runs out, 230 seconds by
default. The shop's file sets both pairs to `/healthz` and `200`, on both slots, so the start-up
waits for the shop to be ready and the swap checks it once more before it switches.

## A shop that is slow to be ready

The shop of lesson 7 is ready the moment it listens. A real order API rarely is: it opens its
database connections, loads the catalogue and the price list, fills a cache. To see what the
defaults would do with that, here is a version that listens at once and answers 503 until a
number of seconds have passed. It imports lesson 7's `app.py` and changes nothing in it. Save it
beside it as `~/azure/shop/warm.py`:

```schooling-example
{"language": "python", "file": "warm.py", "parts": [{"code": "# warm.py\nimport json\nimport os\nimport threading\nimport time\nfrom http.server import ThreadingHTTPServer\n\nimport app\n\nWARMUP = float(os.environ.get('SHOP_WARMUP_SECONDS', '20'))\nREADY = threading.Event()\n\n", "note": "`import app` is lesson 7's file, unchanged, so the order API's code exists once. The warm-up's length comes from an environment variable, which on App Service is an app setting. `READY` is a flag that one thread sets and every request thread reads, and `threading.Event` is the standard library's safe way to share one."}, {"code": "\nclass WarmingShop(app.Shop):\n    def do_GET(self):\n        if not READY.is_set():\n            return self.answer(503, {'status': 'warming'})\n        super().do_GET()\n\n    def do_POST(self):\n        if not READY.is_set():\n            return self.answer(503, {'status': 'warming'})\n        super().do_POST()\n\n", "note": "Until the flag is set, **every request is answered with a 503**, on any path, including `/healthz` and pages the shop does not have. That is a listening server that is not ready, which is exactly the state a check that accepts any status cannot tell from a ready one. After the flag, lesson 7's handlers answer as before."}, {"code": "\ndef warm_up():\n    time.sleep(WARMUP)\n    READY.set()\n    print(json.dumps({'msg': 'ready', 'after_s': WARMUP}), flush=True)\n\n", "note": "The sleep stands in for the real work: opening database connections, loading the catalogue, filling a cache. It runs in a thread of its own so that the server can answer, with 503, while it happens. The log line uses the shop's JSON format, so the moment of readiness is in the container's log."}, {"code": "\nif __name__ == '__main__':\n    threading.Thread(target=warm_up, daemon=True).start()\n    print(json.dumps({'msg': 'listening', 'port': app.PORT, 'version': app.VERSION,\n                      'warmup_s': WARMUP}), flush=True)\n    ThreadingHTTPServer(('0.0.0.0', app.PORT), WarmingShop).serve_forever()\n", "note": "The same server as lesson 7's, on the same port, with the new handler class. The warm-up thread starts first and the server listens at once, so **listening and ready are two moments**, a few seconds apart, and the log has a line for each."}]}
```

And the image for it, `~/azure/shop/Dockerfile.warm`, which is lesson 7's with the new file added
and the version set to 1.1:

```dockerfile
# Dockerfile.warm
FROM python:3.12-slim
WORKDIR /app
COPY app.py warm.py ./
ENV PORT=8080 SHOP_VERSION=1.1
EXPOSE 8080
USER nobody
CMD ["python", "warm.py"]
```

Build it as `shop:1.1`, the tag the staging slot runs:

```sh
docker build --tag shop:1.1 --file shop/Dockerfile.warm shop
```

Then run it with a warm-up of six seconds, passed as an environment variable, which is how an app
setting would arrive. Ask it once a second for two paths: the shop's `/healthz`, and the path App
Service asks by default.

```
ana@laptop:~/azure$ ls shop
Dockerfile.warm
app.py
warm.py
ana@laptop:~/azure$ docker run -d --name shop-warm -p 8088:8080 -e SHOP_WARMUP_SECONDS=6 shop:1.1 > /dev/null
ana@laptop:~/azure$ for i in $(seq 1 20); do h=$(curl -s -o /dev/null -w '%{http_code}' localhost:8088/healthz); r=$(curl -s -o /dev/null -w '%{http_code}' localhost:8088/robots933456.txt); echo "$i  /healthz $h  /robots933456.txt $r"; [ "$h" = 200 ] && break; sleep 1; done
1  /healthz 000  /robots933456.txt 000
2  /healthz 503  /robots933456.txt 503
3  /healthz 503  /robots933456.txt 503
4  /healthz 503  /robots933456.txt 503
5  /healthz 503  /robots933456.txt 503
6  /healthz 503  /robots933456.txt 503
7  /healthz 503  /robots933456.txt 503
8  /healthz 200  /robots933456.txt 404
ana@laptop:~/azure$ docker logs shop-warm | grep msg
{"msg": "listening", "port": 8080, "version": "1.1", "warmup_s": 6.0}
{"msg": "ready", "after_s": 6.0}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8088/version
{"version": "1.1", "host": "8b8c2663dde3", "up_s": 6.9}
```

**This is the laptop's Docker, not App Service**, and the timing is the laptop's. Read it as three
states. On the first probe nothing answered at all, `000`: the container was still starting
Python. From the second to the seventh the shop was listening and not ready, and answered 503 on
both paths. On the eighth `/healthz` said 200 and the default path said 404, because the shop has
no such page. A start-up check on the default path with no status list would have called the shop
ready on the second probe, six seconds before it was, and a swap's warm-up on `/` would have done
the same. With `/healthz` and `200`, the start-up check counts the shop as ready only at the eighth probe,
and the swap only switches a slot that already answers 200.

The status list has one more trap. The documentation separates its codes with commas:

```
ana@laptop:~/azure$ sed "s/WARMUP_PING_STATUSES', value: '200'/WARMUP_PING_STATUSES', value: '200;202'/" shop-web.bicep > statuses.bicep
ana@laptop:~/azure$ bicep build statuses.bicep
```

`200;202` compiles, because to the compiler it is a string like any other. What App Service makes
of a list it cannot split is not documented; this course would not find out without a
subscription, and a file is not the place to find out.

## Preview, auto swap, and going back

**Swap with preview** stops after step 1 and waits. Staging is then running the new code with
production's settings, at its own address, and somebody can test exactly what customers will get
before anything reaches them. The CLI calls the three halves `preview`, `swap` and `reset`:

```
ana@laptop:~/azure$ az webapp deployment slot swap --help | sed -n '/^Arguments/,/^$/p'
Arguments
    --slot -s   [Required] : The name of the slot.
    --action               : Swap types. use 'preview' to apply target slot's settings on the source
                             slot first; use 'swap' to complete it; use 'reset' to reset the swap.
                             Allowed values: preview, reset, swap.  Default: swap.
    --preserve-vnet        : Preserve Virtual Network to the slot during swap, default to 'true'.
                             Allowed values: false, true.
    --target-slot          : Target slot to swap, default to 'production'.
```

`--target-slot` defaults to `production`, and the documentation asks for production always to be
the target, so the preparation always happens on the other side. Preview is not available while
authentication is enabled on either slot. Without an account, the first half answers as every
command here does:

```
ana@laptop:~/azure$ az webapp deployment slot swap --resource-group shop --name shop-sp --slot staging --action preview
ERROR: Please run 'az login' to setup account.
```

**Auto swap** swaps a slot into production every time something is deployed to it. The
documentation is short about where: it is not supported in web apps on Linux or in Web App for
Containers, which is the shop on both counts. The setting is a property of `siteConfig`, and the
compiler has no way to know which kind of app it is on:

```
ana@laptop:~/azure$ sed "0,/alwaysOn: true/! s/alwaysOn: true/alwaysOn: true\n      autoSwapSlotName: 'production'/" shop-web.bicep > autoswap.bicep
ana@laptop:~/azure$ grep -n autoSwapSlotName autoswap.bicep
58:      autoSwapSlotName: 'production'
ana@laptop:~/azure$ bicep build autoswap.bicep
```

**Going back is the same swap again.** After a swap, staging holds the version production was
running a minute ago, already warm, so swapping the same two slots restores it, with the same five
steps and the same zero restarts of production. That holds only while nobody has deployed to
staging since. And one cost lands on the old version rather than the new: in step 5 the former
production instances are recycled, and a long-running operation in them is abandoned. An order
half written when the swap finished is the shop's code's problem to survive.

## After the switch: the health check

Warm-up guards the moment of the swap. `healthCheckPath` guards every minute after it. With it
set, App Service asks that path on every instance once a minute, and an instance that answers
anything outside 200 to 299 after ten requests is taken out of the load balancer.
`WEBSITE_HEALTHCHECK_MAXPINGFAILURES` moves the ten anywhere from 2 to 10. A removed instance keeps
being asked and comes back when it answers well; one unhealthy for an hour is replaced, at most one
per hour and three a day per plan. **No more than half of the instances are taken out by
default**, so a plan of four with three failing keeps two serving, one healthy and one not; the
documentation's reason is not to overwhelm the healthy ones. With every instance failing, none is
taken out.

Two consequences for the shop. The check needs at least two instances to have anywhere to send
traffic, which the plan's `capacity: 2` gives it. And the path should answer 200 only when the
instance can really serve, which is what `warm.py` does with `/healthz`: one endpoint, read by the
start-up, the swap and the check. Changing the health check setting restarts the app, so the
documentation suggests making the change in a slot and swapping it in.
