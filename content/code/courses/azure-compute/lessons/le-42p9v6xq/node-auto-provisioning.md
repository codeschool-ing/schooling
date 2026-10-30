---
title: Node auto-provisioning, Karpenter run by AKS
version: 1
---

It is natural to read "Automatic manages the nodes" as the cluster autoscaler switched on for
you. That is a different machine. In lesson 11 the pool `apps` fixed the size of its machines,
`Standard_D4s_v5`, before anybody knew what would run there; the cluster autoscaler, an option on
Standard, can only change how many of them there are. **Node auto-provisioning starts from the
other end: it looks at the pods that cannot be scheduled, works out a virtual machine size that
would hold them, and creates that machine.** Microsoft's documentation says it is built on the
open-source Karpenter project and its Azure provider, and that AKS deploys, configures and manages
Karpenter on the cluster for you. On Automatic it is preconfigured; on Standard it is an option
you enable.

## Three objects

The documentation names three:

| object | who writes it | what it says |
|---|---|---|
| `NodePool` | you, or AKS's defaults | which machines may be created, how many in all, and when they may be removed |
| `AKSNodeClass` | you, or AKS's defaults | the Azure half of a node: its image family, OS disk size, `maxPods`, subnet |
| `NodeClaim` | NAP | one per node it created, the record of what it asked Azure for |

The first two are custom resources, Kubernetes objects of types that Kubernetes does not ship and
that a CustomResourceDefinition, a CRD, adds to the API server. With the default setting, NAP
creates a NodePool called `default`, whose requirements allow on-demand machines of the D family,
`amd64`, Linux, and a second pool, `system-surge`, for system add-ons that tolerate the
`CriticalAddonsOnly` taint of lesson 11. **There is no `vmSize` anywhere**, and that is the point.

## What the lab can show

kind runs no Karpenter, and nothing in it will ever create a node. Two halves of the mechanism are
Kubernetes, though, and those run here. One is the event NAP waits for, a pod the scheduler cannot
place. The other is the API server checking a NodePool against its definition, which it does the
same way on any cluster once the CRD is installed.

This lesson's cluster has no pools to imitate, so the workers carry no labels. The two patches
are lesson 11's, for the same reason: they are needed on a machine with cgroup v1, and on cgroup
v2, which is every current distribution and Docker Desktop, they are harmless. Save it over lesson
11's file:

```yaml
# cluster.yaml: one control plane and two workers, with no pools.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
- role: worker
```

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
node/shop-control-plane condition met
node/shop-worker condition met
node/shop-worker2 condition met
```

The shop's image from lesson 7 is copied into the nodes, as in lesson 11, so the pods below have
something to run:

```
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-worker2", loading...
Image: "shop:1.0" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-control-plane", loading...
```

## A pod with nowhere to go

The nightly sales report is the shop's heaviest job. Here it is as a pod that asks for 12 vCPUs
and 48 GiB, with the shop's image standing in for the report's, because it is the image these
nodes have. Save it as `report.yaml`:

```yaml
# report.yaml: a stand-in for the nightly sales report, which needs a big machine.
apiVersion: v1
kind: Pod
metadata:
  name: report
spec:
  restartPolicy: Never
  containers:
  - name: report
    image: shop:1.0
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        cpu: "12"
        memory: 48Gi
      limits:
        cpu: "12"
        memory: 48Gi
```

```
ana@laptop:~/azure$ kubectl apply -f report.yaml
pod/report created
ana@laptop:~/azure$ kubectl get pod report
NAME     READY   STATUS    RESTARTS   AGE
report   0/1     Pending   0          5s
ana@laptop:~/azure$ kubectl get events --field-selector involvedObject.name=report,reason=FailedScheduling -o custom-columns=REASON:.reason,MESSAGE:.message
REASON             MESSAGE
FailedScheduling   0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu, 2 Insufficient memory. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

