---
title: On Azure, and when the abstraction pays off
version: 1
---

Dapr pays when the same code has to meet more than one backend, or when several services in several
languages need the same plumbing and would otherwise each write it. **What it costs is a second
process in every replica, a hop on every call through it, a second log to read, and Dapr's own API
as something you now depend on.** One service talking to one broker it will keep is usually better
served by that broker's own library. This section declares the shop's component the way Container
Apps takes it, compiles it, measures the costs on the laptop, and ends with the decision. The
declaration is compiled; deploying it is read, not run.

## A component belongs to the environment

On your laptop each sidecar read a directory. In Container Apps, **a Dapr component is a resource of
the environment**, not of an app, and by default every Dapr-enabled app in the environment loads
every component. Its `scopes` list narrows that to the app ids that should load it. They are Dapr
app ids, the `appId` of section 02, not the names of the container apps, and Microsoft's
documentation says you should use them.

The file takes a slightly shorter form than the one your sidecars read: no `apiVersion`, no
`kind`, and the type is called `componentType`. Here is the shop's broker as Container Apps would
take it, signed in with a managed identity rather than a connection string:

```yaml
# pubsub-aca.yaml
componentType: pubsub.azure.servicebus.queues
version: v1
metadata:
- name: namespaceName
  value: shop-sb.servicebus.windows.net
- name: azureClientId
  value: 00000000-0000-0000-0000-000000000000
scopes:
- shop
- billing
```

`namespaceName` is the namespace's full host name, which Dapr asks for whenever it signs in with
Microsoft Entra ID rather than a key. `azureClientId` is the client id of a user-assigned managed
identity, and Microsoft's documentation says it is required whenever the component authenticates
with one. The zeros are a placeholder. **With a managed identity there is no secret in the component
at all**, which is why Microsoft recommends it for every Azure service that supports it; the
identity still needs a role on the namespace, as `azure-foundations` lessons 8 and 9 set up for
any identity. For a service that cannot sign in that way, the component names a secret store
instead, such as Key Vault, which `azure-operations` lesson 17 covers. Handing the file to an
environment is one command, and it meets the course's usual refusal:

```
ana@laptop:~/azure$ az containerapp env dapr-component set --resource-group shop --name shop-env --dapr-component-name pubsub --yaml pubsub-aca.yaml
ERROR: Please run 'az login' to setup account.
```

The same component in Bicep is a child of the environment, `daprComponents`. This file declares it
beside the identity, and beside billing as a container app with Dapr turned on. Save it as
`~/azure/dapr.bicep`:

```bicep
// dapr.bicep
param location string = 'brazilsouth'

resource env 'Microsoft.App/managedEnvironments@2026-01-01' existing = {
  name: 'shop-env'
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'shop-dapr'
  location: location
}

resource pubsub 'Microsoft.App/managedEnvironments/daprComponents@2026-01-01' = {
  parent: env
  name: 'pubsub'
  properties: {
    componentType: 'pubsub.azure.servicebus.queues'
    version: 'v1'
    metadata: [
      { name: 'namespaceName', value: 'shop-sb.servicebus.windows.net' }
      { name: 'azureClientId', value: identity.properties.clientId }
    ]
    scopes: [
      'shop'
      'billing'
    ]
  }
}

resource billing 'Microsoft.App/containerApps@2026-01-01' = {
  name: 'billing'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    environmentId: env.id
    configuration: {
      dapr: {
        enabled: true
        appId: 'billing'
        appPort: 8080
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'billing'
          image: 'shopregistry.azurecr.io/billing:1.0'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}
```

`existing` refers to the environment lesson 8 declared, `shop-env`, without declaring it again.
The component takes the identity's client id from the identity itself, so the two cannot drift
apart. The `dapr` block is the four settings of section 02. `minReplicas: 1` is there for a reason
of Dapr's: **a subscriber scaled to zero has no sidecar running to receive messages**, so it either
keeps one replica or gets a scale rule on the queue's length, which is how lesson 8 scaled on
anything that is not HTTP. The compiler checks it, then shows that the scopes reached the template:

```
ana@laptop:~/azure$ bicep build dapr.bicep
ana@laptop:~/azure$ jq '.resources[] | select(.type | endswith("daprComponents")) | .properties.scopes' dapr.json
[
  "shop",
  "billing"
]
```

Silence is the pass. Two mistakes, and what the compiler makes of each:

```
ana@laptop:~/azure$ sed 's/appId:/appID:/' dapr.bicep > typo.bicep; bicep build typo.bicep
/home/ana/azure/typo.bicep(44,9) : Warning BCP089: The property "appID" is not allowed on objects of type "Dapr". Did you mean "appId"? [https://aka.ms/bicep/core-diagnostics#BCP089]
ana@laptop:~/azure$ sed 's/servicebus.queues/servicebus.queue/' dapr.bicep > queue.bicep; bicep build queue.bicep; ls queue.*
queue.bicep
queue.json
```

