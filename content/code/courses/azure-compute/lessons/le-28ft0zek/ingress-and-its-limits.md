---
title: The Ingress, and why it grew annotations
version: 1
---

An Ingress looks like part of Kubernetes, so it is easy to believe that one written for the shop
would route the shop's traffic on any cluster. **An Ingress routes nothing. It is a record in the
API server, and a controller somewhere else has to read it and configure a proxy.** The record can
say very little: a host, a path, a Service and a port, a certificate. Everything the shop actually
needs from the front door beyond that, a canary, a header match, a health probe, a timeout, is
written as an annotation that only one controller understands. So an Ingress file belongs to a
controller, not to Kubernetes, and changing the controller means rewriting it. This section shows
both halves in the lab, and lists what AKS offers to read the file.

## What an Ingress can say

The resource is `networking.k8s.io/v1` and its whole vocabulary fits in two sentences. A rule
matches a host, and a path under it matches by `Exact` or `Prefix` (or `ImplementationSpecific`,
which means "whatever the controller decides"). The path names a backend Service and port, a `tls`
entry names the Secret holding a certificate, and `ingressClassName` says which controller should
read it. There is no field for anything else, and there will not be one: the Kubernetes
documentation says the project recommends Gateway instead of Ingress, and that **the Ingress API
has been frozen**. It stays available and supported, and it is no longer developed.

So every controller grew annotations to say what the fields cannot. Three examples, all for the
shop's release of 1.1:

- ingress-nginx does a canary with a *second* Ingress for the same host, marked
  `nginx.ingress.kubernetes.io/canary: "true"`, with `canary-weight` for a share of the traffic or
  `canary-by-header` for testers who send a header;
- AGIC, the next section's controller, has annotations for its health probe, connection
  draining, timeouts and private addresses, and none for a weighted split;
- a third controller has its own prefix and its own spelling of the same ideas.

An annotation is a string. **The API server stores any annotation it is given and checks none of
them**, so a misspelt one is accepted, ignored by the controller, and noticed when the canary
receives no traffic.

## The shop on a cluster, with an Ingress

The cluster is lesson 11's, smaller: a control plane and one worker, with the same two patches,
which are needed on a machine with cgroup v1. On cgroup v2, which is every current distribution and
Docker Desktop, the two patches are harmless. Save it as `cluster.yaml`:

```yaml
# cluster.yaml: one control plane and one worker, for the shop's front door.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
```

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
node/shop-control-plane condition met
node/shop-worker condition met
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:57a79283049df01c404cb32f1eee2892090634f599171ee97f2c5e153ee7ac4f" not yet present on node "shop-control-plane", loading...
Image: "shop:1.0" with ID "sha256:57a79283049df01c404cb32f1eee2892090634f599171ee97f2c5e153ee7ac4f" not yet present on node "shop-worker", loading...
```

The shop runs as two versions at once, which is what a canary needs. Lesson 8 did the same with two
revisions; here it is two Deployments of lesson 7's image, told apart by `SHOP_VERSION`, each with
a Service of its own. A label on the namespace, `gateway-access`, matters in section 03. Save it as
`shop.yaml`:

```yaml
# shop.yaml: the shop at 1.0 (two pods) and at 1.1 (one), a Service for each.
apiVersion: v1
kind: Namespace
metadata:
  name: shop
  labels:
    gateway-access: "true"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v1-0
  namespace: shop
spec:
  replicas: 2
  selector:
    matchLabels: {app: shop, version: "1.0"}
  template:
    metadata:
      labels: {app: shop, version: "1.0"}
    spec:
      containers:
      - name: shop
        image: shop:1.0
        imagePullPolicy: IfNotPresent
        env:
        - {name: SHOP_VERSION, value: "1.0"}
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /healthz, port: 8080}
          periodSeconds: 2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v1-1
  namespace: shop
spec:
  replicas: 1
  selector:
    matchLabels: {app: shop, version: "1.1"}
  template:
    metadata:
      labels: {app: shop, version: "1.1"}
    spec:
      containers:
      - name: shop
        image: shop:1.0
        imagePullPolicy: IfNotPresent
        env:
        - {name: SHOP_VERSION, value: "1.1"}
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /healthz, port: 8080}
          periodSeconds: 2
---
apiVersion: v1
kind: Service
metadata:
  name: shop-v1-0
  namespace: shop
spec:
  selector: {app: shop, version: "1.0"}
  ports:
  - {port: 80, targetPort: 8080}
---
apiVersion: v1
kind: Service
metadata:
  name: shop-v1-1
  namespace: shop
