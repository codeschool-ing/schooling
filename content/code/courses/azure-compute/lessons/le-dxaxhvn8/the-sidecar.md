---
title: The sidecar, a second process on the shop's localhost
version: 1
---

Dapr, the Distributed Application Runtime, is a program that runs beside yours and answers an HTTP
API on `localhost:3500`. Your code asks it to save a value, publish a message or call another
service, and Dapr does the work against whatever store or broker it was configured with. **In
Container Apps, turning Dapr on is a setting of the app, and Azure then starts the sidecar in
every replica.** This section starts one beside the shop on your laptop, with Docker, and then
reads what Container Apps asks for. The first half is practised; the second half is read from
Microsoft's documentation.

The picture most people arrive with is a library: something you `pip install`, like the Azure SDK,
that turns a function call into a request to Redis or to Service Bus. Or else a service, somewhere
in Azure, that the app calls over the internet. It is neither. **Dapr is a separate process in your
replica, and your program reaches it on `localhost`.** Dapr publishes SDKs for several languages,
but they are thin clients of that same local API; a program with nothing but an HTTP client can use
all of it, and the shop's programs in this lesson do.

## Started beside the shop

The sidecar is a program called `daprd`, and Dapr publishes it as an image, `daprio/daprd`. This
course pins version 1.17.16. Dapr's own command line, `dapr`, can start the same program for you;
here it is started with Docker, so that every setting is visible and the arrangement is the one
Container Apps builds.

