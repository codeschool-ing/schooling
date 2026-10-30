---
title: The Gateway API
version: 1
---

Ingress was one object doing three jobs: choosing the kind of load balancer, holding its address
and certificate, and listing the routes. **The Gateway API splits those jobs across three kinds of
object, so that the people who own each job can change it without touching the others.** It is the
Kubernetes project's successor to Ingress, and GKE implements it with the same load balancers.

## Three objects, three owners

| object | who owns it | what it says |
|---|---|---|
| `GatewayClass` | Google, on GKE | which kind of load balancer: global external, regional external, internal |
| `Gateway` | whoever runs the platform | one load balancer: its address, its listeners, its certificates |
| `HTTPRoute` | each team | which hosts and paths go to which of its Services |

GKE provides the classes; the ones a shop meets first are `gke-l7-global-external-managed`, the
same external Application Load Balancer that section 03's Ingress built, and `gke-l7-rilb`, a
regional internal one. A team never edits the Gateway to add a route: it writes an `HTTPRoute` in
its own namespace that attaches to the Gateway, and the Gateway decides which namespaces may
attach.

## Turning it on

On GKE the Gateway API's objects have to be installed in the cluster, and the cluster resource has
a setting for it. Save this as `cluster.tf` in the `lb` folder of section 03:

```hcl
# lb/cluster.tf
resource "google_container_cluster" "shop" {
  name                = "shop"
  location            = "southamerica-east1"
  enable_autopilot    = true
  deletion_protection = false

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
}
```

The plan now has the address and the cluster:

```
ana@laptop:~/gcp/lb$ terraform plan -no-color | grep -E '^  #|enable_autopilot|channel|^Plan'
  # google_compute_global_address.shop_web will be created
  # google_container_cluster.shop will be created
      + enable_autopilot                         = true
          + channel = "CHANNEL_STANDARD"
      + release_channel (known after apply)
Plan: 2 to add, 0 to change, 0 to destroy.
```

The provider knows three values, one of them to turn it off, and says so when given a fourth:

```
ana@laptop:~/gcp/lb$ sed -i 's/CHANNEL_STANDARD/STANDARD/' cluster.tf
ana@laptop:~/gcp/lb$ terraform validate -no-color

Error: expected gateway_api_config.0.channel to be one of ["CHANNEL_DISABLED" "CHANNEL_EXPERIMENTAL" "CHANNEL_STANDARD"], got STANDARD

  with google_container_cluster.shop,
  on cluster.tf line 9, in resource "google_container_cluster" "shop":
   9:     channel = "STANDARD"
```

`CHANNEL_STANDARD` installs the stable part of the API; `CHANNEL_EXPERIMENTAL` adds what is still
changing upstream, which is for trying, not for production.

## The shop's Gateway and route

Shown from Google's documentation; not run. The platform's Gateway, on the address reserved in
section 03:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shop
  namespace: infra
spec:
  gatewayClassName: gke-l7-global-external-managed
  addresses:
    - type: NamedAddress
      value: shop-web
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```

And the shop team's route, sending nine requests in ten to the current `orders` and one to the new
version:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: orders
  namespace: shop
spec:
  parentRefs:
    - name: shop
      namespace: infra
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/orders
      backendRefs:
        - name: orders
          port: 80
          weight: 90
        - name: orders-next
          port: 80
          weight: 10
```

**Weights are the feature Ingress never had**: a canary between two Services, written by the team
that owns them, with no change to the Gateway. It is the same idea lesson 9 applies to Cloud Run
revisions, here between two Deployments.

## Ingress or Gateway

Both build the same load balancers, and an Ingress that works can keep working. For anything new,
Google's documentation and the Kubernetes project both point at the Gateway API: it splits
ownership, it has weights and header matching built in, and the `GatewayClass` makes the kind of
load balancer an explicit choice rather than an annotation. The shop's cluster is new, so it
starts with a Gateway.
