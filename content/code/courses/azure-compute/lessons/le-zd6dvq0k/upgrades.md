---
title: Upgrades, one minor version and one node at a time
version: 1
---

Two pictures of an AKS upgrade are common, and both are wrong. One is that a managed service keeps
itself current; the other is that an upgrade is one event that happens to the cluster. **On AKS
Standard, nothing upgrades the Kubernetes version until you ask, or a channel you chose asks for
you. And an upgrade is one event per node: a new node added, the old one cordoned and drained, then
rebuilt at the new version.** The drain is where your pods meet it, and it is the part kind can
show you exactly.

## The window of supported versions

Microsoft's documentation, read on 30 October 2026, states the policy as **N-2**: AKS supports the
latest generally available minor version and the two before it. Its calendar gives 1.37 as generally
available since October 2026 and the end of 1.34's life as November, after which the supported
minors are 1.35, 1.36 and 1.37. Each has about a year of this *community support*. After that a
version is *N-3* and gets only platform support: help with Azure's side and none with Kubernetes.
Sixty days after its end of life, AKS upgrades the cluster itself, one minor version at a time, in
what the documentation calls a platform-initiated upgrade.
That upgrade does not wait for your maintenance window, and if a drain fails, it overrides your
PodDisruptionBudgets so that the cluster reaches a supported version.

**Long-term support** adds a second year: about 24 months on one minor version in all, with
security fixes backported. It needs the Premium tier of the first section and the support plan
`AKSLongTermSupport`, chosen explicitly; enrolment is never automatic.

Two rules shape every upgrade. **A cluster outside long-term support cannot skip a minor version**:
1.35 reaches 1.37 by way of 1.36, in two upgrades. And the node pools follow the control plane, never
lead it; since Kubernetes 1.28 they may lag it by up to three minor versions, which is what makes
upgrading the control plane on its own possible.

## Control plane first, then the pools

None of this ran here, because each command needs a subscription. On Azure the sequence is:

```sh
az aks get-upgrades --resource-group shop --name shop-aks --output table
az aks upgrade --resource-group shop --name shop-aks --kubernetes-version 1.37 --control-plane-only
az aks nodepool upgrade --resource-group shop --cluster-name shop-aks --name apps --kubernetes-version 1.37
```

The first lists the versions this cluster may move to. The second moves the control plane alone,
which lets you find out whether the workloads still talk to the new API before any node changes;
without `--control-plane-only`, `az aks upgrade` moves the control plane and then every pool. The
third moves one pool, and the system pool gets the same command with its own name.

**A Kubernetes upgrade and a node image upgrade are different things.** A node image is the
operating system disk AKS builds for its nodes. Microsoft's documentation says a new Linux one is
released every week, with the same Kubernetes version inside it and the latest patches around it.
`az aks nodepool upgrade --node-image-only` replaces the image and leaves the version alone. Any
upgrade of the Kubernetes version brings the latest image with it. Both reach the nodes the same way,
one at a time, below.

And going back is narrow. The documentation says a control plane upgrade cannot be rolled back. A
node pool can be returned to its previous version and image, from API version `2026-04-01`, for
seven days after the upgrade finished, and only one version back.

## One node at a time

