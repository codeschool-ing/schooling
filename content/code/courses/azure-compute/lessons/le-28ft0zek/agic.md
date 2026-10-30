---
title: AGIC, a controller in the cluster for a gateway outside it
version: 1
---

The name suggests an ingress controller like NGINX: a proxy running in the cluster, with the
requests passing through it. **AGIC carries no requests at all.** The Application Gateway Ingress
Controller is one pod that watches the cluster and rewrites the configuration of an Azure
Application Gateway, the regional layer 7 load balancer of `azure-foundations` lesson 22, through
Azure Resource Manager. The gateway sits in a subnet of its own in the cluster's virtual network,
and it sends each request straight to a pod's IP address. Every property of AGIC, good and bad,
follows from that arrangement: the traffic never touches the cluster's nodes on the way in, and the
cluster's state reaches the gateway only as fast as an ARM write.

@@FIG-agic@@

## Pod addresses as the backend pool

Microsoft's documentation, read on 30 October 2026, describes the loop this way: AGIC monitors a
subset of Kubernetes resources, translates the cluster's state into Application Gateway
configuration and applies it to ARM. An Ingress becomes a listener and a rule; the Service it names
becomes a backend pool; and the members of that pool are not the Service's address but its pods'.
The gateway **talks to the pods by their private addresses directly, with no NodePort and no
kube-proxy** in between, which removes a hop and the second load balancer a NodePort design would
need.

In the lab, those addresses are what the Services' EndpointSlices hold. They are what AGIC would
write into the two backend pools:

@@endpoints@@

Two pods behind `shop-v1-0`, one behind `shop-v1-1`. In kind, `10.244.1.x` is an address only the
cluster can reach. On AKS the gateway has to reach it from its own subnet, which is why the network
plugin matters: Microsoft recommends Azure CNI or Azure CNI Overlay for AGIC, and with Overlay it
asks for AGIC 1.9.1 or later and a gateway subnet no larger than a `/24`, delegated to
`Microsoft.Network/applicationGateways`.

## The gateway is AGIC's, all of it

**By default AGIC assumes full ownership of the Application Gateway it is linked to**, and
overwrites any configuration that no Ingress describes. The documentation's example is a listener
for `prod.contoso.com` created by hand on the gateway: AGIC deletes it within seconds. A team that
already has an Application Gateway serving other sites has two choices, a separate gateway for the
cluster or AGIC's shared mode, which only the Helm installation offers.

Only the `Standard_v2` and `WAF_v2` SKUs work with AGIC. The second is the reason many teams choose
AGIC at all: the gateway's web application firewall then sits in front of the shop with no extra
hop, and its autoscaling uses none of the cluster's capacity.

## Add-on or Helm

AGIC is installed in one of two ways, and Microsoft supports both:

| | AKS add-on | Helm |
|---|---|---|
| installed by | `az aks enable-addons --addons ingress-appgw` | a chart you install and upgrade |
| updates | automatic | by hand |
| per cluster | one AGIC, targeting one gateway | several, or several clusters sharing one gateway |
| shared mode, and `ProhibitedTargets` | no | yes |
| `reconcilePeriodSeconds`, `armAuth.type` | not settable | settable |

The command line's own help names the add-on and its options. This is real text from this course's
version of the CLI, and needs no account:

@@az-appgw@@

`--appgw-subnet-cidr` makes the add-on create a gateway in the node resource group, in a new subnet
of that size; `--appgw-id` points it at one that exists. With a subscription, enabling it on the
cluster of lesson 11 would be the following, **not run in this course: it needs a subscription**:

```sh
az aks enable-addons --resource-group shop --name shop-aks --addons ingress-appgw --appgw-subnet-cidr 10.20.8.0/24
```

## The delay, and the coupling

Every change in the cluster that matters to the gateway, a pod started, a pod stopped, a rolling
update, a scale-in, has to travel the same road: AGIC sees it, computes a new configuration, sends
it to ARM, and the gateway applies it. Microsoft's own tutorial warns that the gateway might take a
minute to get an update. **Until it does, the gateway still sends requests to a pod that has gone**,
and the client sees a `502`. That is what the `connection-draining` annotation in the shop's Ingress
is for: the documentation recommends it to reduce intermittent 502 errors during pod removal,
rolling deployments and scale-in events, and `connection-draining-timeout` sets how long, 30
seconds by default.

The probes are coupled too. AGIC builds the gateway's health probe from the pod's `readinessProbe`
when there is one with `httpGet`, and otherwise probes the Ingress's own path, `/` for the shop, and
expects a status from 200 to 399. The shop answers `/` with a 404, `no such page`, so **without the probe in `shop.yaml` or the
`health-probe-path` annotation, the gateway would mark every pod of the shop unhealthy** and serve
nothing. Two settings of the readiness probe, `initialDelaySeconds` and `successThreshold`, are not
carried across at all.

And the gateway's configuration is a function of the cluster. Moving from the Helm installation to
the add-on means removing one AGIC before enabling the other; the documentation says that changes in
the cluster between the two are not reflected on the gateway, which keeps the last configuration it
was given, and advises doing it outside business hours. Several AGICs on one gateway need the Helm
installation, and a cluster upgrade that changes the network plugin is, in the documentation's
words, one to schedule in a maintenance window, the windows of lesson 11.

## Where AGIC stands

AGIC reads only the Ingress API, with the limits of section 01. Every page of its documentation now
opens with the same tip: consider Application Gateway for Containers instead, which section 04 is
about. AGIC is supported and still the way to put an existing Application Gateway, with its firewall
policy, in front of a cluster. For a new cluster, it is the option Microsoft itself points away from.
