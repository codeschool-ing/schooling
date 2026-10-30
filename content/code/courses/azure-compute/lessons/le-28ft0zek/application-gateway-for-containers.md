---
title: Application Gateway for Containers, and the resources behind a Gateway
version: 1
---

With AGIC's name in its own, Application Gateway for Containers reads like AGIC's next version: the
same gateway, a newer controller. **It is a different product, built for Kubernetes, with a
control plane and a data plane of its own**; Microsoft describes it as shaped by what AGIC taught
and separate from it. The proxy is still outside the cluster and operated by Azure. What changed is
everything between the cluster and that proxy. A controller in the cluster, the ALB Controller,
reads Gateway API resources as well as Ingress. On the Azure side the work is split into small
resources with one job each, and the gateway the shop's route attached to in section 03 is, in
Azure, a *frontend*.

## Four resources, and two dependencies

Microsoft's documentation, read on 30 October 2026, lists the parts of a deployment:

- the *Application Gateway for Containers* resource itself, of type
  `Microsoft.ServiceNetworking/trafficControllers`, a parent that deploys the control plane;
- a *frontend*, a child that is one entry point for clients. Each frontend gets a name Azure
  generates, of the form `*.fzXX.alb.azure.com`, which you use as it is or point a CNAME at. It
  listens on ports 80 and 443 only, and has no private address;
- an *association*, a child that connects the data plane to a subnet of your virtual network,
  one to one. Today a resource can have only one;
- a *security policy*, which points at a Web Application Firewall policy.

The two dependencies are a *subnet delegated* to `Microsoft.ServiceNetworking/trafficControllers`,
where the association puts the data plane, and a *user-assigned managed identity* for the ALB
Controller, holding the built-in role *AppGw for Containers Configuration Manager*. That role has
data actions that Owner and Contributor do not have, so giving the controller Contributor is not
enough. The identity reaches the controller's pod by workload identity, the federated credential of
lesson 13; the add-on's documentation requires it to be on.

The subnet has a size rule. **Each association assumes at least 256 free addresses, so the subnet
is a `/24` or larger**, and several resources sharing one subnet need n × 256 of them.

## Bring your own, or managed by the controller

There are two ways to own these resources, and the choice decides who creates a frontend.

*Bring your own.* You create the resource, the frontend and the association in Azure, with the
CLI, Bicep or Terraform, and a Gateway in the cluster refers to them: an annotation names the
resource and an address names the frontend. Deleting the Gateway leaves the frontend where it is,
and its FQDN with it, because the Azure administrator owns it. In the shop's `gateway.yaml` that is
two additions:

```yaml
metadata:
  name: shop-gateway
  namespace: infra
  annotations:
    alb.networking.azure.io/alb-id: /subscriptions/<id>/resourceGroups/shop/providers/Microsoft.ServiceNetworking/trafficControllers/shop-agc
spec:
  gatewayClassName: azure-alb-external
  addresses:
  - type: alb.networking.azure.io/alb-frontend
    value: shop-frontend
```

*Managed by the ALB Controller.* You create a custom resource in the cluster, an
`ApplicationLoadBalancer` naming the delegated subnet, and the controller creates the Azure resource
and its association; the documentation allows five to six minutes for that. Each Gateway that names
it by two annotations, `alb.networking.azure.io/alb-namespace` and `alb.networking.azure.io/alb-name`,
gets a new frontend, and loses it when the Gateway is deleted. A new Gateway is a new FQDN, which is
a reason to prefer bring-your-own for an address customers have in their DNS.

The rest of the shop's files do not change. **The route, the weights, the header match and the
grant are the same files on either strategy**, and the same files the lab applied to a cluster with
no controller.

## The controller

The ALB Controller is two pods: `alb-controller`, which turns the cluster's resources into
configuration, and `alb-controller-bootstrap`, which manages its custom resource definitions. It
uses ARM and a configuration API of the service's own to apply the changes, and it is installed by
Helm or by an AKS add-on that creates the identity and a delegated subnet called `aks-appgateway` for
you. The add-on is in preview, and Microsoft's quickstart reaches it through the `aks-preview`
extension and two feature registrations. The resource commands live in an extension too, `alb`,
which this course's command line does not have:

```
ana@laptop:~/azure$ az network alb --help
ERROR: 'alb' is misspelled or not recognized by the system.
Did you mean 'lb' ?

https://aka.ms/cli_ref
Read more about the command in reference docs
```

Once installed, the controller claims the class the lab wrote by hand. The add-on's quickstart
checks for a GatewayClass called `azure-alb-external` with the controller name
`alb.networking.azure.io/alb-controller`, and expects its `Accepted` condition to read `True`, with
the message `Valid GatewayClass`, where the lab's read `Unknown`. The documentation says the
controller implements version 1.5 of the Gateway API, and lists GatewayClass, Gateway, HTTPRoute,
GRPCRoute and ReferenceGrant among what it supports, with listeners on ports 80 and 443 only.

