---
title: What a plan decides, and the five there are
version: 1
---

The names make the plans look like price tiers of one product: Consumption the cheap one, Premium
the dear one, Dedicated somewhere in between. **A plan is the machinery a function app runs on.**
The plans differ in what that machinery does: how instances are added and how many, whether the
last one is taken away when nobody calls, how long a function may run, and what the meter counts.
The price follows from those. It can come out either way round, which is the last section's
arithmetic.

The three names in this lesson's title are also no longer the list. Microsoft's documentation, read
on 2026-10-30, gives five hosting options for a function app and calls one of them legacy:

| | Flex Consumption | Premium | Dedicated | Container Apps | Consumption (legacy) |
|---|---|---|---|---|---|
| adds instances | per function, on events | per app, on events, with prewarmed ones | by hand or by autoscale | by Container Apps' own rules | per app, on events |
| most instances | 1,000 per function group, 100 by default | Windows 100, Linux 20 to 100 | 10 to 30, 100 in an ASE | 10 by default, up to 1,000 | Windows 200, Linux 100 |
| stops when idle | yes | no: at least one instance | no, with Always On | only with a minimum of zero replicas | yes |
| timeout, default and most | 30 min, unbounded | 30 min, unbounded | 30 min, unbounded with Always On | 30 min, unbounded with a replica kept | 5 min, 10 min |
| you pay for | executions, and memory while executing; any always ready instances | cores and memory of every allocated instance, prewarmed ones included | the App Service plan | Container Apps' billing | executions, and memory times execution time |
| takes a container | no | Linux | Linux | only a container | no |

Two lines of small print apply to all of them. "Unbounded" means no maximum is enforced, but an
execution still gets only 60 minutes of grace when its instance is taken away during scale-in, and
10 minutes during a platform update. And **an HTTP function has 230 seconds to answer, whatever the
timeout says.** That is the idle timeout of the load balancer in front of the app. The
documentation sends longer work to a queue or to Durable Functions, which is lesson 17.

## Flex Consumption, the serverless plan now

Flex Consumption is what the documentation recommends for a new serverless app, and it is the one
the rest of this lesson measures against. It runs on Linux only. **You choose the size of each
instance, from three**: 512 MB with a quarter of a core, 2,048 MB with one core, or 4,096 MB with
two, and 2,048 MB is the documented default for most apps. Memory and processor come together, so a
smaller instance is also a slower one, which the section `measuring-it` puts a number on.

It scales each function on its own, with three exceptions that scale as groups: all the HTTP
functions of an app together, all the blob functions that use Event Grid, and all the Durable
Functions. For the shop that means `take_order` and the queue-triggered `make_receipt` of lesson 15
get separate instances, so a backlog of receipts adds instances that never answer a customer. Each
group may grow to the app's maximum instance count, 100 unless you change it, and never past 1,000.
All the Flex apps of a subscription also share a regional quota, 250 cores by default.

It also connects to a virtual network, which the old Consumption plan never could, and it can keep
**always ready** instances: a number of instances per group that are never taken away, 0 unless you
say otherwise. They are the plan's answer to the cold start, and they are billed whether anyone calls
them or not.

## Consumption, which is legacy

The Consumption plan is the original serverless plan, and the documentation now says so in a box at
the top of its page: it is legacy, and new serverless apps should use Flex Consumption. On Linux it
is being retired. The hosting table already marks Linux Consumption as retired. The notice beside it
says the option retires on 30 September 2028 and gets no new features or language versions, and
that apps still on the version 3 runtime there stopped running after 30 September 2026. Windows
Consumption is not affected.

**For the shop that settles it.** Python runs only on Linux in Azure Functions, so a Python app has
exactly one serverless plan to choose for a new deployment: Flex Consumption. Consumption stays in
this lesson because its figures are the ones most articles about Functions still quote, and its
cold starts are the ones those articles describe.

## Premium and Dedicated, which never stop

The Premium plan is Elastic Premium in Resource Manager, with three instance sizes: EP1 with one core
and 3.5 GB, EP2 with two and 7 GB, EP3 with four and 14 GB. It scales on events like the consumption
plans. But **every Premium plan always has at least one billed instance**, so it never scales to
zero. The always ready count of the busiest app in the plan is the plan's minimum, up to 20 per app,
and a buffer of prewarmed instances, one by default, is started ahead of HTTP load. In São Paulo,
`brazilsouth`, a Linux Premium plan scales out to at most 20 instances. Mind the letter: the
documentation warns that a plan named `P1V2` is not Premium but a Dedicated plan, and does not scale
on events at all.

