---
title: Every pod has an address that every other pod can reach
version: 1
---

**People coming from Docker expect containers to hide behind their host's address, with ports
published to the outside.** Kubernetes asks for the opposite. Its network model has three rules: every
pod gets an address of its own; every pod can reach every other pod at that address, on any node,
without address translation; and the agents on a node can reach every pod on it. What the plugin does
is make those three rules true.

The first step is a range per node. Each node is given a slice of the cluster's pod range, and every
pod on it takes an address from that slice:

```
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address,POD-CIDR:.spec.podCIDR
NAME                 ADDRESS      POD-CIDR
shop-control-plane   172.18.0.2   10.244.0.0/24
shop-worker          172.18.0.3   10.244.2.0/24
shop-worker2         172.18.0.4   10.244.1.0/24
```

`shop-worker` hands out `10.244.2.x`, `shop-worker2` hands out `10.244.1.x`. Two pods pinned to the two
workers, by naming the node in their spec:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: left
spec:
  nodeName: shop-worker
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: right
spec:
  nodeName: shop-worker2
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
```

```
ana@laptop:~/shop$ kubectl apply -f pods.yaml
pod/left created
pod/right created
ana@laptop:~/shop$ kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
left    1/1     Running   0          1s    10.244.2.2   shop-worker    <none>           <none>
right   1/1     Running   0          1s    10.244.1.2   shop-worker2   <none>           <none>
```

## From inside a pod

```
ana@laptop:~/shop$ kubectl exec left -- ip -4 addr show eth0
2: eth0@if3: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue qlen 1000
    inet 10.244.2.2/24 brd 10.244.2.255 scope global eth0
       valid_lft forever preferred_lft forever
ana@laptop:~/shop$ kubectl exec left -- ip route
default via 10.244.2.1 dev eth0 
10.244.2.0/24 via 10.244.2.1 dev eth0  src 10.244.2.2 
10.244.2.1 dev eth0 scope link  src 10.244.2.2 
```

`left` has one interface, `eth0`, with `10.244.2.2/24`, and every route goes through `10.244.2.1`. That
address is on the node, at the other end of the pod's cable, and it is the pod's only way out.

```
ana@laptop:~/shop$ kubectl exec left -- ping -c 3 10.244.1.2
PING 10.244.1.2 (10.244.1.2): 56 data bytes
64 bytes from 10.244.1.2: seq=0 ttl=62 time=0.375 ms
64 bytes from 10.244.1.2: seq=1 ttl=62 time=0.121 ms
64 bytes from 10.244.1.2: seq=2 ttl=62 time=0.123 ms

--- 10.244.1.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.121/0.206/0.375 ms
```

**Three packets out, three back, well under a millisecond each, and the `ttl` came back at 62**: the
reply was routed twice on its way, once by each node. The path, one hop at a time:

```
ana@laptop:~/shop$ kubectl exec left -- traceroute -n -m 4 10.244.1.2
traceroute to 10.244.1.2 (10.244.1.2), 4 hops max, 46 byte packets
 1  10.244.2.1  0.006 ms  0.002 ms  0.005 ms
 2  172.18.0.4  0.002 ms  0.001 ms  0.001 ms
 3  10.244.1.2  0.002 ms  0.002 ms  0.002 ms
```

Hop 1 is `left`'s own node, `10.244.2.1`. Hop 2 is `172.18.0.4`, the address of `shop-worker2`. Hop 3
is `right` itself. **There is no tunnel and no translation anywhere in that path**: the packet left
with `right`'s real address on it and arrived with the same one, which is the model's second rule
working.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two nodes on the network 172.18.0.0/16. On shop-worker, the pod left at 10.244.2.2 is joined by a veth cable to the node's gateway 10.244.2.1. The node's route table says 10.244.1.0/24 via 172.18.0.4. The packet crosses to shop-worker2 at 172.18.0.4, which has the route 10.244.2.0/24 via 172.18.0.3 back, and delivers it through another veth to the pod right at 10.244.1.2. Three numbered hops.\"><defs><marker id=\"hop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hop-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker</text><text x=\"324\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.3</text><rect x=\"36\" y=\"56\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"101.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">left</text><text x=\"101.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.2.2</text><rect x=\"36\" y=\"150\" width=\"288\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">route</text><text x=\"180.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.1.0/24 via 172.18.0.4</text><text x=\"250\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.244.2.0/24</text><rect x=\"380\" y=\"20\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker2</text><text x=\"684\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.4</text><rect x=\"396\" y=\"56\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"461.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">right</text><text x=\"461.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.1.2</text><rect x=\"396\" y=\"150\" width=\"288\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">route</text><text x=\"540.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.2.0/24 via 172.18.0.3</text><text x=\"610\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.244.1.0/24</text><path d=\"M40 250 L680 250\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the nodes' network 172.18.0.0/16</text><path d=\"M166 100 L166 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hop-ah-phosphor)\"></path><text x=\"176\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hop 1 · 10.244.2.1</text><path d=\"M300 202 L300 236 L460 236 L460 202\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hop-ah-phosphor)\"></path><text x=\"380\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hop 2</text><path d=\"M526 148 L526 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hop-ah-phosphor)\"></path><text x=\"536\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hop 3</text></svg>", "caption": "The packet carries right's real address the whole way. Each node only needs a route to the other node's slice."}
```