**That `Pending`, and the event beside it, is everything NAP reacts to.** The scheduler found
no node with 12 free vCPUs and 48 GiB, and said so: the two workers are too small, and the third
node is the control plane, tainted against everybody as in lesson 11. The numbers in the message
are this laptop's, which has 4 cores and 15 GB; on a machine with more, the same pod might fit.
In lesson 11's cluster the answer would have been the same. The cluster autoscaler tries a pending
pod against the size of each pool before it adds a node, and a `Standard_D4s_v5` has 4 vCPUs, so
it would add nothing and the report would wait. On Automatic,
NAP reads the request, keeps the sizes its NodePools allow that would hold the pod with room for
the node's own daemons, and creates one, a D-series with 16 vCPUs for instance. When the report
finishes and the node is empty, consolidation removes it. Here, nothing answers, and the pod
waits for ever:

```
ana@laptop:~/azure$ kubectl delete pod report
pod "report" deleted from default namespace
```

## A NodePool of the shop's own

The shop's pool, as Karpenter's `karpenter.sh/v1` API describes it. Save it as `nodepool.yaml`:

```schooling-example
{"language": "yaml", "file": "nodepool.yaml", "parts": [{"code": "apiVersion: karpenter.sh/v1\nkind: NodePool\nmetadata:\n  name: shop\n", "note": "**A NodePool is a Kubernetes object, not an Azure resource.** You write it with `kubectl`, and nothing in Resource Manager knows it exists."}, {"code": "spec:\n  template:\n    spec:\n      nodeClassRef:\n        group: karpenter.azure.com\n        kind: AKSNodeClass\n        name: default\n", "note": "The Azure half of each node comes from the `AKSNodeClass` called `default`, the one NAP creates with its default pools."}, {"code": "      requirements:\n      - key: kubernetes.io/arch\n        operator: In\n        values: [\"amd64\"]\n      - key: karpenter.azure.com/sku-family\n        operator: In\n        values: [\"D\", \"E\"]\n      - key: karpenter.azure.com/sku-cpu\n        operator: Lt\n        values: [\"33\"]\n      - key: karpenter.sh/capacity-type\n        operator: In\n        values: [\"on-demand\"]\n", "note": "**A range of sizes, not a size.** Any `amd64` machine of the D family, general purpose, or the E family, memory optimised, with fewer than 33 vCPUs, on ordinary capacity. Adding `spot` to the last list would allow the evictable capacity of lesson 5, and NAP tries spot first when both are allowed."}, {"code": "      expireAfter: Never\n", "note": "No node is replaced only for being old. Expiry is the one disruption the budgets below cannot hold back, so turning it off leaves the budgets in charge."}, {"code": "  limits:\n    cpu: \"64\"\n    memory: 256Gi\n", "note": "A ceiling on everything this pool creates, all its nodes together. It is the guard against a deployment with a typo in its replica count buying machines all night."}, {"code": "  disruption:\n    consolidationPolicy: WhenEmptyOrUnderutilized\n    consolidateAfter: 0s\n    budgets:\n    - nodes: \"20%\"\n    - nodes: \"0\"\n      schedule: \"0 12 * * *\"\n      duration: 12h\n", "note": "**When NAP may remove or replace a node**: when it is empty or could be packed onto others, as soon as it notices, as AKS's own default pool is set. At most a fifth of the pool's nodes at a time, and none from 12:00 to 24:00 UTC, which is 09:00 to 21:00 in São Paulo, when the shop is selling."}]}
```

The CRD that defines this type comes from the AKS Karpenter provider's own repository. This is
its release `v1.15.1`; an AKS cluster carries whatever version AKS runs on it, which may be newer.
Fetch it and install it, then ask the API server to check the pool without storing it. The
definition is installed with `kubectl create`, because it is put there once and nothing here
edits it:

```
ana@laptop:~/azure$ curl -sLO https://raw.githubusercontent.com/Azure/karpenter-provider-azure/v1.15.1/pkg/apis/crds/karpenter.sh_nodepools.yaml
ana@laptop:~/azure$ kubectl create -f karpenter.sh_nodepools.yaml
customresourcedefinition.apiextensions.k8s.io/nodepools.karpenter.sh created
ana@laptop:~/azure$ kubectl wait --for=condition=Established crd/nodepools.karpenter.sh --timeout=60s
customresourcedefinition.apiextensions.k8s.io/nodepools.karpenter.sh condition met
ana@laptop:~/azure$ kubectl apply --dry-run=server -f nodepool.yaml
nodepool.karpenter.sh/shop created (server dry run)
```