spec:
  selector: {app: shop, version: "1.1"}
  ports:
  - {port: 80, targetPort: 8080}
```

```
ana@laptop:~/azure$ kubectl apply -f shop.yaml
namespace/shop created
deployment.apps/shop-v1-0 created
deployment.apps/shop-v1-1 created
service/shop-v1-0 created
service/shop-v1-1 created
ana@laptop:~/azure$ kubectl rollout status deployment/shop-v1-0 -n shop --timeout=120s
Waiting for deployment "shop-v1-0" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "shop-v1-0" rollout to finish: 1 of 2 updated replicas are available...
deployment "shop-v1-0" successfully rolled out
ana@laptop:~/azure$ kubectl rollout status deployment/shop-v1-1 -n shop --timeout=120s
deployment "shop-v1-1" successfully rolled out
```

The Ingress is written for AGIC, the way Microsoft's AGIC documentation writes one: the class as
the annotation `kubernetes.io/ingress.class`, and two of AGIC's own annotations. Save it as
`ingress.yaml`:

```yaml
# ingress.yaml: shop.example.com to the shop at 1.0, in AGIC's dialect.
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
  namespace: shop
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/health-probe-path: /healthz
    appgw.ingress.kubernetes.io/connection-draining: "true"
spec:
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop-v1-0
            port:
              number: 80
```

```
ana@laptop:~/azure$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/shop created
Warning: annotation "kubernetes.io/ingress.class" is deprecated, please use 'spec.ingressClassName' instead
ana@laptop:~/azure$ kubectl get ingress -n shop
NAME   CLASS    HOSTS              ADDRESS   PORTS   AGE
shop   <none>   shop.example.com             80      0s
ana@laptop:~/azure$ kubectl get ingressclass
No resources found
```

Three things in that answer. The warning is the API server's: the annotation is the old way to name
a class, and `spec.ingressClassName` replaced it, but AGIC's documentation still writes the
annotation, so the warning comes with copying the documentation. `ADDRESS` is empty, because an
address is something a controller writes back. And there is no IngressClass at all: **nothing in this
cluster reads Ingress objects**, so this one is a wish stored in etcd. On AKS it would be the same
until an add-on or a Helm chart put a controller there.

Notice also what the file does not say. The shop at 1.1 has a Service and a pod, and the Ingress
has no way to send it ten per cent of the requests. In AGIC's dialect there is no way at all; in
ingress-nginx's it is a second file.

## What AKS offers to read it

Microsoft's documentation, read on 30 October 2026, offers four ways to read those resources on AKS,
leaving aside the Istio service mesh, which is a subject of its own:

| option | what it reads | where the proxy runs |
|---|---|---|
| application routing add-on, managed NGINX | Ingress | pods in the cluster |
| application routing add-on, Gateway API (`approuting-istio`) | Gateway API | pods in the cluster |
| AGIC, as an add-on or with Helm | Ingress | an Application Gateway, outside the cluster |
| Application Gateway for Containers | Ingress and Gateway API | Azure-operated, outside the cluster |

**The first row is ending.** The Kubernetes project retired Ingress NGINX, and its maintenance ended
in March 2026. Microsoft provides critical security patches for the add-on's NGINX through November
2026, and asks users to move to the add-on's Gateway API implementation or to Application Gateway
for Containers. That is why lesson 12 found AKS Automatic, from AKS 1.36, giving new clusters the
Gateway API through the add-on instead of NGINX. The Gateway API implementation runs an Istio
control plane without the mesh: no sidecars, only the gateways.

The command line in this course's version knows the add-on in both forms, and the switch that
installs the Gateway API's definitions on a cluster:

```
ana@laptop:~/azure$ az aks create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(enable-app-routing|enable-app-routing-istio --enable-ari|enable-gateway-api) '
 --enable-app-routing : Enable Application Routing addon. 
 --enable-app-routing-istio --enable-ari : Enable Gateway API based ingress on App Routing via Istio without service mesh functionality. This enables an ingress-only version of Istio that reconciles Gateway API resources for App Routing. It does not provide service mesh functionality (e.g. mTLS, traffic management between services). Cannot be used simultaneously with the Istio service mesh add-on (--enable-azure-service- mesh). 
 --enable-gateway-api : Enable managed installation of Gateway API CRDs from the standard release channel. 
```

None of those is run here: each needs a cluster in a subscription. What the lab can show is the
part they all have in common, the resources a controller reads. The next section takes the row
whose proxy lives furthest from the cluster.
