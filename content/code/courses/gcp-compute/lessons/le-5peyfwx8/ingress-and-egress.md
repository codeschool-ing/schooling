---
title: Ingress and egress settings
version: 1
---

A service with a way into the VPC still has two separate questions to answer, and teams mix them
up. **Ingress is who may send requests to the service. Egress is where the service's own outbound
connections are sent.** They are set in different places, they fail differently, and changing one
never changes the other.

## Ingress: three values, set on the service

Ingress belongs to the service as a whole, not to a revision. The provider lists the values it
accepts, and the quickest way to see them is to write one it does not:

```
ana@laptop:~/gcp/run-vpc$ sed -i 's/INGRESS_TRAFFIC_ALL/INTERNAL/' main.tf
ana@laptop:~/gcp/run-vpc$ terraform validate -no-color

Error: expected ingress to be one of ["INGRESS_TRAFFIC_ALL" "INGRESS_TRAFFIC_INTERNAL_ONLY" "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" ""], got INTERNAL

  with google_cloud_run_v2_service.orders,
  on main.tf line 19, in resource "google_cloud_run_v2_service" "orders":
  19:   ingress  = "INTERNAL"
```

The three that mean something:

| value | who reaches the service |
|---|---|
| `INGRESS_TRAFFIC_ALL` | anyone on the internet, through the service's own URL |
| `INGRESS_TRAFFIC_INTERNAL_ONLY` | only traffic from inside your VPC networks and some Google services |
| `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` | internal traffic, plus an external Application Load Balancer you put in front |

**Ingress is a network check and not an identity check.** A service with `INGRESS_TRAFFIC_ALL`
can still refuse every caller without permission to invoke it; that is IAM, the `roles/run.invoker`
role, and `gcp-foundations` covers how it is granted. The two combine: the orders service only
needs to be called by the web front end and the worker, so it should take internal traffic only and
require an invoker identity as well.

Ingress also has a trap worth one sentence. Traffic from another Cloud Run service counts as
internal only if it leaves that service **through the VPC**. A caller with no VPC egress reaches
the orders service from Google's network, which `INGRESS_TRAFFIC_INTERNAL_ONLY` refuses. This
is the most common surprise after locking a service down.

## Egress: two values, set on the revision

Egress belongs to the `vpc_access` block, and the provider accepts two values:

```
ana@laptop:~/gcp/run-vpc$ sed -i 's/PRIVATE_RANGES_ONLY/PRIVATE_ONLY/' main.tf
ana@laptop:~/gcp/run-vpc$ terraform validate -no-color

Error: expected template.0.vpc_access.0.egress to be one of ["ALL_TRAFFIC" "PRIVATE_RANGES_ONLY" ""], got PRIVATE_ONLY

  with google_cloud_run_v2_service.orders,
  on main.tf line 31, in resource "google_cloud_run_v2_service" "orders":
  31:       egress = "PRIVATE_ONLY"
```

- **`PRIVATE_RANGES_ONLY`** sends traffic for private address ranges into the VPC, and everything
  else, including the public internet and Google's public APIs, goes out the way it would without a
  VPC at all.
- **`ALL_TRAFFIC`** sends every outbound connection into the VPC. From there it follows the VPC's
  routes, which means the internet is reachable only if the VPC has a way out, usually Cloud NAT.

The second one exists for one recurring requirement: **a fixed outbound address.** A partner's API
that admits only known IP addresses cannot be called from the shared addresses Cloud Run uses by
default. With `ALL_TRAFFIC` and a Cloud NAT gateway holding a reserved address, every request the
service makes leaves from that address, and the partner can admit it. The price of that is the NAT
gateway's own charges and one more component on the path, so it is chosen for the requirement,
never as a default.

## Putting the shop together

| service | ingress | egress |
|---|---|---|
| `web` | `INGRESS_TRAFFIC_ALL`, public | direct, `PRIVATE_RANGES_ONLY`, to call `orders` |
| `orders` | `INGRESS_TRAFFIC_INTERNAL_ONLY` | direct, `PRIVATE_RANGES_ONLY` |
| a service calling the payment partner | internal only | direct, `ALL_TRAFFIC` through Cloud NAT |

The front end has no private database of its own, and it still gets direct egress: its calls to
`orders` must leave through the VPC to count as internal, which is the trap above. With
`PRIVATE_RANGES_ONLY` that changes nothing else about how `web` reaches the internet.
