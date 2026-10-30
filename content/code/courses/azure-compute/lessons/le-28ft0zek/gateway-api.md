---
title: The Gateway API, three resources for three owners
version: 1
---

It is tempting to read the Gateway API as a bigger Ingress, the same file with the missing fields
added. The fields are there, weights and header matches among them, but that is the smaller change.
**The Gateway API splits the front door into separate resources, one for each person who owns a
part of it.** A *GatewayClass* says which controller implements gateways, and belongs to whoever
installs that controller. A *Gateway* is one entry point, its listeners and ports and which
namespaces may use it, and belongs to the team that runs the cluster. An *HTTPRoute* says which
requests go to which Services, and belongs to the team that ships the application. Each one points
at the one above it, and each owner can be given permission over their own resource only.

@@FIG-roles@@

## The definitions are not part of Kubernetes

A cluster does not know the Gateway API until its custom resource definitions are installed. They
are published by the Kubernetes project as one file per release, in two channels: *standard*, the
stable resources, and *experimental*. AKS installs the standard channel for you with
`--enable-gateway-api`, and its documentation, read on 30 October 2026, says which bundle it puts on
which Kubernetes version: `v1.6.1` for 1.37. The lab's cluster runs 1.37, so it gets the same
bundle, from the release page:

@@crds@@

The file holds ten definitions and a ValidatingAdmissionPolicy that refuses experimental definitions
on top of standard ones. `--server-side` is there because the definitions are large; a client-side
apply would try to store each one again in an annotation. The last command printed the annotations
Microsoft's documentation tells you to check on a managed installation: the bundle version and the
channel. On AKS a further one, `app.kubernetes.io/managed-by: aks`, says who keeps them up to date,
and the bundle moves on by itself when the cluster moves to the next minor version.

## The infrastructure half

The class and the gateway are the cluster team's file. The class names the controller of section
04, `alb.networking.azure.io/alb-controller`, under the class name Microsoft gives it; on AKS the
add-on creates this object and you would not write it. The gateway listens for HTTP on port 80 and
accepts routes only from namespaces labelled `gateway-access: "true"`, which `shop.yaml` gave the
shop. Save it as `gateway.yaml`:

```yaml
# gateway.yaml: the cluster team's half, a class and one gateway.
apiVersion: v1
kind: Namespace
metadata:
  name: infra
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: azure-alb-external
spec:
  controllerName: alb.networking.azure.io/alb-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shop-gateway
  namespace: infra
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            gateway-access: "true"
```

@@gateway@@

**Both objects were accepted, and neither is working.** `Unknown` with the reason `Pending` and the
message `Waiting for controller` is not something a controller wrote: it is the default the
definition itself puts in `status`, so that a gateway nobody has claimed says so instead of saying
nothing. On AKS with the ALB Controller running, the class's condition would turn `True` and the
gateway would be `Programmed`, with an address. Here nothing claims `alb.networking.azure.io/alb-controller`,
and nothing will.

## The application half

The route is the shop team's file, in the shop's namespace. It attaches to the gateway in `infra`,
answers for `shop.example.com`, and has two rules. Testers who send `x-shop-canary: yes` always get
1.1; everybody else is split between the two versions, 90 to 10. Save it as `route.yaml`:

```yaml
# route.yaml: the shop team's half, a canary for 1.1.
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
  namespace: shop
spec:
  parentRefs:
  - name: shop-gateway
    namespace: infra
  hostnames:
  - shop.example.com
  rules:
  - name: testers
    matches:
    - headers:
      - name: x-shop-canary
        value: "yes"
    backendRefs:
    - name: shop-v1-1
      port: 80
  - name: everyone
    backendRefs:
    - name: shop-v1-0
      port: 80
      weight: 90
    - name: shop-v1-1
      port: 80
      weight: 10
```

@@route@@

The API server filled in what the file left out, and the defaults are worth reading. The header
match is `Exact`. A rule with no `matches` matches everything under `/`, so both rules now carry a
`PathPrefix` of `/`. And `shop-v1-1` in the first rule has a weight of 1, which with one backend
means all of it.

So how does a request with the header know which rule it belongs to, when both match? The
specification gives the order: an `Exact` path first, then the longest prefix, then a method match,
then **the largest number of header matches**. Both paths are `/`, neither names a method, and
`testers` has one header against none, so a tester's request goes to 1.1 every time. The order of
the rules in the file only breaks a tie that survives all of that.

A **weight is a proportion, not a percentage**. Each backend gets its weight divided by the sum of
the weights in its list, so `90` and `10` mean the same as `9` and `1`, and the sum does not have to
be 100. Lesson 8's Container Apps insisted on 100; this API does not. The definition's own text says
so, and `kubectl explain` prints it:

@@explain@@

The output above ends with `spec`: **the route has no `status` at all**. A Gateway carries a
default; a route's status is a list with one entry per gateway that has processed it, written by
that gateway's controller, and no controller has written one.

## Crossing a namespace

The route reached a gateway in another namespace because the gateway's `allowedRoutes` said it
could: attaching a route to a gateway is the one reference that the gateway's side controls. Every
other reference across namespaces needs a **ReferenceGrant** in the namespace being referred to,
written by its owners. If the shop's route sent `/export` to the finance export's Service in the
namespace `finance`, the finance team would have to allow it. Save it as `grant.yaml`:

```yaml
# grant.yaml: the finance team lets routes in shop refer to its export Service.
apiVersion: v1
kind: Namespace
metadata:
  name: finance
---
apiVersion: gateway.networking.k8s.io/v1
kind: ReferenceGrant
metadata:
  name: shop-routes
  namespace: finance
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: shop
  to:
  - group: ""
    kind: Service
    name: export
```

@@grant@@

The grant is checked by the controller, every time it builds its configuration, and removing the
grant has to revoke what it allowed. The API server only stores it.

## What the API server refuses, and what it cannot

The definitions carry their own validation, so some mistakes never reach etcd. A route with three of
them, saved as `bad-route.yaml`:

```yaml
# bad-route.yaml: three mistakes the definition catches.
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop-bad
  namespace: shop
spec:
  parentRefs:
  - name: shop-gateway
    namespace: infra
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: orders
    backendRefs:
    - name: shop-v1-0
      weight: 90
    - name: shop-v1-1
      port: 80
      weight: 1000001
```

`--dry-run=server` sends it to the API server for every check, and stores nothing:

@@bad@@

A path that does not start with `/`, a weight above the maximum of 1,000,000, and a Service named
without a port, all three in one answer. Now a mistake of a different kind, a Service name with one
digit wrong:

@@typo@@

**Accepted.** No Service called `shop-v1-2` exists, and the API server does not look; checking that
is the controller's job. A controller would report it on the route, and the specification says what
it must do meanwhile: requests that would have gone to an invalid backend are answered with a `500`,
in proportion to its weight. That typo, on the backend with weight 90, would answer nine requests in
ten with an error.

The lab installs no controller. The implementations that would run here are other vendors' proxies,
and none of them is the one AKS runs; installing one would show a gateway working, but not Azure's.
What the lab has shown is the part that is the same on every implementation: the resources, their
defaults, and their validation. Section 04 gives the class a controller.

The cluster is not needed after this section. Delete it:

@@delete@@
