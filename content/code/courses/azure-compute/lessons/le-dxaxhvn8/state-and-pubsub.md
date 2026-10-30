---
title: State and pub/sub, through the sidecar
version: 1
---

A component is a short YAML file with a name, a type and the type's settings. **The name is what
the code says, and the type is what the sidecar connects to.** The URL `/v1.0/state/statestore`
names a component called `statestore`; whether that is Redis, Cosmos DB or a table somewhere is
written in the file and nowhere in the program. This section gives the shop's sidecar two
components, a state store and a message broker, both on Redis, and uses each of them. It is
practised in full.

It is easy to come away thinking the sidecar keeps the state or holds the messages. It keeps
nothing. Redis keeps them, and the sidecar is a Redis client with Dapr's API in front of it. What
the sidecar adds is the shape of the request and the layout of what lands in Redis, and both are
visible below.

## Two components

Redis goes on the same network as the shop, under the name `redis`, which is how the sidecar will
find it:

```
ana@laptop:~/azure$ docker run -d --name redis --network shop-net redis:8-alpine > /dev/null
```

Save the state store as `~/azure/components/statestore.yaml`:

```yaml
# components/statestore.yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis:6379
```

and the broker as `~/azure/components/pubsub.yaml`:

```yaml
# components/pubsub.yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis:6379
```

The two files differ in their `name` and their `type` and nowhere else. `state.redis` keeps values
in Redis; `pubsub.redis` uses Redis streams as a broker. The `metadata` list holds whatever the
type needs, here only the address. `redis:6379` is resolved on `shop-net`, and inside the sidecar
`localhost` would mean the shop.

This sidecar reads its components when it starts, so it is replaced rather than told:

```
ana@laptop:~/azure$ ls components
pubsub.yaml
statestore.yaml
ana@laptop:~/azure$ docker rm -f shop-dapr > /dev/null
ana@laptop:~/azure$ docker run -d --name shop-dapr --network container:shop -v ~/azure/components:/components daprio/daprd:1.17.16 ./daprd --app-id shop --app-port 8080 --resources-path /components > /dev/null
ana@laptop:~/azure$ docker logs shop-dapr 2>&1 | grep -o 'msg="Component loaded[^"]*"'
msg="Component loaded: pubsub (pubsub.redis/v1)"
msg="Component loaded: statestore (state.redis/v1)"
```

Both components loaded, and the shop's log has a line it did not have before. With a broker
loaded, the sidecar asked the app what it subscribes to, and the shop answered 404: it subscribes
to nothing, which is correct.

## State

Saving is a POST of a list of keys and values; reading is a GET of one key:

```
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{"key": "order-1", "value": {"item": "coffee", "qty": 2}}]'
204
ana@laptop:~/azure$ curl -s -w '\n' localhost:3500/v1.0/state/statestore/order-1
{"item":"coffee","qty":2}
```

Now look at Redis itself, which the shop never spoke to:

```
ana@laptop:~/azure$ docker exec redis redis-cli KEYS '*'
shop||order-1
ana@laptop:~/azure$ docker exec redis redis-cli HGETALL 'shop||order-1'
data
{"item":"coffee","qty":2}
version
1
```

**The key in Redis is not `order-1`. It is `shop||order-1`, the app id in front**, and the value is a
hash holding the data and a version. The prefix is how two apps can share one store without
reading each other's keys, which the end of this section shows. It also means this Redis now holds
data in Dapr's layout, and section 05 comes back to what that costs.

The version is the state store's guard against two writers. Dapr hands it out as an ETag; a write
that carries one succeeds only if it still matches:

```
ana@laptop:~/azure$ curl -s -D - -o /dev/null localhost:3500/v1.0/state/statestore/order-1 | grep -i etag
Etag: 1
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{"key": "order-1", "value": {"item": "coffee", "qty": 3}, "etag": "1"}]'
204
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -o err.json -X POST localhost:3500/v1.0/state/statestore -H 'Content-Type: application/json' -d '[{"key": "order-1", "value": {"item": "coffee", "qty": 5}, "etag": "1"}]'
409
ana@laptop:~/azure$ jq -r .errorCode err.json
ERR_STATE_SAVE
ana@laptop:~/azure$ curl -s -w '\n' localhost:3500/v1.0/state/statestore/order-1
{"item":"coffee","qty":3}
```

The first write carried ETag 1, matched, and moved the version to 2. The second carried the same
stale 1 and was refused with 409, so quantity 5 never landed and the value is still 3. Dapr calls
this first-write-wins. A write with no ETag is never refused, so the last one wins: that is the
default, and the documentation tells you to assume it.

## Publish and subscribe

A subscriber is any program that answers two things: a list of what it subscribes to, and a POST
for each message. Save this as `~/azure/subscriber.py`:

