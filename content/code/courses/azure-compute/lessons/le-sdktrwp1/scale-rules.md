---
title: "Scale rules, and what zero costs"
version: 1
---

Lesson 4's scale set added machines when their average processor load crossed a line, and it never
went below its minimum of three. A container app scales differently in two
ways. **It counts the work arriving rather than the load it causes**: requests per second, open
connections, messages waiting in a queue. And **its minimum can be zero**, so a revision with
nothing to do runs no replicas and costs nothing. The price of zero is paid by the first request
after it, which has to wait for a replica to start. This section reads the rules from Microsoft's
documentation, compiles the shop's, and shows one mistake the compiler catches and one it does not.

## Limits, per revision

A *replica* is one running copy of a revision, and the scale block sets how many there may be:

```
ana@laptop:~/azure$ az containerapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(min-replicas|max-replicas|scale-rule-http-concurrency|scale-rule-type) ' | sed 's/ For more.*//'
 --max-replicas : The maximum number of replicas. 
 --min-replicas : The minimum number of replicas. 
 --scale-rule-http-concurrency --scale-rule-tcp-concurrency --srhc --srtc : The maximum number of concurrent requests before scale out. Only supported for http and tcp scale rules. 
 --scale-rule-type --srt : The type of the scale rule. Default: http.
```

The help gives no defaults for the two limits; the documentation does. **`minReplicas` defaults
to 0 and `maxReplicas` to 10**, and either may go as high as 1,000. Both count replicas **per
revision**, which matters in section 05: two revisions sharing the traffic may each run up to ten.
The shop's limits, as the template carries them:

```
ana@laptop:~/azure$ jq '.resources[1].properties.template.scale' shop-app.json
{
  "minReplicas": 0,
  "maxReplicas": 10,
  "cooldownPeriod": 300,
  "pollingInterval": 30,
  "rules": [
    {
      "name": "http",
      "http": {
        "metadata": {
          "concurrentRequests": "50"
        }
      }
    }
  ]
}
```

`cooldownPeriod` and `pollingInterval` are written out at 300 and 30 seconds, which are the
documented defaults. Leaving them out would change nothing. Writing them down puts the two
numbers in front of whoever reads the file next.

## Three kinds of rule

**HTTP** counts concurrent requests, and the documentation defines the count precisely: every 15
seconds, the number of requests in the past 15 seconds divided by 15. 1,500 requests in a quarter
of a minute is a concurrency of 100. When that exceeds the rule's `concurrentRequests`, 10 unless
you say otherwise, the revision gains a replica, and keeps gaining them up to `maxReplicas`. The
shop's rule says 50. **TCP** is the same idea with open connections, for an app whose ingress
speaks TCP rather than HTTP.

**Custom** rules are any of KEDA's scalers: a Storage queue, a Service Bus queue, Event Hubs,
Kafka, Redis, processor or memory load. The shop's order worker, which lesson 20 builds on Service
Bus, would scale on its queue. In the shape Microsoft's scale page gives for a Storage queue, read
by the app's own managed identity rather than with a key, the rule is:

```bicep
rules: [
  {
    name: 'orders-queue'
    custom: {
      type: 'azure-queue'
      metadata: {
        accountName: 'shopordersp'
        queueName: 'orders'
        queueLength: '5'
      }
      identity: 'system'
    }
  }
]
```

That fragment is not part of the shop's file and was not compiled on its own. Where the scaler
needs a secret instead, the rule's `auth` list names one of the app's secrets. Microsoft's page
adds one condition: an app scaling on events other than HTTP should run in *single* revision mode,
which section 04 explains.

**A rule on processor load cannot reach zero by itself.** KEDA's own documentation says its CPU and
memory scalers scale to zero only when another scaler, of a different kind, is defined beside them.
A replica that is not running has no processor load to measure, so nothing would ever bring the
first one back.

Two more rules of combination. With several rules, the app starts to scale as soon as any one of
them is met. With none, a default applies: HTTP, between 0 and 10. **An app with no ingress, no
custom rule and a minimum of 0 scales to zero and has no way of starting again**, because the only
rule it has counts requests that cannot arrive. The documentation marks that as important, and it
is the kind of mistake nothing reports: the app is healthy, and idle for ever.

## How a decision is made

KEDA does not react to every request. The documentation's table of behaviour:

| behaviour | value |
| --- | --- |
| polling interval | 30 seconds, for event sources; not used by HTTP and TCP rules |
| cool-down period | 300 seconds, applied only when the last replica goes to zero |
| scale-up stabilisation window | 0 seconds |
| scale-down stabilisation window | 300 seconds |
| scale-up step | 1, then 4, 8, 16, 32 and so on, up to the maximum |
| scale-down step | all the replicas that are no longer needed |
| desired replicas | `ceil(currentMetricValue / targetMetricValue)` |

