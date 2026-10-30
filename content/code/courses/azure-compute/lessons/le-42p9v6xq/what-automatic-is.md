---
title: What Automatic is, and what it has already decided
version: 1
---

The name suggests a different product: a Kubernetes without nodes, the way the Container Apps of
lesson 8 are containers without a cluster. **AKS Automatic is the same AKS with a different SKU.**
The API server, `kubectl`, a Deployment and a PodDisruptionBudget are what lesson 11 used, and
they work the same way. What changes is who makes the decisions lesson 11 left to you, and
whether you may change them afterwards. Most of that lesson's `aks.bicep` described pools,
channels and surge settings; an Automatic cluster has none of those to write, because Microsoft
has already chosen them.

## Preconfigured, default, optional

Microsoft's documentation, read on 30 October 2026, sorts every feature of the two SKUs into
three words, and the first is the one to read carefully:

- preconfigured: always on, and you can neither switch it off nor change its settings;
- default: set up for you, and you may change it;
- optional: available, off until you configure it.

On AKS Standard, the SKU lesson 11 declared, almost everything is optional or default. On
Automatic, much of it is preconfigured. Here are the decisions lesson 11 made by hand, and what
Automatic does with each:

| lesson 11 decided | on Automatic |
|---|---|
| the tier: Free, Standard or Premium | **Standard, preconfigured**, with up to 5,000 nodes |
| a system pool: size, count, zones, taint | managed system node pools: AKS creates, scales and upgrades them, and hosts them in AKS's own subscriptions |
| user pools: `vmSize`, `count`, `maxPods` | none to declare: node auto-provisioning creates nodes from what the pods request, the next section |
| the operating system | Azure Linux on the system nodes, preconfigured; Azure Linux or Ubuntu on yours |
| `upgradeChannel` | `stable`, preconfigured: the latest patch of minor version N-1 |
| `nodeOSUpgradeChannel` | `NodeImage`, preconfigured |
| the maintenance windows | a default: you may still set planned maintenance |
| the node resource group | fully managed and locked against changes |

**The system nodes are not in your subscription at all.** In lesson 11 they were three
`Standard_D4s_v5` machines in the node resource group, billed to you. On Automatic, Microsoft's
documentation says the virtual machines of the managed system node pools are not charged to your
subscription, and you track no quota for them. They run CoreDNS, the metrics server, KEDA, the
Vertical Pod Autoscaler, the workload identity webhook and the image cleaner, and you cannot
schedule a pod of your own onto them.

## What lesson 11 never had to decide

The rest of the list is the cluster's surroundings, each of which is an option on Standard. On an
Automatic cluster, as the documentation gives it:

- networking: a managed virtual network using Azure CNI Overlay powered by Cilium, as a
  default; a virtual network of your own, the kind `azure-foundations` lesson 16 built, is the
  option. Outbound traffic leaves through a managed NAT gateway, and LocalDNS, a DNS proxy on each
  node, is preconfigured;
- ingress: from AKS 1.36, new clusters get the Kubernetes Gateway API through the application
  routing add-on. Older clusters got managed NGINX through the same add-on, and the change follows
  the upstream retirement of Ingress NGINX. Lesson 14 is about both;
- identity: Azure RBAC decides who may do what inside the cluster, the API server is
  integrated into the virtual network, and workload identity with its OIDC issuer is on. Lesson 13
  is about that last one;
- scaling pods: the Horizontal Pod Autoscaler, KEDA, which lesson 8 used inside Container
  Apps, and the Vertical Pod Autoscaler are enabled;
- policy: deployment safeguards and the baseline Pod Security Standard, both enforced, which
  is the section after next;
- images: the image cleaner, which removes unused images with known vulnerabilities from the
  nodes;
- monitoring: Managed Prometheus for metrics and Container insights for logs, as defaults when
  the cluster is created from the CLI or the portal.

## Two promises instead of one

Lesson 11's Standard tier promised one thing, that the API server answers. Automatic keeps that,
99.95%, and adds a second, which only Automatic carries: **a pod readiness SLA, under which 99.9%
of qualifying pod readiness operations complete within five minutes**, including the node that
has to be created for them. Put numbers on it: if the shop's deployments and scaling ask for 2,000
pods to become ready in a month, the promise holds as long as no more than 2 of them take longer
than five minutes. Which operations qualify is defined in Microsoft's SLA document, not in the AKS
documentation this course reads, so this lesson says no more about it than that.

## The declaration

The SKU is one property of the cluster, `sku.name`, and its two values are `Base`, which lesson
11's `aks.bicep` wrote, and `Automatic`. Save this as `automatic.bicep`:

```bicep
// automatic.bicep
param location string = 'brazilsouth'

resource aks 'Microsoft.ContainerService/managedClusters@2026-02-01' = {
  name: 'shop-auto'
  location: location
  sku: {
    name: 'Automatic'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hostedSystemProfile: {
      enabled: true
    }
  }
}
```

That is all of it. `tier: 'Standard'` is the tier Automatic would choose anyway, and
`hostedSystemProfile` asks for managed system node pools, which a new Automatic cluster gets by
default; both are written down so a reader does not have to know the defaults. The API version is
`2026-02-01`, the one Microsoft's quickstart uses; the compiler's types for `2026-01-01`, lesson
11's, do not know `hostedSystemProfile` and warn about it. Lesson 11's file declared two pools in
more than a dozen lines each, and this one declares no pool at all.

```
ana@laptop:~/azure$ bicep build automatic.bicep
ana@laptop:~/azure$ jq -c '.resources[0] | [.sku, .properties]' automatic.json
[{"name":"Automatic","tier":"Standard"},{"hostedSystemProfile":{"enabled":true}}]
```

Three slips a person makes when writing it from memory: the SKU's name in lower case, as the
command line spells it, the Free tier from lesson 11's table, and `true` written as a string.
`sed` writes them into a copy:

```
ana@laptop:~/azure$ sed -e "s/name: 'Automatic'/name: 'automatic'/" -e "s/tier: 'Standard'/tier: 'Free'/" -e "s/enabled: true/enabled: 'true'/" automatic.bicep > slip.bicep
ana@laptop:~/azure$ bicep build slip.bicep
/home/ana/azure/slip.bicep(16,16) : Warning BCP036: The property "enabled" expected a value of type "bool | null" but the provided value is of type "'true'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

One warning, for the string where a boolean belongs. **The other two compiled in silence**: the
types of `sku.name` and `sku.tier` accept any string. Whether Azure refuses an Automatic cluster on
the Free tier, or quietly makes it Standard, is the service's to decide, and nothing on a laptop
can ask it. Lesson 1's rule holds here as it did in lesson 11: treat every warning as a refusal,
and read a clean compile as the least a file needs.

## The command line

On a subscription the same cluster is one command. It was not run here, because it needs one:

```sh
az aks create --resource-group shop --name shop-auto --sku automatic --enable-hosted-system
```

The command line spells the SKU in lower case and lists the values it accepts:

```
ana@laptop:~/azure$ az aks create --help | grep -A5 -- "^    --sku "
    --sku                                                         : Specify SKU name for managed
                                                                    clusters. Use '--sku base'
                                                                    enables a base managed cluster.
                                                                    Use '--sku automatic' enables an
                                                                    automatic managed cluster.
                                                                    Allowed values: automatic, base.
```

Microsoft's quickstart asks for version 2.86.0 of the CLI or later, and the 2.91.0 of lesson 1 is
newer. It also asks you to register the `Microsoft.PolicyInsights` resource provider on the
subscription first, because an Automatic cluster switches Azure Policy on, and Azure Policy is
what the safeguards of the section after next are made of.
