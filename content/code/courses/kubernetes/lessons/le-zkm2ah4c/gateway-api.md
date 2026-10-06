---
title: The Gateway API splits the entrance from the routes
version: 1
---

**Ingress put everything in one object**: the entrance, the hosts, the paths and the services behind
them, all edited by whoever had permission to edit Ingress. In a cluster shared by several teams that
is either too much power for each team or a queue at the platform team's door. The Gateway API breaks
it into objects that match the people:

| object | written by | says |
|---|---|---|
| GatewayClass | whoever installs the controller | which controller implements this kind of entrance |
| Gateway | the people who run the cluster | an entrance: which ports, which protocols, which namespaces may attach routes |
| HTTPRoute | the team that owns the application | for these hosts and paths, send traffic to these Services |

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public
spec:
  gatewayClassName: traefik
  listeners:
  - name: web
    protocol: HTTP
    port: 8000
    allowedRoutes:
      namespaces:
        from: Same
```

The Gateway `public` listens for HTTP on the controller's port and accepts routes from its own
namespace only, which is a decision the cluster's operators make once. The route is the application
team's file:

```schooling-example
{"language": "yaml", "file": "route.yaml", "parts": [{"code": "apiVersion: gateway.networking.k8s.io/v1\nkind: HTTPRoute\nmetadata:\n  name: shop\nspec:\n  parentRefs:\n  - name: public\n", "note": "**An HTTPRoute, attached to a Gateway by name.** `parentRefs` is how the application team says which entrance its routes belong to, without editing that entrance."}, {"code": "  hostnames:\n  - shop.example.test\n", "note": "**Which host this route answers for.** A request for any other host does not reach these rules."}, {"code": "  rules:\n  - matches:\n    - path:\n        type: PathPrefix\n        value: /admin\n      headers:\n      - name: X-Staff\n        value: \"yes\"\n    backendRefs:\n    - name: admin\n      port: 80\n", "note": "**The first rule needs both matches**: a path under `/admin` and the header `X-Staff: yes`. Ingress has no field for a header; the Gateway API does."}, {"code": "  - backendRefs:\n    - name: shop\n      port: 80\n", "note": "**Everything else on this host goes to the shop.** A rule with no `matches` is the fallback."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f gateway.yaml -f route.yaml
gatewayclass.gateway.networking.k8s.io/traefik created
gateway.gateway.networking.k8s.io/public created
httproute.gateway.networking.k8s.io/shop created
ana@laptop:~/shop$ kubectl get gatewayclass,gateway
NAME                                             CONTROLLER                      ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/traefik   traefik.io/gateway-controller   True       5s

NAME                                       CLASS     ADDRESS   PROGRAMMED   AGE
gateway.gateway.networking.k8s.io/public   traefik             True         5s
ana@laptop:~/shop$ kubectl get httproute shop -o jsonpath="{.status.parents[0].conditions[*].type}"; echo
Accepted ResolvedRefs
```

Every object reports back. The GatewayClass is `ACCEPTED` by Traefik, the Gateway is `PROGRAMMED`,
and the route's conditions say `Accepted` (the Gateway took it) and `ResolvedRefs` (both Services
exist). **That status is the difference from the stray Ingress of the last section**: a route nobody
carries out would show no conditions at all, or say why.

```
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/admin
shop 1.0 on shop-774b84ff8c-gw795
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" -H "X-Staff: yes" localhost:8080/admin
admin 1.0 on admin-76fdf69bb5-679z5
```

Without the header, `/admin` reaches the shop through the fallback rule; with `X-Staff: yes`, it
reaches `admin`. Matching on headers, splitting traffic by weight (lesson 36 does it for a canary),
and routing gRPC and TLS are part of the standard, where Ingress needed a different annotation for
every controller.

```
ana@laptop:~/shop$ kubectl api-resources --api-group=gateway.networking.k8s.io
NAME                 SHORTNAMES   APIVERSION                          NAMESPACED   KIND
backendtlspolicies   btlspolicy   gateway.networking.k8s.io/v1        true         BackendTLSPolicy
gatewayclasses       gc           gateway.networking.k8s.io/v1        false        GatewayClass
gateways             gtw          gateway.networking.k8s.io/v1        true         Gateway
grpcroutes                        gateway.networking.k8s.io/v1        true         GRPCRoute
httproutes                        gateway.networking.k8s.io/v1        true         HTTPRoute
referencegrants      refgrant     gateway.networking.k8s.io/v1beta1   true         ReferenceGrant
```

The API is a set of CRDs, installed beside the controller, which is why this cluster had to be given
them: lesson 43 shows what that means. Its core types are `v1`, as stable as the rest of Kubernetes.
