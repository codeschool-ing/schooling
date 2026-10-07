---
title: An Ingress is a request that a controller carries out
version: 1
---

## Where this lesson starts

Three files and five commands, before the first transcript. The controller is Traefik v3.6, from the
manifests its vendor documents, gathered into one file.

`traefik.yaml`:

```yaml
# Traefik as the cluster's ingress controller AND its Gateway API
# implementation, for lessons 16 and 36. The RBAC rules are the two that
# Traefik's own documentation publishes for v3.6 — one for the Ingress
# provider, one for the Gateway provider — joined into one role. Its web
# entry point is published as NodePort 30080, which lesson 8's ports.yaml
# maps to port 8080 of your machine.
apiVersion: v1
kind: Namespace
metadata:
  name: traefik
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik
  namespace: traefik
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik
rules:
- apiGroups: [""]
  resources: [namespaces, nodes]
  verbs: [list, watch]
- apiGroups: [""]
  resources: [services, secrets, configmaps]
  verbs: [get, list, watch]
- apiGroups: [discovery.k8s.io]
  resources: [endpointslices]
  verbs: [get, list, watch]
- apiGroups: [networking.k8s.io]
  resources: [ingresses, ingressclasses]
  verbs: [get, list, watch]
- apiGroups: [networking.k8s.io]
  resources: [ingresses/status]
  verbs: [update]
- apiGroups: [gateway.networking.k8s.io]
  resources: [gatewayclasses, gateways, httproutes, grpcroutes, referencegrants, backendtlspolicies]
  verbs: [get, list, watch]
- apiGroups: [gateway.networking.k8s.io]
  resources: [gatewayclasses/status, gateways/status, httproutes/status, grpcroutes/status, referencegrants/status, backendtlspolicies/status]
  verbs: [update]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik
subjects:
- kind: ServiceAccount
  name: traefik
  namespace: traefik
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik
      containers:
      - name: traefik
        image: traefik:v3.6
        args:
        - --entryPoints.web.address=:8000
        - --providers.kubernetesingress
        - --providers.kubernetesgateway
        - --log.level=INFO
        ports:
        - name: web
          containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik
spec:
  type: NodePort
  selector:
    app: traefik
  ports:
  - name: web
    port: 80
    targetPort: web
    nodePort: 30080
---
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: traefik
spec:
  controller: traefik.io/ingress-controller
```

`apps.yaml`, two small Deployments to route to: the shop, and `admin`, which is the shop image again
with a different greeting:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop}
spec:
  replicas: 2
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec: {containers: [{name: shop, image: "shop:1.0"}]}
---
apiVersion: v1
kind: Service
metadata: {name: shop}
spec: {selector: {app: shop}, ports: [{port: 80, targetPort: 8080}]}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: admin}
spec:
  replicas: 1
  selector: {matchLabels: {app: admin}}
  template:
    metadata: {labels: {app: admin}}
    spec: {containers: [{name: admin, image: "shop:1.0", env: [{name: GREETING, value: "admin"}]}]}
---
apiVersion: v1
kind: Service
metadata: {name: admin}
spec: {selector: {app: admin}, ports: [{port: 80, targetPort: 8080}]}
```

The cluster is lesson 8's, with your machine's port 8080 on the controller's NodePort. The Gateway
API's types come from their project's own release, at v1.4.0, the version this Traefik is built
against; the next section is about them.

```sh
./up.sh ports.yaml
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
kubectl apply -f traefik.yaml
kubectl -n traefik rollout status deployment/traefik
kubectl apply -f apps.yaml
```

## The controller

**The surprising part of Ingress is that Kubernetes ships the object and not the thing that obeys
it.** There is no built-in ingress controller. You install one — Traefik here, from its vendor's
manifests — and it watches Ingress objects and configures itself to route accordingly. This lesson's
controller listens on the laptop's port 8080, through a NodePort:

```
ana@laptop:~/shop$ kubectl get pods -n traefik
NAME                       READY   STATUS    RESTARTS   AGE
traefik-5bf554899f-sfhr5   1/1     Running   0          2s
ana@laptop:~/shop$ kubectl get ingressclass
NAME      CONTROLLER                      PARAMETERS   AGE
traefik   traefik.io/ingress-controller   <none>       2s
ana@laptop:~/shop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8080
404
```

One controller pod, and one **IngressClass** naming it. Asked for anything, it answers `404`: there are
no routes yet.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
spec:
  ingressClassName: traefik
  rules:
  - host: shop.example.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin
            port:
              number: 80
```