A Dedicated plan is an ordinary App Service plan, Basic, Standard, Premium or Isolated (Free and
Shared are not supported), with function apps on it beside web apps. You pay for the plan however many
apps it holds and however idle they are, and you scale it by hand or with autoscale rules like the
scale set of lesson 4. Without the setting **Always On**, the runtime goes idle after a few minutes
and only an HTTP request wakes it, which leaves a timer trigger silently not running. Lesson 18 is
about these plans.

The fifth option, Container Apps, runs the function app's container as a container app, through the
`--environment` parameter lesson 15 read in the CLI's help. Its scaling and its bill are Container
Apps' own, from lesson 8, and its cold start depends on one number: whether the minimum number of
replicas is zero.

## Where the decision is written

On the command line, the plan is chosen by the parameters of `az functionapp create`. The help is
real on the laptop. These are the ones that belong to Flex Consumption:

```
ana@laptop:~/azure$ az functionapp create --help | grep -E '^    --(flexconsumption-location|instance-memory|maximum-instance-count|always-ready-instances) '
    --always-ready-instances                       : Space-separated configuration for the number of
    --flexconsumption-location -f                  : Geographic location where function app will be
    --instance-memory                              : The instance memory size in MB. See
    --maximum-instance-count                       : The maximum number of instances.
```

A Premium plan is created first, as a plan, and the CLI's own example makes an EP1 that can burst to
ten instances:

```
ana@laptop:~/azure$ az functionapp plan create --help | grep -A2 'elastic premium'
    Create an elastic premium app service plan with burst out capability up to 10 instances.
        az functionapp plan create -g MyResourceGroup -n MyPlan --min-instances 1 --max-burst 10
        --sku EP1
```

Neither was run against Azure: both need a subscription. In Bicep, a plan is a
`Microsoft.Web/serverfarms` resource, and the documentation's table gives its `sku`: `FC1` with the
tier `FlexConsumption`, `EP1` to `EP3` with `ElasticPremium`, an App Service size such as `B1` for
Dedicated, and `Y1` with `Dynamic` for Consumption. For Flex, the decisions of this section sit on
the app, in `functionAppConfig`. Save this as `flex.bicep`:

```bicep
// flex.bicep
param location string = 'brazilsouth'
param deployContainer string = 'https://shopfnstore.blob.${environment().suffixes.storage}/deploy'

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'shop-flex'
  location: location
  kind: 'functionapp'
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: 'shop-fn'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: deployContainer
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.12'
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 100
        alwaysReady: [
          {
            name: 'http'
            instanceCount: 1
          }
        ]
      }
    }
  }
}
```

And compile it, then move two of its numbers to values the documentation rules out, 1,024 MB
for an instance and 2,000 for the ceiling, and compile it again:

```
ana@laptop:~/azure$ bicep build flex.bicep
ana@laptop:~/azure$ sed -i 's/instanceMemoryMB: 2048/instanceMemoryMB: 1024/; s/maximumInstanceCount: 100/maximumInstanceCount: 2000/' flex.bicep
ana@laptop:~/azure$ bicep build flex.bicep
ana@laptop:~/azure$ jq ".resources[1].properties.functionAppConfig.scaleAndConcurrency" flex.json
{
  "instanceMemoryMB": 1024,
  "maximumInstanceCount": 2000,
  "alwaysReady": [
    {
      "name": "http",
      "instanceCount": 1
    }
  ]
}
```

**Both compiles are silent, and the template carries the wrong numbers.** The resource types say that
`instanceMemoryMB` and `maximumInstanceCount` are numbers, and a number is what they got; which
numbers Flex Consumption offers, 512, 2,048 or 4,096 MB and at most 1,000 instances, is written in
the documentation and nowhere in the types. Whether Azure would refuse this template, and with what
message, cannot be found out on a laptop. Put the two values back before going on. `alwaysReady` is
the cold-start setting, one instance kept for the `http` group, and it is the subject of the next
section.