`--dry-run=server` sends the object through the API server's validation and defaulting and keeps
nothing. The pool was accepted, and nothing will act on it: there is no Karpenter here to read it.

## What the definition refuses

Three slips, each from somewhere a reader of this course has been: lesson 11's pool label used as
a requirement, the name of an older Karpenter API's consolidation policy, and a budget over 100%.

```
ana@laptop:~/azure$ sed -e 's#karpenter.azure.com/sku-family#kubernetes.azure.com/agentpool#' -e 's/WhenEmptyOrUnderutilized/WhenUnderutilized/' -e 's/"20%"/"120%"/' nodepool.yaml > slips.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f slips.yaml
The NodePool "shop" is invalid: 
* spec.disruption.budgets[0].nodes: Invalid value: "120%": spec.disruption.budgets[0].nodes in body should match '^((100|[0-9]{1,2})%|[0-9]+)$'
* spec.disruption.consolidationPolicy: Unsupported value: "WhenUnderutilized": supported values: "WhenEmpty", "WhenEmptyOrUnderutilized", "Balanced"
* <nil>: Invalid value: null: some validation rules were not checked because the object was invalid; correct the existing errors to complete validation
ana@laptop:~/azure$ sed -e 's#karpenter.azure.com/sku-family#kubernetes.azure.com/agentpool#' nodepool.yaml > slips.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f slips.yaml
The NodePool "shop" is invalid: spec.template.spec.requirements[1].key: Invalid value: "kubernetes.azure.com/agentpool": label domain "kubernetes.azure.com" is restricted
```

The first answer named two of the three, and its last line says why it stopped. The CRD's
structural rules, a list of allowed values and a pattern, are checked first; the rules written as
expressions only run on an object that passed them. With the label as the only slip left, the
expression rule answered. **The label domain `kubernetes.azure.com` is AKS's own**, and a NodePool
may require only the handful of keys in it that NAP knows; `agentpool` is not one, because a NAP
node belongs to no agent pool. Unlike Bicep, which lets many strings through, a CRD can carry the
service's own rules, and the API server applies them to every object of that type.

It does not catch everything. A series where a family belongs, `Dpls_v6` instead of `D`, is a valid
string to the definition:

```
ana@laptop:~/azure$ sed -e 's/\["D", "E"\]/["Dpls_v6"]/' nodepool.yaml > series.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f series.yaml
nodepool.karpenter.sh/shop created (server dry run)
```

Accepted. On AKS that pool would never create a node. `Dpls_v6` is the name of a series, which a
different key matches, and no machine has it as its family, so the pods asking for it would stay
`Pending` like the report did. The documentation lists the values each key takes; the CRD checks
only that the key is allowed.

## When nodes go away

A pool that only grew would be a cluster autoscaler with better taste. Karpenter also removes, by
three methods the documentation names:

- consolidation deletes empty nodes, and deletes or replaces nodes whose pods would fit on
  fewer or cheaper ones, with `consolidationPolicy` set to `WhenEmpty` or
  `WhenEmptyOrUnderutilized`;
- drift replaces a node whose NodePool or AKSNodeClass has changed since it was created: a new
  image family, a different subnet, a different OS disk. A setting changed on an AKSNodeClass is
  never applied to running nodes in place;
- expiration replaces a node older than `expireAfter`. It is the forceful one, and it is not
  held back by the pool's budgets.

**Consolidation moves your pods, which is how it saves money.** A node is cordoned and drained the
way lesson 11 drained `shop-worker2`, and the shop's PodDisruptionBudget is respected during that
drain, unless the pool sets a `terminationGracePeriod`, which overrides it. A pod that must not be
moved carries the annotation `karpenter.sh/do-not-disrupt: "true"`, which holds off consolidation
and drift but not expiry.

The budgets limit how many nodes may be disrupted at once. The documentation gives the arithmetic:
the allowed disruptions are the pool's node count times the percentage, rounded up, minus the
nodes already being deleted and the nodes that are not ready. With 10 nodes and the `20%` budget
above, one node already deleting and none unready, that is ceil(10 × 0.2) − 1 − 0 = 1 more node.
When several budgets are active, the most restrictive wins, which is how the `0` budget closes the
shop's selling hours. **A budget's schedule is in UTC and cannot be anything else**, the same trap
as lesson 11's `utcOffset`, without a field to fix it.

