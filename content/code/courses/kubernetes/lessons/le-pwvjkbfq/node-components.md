---
title: What runs on every node
version: 1
---

A worker node runs no part of the control plane. **It runs four things, and only one of them is a
Kubernetes program in the usual sense**: the kubelet, which turns the API server's objects into
running containers. The other three are a container runtime, kube-proxy and a network plugin, and
each answers one question the kubelet does not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The control-plane node holds the API server in the middle, etcd beside it, and the scheduler and the controller manager below. Two worker nodes each hold a kubelet, containerd, kube-proxy, a CNI plugin and pods. Every component has an arrow to the API server, and only the API server has an arrow to etcd. kubectl also talks to the API server.\"><defs><marker id=\"ar-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ar-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"380\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">control-plane node</text><rect x=\"150\" y=\"50\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-apiserver</text><rect x=\"40\" y=\"50\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"78.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">etcd</text><rect x=\"40\" y=\"150\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kube-scheduler</text><rect x=\"246\" y=\"150\" width=\"146\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"319.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-controller-manager</text><path d=\"M130 150 L195 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><path d=\"M300 150 L265 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><path d=\"M118 72 L148 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-phosphor)\" marker-start=\"url(#ar-ah-phosphor)\"></path><text x=\"40\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">only the API server</text><text x=\"40\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">reads and writes etcd</text><rect x=\"450\" y=\"50\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kubectl</text><path d=\"M450 72 L312 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><rect x=\"20\" y=\"240\" width=\"330\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker node</text><rect x=\"30\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kubelet</text><rect x=\"110\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"146.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">containerd</text><rect x=\"190\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"270\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"306.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">CNI</text><rect x=\"370\" y=\"240\" width=\"330\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker node</text><rect x=\"380\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kubelet</text><rect x=\"460\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">containerd</text><rect x=\"540\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"620\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">CNI</text><path d=\"M66 238 L66 230 L222 230 L222 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><path d=\"M416 238 L416 230 L234 230 L234 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path></svg>", "caption": "Every arrow ends at the API server. The components never call each other, and nothing but the API server touches etcd."}
```

## The kubelet and the runtime are services, not pods

On a node, `systemd` starts them like any other daemon:

```
ana@laptop:~/shop$ docker exec shop-worker systemctl is-active containerd kubelet
active
active
```

**The kubelet is the one component that cannot run as a pod**, because it is what runs pods. It
watches the API server for pods assigned to its node and asks the container runtime to start
them, over an interface called CRI. The runtime here is containerd, the same one inside Docker from
the `docker` course, and `crictl` is the tool that speaks CRI to it directly:

```
ana@laptop:~/shop$ docker exec shop-worker2 crictl ps -o table
CONTAINER           IMAGE               CREATED                  STATE               NAME                ATTEMPT             POD ID              POD                    NAMESPACE
2de426ff547f5       c9131139e6342       Less than a second ago   Running             shop                0                   a3d9a1b867102       web-768c88b7c7-mlp9j   default
7c8ab5690b8fa       4626fe10df5b9       12 seconds ago           Running             kindnet-cni         0                   1488fdef332c1       kindnet-ftfrd          kube-system
5294a330f3551       d6a28daf3e6b0       13 seconds ago           Running             kube-proxy          0                   d627597dbe894       kube-proxy-5cmg7       kube-system
```

Three containers on `shop-worker2`. The first is Ana's `shop`, in a pod named after her deployment.
The other two are `kindnet-cni` and `kube-proxy`, and they are pods too, in `kube-system`: a
DaemonSet (lesson 12) puts one copy of each on every node. So the network machinery of the node is
started by the kubelet like any other workload, which is why upgrading it is a rollout rather than a
login to every machine.

## kube-proxy: making a Service address reach a pod

A Service gets an address from `10.96.0.0/16` that no network interface has. **kube-proxy watches
Services and their pods, and writes rules into the node's kernel** — iptables or nftables, depending on how it is set up —
so that a packet sent to that address is rewritten to reach one of the pods. Nothing is proxied
through kube-proxy itself, whatever its name suggests; it programs the kernel and steps aside.
Lesson 17 reads those rules.

## The network plugin: giving a pod an address

When the runtime creates a pod, something has to give it a network interface, an address and a
route to every other pod in the cluster. That is the job of a **CNI plugin**, a program the runtime
calls with a configuration it finds in one directory:

```
ana@laptop:~/shop$ docker exec shop-worker ls /etc/cni/net.d
10-kindnet.conflist
```

kind installs kindnet, which is simple and does nothing else. Clusters in production more often run
Calico or Cilium, which also enforce network policies, and lesson 18 compares them. The point here
is the shape: **Kubernetes defines what a pod's network must do and leaves how to a plugin**, so the
same cluster runs on a laptop, in a data centre and on every cloud with a different plugin in each.
