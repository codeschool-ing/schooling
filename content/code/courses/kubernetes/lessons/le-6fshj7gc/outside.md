---
title: Outside the cluster, a choice between a hop and an address
version: 1
---

A request from outside arrives at a node, through a NodePort or through the load balancer in front of
one. **The node it reaches may not run any of the Service's pods**, and what happens then is the
Service's `externalTrafficPolicy`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-public
spec:
  type: NodePort
  externalTrafficPolicy: Cluster
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

`Cluster` is the default, written out here because the next step changes it. Before the requests, the
shop was scaled down to one copy, so that two of the three nodes have no pod of their own:

```
ana@laptop:~/shop$ kubectl apply -f shop-public.yaml
service/shop-public created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
shop-774b84ff8c-mt4qn   1/1     Running   0          13s   10.244.2.4   shop-worker   <none>           <none>
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address
NAME                 ADDRESS
shop-control-plane   172.18.0.7
shop-worker          172.18.0.6
shop-worker2         172.18.0.5
```

The laptop calls the NodePort on each node in turn, and then reads the last three lines of the shop's
log, which records where each request came from:

```
ana@laptop:~/shop$ for ip in 172.18.0.7 172.18.0.6 172.18.0.5 ; do echo -n "$ip: "; curl -s -m 2 $ip:30080 || echo no answer; done
172.18.0.7: shop 1.0 on shop-774b84ff8c-mt4qn
172.18.0.6: shop 1.0 on shop-774b84ff8c-mt4qn
172.18.0.5: shop 1.0 on shop-774b84ff8c-mt4qn
ana@laptop:~/shop$ kubectl logs deployment/shop --tail=3
2026-10-06T17:49:43Z GET / from 172.18.0.7:22551
2026-10-06T17:49:43Z GET / from 10.244.2.1:27346
2026-10-06T17:49:43Z GET / from 172.18.0.5:31359
```

**Every node answered, and the one pod served all three.** The two nodes without a pod passed the
request on to `shop-worker`. To get the answer back through themselves, they rewrote the source
address to their own, so the shop saw `172.18.0.7` and `172.18.0.5` instead of the laptop. The node
with the pod rewrote it too, to its gateway on the pod network, `10.244.2.1`. **Under `Cluster`, the
application never learns who called.**

## Local: no hop, and the real address

```
ana@laptop:~/shop$ kubectl patch service shop-public -p '{"spec":{"externalTrafficPolicy":"Local"}}'
service/shop-public patched
ana@laptop:~/shop$ for ip in 172.18.0.7 172.18.0.6 172.18.0.5 ; do echo -n "$ip: "; curl -s -m 2 $ip:30080 || echo no answer; done
172.18.0.7: no answer
172.18.0.6: shop 1.0 on shop-774b84ff8c-mt4qn
172.18.0.5: no answer
ana@laptop:~/shop$ kubectl logs deployment/shop --tail=1
2026-10-06T17:49:49Z GET / from 172.18.0.1:39834
```

With `Local`, a node only hands a request to a pod on the same node. The two nodes without one gave no
answer at all; the node with the pod answered, and the log shows `172.18.0.1`, the laptop's own
address on the network kind created.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two panels. Left, externalTrafficPolicy Cluster: the laptop at 172.18.0.1 sends a request to each of three nodes, control-plane, worker and worker2. Only worker runs the shop's pod. The other two nodes forward their request to it, so all three answer, and the pod sees a node's address instead of the laptop's. Right, externalTrafficPolicy Local: the same three requests. Control-plane and worker2 give no answer; worker answers, and its pod sees 172.18.0.1.\"><defs><marker id=\"etp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"etp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"etp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"330\" height=\"274\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">externalTrafficPolicy: Cluster</text><rect x=\"125\" y=\"48\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"185.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">172.18.0.1</text><rect x=\"30\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"78.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">control-plane</text><path d=\"M185 90 L78 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><rect x=\"137\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><text x=\"185.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pod</text><path d=\"M185 90 L185 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><rect x=\"244\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker2</text><path d=\"M185 90 L292 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><path d=\"M78 228 L78 248 L175 248 L175 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-phosphor)\"></path><path d=\"M292 228 L292 248 L195 248 L195 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-phosphor)\"></path><text x=\"185\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">all answer; the pod sees a node's address</text><rect x=\"370\" y=\"14\" width=\"330\" height=\"274\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">externalTrafficPolicy: Local</text><rect x=\"475\" y=\"48\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"535.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">172.18.0.1</text><rect x=\"380\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">control-plane</text><path d=\"M535 90 L428 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-amber)\"></path><text x=\"428\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">no answer</text><rect x=\"487\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><text x=\"535.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pod</text><path d=\"M535 90 L535 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><rect x=\"594\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"642.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker2</text><path d=\"M535 90 L642 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-amber)\"></path><text x=\"642\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">no answer</text><text x=\"535\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">one answers; the pod sees 172.18.0.1</text></svg>", "caption": "Cluster spends a hop and the caller's address to make every node useful. Local keeps both, and makes a node without a pod useless."}
```

| | `Cluster` | `Local` |
|---|---|---|
| a node without a pod | forwards to another node | refuses |
| the address the pod sees | a node's | the caller's |
| how evenly pods share the load | evenly, across all pods | by node: two pods on one node split that node's share |
| an extra hop | sometimes | never |

**`Local` only works with something in front that knows which nodes to avoid.** A cloud load balancer
does: Kubernetes gives a `Local` Service a health-check port, and each node answers it with success
only while it runs a pod. The load balancer then sends traffic to those nodes and no others. A person
typing a node's address by hand, as above, gets no such help.

The usual reason to choose `Local` is the table's second row: an application
that logs, rate-limits or blocks by client address needs the real one. The other usual answer is a
proxy in front that writes the caller's address into a header, `X-Forwarded-For`, which lesson 16's
ingress controllers do.
