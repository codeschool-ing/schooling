---
title: Swapping a component, and what comes with it
version: 1
---

This is the promise Dapr makes, and the section tests it: point the broker at Azure Service Bus by
writing a different YAML file, keep the name `pubsub`, and change neither `subscriber.py` nor the
request that publishes. **It works, after one setting, and the delivery is no longer the same.**
Both halves are practised, against Microsoft's Service Bus emulator, with the same three
programs as the last section.

The picture to replace is that a component is an address: swap the file and only the destination
changes. A component is a client for one product, with that product's defaults, and it brings
them along. One of them stops the swap on the first try, and another changes who receives what
without a single error.

## A Service Bus on the laptop

Lesson 20 is about Service Bus itself and runs its emulator properly. Here it is only a broker, so
the introduction is short. The emulator is two containers, the broker and the SQL Server it keeps
its messages in, and it reads the entities it should create from a file. Make a directory
`~/azure/servicebus` and save this as `~/azure/servicebus/Config.json`:

```json
{
  "UserConfig": {
    "Namespaces": [
      {
        "Name": "sbemulatorns",
        "Queues": [
          {
            "Name": "orders"
          }
        ]
      }
    ],
    "Logging": {
      "Type": "Console"
    }
  }
}
```

One namespace, whose name `sbemulatorns` is the emulator's own and cannot be changed, holding one
queue, `orders`, named after the topic the programs already use. Start both containers on
`shop-net`, so the sidecars can reach the broker by its name, `servicebus`. **`ACCEPT_EULA=Y`
accepts two licences**, the emulator's and SQL Server's; read them at the addresses Microsoft's
documentation gives before you set it. The password is for a database that lives and dies on your
laptop. SQL Server takes most of the half minute the health check waits:

```
ana@laptop:~/azure$ docker run -d --name mssql --network shop-net -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=Shop-lab-2026 mcr.microsoft.com/mssql/server:2022-latest > /dev/null
ana@laptop:~/azure$ docker run -d --name servicebus --network shop-net -p 5300:5300 -v ~/azure/servicebus/Config.json:/ServiceBus_Emulator/ConfigFiles/Config.json -e SQL_SERVER=mssql -e MSSQL_SA_PASSWORD=Shop-lab-2026 -e ACCEPT_EULA=Y mcr.microsoft.com/azure-messaging/servicebus-emulator:2.0.1 > /dev/null
ana@laptop:~/azure$ until curl -sf localhost:5300/health; do sleep 2; done; echo
{"status":"healthy","message":"Service is healthy."}
```

## The swap

The new component goes in a directory of its own, `~/azure/components-sb`, so that the Redis one
stays as it was. Save this as `~/azure/components-sb/pubsub.yaml`:

```yaml
# components-sb/pubsub.yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.azure.servicebus.queues
  version: v1
  metadata:
  - name: connectionString
    value: "Endpoint=sb://servicebus;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
```

The name is still `pubsub`. The type is Dapr's component for Service Bus queues, and its one
setting is the emulator's connection string, which is fixed and the same on every machine except
for the host: `servicebus`, the container's name, rather than `localhost`, which inside a sidecar is
its app. `UseDevelopmentEmulator=true` tells the client to talk plain AMQP rather than TLS. The
state store does not change, so it is copied across, and all three sidecars are replaced to read
the new directory:

```
ana@laptop:~/azure$ cp components/statestore.yaml components-sb/
ana@laptop:~/azure$ ls components-sb
pubsub.yaml
statestore.yaml
ana@laptop:~/azure$ docker rm -f shop-dapr billing-dapr audit-dapr > /dev/null
ana@laptop:~/azure$ for app in shop billing audit; do docker run -d --name $app-dapr --network container:$app -v ~/azure/components-sb:/components daprio/daprd:1.17.16 ./daprd --app-id $app --app-port 8080 --resources-path /components > /dev/null; done
```

Then the same publish as before, with the answer kept in a file so its message can be read:

```
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -o err.json -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{"id": 2, "item": "tea", "qty": 1}'
500
ana@laptop:~/azure$ jq -r .message err.json
error when publishing to topic orders in pubsub pubsub: failed to create a sender: could not get queue orders: Get "https://servicebus/orders?api-version=2021-05": dial tcp 172.20.0.7:443: connect: connection refused
```

