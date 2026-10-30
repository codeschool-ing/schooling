---
title: "Event Grid: a notice pushed to whoever asked"
version: 1
---

Event Grid appears beside Service Bus in every list of Azure's messaging services, and it is easy to
take for another queue. **It is a router, and it holds nothing for anybody to collect.** A publisher posts an *event*,
a short notice that something happened, to a **topic**. Each **event subscription** on that topic
says which events it wants and where they go, and Event Grid *pushes* each matching event there, as
an HTTP request, at once. Nobody polls and nothing waits to be received: if the handler is down,
Event Grid retries on its own schedule and then gives up. A Service Bus message is work somebody
must do; an Event Grid event is news that somebody may care about.

**Nothing on a laptop runs Event Grid**, and Microsoft publishes no emulator for it, so this section
is read. The parts that run are the declaration, which the Bicep compiler checks, and the CLI's
help.

## Where events come from

A **system topic** carries the events of an Azure service: a storage account announcing that a blob
was created, a resource group announcing that a resource was written. Only the service publishes to
it, so it has no endpoint or key of yours, and there is one system topic per source. A **custom
topic** is the application's own: the shop creates one, gets an endpoint and an access key, and
posts its events there.

An event arrives in one of two shapes. The Event Grid schema is Microsoft's own; **CloudEvents 1.0**
is an open specification from the Cloud Native Computing Foundation, and Event Grid accepts and
delivers it natively. This is the event the shop's order API would post when an order is placed. It
is written for this lesson, not received from anywhere:

```json
{
  "specversion": "1.0",
  "type": "shop.order.placed",
  "source": "/shop/orders",
  "id": "order-42-placed",
  "time": "2026-10-30T14:05:00Z",
  "subject": "orders/42",
  "datacontenttype": "application/json",
  "data": {"order": 42, "total": 150000}
}
```

The envelope is the specification's: `type` says what happened, `source` and `subject` say where,
`id` names this one event, and `data` is the shop's, here a total in centavos. The `id` matters at
the end of this lesson, because it is what a handler that has seen an event before recognises it by.

## A subscription, declared and compiled

The shop wants large orders reviewed by a person. One subscription on the custom topic does it: it
takes only `shop.order.placed`, only above R$ 1,000.00, and sends them to the review service's
address. The address is a parameter marked `@secure()`, because a webhook address often carries a
key in its query string, and the compiler warns about one written in the file. Save this as
`~/azure/events.bicep`:

```bicep
// events.bicep
param location string = 'brazilsouth'

@secure()
param reviewUrl string

resource topic 'Microsoft.EventGrid/topics@2025-02-15' = {
  name: 'shop-orders'
  location: location
  properties: {
    inputSchema: 'CloudEventSchemaV1_0'
  }
}

resource bigOrders 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = {
  parent: topic
  name: 'big-orders'
  properties: {
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: reviewUrl
      }
    }
    filter: {
      includedEventTypes: [
        'shop.order.placed'
      ]
      advancedFilters: [
        {
          operatorType: 'NumberGreaterThan'
          key: 'data.total'
          value: 100000
        }
      ]
    }
    retryPolicy: {
      maxDeliveryAttempts: 10
      eventTimeToLiveInMinutes: 120
    }
    deadLetterDestination: {
      endpointType: 'StorageBlob'
      properties: {
        resourceId: resourceId('Microsoft.Storage/storageAccounts', 'shopdeadletters')
        blobContainerName: 'undelivered'
      }
    }
  }
}
```

The filter has the three levels Event Grid offers: event types, a subject that begins or ends with
something (unused here), and **advanced filters** on any field of the event, `data.total` included.
Compile it, then compile two copies with one value changed in each, an operator misspelt and an
attempt count raised to 50:

