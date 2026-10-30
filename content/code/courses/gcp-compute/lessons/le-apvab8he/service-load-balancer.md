---
title: A Service of type LoadBalancer
version: 1
---

Inside the cluster, a Service gives a set of pods one stable address. To reach them from outside,
Kubernetes has always had one answer that every provider implements: **`type: LoadBalancer`. On
GKE that one line makes Google build a real load balancer outside the cluster**, with its own IP
address, its own forwarding rule and its own line on the bill. Nothing in the cluster is that load
balancer; GKE creates it in your project and keeps it in step with the Service.

## The manifest

This is the `web` front end exposed the simplest way. It is shown from Google's documentation and
was not run: there is no cluster in this lab to apply it to.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: shop
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
```

On GKE this produces a **passthrough Network Load Balancer**: it works at layer 4, forwards TCP
connections to the nodes or pods without reading them, and is regional, in the cluster's region.
The external address appears in the Service's status a minute or two after it is applied. On a
local cluster such as kind, which the `kubernetes` course uses where a track includes it, the same
manifest leaves the address as `<pending>` for ever, because nobody is there to build the load
balancer; on GKE, Google is.

## What layer 4 means here

A passthrough load balancer **sees connections, not requests.** It cannot route `/orders` to one
service and `/` to another, cannot terminate TLS with a certificate Google manages, and cannot
apply a security policy to an HTTP path. Every Service of this type gets its own load balancer and
its own address, so a shop with five public services this way has five addresses and five
forwarding rules, each billed.

That makes it the right tool for traffic that is not HTTP, a database proxy, a game server, an
MQTT broker, and for internal services, which take one annotation:

```yaml
metadata:
  annotations:
    networking.gke.io/load-balancer-type: "Internal"
```

With it, the load balancer gets an address inside the VPC instead of on the internet, which is how
a service in the cluster is offered to virtual machines and Cloud Run services that reach the VPC
the way lesson 12 described.

## Keeping the address

The address of a `LoadBalancer` Service belongs to that Service. **Delete and recreate the Service,
and the address is usually a different one**, which breaks every DNS record pointing at it. A
production Service either reserves a static regional address and names it in the manifest, or, for
HTTP, does not use this type at all and lets the next section's Ingress or the Gateway of section
05 hold one global address for many services.