```schooling-example
{"language": "python", "file": "subscriber.py", "parts": [{"code": "# subscriber.py\nimport json\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\n", "note": "The standard library again, like the shop: the image it runs in needs nothing from PyPI, and nothing in the file is Dapr's."}, {"code": "SUBSCRIPTIONS = [{'pubsubname': 'pubsub', 'topic': 'orders', 'route': '/orders'}]\n\n\n", "note": "The subscription, as data. It names the component (`pubsub`), the topic, and the path on this program where the sidecar should deliver each message. Nothing here says Redis or Service Bus."}, {"code": "class Subscriber(BaseHTTPRequestHandler):\n    def answer(self, body):\n        data = json.dumps(body).encode()\n        self.send_response(200)\n        self.send_header('Content-Type', 'application/json')\n        self.send_header('Content-Length', str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n", "note": "Every answer goes out as JSON with its length stated, the same helper as the shop's."}, {"code": "    def do_GET(self):\n        if self.path == '/dapr/subscribe':\n            self.answer(SUBSCRIPTIONS)\n        else:\n            self.send_error(404)\n\n", "note": "The sidecar asks `GET /dapr/subscribe` once, when it starts, and subscribes on the app's behalf to whatever comes back. Any other page is a 404, which is also what the sidecar gets when it asks for `/dapr/config`."}, {"code": "    def do_POST(self):\n        size = int(self.headers.get('Content-Length', 0))\n        event = json.loads(self.rfile.read(size))\n        print(json.dumps({'order': event['data'], 'from': event['source'],\n                          'type': event['type']}), flush=True)\n        self.answer({'status': 'SUCCESS'})\n\n", "note": "A delivery arrives as a POST to the route. The body is a CloudEvent: the order the publisher sent is under `data`, the publisher's app id under `source`. The answer `SUCCESS` tells the sidecar the message is done with."}, {"code": "    def log_message(self, fmt, *args):\n        pass\n\n\n", "note": "The standard library's own line per request is silenced, so the log holds only what was received."}, {"code": "if __name__ == '__main__':\n    HTTPServer(('0.0.0.0', 8080), Subscriber).serve_forever()\n", "note": "It listens on 8080, the same port as the shop. That is no clash: each copy runs in a namespace of its own, with its own `localhost`."}]}
```

Two of the shop's teams need every order: billing, to charge for it, and audit, to record it. The
same file stands in for both. Each runs in a container of its own, from `python:3.12-slim`, as the
user `nobody`, with its own sidecar under its own app id:

```
ana@laptop:~/azure$ for app in billing audit; do docker run -d --name $app --user nobody --network shop-net -v ~/azure/subscriber.py:/subscriber.py:ro python:3.12-slim python /subscriber.py > /dev/null; done
ana@laptop:~/azure$ for app in billing audit; do docker run -d --name $app-dapr --network container:$app -v ~/azure/components:/components daprio/daprd:1.17.16 ./daprd --app-id $app --app-port 8080 --resources-path /components > /dev/null; done
ana@laptop:~/azure$ docker logs billing-dapr 2>&1 | grep -o 'msg="app is subscribed[^"]*"'
msg="app is subscribed to the following topics: [[orders]] through pubsub=pubsub"
```

The sidecar read `/dapr/subscribe` and subscribed `billing` to `orders` through the component
called `pubsub`. Now the shop's side publishes one order. The shop's code does not publish, so
`curl` on the laptop stands in for the line a later version of the shop would carry; it is the
same request either way:

```
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{"id": 1, "item": "coffee", "qty": 2}'
204
ana@laptop:~/azure$ docker logs billing
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
ana@laptop:~/azure$ docker logs audit
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
```

`204` means the broker took it. Both subscribers printed the order, and the envelope round it says
who sent it: `from` is `shop`, the publisher's app id, and `type` is `com.dapr.event.sent`. **Dapr
wraps every published message in a CloudEvent**, an open format for describing an event, and puts
what you sent under `data`. A subscriber that answers `SUCCESS` is finished with the message;
`RETRY` asks for it again and `DROP` discards it, and an app that answers 404 has the message
dropped with an error in the sidecar's log.

What it did in Redis:

```
ana@laptop:~/azure$ docker exec redis redis-cli XLEN orders
1
ana@laptop:~/azure$ docker exec redis redis-cli XINFO GROUPS orders | paste - - | grep -E '^(name|entries-read)'
name	audit
entries-read	1
name	billing
entries-read	1
```

One message in the stream `orders`, and two consumer groups named after the two app ids, each
having read it once. **Dapr gives every app id its own group, so each app gets its own copy.** Two
replicas of billing would share the group `billing` and split the messages between them, which is
what a second replica is for. That arrangement belongs to the Redis component, and section 04
shows it does not survive the swap unchanged.

## Each app's own keys

The prefix from earlier, seen from billing's side. Billing's sidecar is asked for the same key the
shop saved:

```
ana@laptop:~/azure$ docker exec billing python -c "import urllib.request as u; r = u.urlopen('http://localhost:3500/v1.0/state/statestore/order-1'); print(r.status, r.read())"
204 b''
```

`204` and an empty body: nothing there. Billing's sidecar looked for `billing||order-1`, which
does not exist. Two apps on one store each see only their own keys unless the component says
otherwise. The state store's `keyPrefix` setting can put the component's name in front instead of
the app id, or nothing at all, so sharing state between apps is a line somebody writes into the
component, never an accident.
