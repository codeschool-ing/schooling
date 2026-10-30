---
title: "The environment, and the app inside it"
version: 1
---

Lesson 7 ended with the gaps a container group leaves: one copy, an update that restarts it in
place, no address in front of several copies. The tempting picture of Container Apps is a container
group with those three bolted on. **It is closer to a Kubernetes cluster that Microsoft runs and you
never see**: the documentation says the service manages the details of Kubernetes and container
orchestration for you, and scales with KEDA, the Kubernetes event-driven autoscaler. What you
declare is two resources. An **environment**, `Microsoft.App/managedEnvironments`, is the boundary:
a network and a log destination shared by everything inside it. A **container app**,
`Microsoft.App/containerApps`, names its environment and describes one service. This section
declares both for the shop and compiles them. Nothing is created: that needs a subscription, and
the commands that would create them are shown and marked as not run.

## The environment

Microsoft's documentation calls an environment a secure boundary around one or more container apps
and jobs, and the runtime looks after it: operating system upgrades, scaling, failover. Apps in one
environment **share a virtual network and a log destination**, and that is the test for how many
you need. The shop's order API and its nightly report belong in one. A test copy of the shop, which
must never share compute with production, belongs in another.

There are two kinds, and the CLI's help shows which one you get by default. Its descriptions wrap
in a narrow column, so the `awk` and `tr` join each parameter onto one line:

```
ana@laptop:~/azure$ az containerapp env create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(enable-workload-profiles|infrastructure-subnet-resource-id|internal-only) '
 --enable-workload-profiles -w : Boolean indicating if the environment is enabled to have workload profiles. Allowed values: false, true. Default: True. 
 --infrastructure-subnet-resource-id -s : Resource ID of a subnet for infrastructure components and user app containers. 
 --internal-only : Boolean indicating the environment only has an internal load balancer. These environments do not have a public static IP resource, therefore must provide infrastructureSubnetResourceId if enabling this property. Allowed values: false, true. 
```

`--enable-workload-profiles` defaults to true, so a new environment is a **workload profiles**
environment, which the documentation calls the default and the one every new environment should
be. The other kind, *Consumption only*, is labelled legacy. A workload profile is the kind of
compute an app runs on. Every workload profiles environment comes with one you cannot remove,
the first in this table:

| profile | what you get | how it is billed |
| --- | --- | --- |
| Consumption | 0.25 to 4 vCPUs and 0.5 to 8 GiB per replica, scale to zero | per second, for what each running replica was given, and per request |
| Dedicated, e.g. `D4` to `D32`, `E4` to `E32` | whole nodes of a chosen size, several apps on each | per node, plus a fixed management charge for the environment |
| Flexible (preview) | single-tenant, up to 16 GiB per replica | like Consumption, plus the management charge; cannot scale to zero |

**Scale to zero belongs to the Consumption profile.** The shop runs there, and so does everything
in this lesson. A Dedicated profile is for steady work on hardware you choose, and lesson 21 puts
it against the other services with arithmetic.

An environment with nothing running in it is not free of rules either. Microsoft deletes an
environment that has been idle, or failed because of its network or a policy, for more than 90
days.

## The network under it

When you create an environment you choose its network once, and the choice is permanent. With no
network named, Azure gives it one of its own, reachable from the internet and able to reach only
what is on the internet. With your own virtual network, the environment takes **a subnet of its
own**, and for a workload profiles environment the documentation sets three conditions: at least a
`/27`, delegated to `Microsoft.App/environments`, and a size you cannot change afterwards. A `/27`
has 18 addresses left once the platform has taken its 14, and the documentation plans one address
per ten Consumption replicas, with room held back for the doubling a deployment needs (section 04):
at most 90 replicas. `azure-foundations` lesson 16 built the shop's virtual network; the
environment's subnet would be one more in it.

`--internal-only` is the other permanent decision. An internal environment has no public address
at all, as the help text above says, and answers only on a load balancer inside the virtual
network. That is the place for the finance export, which nobody outside the company should reach.

## The app, in two halves

Here is the shop as a container app, declared in Bicep. It is the file as it stands on the day a
second version goes out to one customer in ten, so it carries a scale rule, a revision suffix and a
traffic split that sections 03 to 05 explain. Save it as `~/azure/shop-app.bicep`:

```bicep
// shop-app.bicep
param location string = 'brazilsouth'
param registry string = 'shopregistry.azurecr.io'
@secure()
param registryPassword string

resource env 'Microsoft.App/managedEnvironments@2026-01-01' = {
  name: 'shop-env'
  location: location
  properties: {
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource shop 'Microsoft.App/containerApps@2026-01-01' = {
  name: 'shop'
  location: location
  properties: {
    environmentId: env.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: [
        { name: 'registry-password', value: registryPassword }
      ]
      registries: [
        { server: registry, username: 'shopregistry', passwordSecretRef: 'registry-password' }
      ]
      ingress: {
        external: true
        targetPort: 8080
        traffic: [
          { revisionName: 'shop--v1-0', weight: 90 }
          { revisionName: 'shop--v1-1', weight: 10, label: 'canary' }
        ]
      }
    }
    template: {
      revisionSuffix: 'v1-1'
      containers: [
        {
          name: 'shop'
          image: '${registry}/shop:1.0'
          env: [
            { name: 'SHOP_VERSION', value: '1.1' }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        cooldownPeriod: 300
        pollingInterval: 30
        rules: [
          {
            name: 'http'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = shop.properties.configuration.ingress.fqdn
```

