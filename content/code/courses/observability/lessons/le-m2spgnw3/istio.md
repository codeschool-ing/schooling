---
title: Istio on Kubernetes
version: 2
---

Istio puts an Envoy beside every pod and configures all of them from one control plane, `istiod`. This
section needs a Kubernetes cluster again, and lesson 14 built one with kind: if `kind` and `kubectl`
are not on your machine any more, its section *Readiness and liveness on Kubernetes* installs them.
These lines add the two command-line tools this lesson uses, `istioctl` and `linkerd`, at the
versions it was recorded with, create the cluster, and copy the shop's image into it:

```sh
ARCH=$(dpkg --print-architecture)
curl -L https://github.com/istio/istio/releases/download/1.30.5/istioctl-1.30.5-linux-$ARCH.tar.gz | tar xz
curl -Lo linkerd https://github.com/linkerd/linkerd2/releases/download/edge-26.9.3/linkerd2-cli-edge-26.9.3-linux-$ARCH
sudo install istioctl linkerd /usr/local/bin/
rm istioctl linkerd
kind create cluster --name lab
kind load docker-image shop:1.4.0 --name lab
mkdir -p ~/shop/k8s
```

The machine this was recorded on also copied Istio's two images into the cluster by hand, because
its cluster could not reach Docker Hub on its own; yours pulls them when they are first needed. Then
the minimal profile, with images from Docker Hub:

```
ana@obs:~/shop$ istioctl install --set profile=minimal --set hub=docker.io/istio -y >/dev/null 2>&1 && kubectl -n istio-system get deployments
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
istiod   1/1     1            1           7s
```

In the minimal profile the whole control plane is that one Deployment. A namespace labelled `istio-injection=enabled` tells Istio to add the proxy to every pod created in it.
Two small workloads go there: a server, and a client that requests it twice a second. Save them as
one file:

`~/shop/k8s/mesh.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: server}
spec:
  replicas: 1
  selector: {matchLabels: {app: server}}
  template:
    metadata: {labels: {app: server}}
    spec:
      containers:
        - name: server
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -m, http.server, "8000"]
---
apiVersion: v1
kind: Service
metadata: {name: server}
spec:
  selector: {app: server}
  ports: [{name: http, port: 80, targetPort: 8000}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: client}
spec:
  replicas: 1
  selector: {matchLabels: {app: client}}
  template:
    metadata: {labels: {app: client}}
    spec:
      containers:
        - name: client
          image: shop:1.4.0
          imagePullPolicy: Never
          command: [python, -c, "import time, urllib.request\nwhile True:\n    try: urllib.request.urlopen('http://server/', timeout=2).read()\n    except Exception as e: print(e, flush=True)\n    time.sleep(0.5)"]
```

And apply it in the labelled namespace:

```
ana@obs:~/shop$ kubectl create namespace shop-mesh && kubectl label namespace shop-mesh istio-injection=enabled
namespace/shop-mesh created
namespace/shop-mesh labeled
ana@obs:~/shop$ kubectl -n shop-mesh apply -f k8s/mesh.yaml
deployment.apps/server created
service/server created
deployment.apps/client created
```

```
ana@obs:~/shop$ kubectl -n shop-mesh get pods
NAME                      READY   STATUS    RESTARTS   AGE
client-6fd79bfb55-qwd9p   2/2     Running   0          5s
server-dd589bb9d-54l7k    2/2     Running   0          6s
```

**Each pod is `2/2`**: two containers where the manifest asked for one. Which two:

```
ana@obs:~/shop$ kubectl -n shop-mesh get pod -l app=server -o jsonpath='{.items[0].spec.containers[*].name}{"\n"}{.items[0].spec.initContainers[*].name}{"\n"}'
server
istio-init istio-proxy
```

The application's container is `server`. **`istio-init`** sets the pod's network rules so that every
connection in and out goes through the proxy, and **`istio-proxy`** is the Envoy. It is listed among the
init containers because current Kubernetes runs sidecars that way: started before the application and
kept running beside it.

Then the telemetry, read from the server's proxy, one label per line:

```
ana@obs:~/shop$ kubectl -n shop-mesh exec deploy/server -c istio-proxy -- pilot-agent request GET stats/prometheus 2>/dev/null | grep '^istio_requests_total' | tr ',' '\n' | grep -E 'source_workload=|destination_workload=|source_principal|response_code|connection_security_policy|^istio_requests_total|} '
istio_requests_total{reporter="destination"
source_workload="client"
source_principal="spiffe://cluster.local/ns/shop-mesh/sa/default"
destination_workload="server"
response_code="200"
connection_security_policy="mutual_tls"} 42
```

Forty-two requests from `client` to `server`, all 200, counted by the server's proxy (`reporter="destination"`). The labels are what the mesh adds: which workload called which, under what identity, and how the connection was secured. Neither application was changed to produce any of it.