**The component did more than the code asked for.** Before sending, it asked the namespace's
management endpoint, over HTTPS on port 443, whether the queue `orders` exists, because by default
Dapr's Service Bus components create the queues and subscriptions they need. The emulator does not
answer there, and the publish failed with 500. Against a real namespace the same default needs a
credential that may manage entities, not only send and receive; Dapr's documentation says so for a
shared access policy. Here the queue is already declared in `Config.json`, so the fix is to tell the
component not to manage it. That is one setting, appended to the file:

```
ana@laptop:~/azure$ printf '  - name: disableEntityManagement\n    value: "true"\n' >> components-sb/pubsub.yaml
ana@laptop:~/azure$ tail -n 4 components-sb/pubsub.yaml
  - name: connectionString
    value: "Endpoint=sb://servicebus;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;"
  - name: disableEntityManagement
    value: "true"
ana@laptop:~/azure$ docker rm -f shop-dapr billing-dapr audit-dapr > /dev/null
ana@laptop:~/azure$ for app in shop billing audit; do docker run -d --name $app-dapr --network container:$app -v ~/azure/components-sb:/components daprio/daprd:1.17.16 ./daprd --app-id $app --app-port 8080 --resources-path /components > /dev/null; done
ana@laptop:~/azure$ curl -s -w '%{http_code}\n' -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d '{"id": 2, "item": "tea", "qty": 1}'
204
```

`204`, and no line of `subscriber.py` or of the publish changed. That is the half of the promise
that holds.

## The same two programs, a different delivery

Four more orders, and then what each subscriber printed since it started:

```
ana@laptop:~/azure$ for id in 3 4 5 6; do curl -s -o /dev/null -X POST localhost:3500/v1.0/publish/pubsub/orders -H 'Content-Type: application/json' -d "{\"id\": $id}"; done
ana@laptop:~/azure$ docker logs billing
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 3}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 5}, "from": "shop", "type": "com.dapr.event.sent"}
ana@laptop:~/azure$ docker logs audit
{"order": {"id": 1, "item": "coffee", "qty": 2}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 2, "item": "tea", "qty": 1}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 4}, "from": "shop", "type": "com.dapr.event.sent"}
{"order": {"id": 6}, "from": "shop", "type": "com.dapr.event.sent"}
```

Order 1 is in both logs: it came through Redis, in the last section, as one copy per app. Orders 2
to 6 came through Service Bus, and **each of them reached exactly one of the two**. Which one took
which differs from run to run; that each went to only one does not. Billing would never have
charged for some of these orders, and nothing anywhere logged an error.

The reason is in the component's name. `pubsub.azure.servicebus.queues` maps the topic `orders` to
the queue `orders`, and every app that subscribes reads that one queue, so billing and audit are
two receivers on it, and a queue hands each message to one receiver. Redis gave every app id a
consumer group of its own. The API both programs called was the same; the delivery is the
component's, and the component changed. Redis received nothing this time, and the sidecar names
its new broker:

```
ana@laptop:~/azure$ docker exec redis redis-cli XLEN orders
1
ana@laptop:~/azure$ curl -s localhost:3500/v1.0/metadata | jq -c '.components[]'
{"name":"pubsub","type":"pubsub.azure.servicebus.queues","version":"v1","capabilities":["MESSAGE_TTL","BULK_PUBSUB"]}
{"name":"statestore","type":"state.redis","version":"v1","capabilities":["ETAG","TRANSACTIONAL","TTL","QUERY_API","KEYS_LIKE","ACTOR"]}
```

What billing and audit expected is what Dapr's other Service Bus component does,
`pubsub.azure.servicebus.topics`: the topic becomes a Service Bus topic, and each app gets a
subscription of its own on it, named after its consumer ID, which is its app id unless the
component sets one. With entity management off, as here, the subscriptions `billing` and `audit`
would have to exist beforehand, declared in `Config.json` or in Bicep. That is not run in this
lesson. **Choosing between the two is a question about the system, and no file in it
answers it for you**: a queue is right for work that one worker should do once, and a topic for
news that every interested team should hear. Lesson 20 draws that line for Service Bus itself.

So, against the promise:

| | Redis | Service Bus queues |
| --- | --- | --- |
| `subscriber.py` and the publish | unchanged | unchanged |
| the component's name, `pubsub` | unchanged | unchanged |
| creating the queue | not needed | tried by default, refused here |
| two apps on one topic | a copy each | one copy between them |