`appID` is refused, with the right name offered, because the `dapr` block's properties are known to
the compiler. The singular `pubsub.azure.servicebus.queue` compiled without a word: `componentType`
is a plain string, and the compiler cannot know which strings Dapr has components for. The sidecar
can, and it does not start:

```
ana@laptop:~/azure$ mkdir typo
ana@laptop:~/azure$ sed 's/servicebus.queues/servicebus.queue/' components-sb/pubsub.yaml > typo/pubsub.yaml
ana@laptop:~/azure$ docker run --rm --network shop-net -v ~/azure/typo:/components daprio/daprd:1.17.16 ./daprd --app-id typo --resources-path /components 2>&1 | grep -o 'level=fatal msg="[^"]*'
level=fatal msg="Fatal error from runtime: process component pubsub error: [INIT_COMPONENT_FAILURE]: initialization error occurred for pubsub (pubsub.azure.servicebus.queue/v1): [CREATE_COMPONENT_FAILURE]: initialization error occurred for pubsub (pubsub.azure.servicebus.queue/v1): couldn't find message bus pubsub.azure.servicebus.queue/v1
```

That is the open-source `daprd` 1.17.16 refusing it. **Write the type exactly as Dapr's own
reference spells it.** The singular is worth a warning because Microsoft's own page about Dapr
components in Container Apps uses it in its example, and that page does not say whether Azure's
build accepts it.

What a component may name is narrower in Container Apps than in Dapr. Microsoft's documentation
supports only the components it lists as Tier 1, which are fully supported, and Tier 2, which are
supported on a best-effort basis; read that list before you design around a component.

## What it costs

The sidecars are still running, so measure two of the costs on the laptop. Memory first, with
the total that `docker stats` prints after the slash cut away:

```
ana@laptop:~/azure$ docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' shop shop-dapr billing billing-dapr | cut -d/ -f1
shop 14.02MiB 
shop-dapr 23.85MiB 
billing 13.98MiB 
billing-dapr 23.96MiB 
```

Each sidecar takes more memory than the program it serves. These are the laptop's numbers, for a
program of fifty lines, and the documentation does not say how much of a replica's CPU and memory
the sidecar takes in Container Apps, so do not carry them across. What does carry across is the
shape: **every replica of every Dapr-enabled app carries a second process**, and beside a small
program it can be the larger of the two.

Then the hop. The first loop asks the shop for `/healthz` directly, two hundred times, and prints
the average; the second asks the shop's own sidecar to call the same page, which is Dapr's service
invocation:

```
ana@laptop:~/azure$ for i in $(seq 200); do curl -s -o /dev/null -w '%{time_total}\n' localhost:8080/healthz; done | awk '{s += $1} END {printf "%.2f ms\n", s / NR * 1000}'
3.07 ms
ana@laptop:~/azure$ for i in $(seq 200); do curl -s -o /dev/null -w '%{time_total}\n' localhost:3500/v1.0/invoke/shop/method/healthz; done | awk '{s += $1} END {printf "%.2f ms\n", s / NR * 1000}'
5.14 ms
```

The difference is what one trip through a sidecar costs, on loopback, on this laptop; the numbers
move between runs. Between two apps in Container Apps a service invocation passes through two
sidecars, the caller's and the callee's, and in return each call gets discovery by app id and
encryption that Container Apps manages.

The other two costs do not show in a measurement. **There is a second thing to debug.** The 500 of
section 04 was the sidecar's; the shop's log never mentioned it, and a subscription that failed to
start would have been visible only in the subscriber's sidecar's log. Every replica now has two
logs, and a problem may be in either. And **you depend on Dapr's API**, not only on the broker's:
the `/v1.0/` paths, the CloudEvent envelope, and the `shop||order-1` layout in Redis, which a
program reading that store without Dapr has to know about. In Container Apps that API is upgraded
for you, on Microsoft's schedule. A feature the broker has and the building block does not name,
such as Service Bus sessions, is reached through component metadata if at all, and every such use
ties the code back to one broker.

## When it pays

The shop gives one case each way. Billing and audit run on Redis on every developer's laptop and
on Service Bus in Azure; the difference is one file per environment, with the right component type
in it, and the code is tested the same in both places. That pays. So does a second team writing
in another language, who get the same state and pub/sub API without learning a second SDK. A
single order API that will only ever talk to one Service Bus namespace gains a process and a hop
and loses direct use of the broker; the `azure-servicebus` library of lesson 20 serves it better.
Lesson 22 is about portable seams in general, of which this is one kind.

Before moving on, remove everything this lesson started:

```
ana@laptop:~/azure$ docker rm -f shop shop-dapr billing billing-dapr audit audit-dapr redis servicebus mssql > /dev/null
ana@laptop:~/azure$ docker network rm shop-net
shop-net
```
