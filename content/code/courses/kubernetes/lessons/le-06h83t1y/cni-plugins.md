---
title: What the plugin wrote, and what other plugins do instead
version: 1
---

The routes that made those hops are on the nodes, written by the plugin. On `shop-worker`:

```
ana@laptop:~/shop$ docker exec shop-worker ip route
default via 172.18.0.1 dev eth0 
10.244.0.0/24 via 172.18.0.2 dev eth0 
10.244.1.0/24 via 172.18.0.4 dev eth0 
10.244.2.2 dev vetha9f24dcd scope host 
172.18.0.0/16 dev eth0 proto kernel scope link src 172.18.0.3 
```

**One route per other node**: `10.244.0.0/24` via the control-plane node, `10.244.1.0/24` via
`shop-worker2`. And one route per local pod, `10.244.2.2` straight into the `veth` interface that is
the node's end of `left`'s cable:

```
ana@laptop:~/shop$ docker exec shop-worker ip route get 10.244.2.2
10.244.2.2 dev vetha9f24dcd src 10.244.2.1 uid 0 
    cache 
```

That is the whole design of kindnet: routes, kept in step as nodes join and leave. It works because
all three nodes sit on one network, `172.18.0.0/16`, where each can reach the others directly. The
plugin's configuration, which the container runtime reads when a pod is created:

```
ana@laptop:~/shop$ docker exec shop-worker cat /etc/cni/net.d/10-kindnet.conflist

{
	"cniVersion": "0.3.1",
	"name": "kindnet",
	"plugins": [
	{
		"type": "ptp",
		"ipMasq": false,
		"ipam": {
			"type": "host-local",
			"dataDir": "/run/cni-ipam-state",
			"routes": [
				
				
				{ "dst": "0.0.0.0/0" }
			],
			"ranges": [
				
				
				[ { "subnet": "10.244.2.0/24" } ]
			]
		}
		,
		"mtu": 1500
		
	},
	{
		"type": "portmap",
		"capabilities": {
			"portMappings": true
		}
	}
	]
}
```

Two plugins are chained. `ptp` makes the pod's cable — a pair of virtual interfaces, one end in the
pod and one on the node — and `host-local` hands out addresses from this node's slice, `10.244.2.0/24`.
`portmap` comes second and implements `hostPort`. This is the CNI contract in action: **the runtime
calls a list of small programs with a configuration, and each does one part of a pod's network.**

## What other plugins do

Routes alone need every node on one network that will carry pod addresses. When the nodes are in
different subnets, or the network underneath refuses unknown addresses, a plugin either wraps pod
packets in node packets — an **overlay**, such as VXLAN — or teaches the real network the pod ranges,
with BGP. Cloud plugins take a third way and give pods addresses from the cloud's own network.

| plugin | how pods reach each other | enforces network policy | common where |
|---|---|---|---|
| kindnet | routes between nodes on one network | yes, where the kernel supports its nftables engine | kind clusters |
| Flannel | VXLAN overlay, or routes | no | small clusters, k3s by default |
| Calico | routes with BGP, or an overlay; eBPF available | yes | on-premises and clouds alike |
| Cilium | eBPF in the kernel, overlay or routes | yes, up to HTTP level | clusters that want observability and policy together |
| a cloud's own (AWS VPC CNI, Azure CNI, GKE's) | pods get addresses from the cloud network | with an add-on or built in | managed clusters |

**The column that decides most choices is the policy one.** A plugin that does not enforce network
policies accepts them and ignores them, and nothing warns you. Lesson 24 shows what that looks like on the machine this course was recorded on, where kindnet's engine could not start, and then installs Calico to make them real. The other differences — overlay or not, eBPF or
iptables — matter for performance and debugging, and they are rarely what makes a team change plugin
on a cluster that is already running, which is a migration nobody undertakes lightly.
