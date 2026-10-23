---
title: Centrifugo, a server for the sockets
version: 1
---

Melody moves the hub into a library; **Centrifugo moves the connections out of your program
altogether.** It is a separate server, written in Go, whose whole job is to hold WebSocket and
server-sent event connections and deliver messages to them. Clients connect to Centrifugo. Your program
never holds a connection: when something happens, it makes one HTTP call to Centrifugo's API, and
Centrifugo fans the message out to everybody subscribed to that channel.

What that buys is mostly what a hand-written hub does not have: a deploy of boxoffice no longer drops ten
thousand connections, because they were never boxoffice's; several Centrifugo nodes can share their
subscribers through Redis; and it brings presence, message history and recovery of missed messages on
reconnect. What it costs is a second server to run, configure, secure and update.

## Installing it

Centrifugo publishes a binary for each platform with every release, and a file of checksums beside them.
Download both, check one against the other, and unpack only the binary:

```
ana@vm:~/centrifugo$ curl -sSLO https://github.com/centrifugal/centrifugo/releases/download/v6.9.7/centrifugo_6.9.7_linux_amd64.tar.gz
ana@vm:~/centrifugo$ curl -sSLO https://github.com/centrifugal/centrifugo/releases/download/v6.9.7/centrifugo_6.9.7_checksums.txt
ana@vm:~/centrifugo$ grep linux_amd64.tar.gz centrifugo_6.9.7_checksums.txt | sha256sum -c
centrifugo_6.9.7_linux_amd64.tar.gz: OK
ana@vm:~/centrifugo$ tar xzf centrifugo_6.9.7_linux_amd64.tar.gz centrifugo && ./centrifugo version
Centrifugo v6.9.7 (Go version: go1.26.8)
```

The archive is about 24 MB and the binary inside it 67 MB. **The checksum check is the step people skip**,
and it is what tells you the file that arrived is the one that was published. `version` also names the Go it
was built with, which is not the Go on your machine and does not need to be.
There is also an official container image, `centrifugo/centrifugo`, for when lesson 16's container
runtime is installed.

## Configuring it

`genconfig` writes a `config.json` with fresh secrets in it, which is why the file is created readable by
its owner only:

```
ana@vm:~/centrifugo$ ./centrifugo genconfig && python3 -c "import json; print(sorted(json.load(open(\"config.json\"))))"
['admin', 'client', 'http_api']
ana@vm:~/centrifugo$ python3 - <<'PY'
import json
c = json.load(open("config.json"))
c["http_server"] = {"address": "127.0.0.1", "port": 8000}
c["channel"] = {"without_namespace": {"allow_subscribe_for_client": True}}
json.dump(c, open("config.json", "w"), indent=2)
PY
```

`client.token.hmac_secret_key` signs the tokens clients connect with, `http_api.key` is the password your
program uses to publish, and `admin` is a web interface, off by default. `client.allowed_origins` is
section 05's `Origin` check: empty, as here, it admits programs that send no `Origin`, and a browser page
will need its site listed there. Two settings are missing for this lesson, and a few lines of Python add
them: listen only on `127.0.0.1`, port 8000, and let any connected client subscribe to channels with
plain names like `event-1`. By default a client may not subscribe to anything; production configurations
group channels into namespaces, each with its own rules.

Start it in another terminal with `./centrifugo -c config.json`. Its log is JSON, like boxoffice's:

```
ana@vm:~/centrifugo$ grep -e "starting Centrifugo" -e serving .server.log
{"level":"info","version":"6.9.7","runtime":"go1.26.8","pid":22890,"gomaxprocs":4,"engine":"memory","time":"2026-10-22T19:36:08-03:00","message":"starting Centrifugo"}
{"level":"info","time":"2026-10-22T19:36:08-03:00","message":"serving websocket, api endpoints on 127.0.0.1:8000"}
```

**`"engine":"memory"` means one node**, with subscriptions kept in its own memory. A second node with the
same engine would not know about the first's subscribers; the Redis engine is what lets several share
them.

## A subscriber and a publisher

A client proves who it is with a JWT signed with `hmac_secret_key`. In production boxoffice would sign one
when a person signs in, with their id as the subject; for this lesson `gentoken` makes one for the user
`ana`:

```
ana@vm:~/centrifugo$ ./centrifugo gentoken -c config.json -u ana
HMAC SHA-256 JWT for user "ana" with expiration TTL 168h0m0s:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmEiLCJleHAiOjE3OTMzMTMzNjgsImlhdCI6MTc5MjcwODU2OH0.iAaNeEmF2qOU_CxWAmRyfodQ0oSx7zJOlAEMKnMhjBM
```

Keep the token, and the API key from the configuration, in two shell variables:

```sh
TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...   # the whole token gentoken printed
KEY=$(python3 -c 'import json; print(json.load(open("config.json"))["http_api"]["key"])')
```

Centrifugo's protocol over a WebSocket is JSON commands, each with an id its reply repeats. Section 05's
client sends a `connect` with the token and a `subscribe` to `event-1`, and then listens:

```
ana@vm:~/centrifugo$ ~/boxoffice/watchws ws://localhost:8000/connection/websocket 3s '{"id":1,"connect":{"token":"'"$TOKEN"'"}}' '{"id":2,"subscribe":{"channel":"event-1"}}'
connected: 101 Switching Protocols
19:36:09 {"id":1,"connect":{"client":"af68566c-d5c4-48ba-bc9a-f2df5f09959c","version":"6.9.7 OSS","expires":true,"ttl":604800,"ping":25,"pong":true}}
19:36:09 {"id":2,"subscribe":{}}
19:36:10 {"push":{"channel":"event-1","pub":{"data":{"event_id":1,"available":112}}}}
stopped: context deadline exceeded
```

While it listened, the publish came from another terminal, as boxoffice would make it:

```
ana@vm:~/centrifugo$ curl -s -H "X-API-Key: $KEY" --json '{"channel":"event-1","data":{"event_id":1,"available":112}}' localhost:8000/api/publish
{"result":{}}
```

The reply to `connect` names the connection, the version, and the token's remaining life in seconds,
604,800, which is the 168 hours `gentoken` gave it. `ping` is 25: Centrifugo sends a ping every 25
seconds, so idle connections never look idle to a proxy. The reply to `subscribe` is empty because there
was nothing to say, and the `push` is the published data, delivered to the channel's one subscriber. The
publish itself answered `{"result":{}}`, which is success.

## In boxoffice

The change to boxoffice would be small. `listen` stays, and instead of `h.publish(id, available)` it
posts `{"channel":"event-N","data":…}` to Centrifugo's API; the hub, `liveEvents` and `liveSocket` go away,
and pages connect to Centrifugo with a token boxoffice issued. **The database is still where the news
comes from; Centrifugo only replaces the part that delivers it.** Whether that trade is worth a second
server is the question of the next section.
