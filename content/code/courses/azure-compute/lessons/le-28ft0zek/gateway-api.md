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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"Four resources and their owners. A GatewayClass, azure-alb-external, cluster-wide, owned by whoever installs the controller, says which controller implements gateways. A Gateway, shop-gateway in the namespace infra, owned by the cluster team, has a listener on port 80 and says which namespaces may attach. An HTTPRoute, shop in the namespace shop, owned by the shop team, sends testers to 1.1 and the rest 90 to 10. Each points at the one above it. Beside them, a ReferenceGrant in the namespace finance, owned by the finance team, lets routes in shop name its Service.\"><text x=\"16\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">who owns it</text><text x=\"300\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the resource</text><text x=\"452\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what it says</text><text x=\"16\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">whoever installs the controller</text><rect x=\"200\" y=\"36\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"300\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">GatewayClass</text><text x=\"300\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">azure-alb-external</text><text x=\"300\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cluster-wide</text><text x=\"452\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">which controller implements gateways</text><text x=\"16\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the cluster team</text><rect x=\"200\" y=\"122\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"300\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">Gateway</text><text x=\"300\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-gateway</text><text x=\"300\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">namespace infra</text><text x=\"452\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a listener on port 80, and which namespaces may attach</text><text x=\"16\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the shop team</text><rect x=\"200\" y=\"208\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"300\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">HTTPRoute</text><text x=\"300\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop</text><text x=\"300\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">namespace shop</text><text x=\"452\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop.example.com: testers to 1.1, the rest 90 to 10</text><line x1=\"300\" y1=\"206\" x2=\"300\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"300,184 302.7,190.4 297.3,190.4\" fill=\"var(--paper-dim)\"></polygon><line x1=\"300\" y1=\"120\" x2=\"300\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"300,98 302.7,104.4 297.3,104.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"310\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">points at the one above</text><text x=\"16\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the finance team</text><rect x=\"200\" y=\"300\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">ReferenceGrant</text><text x=\"300\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-routes</text><text x=\"300\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">namespace finance</text><text x=\"452\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">routes in shop may name its Service</text><line x1=\"300\" y1=\"298\" x2=\"300\" y2=\"270\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><polygon points=\"300,270 302.7,276.4 297.3,276.4\" fill=\"var(--amber)\"></polygon></svg>", "caption": "One file per owner. The arrows are references written in the lower file: a route names its gateway, a gateway names its class. The grant points the other way, because only the owner of what is referred to can allow it."}
```

## The definitions are not part of Kubernetes

A cluster does not know the Gateway API until its custom resource definitions are installed. They
are published by the Kubernetes project as one file per release, in two channels: *standard*, the
stable resources, and *experimental*. AKS installs the standard channel for you with
`--enable-gateway-api`, and its documentation, read on 30 October 2026, says which bundle it puts on
which Kubernetes version: `v1.6.1` for 1.37. The lab's cluster runs 1.37, so it gets the same
bundle, from the release page:

```
ana@laptop:~/azure$ curl -sSLO https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml
ana@laptop:~/azure$ grep -c "^kind: CustomResourceDefinition" standard-install.yaml
10
ana@laptop:~/azure$ kubectl apply --server-side -f standard-install.yaml
customresourcedefinition.apiextensions.k8s.io/backendtlspolicies.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/listenersets.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/tcproutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/tlsroutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/udproutes.gateway.networking.k8s.io serverside-applied
validatingadmissionpolicy.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io serverside-applied
validatingadmissionpolicybinding.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io serverside-applied
ana@laptop:~/azure$ kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations}{"\n"}'
{"api-approved.kubernetes.io":"https://github.com/kubernetes-sigs/gateway-api/pull/4530","gateway.networking.k8s.io/bundle-version":"v1.6.1","gateway.networking.k8s.io/channel":"standard"}
```

The file holds ten definitions and a ValidatingAdmissionPolicy that refuses experimental definitions
on top of standard ones. `--server-side` leaves the record of who set which field to the API server, instead of copying each
of these large definitions into an annotation of its own, as a plain `apply` would. The last command printed the annotations
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

```
ana@laptop:~/azure$ kubectl apply -f gateway.yaml
namespace/infra created
gatewayclass.gateway.networking.k8s.io/azure-alb-external created
gateway.gateway.networking.k8s.io/shop-gateway created
ana@laptop:~/azure$ kubectl get gatewayclass,gateway -A
NAME                                                        CONTROLLER                               ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/azure-alb-external   alb.networking.azure.io/alb-controller   Unknown    0s