```
ana@laptop:~/azure$ bicep build events.bicep
ana@laptop:~/azure$ sed "s/NumberGreaterThan/NumberGreaterThen/" events.bicep > typo.bicep; bicep build typo.bicep
/home/ana/azure/typo.bicep(32,25) : Warning BCP088: The property "operatorType" expected a value of type "'BoolEquals' | 'IsNotNull' | 'IsNullOrUndefined' | 'NumberGreaterThan' | 'NumberGreaterThanOrEquals' | 'NumberIn' | 'NumberInRange' | 'NumberLessThan' | 'NumberLessThanOrEquals' | 'NumberNotIn' | 'NumberNotInRange' | 'StringBeginsWith' | 'StringContains' | 'StringEndsWith' | 'StringIn' | 'StringNotBeginsWith' | 'StringNotContains' | 'StringNotEndsWith' | 'StringNotIn'" but the provided value is of type "'NumberGreaterThen'". Did you mean "'NumberGreaterThan'"? [https://aka.ms/bicep/core-diagnostics#BCP088]
ana@laptop:~/azure$ sed "s/maxDeliveryAttempts: 10/maxDeliveryAttempts: 50/" events.bicep > fifty.bicep; bicep build fifty.bicep
```

The clean file compiles without a word. The misspelt operator gets a warning, which this course
treats as a refusal, with the list of the nineteen operators it could have been and the one it most
likely was. **The count of 50 passed, though Microsoft's documentation allows only 1 to 30**: the
resource type says that the property is a number and nothing about its range, which lives in the
service. The CLI's help states it, offline:

```
ana@laptop:~/azure$ az eventgrid event-subscription create --help | grep -A2 -E -- "--(max-delivery-attempts|event-ttl) "
    --event-ttl                                           : Event time to live (in minutes). Must be
                                                            a number between 1 and 1440.  Default:
                                                            1440.
--
    --max-delivery-attempts                               : Maximum number of delivery attempts.
                                                            Must be a number between 1 and 30.
                                                            Default: 30.
--
            --max-delivery-attempts 10 --event-ttl 120
```

So both limits of a retry policy have a fence the compiler does not know: 1 to 30 attempts, and 1 to
1440 minutes, a day, for the event's time to live. Deploying the file is one command, not run in this
course because it needs a subscription:

```sh
az deployment group create --resource-group shop-rg --template-file events.bicep --parameters reviewUrl="$REVIEW_URL"
```

## Push, retry, dead-letter

**Event Grid delivers at least once, and in no guaranteed order.** It posts the event and waits 30
seconds for an answer. A success code ends it. A failure, or no answer, puts the event on a retry
schedule. Microsoft's documentation gives it as 10 seconds, 30 seconds, 1 minute, 5, 10 and 30
minutes, 1, 3 and 6 hours, then every 12 hours up to 24. Some randomness is added, and retries are
skipped for an endpoint that looks unhealthy. Some answers are not retried at all, because trying
again cannot help: for a webhook, 400, 401, 403 and 413.

When the attempts or the time to live run out, whichever comes first, the event is **dead-lettered**
if the subscription names a blob container for it, five minutes after the last attempt, and
dropped if it does not. Dead-lettering is off unless you turn it on, which is why
`events.bicep` turns it on: an order above R$ 1,000.00 that nobody reviewed should leave a file
behind, not a silence. A consequence of all this is the same as for any queue: an endpoint that
answers slowly can receive the same event twice, and the documentation says so in as many words.

## The handshake

A system that posts to any address it is given could be pointed at somebody else's server, so Event
Grid asks a webhook to prove that it expects the traffic before it delivers anything. With the Event
Grid schema, it sends a `Microsoft.EventGrid.SubscriptionValidationEvent` whose `data` carries a
`validationCode`, and the endpoint echoes it back as `{"validationResponse": "<the code>"}`. An
endpoint that cannot answer that way can instead open the `validationUrl` from the same event within
ten minutes. With CloudEvents, as here, the check is the specification's own: an HTTP `OPTIONS`
request with a `WebHook-Request-Origin` header, which the endpoint answers with
`WebHook-Allowed-Origin`.

**An Azure Function with an Event Grid trigger skips all of it**, and so do Logic Apps and Azure
Automation: Azure validates those endpoints itself. A function app of the kind lesson 15 built, given
an Event Grid trigger, is the short way to a handler; a plain web app, such as the shop's own API, has
to answer the handshake in its own code.

Two more destinations change the picture. A subscription can deliver to a Service Bus queue or an
event hub instead of a webhook. That puts Event Grid's routing in front of a consumer that receives
at its own pace, with the locks and the dead-letter subqueue of the first section. And
Event Grid also offers **pull delivery**, for topics in an Event Grid namespace, where the consumer
connects and reads events rather than exposing an endpoint; the shop does not need it.
