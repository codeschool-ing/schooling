---
title: Istio on Kubernetes
version: 1
---

Istio puts an Envoy beside every pod and configures all of them from one control plane, `istiod`. The
lab installs its minimal profile into the kind cluster, with images from Docker Hub:

```
ana@obs:~/shop$ istioctl install --set profile=minimal --set hub=docker.io/istio -y 2>&1 | grep '✔'
✔ Istio core installed ⛵️
✔ Istiod installed 🧠
✔ Installation complete
```

A namespace labelled `istio-injection=enabled` tells Istio to add the proxy to every pod created in it.
Two small workloads go there: a server, and a client that requests it twice a second:

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
client-6fd79bfb55-69sgd   2/2     Running   0          4s
server-dd589bb9d-lrh7v    2/2     Running   0          4s
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
connection_security_policy="mutual_tls"} 41
```

Forty-one requests from `client` to `server`, all 200, counted by the server's proxy (`reporter="destination"`). The labels are what the mesh adds: which workload called which, under what identity, and how the connection was secured. Neither application was changed to produce any of it.