The documentation works one example through, and it is worth following once. A queue rule asks for
one replica per 5 messages, with a maximum of 20, and 50 messages arrive: the desired count is
`ceil(50/5)`, 10. The app does not jump to 10. Each step is
`min(maxReplicaCount, desiredReplicas, max(4, 2*currentReplicaCount))`, so from 1 replica the next
count is `min(20, 10, 4)`, 4; at the next poll `min(20, 10, 8)`, 8; then 10. **Scaling up is
quick, and scaling down waits**: five minutes of a condition holding before replicas go, and five
minutes after the last event before the last replica does.

The limits are where the compiler stops helping. Microsoft's own Bicep example of an HTTP rule
says it scales out to five replicas and in to zero, and writes `maxReplicas: 0` and
`minReplicas: 5`. The same swap in the shop's file:

```
ana@laptop:~/azure$ sed 's/minReplicas: 0/minReplicas: 5/; s/maxReplicas: 10/maxReplicas: 0/' shop-app.bicep > swap.bicep
ana@laptop:~/azure$ bicep build swap.bicep
ana@laptop:~/azure$ jq -c '.resources[1].properties.template.scale | {minReplicas, maxReplicas}' swap.json
{"minReplicas":5,"maxReplicas":0}
```

No warning. Both are whole numbers, which is all the type asks, and the compiler does not compare
one property with another: the blind spot lesson 4 met with an autoscale minimum above its
maximum. A metadata value is different, because every value in `metadata` is
typed as text:

```
ana@laptop:~/azure$ sed "s/concurrentRequests: '50'/concurrentRequests: 50/" shop-app.bicep > number.bicep
ana@laptop:~/azure$ bicep build number.bicep
/home/ana/azure/number.bicep(68,37) : Warning BCP036: The property "concurrentRequests" expected a value of type "string" but the provided value is of type "50". [https://aka.ms/bicep/core-diagnostics#BCP036]
```

## What zero costs

**A revision at zero replicas incurs no usage charges**, by Microsoft's billing page, which is
the whole point of the Consumption profile for a shop that is quiet from midnight to seven. A
revision kept at a minimum of 1 or more is billed for that replica all night. The rate drops to a
reduced *idle* one while the replica handles no requests, uses less than 0.01 of a core and
receives under 1,000 bytes a second. Lesson 21 puts numbers on the difference.

The other side is the **cold start**. The documentation defines it as the time it takes to pull the
image, provision the resources and start the application, and the first request after zero waits
for all three. The revision's state shows it: *Scale to 0* while idle, *Activating* while the first
replica is being provisioned. Part of what is pulled is this:

```
ana@laptop:~/azure$ docker image ls shop:1.0 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
shop:1.0  178MB
```

178 MB, almost all of it the `python:3.12-slim` base, since `app.py` is a few kilobytes. A small
image is the first of Microsoft's suggestions for a shorter cold start. The second is a registry in
the same region as the environment, which is why the shop's registry is in `brazilsouth`. The
third is an application that opens its port early, before any slow initialisation, and the
fourth is clients that expect a slow first answer and retry. The last is to wake the app on
purpose, with a request sent by a scheduled job a little before the first customer. Lesson 16
measures a cold start on the laptop, for Functions, where the same trade decides the plan.

So the choice for the shop is between a first request in the morning that waits, at no cost
overnight, and a minimum of 1 that never waits and is paid for every hour. Neither is wrong. For an
order API that customers reach from an app on their phones, one idle replica is the usual answer;
for the internal stock page the three developers open twice a day, zero is.

## When the work finishes: jobs

An app is something that runs until it is told to stop, and restarts when it crashes. A **Container
Apps job** runs, finishes and stops, in the same environment as the apps, with the same network and
logs. It is the Container Apps answer to lesson 7's `OnFailure` group, and Microsoft's own example
of one is a process that generates financial reports nightly.

A job is started in one of three ways: *Manual*, on request; *Schedule*, by a cron expression of
five fields; or *Event*, by the same KEDA scalers as above, which start an execution per batch of
messages instead of adding replicas. Jobs do not support HTTP or TCP rules and have no ingress.
Each execution has a `replicaTimeout` in seconds and a `replicaRetryLimit`, which gives the report
what lesson 7's group lacked: a deadline, and a limit on how many times it is tried again. One
detail catches São Paulo. **Cron expressions in scheduled jobs are evaluated in UTC**, so the report
due at 23:30 in São Paulo, three hours behind, is `30 2 * * *`.