The shop's image is the one lesson 7 built, `shop:1.0`. Make a network for this lesson, start the
shop on it, and start the sidecar inside the shop's network namespace with `--network
container:shop`, the flag lesson 7 used for a second container on the same `localhost`. The
sidecar gets three settings: the name it knows the app by, the port the app listens on, and a
directory of components, which is empty for now:

```
ana@laptop:~/azure$ docker network create shop-net
060c017201602ce5c37b560bd66b8f3156780a835e1b15d307272e55718e69f4
ana@laptop:~/azure$ docker run -d --name shop --network shop-net -p 8080:8080 -p 3500:3500 shop:1.0 > /dev/null
ana@laptop:~/azure$ mkdir components
ana@laptop:~/azure$ docker run -d --name shop-dapr --network container:shop -v ~/azure/components:/components daprio/daprd:1.17.16 ./daprd --app-id shop --app-port 8080 --resources-path /components > /dev/null
ana@laptop:~/azure$ docker port shop
3500/tcp -> 0.0.0.0:3500
8080/tcp -> 0.0.0.0:8080
ana@laptop:~/azure$ docker port shop-dapr
```

`docker network create` prints the new network's id, which differs on every machine, and `>
/dev/null` throws away the container ids that `docker run` would print. The two calls to `docker
port` are the point. Ports 8080 and 3500 are both published on the shop's container, and the
sidecar has none. **A sidecar has no network of its own, so its ports are published on the
container whose namespace it joined**: `-p 3500:3500` had to be given when the shop started,
before the sidecar existed.

What the sidecar said as it started, picked out of a log of several dozen lines:

```
ana@laptop:~/azure$ docker logs shop-dapr 2>&1 | grep -o 'msg="[^"]*"' | grep -E 'app id|waiting on port|application discovered|Status: Running'
msg="app id: shop"
msg="application protocol: http. waiting on port 8080.  This will block until the app is listening on that port."
msg="application discovered on port 8080"
msg="dapr initialized. Status: Running. Init Elapsed 15ms"
```

It took the app id `shop`, then waited until something was listening on port 8080 before it called
itself running. The sidecar is started as a partner of one program, and it will not report itself
ready while that program is absent.

## Asking it things

Dapr's health check answers on its own API, and the metadata call says what this sidecar is:

```
ana@laptop:~/azure$ curl -s -o /dev/null -w '%{http_code}\n' localhost:3500/v1.0/healthz
204
ana@laptop:~/azure$ curl -s localhost:3500/v1.0/metadata | jq '{id, runtimeVersion, components, appConnectionProperties}'
{
  "id": "shop",
  "runtimeVersion": "1.17.16",
  "components": null,
  "appConnectionProperties": {
    "port": 8080,
    "protocol": "http",
    "channelAddress": "127.0.0.1"
  }
}
```

`204` is healthy with nothing to say. The metadata names the app id, the version of Dapr that is
running, and `"components": null`: no store and no broker yet. `appConnectionProperties` says the
sidecar reaches the app at `127.0.0.1:8080`, which works only because the two share a `localhost`.

The shop's own log shows the other direction:

```
ana@laptop:~/azure$ docker logs shop
{"msg": "listening", "port": 8080, "version": "1.0"}
{"path": "/dapr/config", "status": "404", "version": "1.0"}
```

The shop never called Dapr; Dapr called the shop. On starting, the sidecar asked the app for its
Dapr configuration at `/dapr/config`, and the shop, which has no such page, answered 404, which the
sidecar takes as "nothing to configure". **The traffic runs both ways**: the app calls the sidecar
to save state and to publish, and the sidecar calls the app to learn what it subscribes to and to
deliver what arrives. The next section shows the second half.

Asking for state now gets a refusal that names what is missing:

```
ana@laptop:~/azure$ curl -s localhost:3500/v1.0/state/statestore/order-1 | jq -c '{errorCode, message}'
{"errorCode":"ERR_STATE_STORE_NOT_CONFIGURED","message":"state store statestore is not configured"}
```

`statestore` is the name of a component, and the components directory is empty. The URL names a
store and says nothing about what kind it is; that is written in a file the sidecar reads, which
is the next section's subject.

```schooling-figure
{"svg": "<svg id=\"fig-sidecar\" viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The shop and its sidecar in one network namespace. curl on the laptop reaches the shop on port 8080 and the sidecar on port 3500, both published on the shop's container. Inside the namespace the shop asks the sidecar on localhost port 3500 for state and to publish, and the sidecar calls the shop on localhost port 8080 for its subscriptions and to deliver events. The sidecar talks to redis on port 6379, which holds state and streams. billing has a namespace of its own with its own sidecar, which reads from redis and delivers to subscriber.py on port 8080. In Container Apps each such box is a replica, and Azure puts the sidecar in every one.\"><defs><marker id=\"sidecar-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"128\" width=\"112\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">curl</text><text x=\"72\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on the laptop</text><rect x=\"160\" y=\"28\" width=\"292\" height=\"252\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></rect><text x=\"306\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one network namespace, one localhost</text><rect x=\"186\" y=\"62\" width=\"240\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">shop</text><text x=\"306\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.py  :8080</text><rect x=\"186\" y=\"194\" width=\"240\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\" font-weight=\"600\">shop-dapr</text><text x=\"306\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">daprd  :3500  :50001</text><polyline points=\"290,124 290,192\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><polyline points=\"322,194 322,126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><text x=\"282\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">state,</text><text x=\"282\" y=\"161\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">publishing</text><text x=\"282\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:3500</text><text x=\"330\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">subscriptions,</text><text x=\"330\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">events</text><text x=\"330\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:8080</text><polyline points=\"128,144 184,96\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><polyline points=\"128,168 184,222\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><text x=\"140\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:8080</text><text x=\"140\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:3500</text><rect x=\"520\" y=\"36\" width=\"184\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">redis  :6379</text><text x=\"612\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">state and streams</text><polyline points=\"426,225 482,225 482,67 518,67\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><rect x=\"512\" y=\"128\" width=\"200\" height=\"152\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></rect><text x=\"612\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">billing's namespace</text><rect x=\"528\" y=\"158\" width=\"168\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">billing-dapr</text><text x=\"612\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daprd</text><rect x=\"528\" y=\"222\" width=\"168\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">billing</text><text x=\"612\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">subscriber.py  :8080</text><polyline points=\"612,98 612,156\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><polyline points=\"612,204 612,220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><text x=\"360\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">In Container Apps each dashed box is a replica, and Azure puts the sidecar in every one.</text></svg>", "caption": "Two processes, one address. The shop and daprd share a localhost, so each reaches the other without a network hop, and the ports a stranger reaches are published on the shop's container because the sidecar has no network of its own."}
```

## What Container Apps asks for

In Container Apps you never start `daprd`. Microsoft's documentation lists Dapr's settings under
`properties.configuration.dapr` of the container app, and the four that matter here are the ones
you just gave as flags: `enabled`, `appId`, `appPort`, and `appProtocol`, which is `http` unless
the app speaks gRPC. The sidecar answers HTTP on port 3500 and gRPC on port 50001, the same two
ports as on your laptop. The Azure CLI's help for turning Dapr on, which needs no account to read,
lists the same settings as flags:

```
ana@laptop:~/azure$ az containerapp dapr enable --help | sed -n '/^Dapr Arguments/,/^Global Policy/p' | head -n -2
Dapr Arguments
    --dal --dapr-enable-api-logging      : Enable API logging for the Dapr sidecar.
    --dapr-app-id                        : The Dapr application identifier.
    --dapr-app-port                      : The port Dapr uses to talk to the application.
    --dapr-app-protocol                  : The protocol Dapr uses to talk to the application.
                                           Allowed values: grpc, http.
    --dapr-http-max-request-size --dhmrs : Increase max size of request body http and grpc servers
                                           parameter in MB to handle uploading of big files.
    --dapr-http-read-buffer-size --dhrbs : Dapr max size of http header read buffer in KB to handle
                                           when sending multi-KB headers..
    --dapr-log-level                     : Set the log level for the Dapr sidecar.  Allowed values:
                                           debug, error, info, warn.
```

Section 05 declares these settings in Bicep and compiles them. Three facts from the documentation
change how you run it there.

**Dapr's settings belong to the app, not to a revision.** Lesson 8 showed that a change to the
template makes a new revision. Changing a Dapr setting does not: in multiple-revision mode, every
existing revision is restarted with the new values. A Dapr change is therefore never something
you can try on a revision with 10% of the traffic.

**You do not choose the version.** Container Apps runs Microsoft's own build of Dapr, numbered like
`1.13.6-msft.1`: the open-source version it matches, then a suffix for Azure's changes. It upgrades
the environment automatically, and planned maintenance on the environment decides when, not
whether. The `runtimeVersion` from `/v1.0/metadata` is how a program finds out which one it got,
and it need not be the 1.17.16 pinned here.

**Some of Dapr is not there.** Container Apps supports Dapr's generally available APIs: state,
pub/sub, bindings, service invocation, actors, secrets and configuration, plus the health and metadata
calls used above. Alpha APIs are not guaranteed. Dapr's own configuration file, and sidecar
annotations the documentation does not list, cannot be used, and a Container Apps job cannot have
Dapr at all. What you do get without asking is a health check on the sidecar itself, which
Container Apps sets up whenever Dapr is enabled.