One host, `shop.example.test`, a name reserved for testing, and two paths: `/admin` goes to the
`admin` Service and everything else under `/` to the shop. `ingressClassName: traefik` says which
controller should carry it out. curl is told which host it is asking for with a `Host` header, since
no DNS points that name at the laptop:

```
ana@laptop:~/shop$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/shop created
ana@laptop:~/shop$ kubectl get ingress shop
NAME   CLASS     HOSTS               ADDRESS   PORTS   AGE
shop   traefik   shop.example.test             80      3s
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/
shop 1.0 on shop-774b84ff8c-gw795
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/admin
admin 1.0 on admin-76fdf69bb5-679z5
ana@laptop:~/shop$ curl -s -o /dev/null -w "%{http_code}\n" -H "Host: other.example.test" localhost:8080/
404
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A request for shop.example.test arrives at the laptop's port 8080, which leads to the NodePort 30080 on a node, which leads to the Traefik pod. Traefik reads the host and the path. A path under /admin goes to the Service admin and its pod; anything else goes to the Service shop and its two pods.\"><defs><marker id=\"ing-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ing-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"100\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">request</text><text x=\"75.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">Host: shop.example.test</text><rect x=\"170\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:8080</text><text x=\"225.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NodePort 30080</text><rect x=\"310\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">traefik</text><text x=\"385.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ingress controller</text><path d=\"M140 125 L168 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-paper-dim)\"></path><path d=\"M280 125 L308 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-paper-dim)\"></path><text x=\"385\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">reads host and path</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">admin</text><text x=\"610.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/admin</text><rect x=\"520\" y=\"170\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"610.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/ · anything else</text><path d=\"M460 112 L518 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-phosphor)\"></path><path d=\"M460 138 L518 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ing-ah-phosphor)\"></path></svg>", "caption": "The Service of type NodePort only gets the request to the controller. The choice of application is the controller's, made from the Ingress."}
```

**The longest matching path wins**: `/admin` went to `admin` although `/` also matches it. A request
for a host no Ingress mentions gets the controller's own `404`, which is what an unconfigured name on a
shared entrance should get.

## An Ingress that nobody carries out

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: stray
spec:
  ingressClassName: nginx
  rules:
  - host: stray.example.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop
            port:
              number: 80
```

```
ana@laptop:~/shop$ kubectl apply -f stray.yaml
ingress.networking.k8s.io/stray created
ana@laptop:~/shop$ kubectl get ingress
NAME    CLASS     HOSTS                ADDRESS   PORTS   AGE
shop    traefik   shop.example.test              80      6s
stray   nginx     stray.example.test             80      3s
ana@laptop:~/shop$ curl -s -o /dev/null -w "%{http_code}\n" -H "Host: stray.example.test" localhost:8080/
404
```

**Accepted, listed, and served by nobody.** There is no controller for the class `nginx` in this
cluster, so the object sits there and the host it names answers `404`. Nothing reports an error,
because from the API server's point of view nothing is wrong: an Ingress is only data. The empty
`ADDRESS` column is the one hint. A controller that adopts an Ingress usually writes the address it
serves it on there; here Traefik does not publish one, so the column is empty for both, and the two
look the same.

The class `nginx` is not a random choice. **ingress-nginx, the controller most clusters ran, was
retired by the Kubernetes project** in 2026, after a long period with too few maintainers for the
code that sits at the edge of every cluster. Clusters that used it move to another controller, and many
use the move to switch to the Gateway API at the same time.
