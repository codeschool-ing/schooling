---
title: Inside the cluster, a weighted coin
version: 1
---

This lesson starts where lesson 15 did: lesson 8's cluster, three copies of the shop behind a Service,
and the `probe` pod to ask from inside.

`shop.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop}
spec:
  replicas: 3
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec: {containers: [{name: shop, image: "shop:1.0"}]}
---
apiVersion: v1
kind: Service
metadata: {name: shop}
spec: {selector: {app: shop}, ports: [{port: 80, targetPort: 8080}]}
```

```sh
./up.sh ports.yaml
kubectl apply -f shop.yaml
kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 3600
```

Lesson 15 showed that a Service's address belongs to no machine, and that kube-proxy turns it into a
pod's address on every node. **How it picks the pod depends on kube-proxy's mode**, and this cluster
runs the default one, which writes iptables rules:

```
ana@laptop:~/shop$ kubectl -n kube-system get configmap kube-proxy -o jsonpath="{.data.config\.conf}" | grep "^mode"
mode: iptables
ana@laptop:~/shop$ kubectl get service shop -o custom-columns=NAME:.metadata.name,CLUSTER-IP:.spec.clusterIP
NAME   CLUSTER-IP
shop   10.96.189.143
```

The shop has three copies behind the ClusterIP `10.96.189.143`. A kind node is a container, so
`docker exec` reads the rules on one of them:

```
ana@laptop:~/shop$ docker exec shop-worker iptables-save -t nat | grep -E 'KUBE-SVC.*default/shop' | grep -v KUBE-MARK
-A KUBE-SVC-PFINMTQ5Y2TT4XZK -m comment --comment "default/shop -> 10.244.1.3:8080" -m statistic --mode random --probability 0.33333333349 -j KUBE-SEP-3WAOER3DW6LNFEFV
-A KUBE-SVC-PFINMTQ5Y2TT4XZK -m comment --comment "default/shop -> 10.244.1.4:8080" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-YMTAF3BZORA45S74
-A KUBE-SVC-PFINMTQ5Y2TT4XZK -m comment --comment "default/shop -> 10.244.2.4:8080" -j KUBE-SEP-SAG3BBXNDBILXXFV
```

**Three rules, one per pod, and the arithmetic is the whole algorithm.** The first rule sends a
connection to the first pod with probability one third. A connection that did not match tries the
second rule, which takes half of what is left. The last rule takes everything that reached it. One
third, then half of two thirds, then the remaining third: each pod gets an equal share, decided by a
random draw per connection.

Random is not the same as even, and 300 requests from a pod called `probe` show the difference:

```
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- shop; done" | sort | uniq -c
     96 shop 1.0 on shop-774b84ff8c-hd42c
     91 shop 1.0 on shop-774b84ff8c-mt4qn
    113 shop 1.0 on shop-774b84ff8c-x7djd
```

96, 91 and 113, against an exact share of 100 each. Over many connections the shares converge; over a
few they wander. Neither iptables nor kube-proxy knows how busy a pod is, so a slow pod keeps getting
its third, and a long request counts the same as a short one.

**The choice is made per connection, not per request.** Each `wget` here opens a new connection, so
each one draws again. A client that keeps one connection open, as HTTP/2 and gRPC clients do, sends
every request down it to the same pod. That is the usual reason one pod of three is busy while the
others idle.

## Pinning a client to a pod

A Service can stop drawing for each connection and remember where a client went:

```
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"sessionAffinity":"ClientIP"}}'
service/shop patched
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- shop; done" | sort | uniq -c
    300 shop 1.0 on shop-774b84ff8c-mt4qn
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"sessionAffinity":"None"}}'
service/shop patched
```

`sessionAffinity: ClientIP` sent all 300 requests to one pod, because they all came from the same
address. kube-proxy remembers each client for three hours by default
(`sessionAffinityConfig.clientIP.timeoutSeconds`).

**It is rarely the right fix.** Many clients behind one gateway share an address, so they all land on
one pod. The affinity also ends when that pod goes away, so whatever the application kept in memory is
lost anyway. Keeping the session somewhere every copy can read, a database or a cache, removes the
need for affinity altogether. The patch at the end puts the Service back to `None`.

kube-proxy also has an `nftables` mode, which makes the same random choice through the kernel's newer
interface. A smarter choice, such as the pod with fewest connections, comes from replacing kube-proxy
altogether, which some network plugins do, Cilium among them. This course did not run either.
