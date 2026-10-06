---
title: From the file to a request that answers
version: 1
---

## Apply, and wait for it

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl rollout status deployment/shop
Waiting for deployment "shop" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 2 of 3 updated replicas are available...
deployment "shop" successfully rolled out
ana@laptop:~/shop$ kubectl get pods -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-7fdcd4cfcd-cscrl   1/1     Running   0          0s    10.244.2.2   shop-worker2   <none>           <none>
shop-7fdcd4cfcd-hdsqh   1/1     Running   0          0s    10.244.1.2   shop-worker    <none>           <none>
shop-7fdcd4cfcd-jsgw9   1/1     Running   0          0s    10.244.1.3   shop-worker    <none>           <none>
ana@laptop:~/shop$ kubectl get service shop
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
shop   ClusterIP   10.96.101.206   <none>        80/TCP    0s
```

`apply` created both objects. `rollout status` waits and reports as the pods become available, one
at a time, and returns when all three are, which makes it the command to put in a script after an
`apply`. **The scheduler spread the three copies over both workers**, two on `shop-worker` and one on
`shop-worker2`, each with an address of its own from `10.244.0.0/16`. The Service got
`10.96.101.206`, from the range lesson 4 found in the API server's flags.

Neither range is reachable from the laptop. They exist inside the cluster's network, and the next
two subsections are the two ordinary ways in.

## A tunnel, for you: `port-forward`

```
ana@laptop:~/shop$ kubectl port-forward service/shop 8081:80 &
Forwarding from 127.0.0.1:8081 -> 8080
ana@laptop:~/shop$ curl -s localhost:8081
shop 1.0 on shop-7fdcd4cfcd-cscrl
ana@laptop:~/shop$ curl -s localhost:8081/healthz
ok
```

`kubectl port-forward` opens port 8081 on the laptop and carries every connection to it, through
the API server and the kubelet, into one of the Service's pods on port 8080. **It is a tool for a
person**, for looking at something that is not published, and it stops when the command stops.
`/healthz`, the endpoint lesson 22's probes will call, answers `ok`.

## A port on the nodes, for everybody: NodePort

To reach the shop the way a browser would, without kubectl in the way, a Service can also open the
same port on every node:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-public
spec:
  type: NodePort
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

```
ana@laptop:~/shop$ kubectl apply -f shop-nodeport.yaml
service/shop-public created
ana@laptop:~/shop$ kubectl get service shop-public
NAME          TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
shop-public   NodePort   10.96.178.61   <none>        80:30080/TCP   0s
ana@laptop:~/shop$ for i in 1 2 3 4 5 6; do curl -s localhost:8080; done
shop 1.0 on shop-7fdcd4cfcd-jsgw9
shop 1.0 on shop-7fdcd4cfcd-jsgw9
shop 1.0 on shop-7fdcd4cfcd-hdsqh
shop 1.0 on shop-7fdcd4cfcd-hdsqh
shop 1.0 on shop-7fdcd4cfcd-cscrl
shop 1.0 on shop-7fdcd4cfcd-cscrl
```

`80:30080/TCP` reads as "port 80 on the Service's address, and port 30080 on every node". The
laptop's port 8080 leads to 30080 on the control-plane node, because the cluster was built with that
mapping, and from there the Service picks a pod for each new connection. **Six requests reached all
three pods**, two each, and none of the pods runs on the node the requests arrived at. A real
cluster puts a load balancer in front of the nodes instead of one laptop port, and lesson 15 does
that too.

## Whose request was that?

The shop writes a line for every request, and `kubectl logs` can read all the pods of a deployment
at once, each line prefixed with the pod it came from:

```
ana@laptop:~/shop$ kubectl logs deployment/shop --all-pods --prefix | grep GET
[pod/shop-7fdcd4cfcd-cscrl/shop] 2026-10-06T16:47:13Z GET / from 127.0.0.1:33746
[pod/shop-7fdcd4cfcd-cscrl/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:13665
[pod/shop-7fdcd4cfcd-cscrl/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:4043
[pod/shop-7fdcd4cfcd-hdsqh/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:56312
[pod/shop-7fdcd4cfcd-hdsqh/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:38412
[pod/shop-7fdcd4cfcd-jsgw9/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:30137
[pod/shop-7fdcd4cfcd-jsgw9/shop] 2026-10-06T16:47:16Z GET / from 172.18.0.2:30813
```

The first line is the port-forward, arriving `from 127.0.0.1`: the tunnel delivers it inside the
pod's own network. The six others arrive from `172.18.0.2`, which is the control-plane node's
address, not the laptop's. **On its way to another node the request had its source rewritten**, so
the reply can find its way back through the same node; lesson 17 shows where that happens and the
setting that keeps the original address.