NAMESPACE   NAME                                             CLASS                ADDRESS   PROGRAMMED   AGE
infra       gateway.gateway.networking.k8s.io/shop-gateway   azure-alb-external             Unknown      0s
ana@laptop:~/azure$ kubectl get gateway shop-gateway -n infra -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
Accepted=Unknown Pending: Waiting for controller
Programmed=Unknown Pending: Waiting for controller
```

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

```
ana@laptop:~/azure$ kubectl apply -f route.yaml
httproute.gateway.networking.k8s.io/shop created
ana@laptop:~/azure$ kubectl get httproute -n shop
NAME   HOSTNAMES              AGE
shop   ["shop.example.com"]   0s
ana@laptop:~/azure$ kubectl get httproute shop -n shop -o yaml | sed -n '/^spec:/,$p'
spec:
  hostnames:
  - shop.example.com
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: shop-gateway
    namespace: infra
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: shop-v1-1
      port: 80
      weight: 1
    matches:
    - headers:
      - name: x-shop-canary
        type: Exact
        value: "yes"
      path:
        type: PathPrefix
        value: /
    name: testers
  - backendRefs:
    - group: ""
      kind: Service
      name: shop-v1-0
      port: 80
      weight: 90
    - group: ""
      kind: Service
      name: shop-v1-1
      port: 80
      weight: 10
    matches:
    - path:
        type: PathPrefix
        value: /
    name: everyone
```

The output ends with `spec`: **the route has no `status` at all**. A Gateway carries a
default; a route's status is a list with one entry per gateway that has processed it, written by
that gateway's controller, and no controller has written one.

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

```
ana@laptop:~/azure$ kubectl explain httproute.spec.rules.backendRefs.weight | sed -n '/^DESCRIPTION/,/^$/p'
DESCRIPTION:
    Weight specifies the proportion of requests forwarded to the referenced
    backend. This is computed as weight/(sum of all weights in this
    BackendRefs list). For non-zero values, there may be some epsilon from
    the exact proportion defined here depending on the precision an
    implementation supports. Weight is not a percentage and the sum of
    weights does not need to equal 100.
    
    If only one backend is specified and it has a weight greater than 0, 100%
    of the traffic is forwarded to that backend. If weight is set to 0, no
    traffic should be forwarded for this entry. If unspecified, weight
    defaults to 1.
    
    Support for this field varies based on the context where used.
    
```

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

```
ana@laptop:~/azure$ kubectl apply -f grant.yaml
namespace/finance created
referencegrant.gateway.networking.k8s.io/shop-routes created
ana@laptop:~/azure$ kubectl get referencegrant -n finance
NAME          AGE
shop-routes   1s
```

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

```
ana@laptop:~/azure$ kubectl apply --dry-run=server -f bad-route.yaml
The HTTPRoute "shop-bad" is invalid: 
* spec.rules[0].backendRefs[1].weight: Invalid value: 1000001: spec.rules[0].backendRefs[1].weight in body should be less than or equal to 1000000
* spec.rules[0].backendRefs[0]: Invalid value: Must have port for Service reference
* spec.rules[0].matches[0].path: Invalid value: value must be an absolute path and start with '/' when type one of ['Exact', 'PathPrefix']
```

A path that does not start with `/`, a weight above the maximum of 1,000,000, and a Service named
without a port, all three in one answer. Now a mistake of a different kind, a Service name with one
digit wrong:

```
ana@laptop:~/azure$ sed 's/name: shop-v1-0/name: shop-v1-2/' route.yaml > typo.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f typo.yaml
httproute.gateway.networking.k8s.io/shop configured (server dry run)
```

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

```
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-control-plane" "shop-worker"]
```