The documented sequence for every pool, with the settings `aks.bicep` declared:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"Five rows, one per step of an AKS surge upgrade of a pool of three nodes on 1.36. Row 1: a surge node on 1.37 is added, set by maxSurge. Row 2: node 1 is cordoned and drained as the PodDisruptionBudget allows, within drainTimeoutInMinutes, and its pods move to the surge node. Row 3: node 1 is empty and AKS waits, for nodeSoakDurationInMinutes. Row 4: node 1 is reimaged at 1.37 and becomes the spare for node 2. Row 5: nodes 2 and 3 go the same way, every node is on 1.37, and the surge node is removed.\"><rect x=\"12\" y=\"14\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">1</text><text x=\"48\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">add a surge node</text><text x=\"48\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">maxSurge</text><rect x=\"386\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"421\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"466\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"72\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">2</text><text x=\"48\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cordon and drain node 1, as the budget allows</text><text x=\"48\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">drainTimeoutInMinutes</text><rect x=\"386\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"421\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cordoned</text><rect x=\"466\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"130\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">3</text><text x=\"48\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">wait before going on</text><text x=\"48\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">nodeSoakDurationInMinutes</text><rect x=\"386\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"421\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">empty</text><rect x=\"466\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"188\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">4</text><text x=\"48\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reimage node 1 at the new version</text><text x=\"48\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">it is the spare for node 2</text><rect x=\"386\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"421\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"466\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"246\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">5</text><text x=\"48\" y=\"263\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nodes 2 and 3 the same way, then the surge node goes</text><rect x=\"386\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"421\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"466\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"546\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"626\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"661\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">removed</text></svg>", "caption": "One pool, one node at a time. The settings in mono are the ones aks.bicep declared for the pool apps; step 2 is the part the lab ran, with shop-worker3 standing for the surge node."}
```

`maxSurge` is how many extra nodes AKS adds before it touches the old ones. The default is one; a
percentage is of the pool's node count, rounded up, and Microsoft recommends 33% for production
pools: a pool of 10 nodes surges ceil(3.3) = 4 at a time. Each surge node needs quota and, on Azure
CNI, addresses in the subnet. `maxUnavailable` is the other way, for a subscription with no room to
surge: it drains existing nodes in place, its default is 0, and a system pool cannot use it.
`drainTimeoutInMinutes` is how long one node's drain may take, 30 minutes by default, between 5
minutes and 24 hours. `nodeSoakDurationInMinutes` waits after a drain before the reimage, from 0, the
default, to 30, so that somebody can look at a dashboard before the next node goes.

## The drain, in kind

The shop's three replicas are on `shop-worker2`. A PodDisruptionBudget says how many of them must
stay available while something evicts them on purpose. Save it as `pdb.yaml`:

```yaml
# pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: shop
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: shop
```

```
ana@laptop:~/azure$ kubectl apply -f pdb.yaml
poddisruptionbudget.policy/shop created
ana@laptop:~/azure$ kubectl get pdb shop
NAME   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
shop   2               N/A               1                     1s
```

`ALLOWED DISRUPTIONS` is the budget's arithmetic done for you: three ready pods, two required, so one
may go. Now the steps AKS takes for one node of a surge upgrade. The surge node arrives, which here
means uncordoning `shop-worker3`, and the old node is drained:

```
ana@laptop:~/azure$ kubectl uncordon shop-worker3
node/shop-worker3 uncordoned
ana@laptop:~/azure$ kubectl drain shop-worker2 --ignore-daemonsets
node/shop-worker2 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-x6s98, kube-system/kube-proxy-fdg8r
evicting pod default/shop-7d76d574f5-rgn8q
evicting pod default/shop-7d76d574f5-8wfqp
evicting pod default/shop-7d76d574f5-l2w4c
error when evicting pods/"shop-7d76d574f5-rgn8q" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-l2w4c" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-rgn8q
evicting pod default/shop-7d76d574f5-l2w4c
error when evicting pods/"shop-7d76d574f5-l2w4c" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-l2w4c
pod/shop-7d76d574f5-8wfqp evicted
pod/shop-7d76d574f5-rgn8q evicted
pod/shop-7d76d574f5-l2w4c evicted
node/shop-worker2 drained
ana@laptop:~/azure$ kubectl get pods -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[0].ready
POD                     NODE           READY
shop-7d76d574f5-hxdv2   shop-worker3   true
shop-7d76d574f5-q5zrp   shop-worker3   true
shop-7d76d574f5-tvfsz   shop-worker3   true
ana@laptop:~/azure$ kubectl get nodes
NAME                 STATUS                     ROLES           AGE    VERSION
shop-control-plane   Ready                      control-plane   2m1s   v1.37.0
shop-worker          Ready                      <none>          107s   v1.37.0
shop-worker2         Ready,SchedulingDisabled   <none>          107s   v1.37.0
shop-worker3         Ready                      <none>          107s   v1.37.0
ana@laptop:~/azure$ kubectl uncordon shop-worker2
node/shop-worker2 uncordoned
```

**That is the budget working.** `kubectl drain` cordoned the node and asked for all three pods to
be evicted at once. The API server granted one and refused two, with *Cannot evict pod as it would
violate the pod's disruption budget*, and drain asked again every five seconds. Each refusal lifted
when a replacement on `shop-worker3` became ready, because only then were there three ready pods
again and one to spare. The shop never had fewer than two pods answering. On AKS this is where
`shop-worker2` would be reimaged at the new version and join the pool again, ready to be the spare
for the next node. Here, uncordoning it stands for that.

## A drain that cannot finish

A budget asking for all three of three can never allow a disruption. Here it is, on a node that has
somewhere for its pods to go:

```
ana@laptop:~/azure$ kubectl patch pdb shop --type merge -p '{"spec":{"minAvailable":3}}'
poddisruptionbudget.policy/shop patched
ana@laptop:~/azure$ kubectl get pdb shop
NAME   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
shop   3               N/A               0                     45s
ana@laptop:~/azure$ kubectl drain shop-worker3 --ignore-daemonsets --timeout=10s
node/shop-worker3 cordoned
evicting pod default/shop-7d76d574f5-tvfsz
evicting pod default/shop-7d76d574f5-hxdv2
evicting pod default/shop-7d76d574f5-q5zrp
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-ws2wl, kube-system/kube-proxy-mhfsg
error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-q5zrp
evicting pod default/shop-7d76d574f5-tvfsz
evicting pod default/shop-7d76d574f5-hxdv2
error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-q5zrp
evicting pod default/shop-7d76d574f5-tvfsz
evicting pod default/shop-7d76d574f5-hxdv2
There are pending pods in node "shop-worker3" when an error occurred: [error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default": global timeout reached: 10s]
pod/shop-7d76d574f5-hxdv2
pod/shop-7d76d574f5-q5zrp
pod/shop-7d76d574f5-tvfsz
error: unable to drain node "shop-worker3" due to error: [error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default": global timeout reached: 10s], continuing command...
There are pending nodes to be drained:
 shop-worker3
error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default": global timeout reached: 10s
error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default": global timeout reached: 10s
error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default": global timeout reached: 10s
ana@laptop:~/azure$ kubectl get nodes
NAME                 STATUS                     ROLES           AGE     VERSION
shop-control-plane   Ready                      control-plane   2m12s   v1.37.0
shop-worker          Ready                      <none>          118s    v1.37.0
shop-worker2         Ready                      <none>          118s    v1.37.0
shop-worker3         Ready,SchedulingDisabled   <none>          118s    v1.37.0
```

There was room on `shop-worker2`, and it made no difference: **the budget refuses before the
scheduler is ever asked.** kind's drain gave up when its own timeout ran out and left the node
cordoned. AKS gives up when `drainTimeoutInMinutes` runs out, and what happens next is the pool's
`undrainableNodeBehavior`. Microsoft's troubleshooting guidance shows an upgrade that stopped on
such a drain: the error is `UpgradeFailed`, with the same sentence about the disruption budget in
it, and a later operation on the cluster resumes the upgrade. With `Cordon`, the setting
`aks.bicep` chose, AKS instead leaves the node cordoned, labels it
`kubernetes.azure.com/upgrade-status=Quarantined`, carries on with the rest of the pool, and leaves
that node for you to deal with. The command line knows both values:

```
ana@laptop:~/azure$ az aks nodepool upgrade --help | grep -A2 -- "--undrainable-node-behavior"
    --undrainable-node-behavior          : Define the behavior for undrainable nodes during upgrade.
                                           The value should be "Cordon" or "Schedule". The default
                                           value is "Schedule".
```

The help names `Schedule` as the default, and the documentation says too little about what it does
for this course to say more. `--enable-force-upgrade` on `az aks upgrade` ignores the budgets
altogether. The documentation's advice is to fix the budget first, and the arithmetic of the budget is the fix: three replicas and
`minAvailable: 2`, never three of three.

## The compiler's fence and the service's

Two of the upgrade settings have documented ranges, and the compiler knows only part of them:

```
ana@laptop:~/azure$ sed -e 's/drainTimeoutInMinutes: 30/drainTimeoutInMinutes: 2/' -e 's/nodeSoakDurationInMinutes: 5/nodeSoakDurationInMinutes: 45/' aks.bicep > short.bicep
ana@laptop:~/azure$ bicep build short.bicep
/home/ana/azure/short.bicep(47,38) : Warning BCP327: The provided value (which will always be greater than or equal to 45) is too large to assign to a target for which the maximum allowable value is 30. [https://aka.ms/bicep/core-diagnostics#BCP327]
```

A soak of 45 minutes was refused against the type's maximum of 30. A drain timeout of 2 minutes
compiled without a word, although Microsoft's documentation gives 5 minutes as the least: the type
says 1 to 1,440, and the 5 is the service's rule.

That is all the cluster is needed for in this lesson. Delete it:

```
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-worker" "shop-worker3" "shop-control-plane" "shop-worker2"]
```