## Against lesson 11

The report's pod, answered by each machine:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two rows of four steps, one pending pod answered two ways. Top row, a fixed pool with the cluster autoscaler, as in lesson 11: the report is Pending, asking for 12 CPUs and 48 GiB; the autoscaler tries it on the size of the pool, Standard_D4s_v5; a node of that size has 4 vCPUs and cannot hold it; it adds nothing, and the report waits until you add a pool. Bottom row, node auto-provisioning: the report is Pending; NAP reads its requests and the NodePool range, families D and E; it creates a machine that fits, 16 vCPUs and 64 GiB for example; the report runs, and when the node is empty, consolidation removes it.\"><text x=\"16\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a fixed pool, with the cluster autoscaler: lesson 11</text><rect x=\"16\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"96.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the report is Pending</text><text x=\"96.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cpu 12, memory 48Gi</text><line x1=\"176\" y1=\"71.0\" x2=\"188\" y2=\"71.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M187 67.0 L194 71.0 L187 75.0 Z\" fill=\"var(--wire)\"></path><rect x=\"194\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the autoscaler tries it</text><text x=\"274.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on the size of the pool</text><text x=\"274.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Standard_D4s_v5</text><line x1=\"354\" y1=\"71.0\" x2=\"366\" y2=\"71.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M365 67.0 L372 71.0 L365 75.0 Z\" fill=\"var(--wire)\"></path><rect x=\"372\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"452.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a node of that size</text><text x=\"452.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">has 4 vCPUs and</text><text x=\"452.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cannot hold it</text><line x1=\"532\" y1=\"71.0\" x2=\"544\" y2=\"71.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M543 67.0 L550 71.0 L543 75.0 Z\" fill=\"var(--wire)\"></path><rect x=\"550\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"630.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">it adds nothing, and</text><text x=\"630.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the report waits</text><text x=\"630.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">until you add a pool</text><text x=\"16\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">node auto-provisioning: this lesson</text><rect x=\"16\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"96.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the report is Pending</text><text x=\"96.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cpu 12, memory 48Gi</text><line x1=\"176\" y1=\"193.0\" x2=\"188\" y2=\"193.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M187 189.0 L194 193.0 L187 197.0 Z\" fill=\"var(--wire)\"></path><rect x=\"194\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">NAP reads its requests</text><text x=\"274.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and the NodePool range</text><text x=\"274.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sku-family: D, E</text><line x1=\"354\" y1=\"193.0\" x2=\"366\" y2=\"193.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M365 189.0 L372 193.0 L365 197.0 Z\" fill=\"var(--wire)\"></path><rect x=\"372\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"452.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">it creates a machine</text><text x=\"452.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">that fits: 16 vCPUs,</text><text x=\"452.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">64 GiB, for example</text><line x1=\"532\" y1=\"193.0\" x2=\"544\" y2=\"193.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M543 189.0 L550 193.0 L543 197.0 Z\" fill=\"var(--wire)\"></path><rect x=\"550\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the report runs; when</text><text x=\"630.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the node is empty,</text><text x=\"630.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consolidation removes it</text></svg>", "caption": "One pending pod, two answers. The autoscaler can only add more of the size a pool already has, and adds none that would not help; NAP chooses the size from the pod. The lab ran the first box of each row and nothing after it."}
```

| | fixed pools, with the cluster autoscaler | node auto-provisioning |
|---|---|---|
| the machine's size | one per pool, chosen in advance | a range, chosen for each batch of pending pods |
| what changes when pods are pending | the pool's node count | which machines exist |
| a pod no pool's size can hold | stays `Pending` until you add a pool | gets a machine, if a NodePool allows one |
| removing nodes | nodes left nearly empty | empty nodes, and nodes it can pack better |
| what you write | pools, in Bicep or `az aks nodepool` | NodePools and AKSNodeClasses, with `kubectl` |

The last row is the one that changes your working day. **The size of your machines moves out of
Resource Manager and into Kubernetes objects**, so it is reviewed, applied and broken the way a
Deployment is, rather than the way a scale set is.
