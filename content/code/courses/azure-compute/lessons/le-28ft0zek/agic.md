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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"AGIC’s arrangement. A client reaches an Application Gateway in a subnet of its own. The gateway sends each request straight to a pod address, 10.244.1.2 and 10.244.1.4 for shop 1.0 and 10.244.1.3 for shop 1.1, with no NodePort and no kube-proxy. Inside the cluster, AGIC, one pod, watches the API server for Ingress, Service and pod changes, writes the gateway’s configuration to Azure Resource Manager, and Resource Manager applies it to the gateway.\"><rect x=\"12\" y=\"22\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a client</text><rect x=\"196\" y=\"12\" width=\"232\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"312\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Application Gateway</text><text x=\"312\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in a subnet of its own</text><rect x=\"500\" y=\"12\" width=\"208\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"604\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Azure Resource Manager</text><line x1=\"132\" y1=\"42\" x2=\"194\" y2=\"42\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"194,42 187.6,44.7 187.6,39.3\" fill=\"var(--paper-dim)\"></polygon><line x1=\"498\" y1=\"42\" x2=\"430\" y2=\"42\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><polygon points=\"430,42 436.4,39.3 436.4,44.7\" fill=\"var(--amber)\"></polygon><text x=\"464\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">applies it</text><rect x=\"12\" y=\"112\" width=\"696\" height=\"210\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the AKS cluster, in the same virtual network</text><rect x=\"40\" y=\"214\" width=\"118\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"99\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.244.1.2</text><text x=\"99\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop 1.0</text><line x1=\"312\" y1=\"74\" x2=\"99\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><polygon points=\"99,212 102.9,206.2 105.9,210.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"172\" y=\"214\" width=\"118\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"231\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.244.1.4</text><text x=\"231\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop 1.0</text><line x1=\"312\" y1=\"74\" x2=\"231\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><polygon points=\"231,212 231.9,205.1 236.6,207.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"304\" y=\"214\" width=\"118\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"363\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.244.1.3</text><text x=\"363\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop 1.1</text><line x1=\"312\" y1=\"74\" x2=\"363\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><polygon points=\"363,212 358.2,206.9 363.3,205.0\" fill=\"var(--phosphor)\"></polygon><text x=\"221\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">requests, straight to pod addresses</text><text x=\"221\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no NodePort, no kube-proxy</text><rect x=\"500\" y=\"150\" width=\"190\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">AGIC, one pod</text><rect x=\"500\" y=\"250\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><text x=\"595\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ingress, Service, pods</text><line x1=\"595\" y1=\"248\" x2=\"595\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"595,198 597.7,204.4 592.3,204.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"605\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">watches</text><line x1=\"640\" y1=\"148\" x2=\"640\" y2=\"74\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><polygon points=\"640,74 642.7,80.4 637.3,80.4\" fill=\"var(--amber)\"></polygon><text x=\"632\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">writes the configuration</text></svg>", "caption": "Two roads. Requests go down, from the gateway to the pods, without touching AGIC. A change in the cluster goes the long way round, through AGIC and Resource Manager, and the gateway knows about a pod only once that road has been travelled."}
```

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

```
ana@laptop:~/azure$ kubectl get endpointslices -n shop
NAME              ADDRESSTYPE   PORTS   ENDPOINTS               AGE
shop-v1-0-5hmkh   IPv4          8080    10.244.1.2,10.244.1.4   3s
shop-v1-1-jzdhd   IPv4          8080    10.244.1.3              3s
```

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

```
ana@laptop:~/azure$ az aks enable-addons --help | grep -- '- ingress-appgw'
        - ingress-appgw            : enable Application Gateway Ingress Controller addon.
ana@laptop:~/azure$ az aks enable-addons --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --appgw-(id|subnet-cidr) '
 --appgw-id : Resource Id of an existing Application Gateway to use with AGIC. Use with ingress-azure addon. 
 --appgw-subnet-cidr : Subnet CIDR to use for a new subnet created to deploy the Application Gateway. Use with ingress-azure addon. 
```

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
the add-on means removing one AGIC before enabling the other. The documentation says that changes in
the cluster between the two are not reflected on the gateway, which keeps the last configuration it
was given, and advises doing it outside business hours. Several AGICs on one gateway need the Helm
installation, and a cluster upgrade that changes the network plugin is, in the documentation's
words, one to schedule in a maintenance window, the windows of lesson 11.

## Where AGIC stands

AGIC reads only the Ingress API, with the limits of section 01. Every page of its documentation now
opens with the same tip: consider Application Gateway for Containers instead, which section 04 is
about. AGIC is supported and still the way to put an existing Application Gateway, with its firewall
policy, in front of a cluster. For a new cluster, it is the option Microsoft itself points away from.
