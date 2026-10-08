---
title: A scheduler is a configuration
version: 1
---

Lesson 29 steered pods with selectors and affinity, all of it written on the pod. The scheduler that
read those rules has rules of its own, and **they are a file**. Every decision it makes is a cycle of
plugins, and its configuration says which plugins run and how much each one counts:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The scheduling cycle of one pod, left to right. A queue of pods with no node. Filter plugins remove the nodes the pod cannot run on, for example NodeResourcesFit when there is not enough CPU. Score plugins give each remaining node a number, and the profile's settings decide how much each plugin counts. The highest score wins and the binding is written to the API server. An extender, if configured, is called over HTTP after the plugins of the filter and score steps.\"><defs><marker id=\"cyc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"60\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"81.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">queue</text><text x=\"81.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pods with no node</text><rect x=\"190\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Filter</text><text x=\"265.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nodes it cannot run on are out</text><rect x=\"380\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Score</text><text x=\"455.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">each node gets a number</text><rect x=\"570\" y=\"60\" width=\"134\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"637.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Bind</text><text x=\"637.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nodeName is written</text><path d=\"M148 88 L188 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cyc-ah-paper-dim)\"></path><path d=\"M342 88 L378 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cyc-ah-paper-dim)\"></path><path d=\"M532 88 L568 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cyc-ah-paper-dim)\"></path><rect x=\"190\" y=\"150\" width=\"340\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">extender: an HTTP call after filter and score</text><path d=\"M265 118 L265 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M455 118 L455 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a profile turns plugins on, off, and sets their weights</text></svg>", "caption": "Every step is a set of plugins. A scheduler profile chooses which of them run and how much each score counts."}
```

The default favours spreading. Among the nodes that pass the filters, `NodeResourcesFit` prefers the
**least** requested, so a new pod tends to go where there is most room. That is good for a service that
wants to survive a node, and wrong for a batch of work that would rather fill two nodes and let an
autoscaler remove the third.

You rarely replace the scheduler for that. You give the same program a second **profile**, under a
name of its own:

```schooling-example
{"language": "yaml", "file": "shop-scheduler.yaml", "parts": [{"code": "apiVersion: kubescheduler.config.k8s.io/v1\nkind: KubeSchedulerConfiguration\nclientConnection:\n  kubeconfig: /home/ana/.kube/config\nleaderElection:\n  leaderElect: false\n", "note": "**How it reaches the API server**, and no leader election: there is one copy of it, on the laptop."}, {"code": "profiles:\n- schedulerName: shop-scheduler\n", "note": "**The profile's name is the scheduler's name.** A pod that sets `schedulerName: shop-scheduler` is this profile's; every other pod is ignored."}, {"code": "  plugins:\n    score:\n      disabled:\n      - name: NodeResourcesBalancedAllocation\n      - name: PodTopologySpread\n", "note": "**Two score plugins switched off.** Both are on by default and both favour spreading the load, which is the opposite of this profile's purpose."}, {"code": "  pluginConfig:\n  - name: NodeResourcesFit\n    args:\n      scoringStrategy:\n        type: MostAllocated\n        resources:\n        - name: cpu\n          weight: 1\n        - name: memory\n          weight: 1\n", "note": "**The packing itself.** `NodeResourcesFit` scores a node by how much of it is requested; `MostAllocated` turns the default round, so the fullest node wins."}]}
```

```
```

`kube-scheduler` is the same binary the control plane runs. Here it runs on your machine beside
`kubectl`, downloaded and checked the way lesson 1 did it, and started in a second terminal, where it
keeps running and writing its log until `Ctrl+C`. Change the `kubeconfig` path in the file to your own
home first, `/home/ubuntu/.kube/config` in the VM:

```sh
ARCH=$(dpkg --print-architecture)
curl -fsSLo kube-scheduler https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kube-scheduler
echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kube-scheduler.sha256)  kube-scheduler" | sha256sum --check
chmod +x kube-scheduler
./kube-scheduler --config shop-scheduler.yaml --secure-port=0
```

`--secure-port=0` turns off its own health and metrics port, which nobody here reads. **A real one runs in
the cluster**, as a Deployment with a ServiceAccount allowed to read pods and nodes and to write
bindings, and with leader election on so a second replica can take over.

The cluster's own scheduler could carry this profile beside `default-scheduler`, since one
configuration may list several. A managed cluster does not let you edit that file, and that is when a
second program is the way. Some second programs are different schedulers altogether, such as Volcano,
built for batch jobs that need all their pods placed at once or none.