On the way to the shop, the data plane adds three headers to every request, `x-forwarded-for`,
`x-forwarded-proto` and `x-request-id`, and waits 60 seconds for an answer unless the route sets
`timeouts.request`. The controller has the service's configuration API beside ARM, where AGIC had
ARM alone, but the documentation gives no figure for how long a change takes to reach the data
plane, and this course does not guess one.

## The Azure half, in Bicep

On the bring-your-own strategy the Azure half is a file. The shop's declares the virtual network
with a subnet for the cluster and a delegated `/24` for the association, the resource, one frontend
and one association. Save it as `agc.bicep`:

```bicep
// agc.bicep
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'shop-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.20.0.0/16']
    }
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: '10.20.0.0/22'
        }
      }
      {
        name: 'agc'
        properties: {
          addressPrefix: '10.20.8.0/24'
          delegations: [
            {
              name: 'agc'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource agc 'Microsoft.ServiceNetworking/trafficControllers@2025-01-01' = {
  name: 'shop-agc'
  location: location
}

resource frontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2025-01-01' = {
  parent: agc
  name: 'shop-frontend'
  location: location
}

resource association 'Microsoft.ServiceNetworking/trafficControllers/associations@2025-01-01' = {
  parent: agc
  name: 'shop-association'
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: '${vnet.id}/subnets/agc'
    }
  }
}

output frontendFqdn string = frontend.properties.fqdn
```

```
ana@laptop:~/azure$ bicep build agc.bicep
ana@laptop:~/azure$ jq -c '.resources[] | [.type, .name]' agc.json
["Microsoft.Network/virtualNetworks","shop-vnet"]
["Microsoft.ServiceNetworking/trafficControllers","shop-agc"]
["Microsoft.ServiceNetworking/trafficControllers/frontends","[format('{0}/{1}', 'shop-agc', 'shop-frontend')]"]
["Microsoft.ServiceNetworking/trafficControllers/associations","[format('{0}/{1}', 'shop-agc', 'shop-association')]"]
ana@laptop:~/azure$ jq -c '.resources[] | select(.type | endswith("associations")) | .dependsOn' agc.json
["[resourceId('Microsoft.ServiceNetworking/trafficControllers', 'shop-agc')]","[resourceId('Microsoft.Network/virtualNetworks', 'shop-vnet')]"]
```

No warnings, four resources, and the association waits for both the network and its parent. The
frontend has no properties at all, and the output reads its `fqdn` back: it is Azure's to choose.
Now four slips in one copy: an FQDN of the shop's choosing on the frontend, `subnet` for `subnets`,
a `/26`, and the delegation's name missing its last letter:

```
ana@laptop:~/azure$ sed -e "/name: 'shop-frontend'/a\\  properties: {\n    fqdn: 'shop.example.com'\n  }" -e "s/'subnets'/'subnet'/" -e 's#10.20.8.0/24#10.20.8.0/26#' -e '26s/trafficControllers/trafficController/' agc.bicep > slips.bicep
ana@laptop:~/azure$ diff agc.bicep slips.bicep
21c21
<           addressPrefix: '10.20.8.0/24'
---
>           addressPrefix: '10.20.8.0/26'
26c26
<                 serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
---
>                 serviceName: 'Microsoft.ServiceNetworking/trafficController'
43a44,46
>   properties: {
>     fqdn: 'shop.example.com'
>   }
52c55
<     associationType: 'subnets'
---
>     associationType: 'subnet'
ana@laptop:~/azure$ bicep build slips.bicep
/home/ana/azure/slips.bicep(45,5) : Warning BCP073: The property "fqdn" is read-only. Expressions cannot be assigned to read-only properties. If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP073]
```

**One warning for four mistakes.** The compiler knows `fqdn` is read-only, so it refuses a name
written there; that is the frontend's design showing through the type. The other three pass. The
association type and the delegation's service name are text to the compiler, and a prefix is a
string, so nothing here knows the documentation's `/24`. What Azure would make of each at
deployment the compiler cannot say, and this course has no subscription to find out. Lesson 1's rule
holds the other way round too: no warning is not the same as correct.

Deploying it would be, **not run in this course: it needs a subscription**:

```sh
az deployment group create --resource-group shop --template-file agc.bicep
```

## Choosing between them

For the shop, the three options of this lesson come down to where the proxy runs and what the files
can say:

| | AGIC | application routing, Gateway API | Application Gateway for Containers |
|---|---|---|---|
| reads | Ingress | Gateway API | Gateway API and Ingress |
| proxy | an Application Gateway you own | pods in the cluster, on your nodes | Azure-operated, outside the cluster |
| weighted canary | no | yes | yes |

A team with an Application Gateway and a firewall policy it already trusts has a reason for AGIC. A
cluster that wants the front door on its own nodes and the Gateway API has the add-on, which is
what AKS Automatic now chooses. The shop, a public API with a canary every release, is the case
Application Gateway for Containers was built for, and the files of section 03 are already written
for it.