**The app's properties split into `configuration` and `template`, and the split is the most
important thing in the file.** `configuration` is about the app as a whole: how many revisions may
be active, its secrets, the registries it pulls from, and its ingress. `template` is what one
revision runs: the containers, their resources, the scale rule, the suffix. Section 04 shows what
follows from that, because a change to `template` makes a new revision and a change to
`configuration` does not.

**Ingress** is what lesson 7's container group did not have: an address in front of every copy,
with no load balancer or public IP address of your own to create. `external: true` publishes the
app at the environment's edge, and `false`, *internal*, makes it reachable only from other apps in
the same environment. `targetPort` is the port the container listens on, the shop's 8080. Callers
never see it: HTTP ingress answers on 443 with a name of its own, and by default redirects port 80
to it. The documentation also sets a request timeout of 240 seconds.

**Secrets** belong to the app, not to a revision, and are referred to by name. The registry's
password arrives as a `@secure()` parameter, so it is never written in the file, and the
`registries` entry points at it with `passwordSecretRef`. A container would reach one the same way,
with `secretRef` in place of `value` in its `env`. A managed identity with the `AcrPull` role,
`azure-foundations` lesson 8, removes the password altogether, with `identity: 'system'` in the
registry entry instead.

**The container's size comes in pairs on Consumption.** The documentation lists the combinations
the containers of one app may add up to, from 0.25 vCPU with 0.5 GiB to 4 vCPUs with 8 GiB, and
half a core goes with 1 GiB. The `json('0.5')` is lesson 7's: Bicep has no fractions. The CLI's
help is narrower than the documentation here:

```
ana@laptop:~/azure$ az containerapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(ingress|target-port|cpu|memory) '
 --cpu : Required CPU in cores from 0.25 - 2.0, e.g. 0.5. 
 --memory : Required memory from 0.5 - 4.0 ending with "Gi", e.g. 1.0Gi. 
 --ingress : The ingress type. Allowed values: external, internal. 
 --target-port : The application port used for ingress traffic. 
```

0.25 to 2.0 cores and up to 4.0 GiB is the limit the documentation gives for the legacy
environment, while a workload profiles environment allows 4 and 8. Where the two disagree, this
course follows the documentation.

## Compiled

```
ana@laptop:~/azure$ bicep build shop-app.bicep
ana@laptop:~/azure$ ls shop-app.*
shop-app.bicep
shop-app.json
ana@laptop:~/azure$ jq -c '.resources[] | {type, apiVersion, name}' shop-app.json
{"type":"Microsoft.App/managedEnvironments","apiVersion":"2026-01-01","name":"shop-env"}
{"type":"Microsoft.App/containerApps","apiVersion":"2026-01-01","name":"shop"}
ana@laptop:~/azure$ jq '.resources[1].dependsOn' shop-app.json
[
  "[resourceId('Microsoft.App/managedEnvironments', 'shop-env')]"
]
```

No warnings, a template beside the file, and the two resources in it with their API version,
`2026-01-01`, a stable one the compiler has types for. **The compiler also worked out the order**:
the app refers to `env.id`, so the template says the app depends on the environment, and Resource
Manager creates them in that order. A port written as text is caught:

```
ana@laptop:~/azure$ sed "s/targetPort: 8080/targetPort: '8080'/" shop-app.bicep > port.bicep
ana@laptop:~/azure$ bicep build port.bicep
/home/ana/azure/port.bicep(36,21) : Warning BCP036: The property "targetPort" expected a value of type "int | null" but the provided value is of type "'8080'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

That is a type, which the compiler knows. Sections 03 to 05 show four mistakes in this file that
it does not know. What creating the environment would look like, with the reply you get without an
account:

```
ana@laptop:~/azure$ az containerapp env create --name shop-env --resource-group shop
ERROR: Please run 'az login' to setup account.
```

On a subscription the next line would be `az containerapp create` with `--environment shop-env`,
or a deployment of the file above; neither is run in this course.

**`az containerapp` is part of the CLI itself**, not something added to it:

```
ana@laptop:~/azure$ az extension list
[]
ana@laptop:~/azure$ az containerapp --help | grep -A1 '^Group'
Group
    az containerapp : Manage Azure Container Apps.
```

No extensions installed, and the command group is there. Microsoft also publishes a `containerapp`
extension, which carries features in preview, and its pages install it with
`az extension add --name containerapp --upgrade --allow-preview true` where a feature needs it. On
the machine this course was recorded on, the extension's index could not be reached, so every
command in this lesson is the core CLI's.
