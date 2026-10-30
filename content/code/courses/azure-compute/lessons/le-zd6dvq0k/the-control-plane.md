---
title: The control plane, and the line AKS draws
version: 1
---

"Managed Kubernetes" sounds like a cluster somebody else runs for you, all of it. **AKS manages one
half: the control plane.** The API server, etcd where the cluster's state is kept, the scheduler,
the controller manager and the cloud controller manager run on machines Microsoft operates, and
Microsoft keeps them patched and answering. The nodes your pods run on are virtual machines in your
subscription, billed as virtual machines. Which Kubernetes version they run, when they move to the
next one and what happens to your pods while they move are your decisions. This lesson is about that
line, and the four sections after this one are the half on your side of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 410\" role=\"img\" aria-label=\"Two boxes. On the left, machines Microsoft operates, holding the control plane: API server, etcd, scheduler, controller manager and cloud controller manager, whose tier, Free, Standard or Premium, decides what is promised. On the right, your subscription: the resource group shop with the cluster resource, and the node resource group with two node pools, each a scale set of virtual machines billed as virtual machines; the system pool is tainted CriticalAddonsOnly and the apps pool runs the shop. Below, the same split in this lab: kind’s node shop-control-plane on the left, and the workers shop-worker, shop-worker2 and shop-worker3 on the right, which are Docker containers with no scale set behind them.\"><rect x=\"12\" y=\"12\" width=\"250\" height=\"300\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">machines Microsoft operates</text><rect x=\"28\" y=\"48\" width=\"218\" height=\"186\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"137\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">the control plane</text><rect x=\"40\" y=\"78\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"40\" y=\"108\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"40\" y=\"138\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">scheduler</text><rect x=\"40\" y=\"168\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">controller manager</text><rect x=\"40\" y=\"198\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cloud controller manager</text><text x=\"137\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the tier decides what is promised</text><text x=\"137\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Free · Standard · Premium</text><rect x=\"282\" y=\"12\" width=\"426\" height=\"300\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"296\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">your subscription</text><rect x=\"298\" y=\"48\" width=\"394\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resource group shop</text><text x=\"680\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the cluster resource</text><rect x=\"298\" y=\"100\" width=\"394\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">node resource group</text><text x=\"680\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">MC_shop_shop-aks_brazilsouth</text><rect x=\"310\" y=\"132\" width=\"178\" height=\"136\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"399\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a node pool: a scale set</text><text x=\"399\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">system</text><rect x=\"320\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"374\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"399\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"428\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"453\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><text x=\"399\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tainted CriticalAddonsOnly</text><text x=\"399\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vmss</text><rect x=\"502\" y=\"132\" width=\"178\" height=\"136\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"591\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a node pool: a scale set</text><text x=\"591\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">apps</text><rect x=\"512\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"537\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"566\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"591\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"620\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><text x=\"591\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the shop’s pods</text><text x=\"591\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vmss</text><text x=\"495\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">billed as virtual machines</text><text x=\"12\" y=\"336\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in this lab, kind</text><rect x=\"28\" y=\"348\" width=\"218\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-control-plane</text><rect x=\"298\" y=\"348\" width=\"126\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"361\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"432\" y=\"348\" width=\"126\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"566\" y=\"348\" width=\"126\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"629\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-worker3</text><text x=\"495\" y=\"394\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Docker containers, no scale set behind them</text></svg>", "caption": "The line AKS draws. The left box is Microsoft’s to run and keep answering, for the tier you chose; the right box is in your subscription and on your bill. In kind, both halves are containers on your laptop, and the left one is yours to break."}
```

## What the tier buys

The control plane has three pricing tiers, and what separates them is a promise rather than a list
of features. Microsoft's documentation, read on 30 October 2026, gives them as follows:

| tier | meant for | nodes | uptime SLA on the API server |
|---|---|---|---|
| Free | development, test and learning; recommended below 10 nodes | up to 1,000 | none financially backed, best effort |
| Standard | production | up to 5,000 | 99.95% with availability zones, 99.9% without |
| Premium | production that has to stay on one Kubernetes version for two years | up to 5,000 | as Standard, plus long-term support |

**On the Free tier the control plane costs nothing and promises nothing.** Every AKS feature is
there; what is missing is a commitment, with money behind it, that the API server answers. Standard
and Premium are charged per cluster and per hour, and this course quotes no Azure price: the pricing
page, or the Retail Prices API of lesson 1, is where to read it.

The SLA covers the API server and nothing else. A Standard cluster whose nodes all sit in one zone
has a control plane that keeps answering while that zone is dark and every pod in it is down, and the
promise was kept. The arithmetic of lesson 6 applies to what it does promise: 99.95% of a month of
730 hours leaves 0.05% × 730 = 0.365 hours, about 22 minutes, in which the API server may be
unreachable without the promise being broken.

The command line describes the tiers in its own help, which is real text from this version of the
CLI and needs no account:

```
ana@laptop:~/azure$ az aks upgrade --help | grep -m1 -A4 -- "--tier "
    --tier                         : Specify SKU tier for managed clusters. '--tier standard'
                                     enables a standard managed cluster service with a financially
                                     backed SLA. '--tier free' does not have a financially backed
                                     SLA. '--tier premium' is required for '--k8s-support-plan
                                     AKSLongTermSupport'.  Allowed values: free, premium, standard.
```

The last sentence is the link to the section on upgrades: long-term support, a second year on one
Kubernetes version, exists only on Premium.

## What stays yours

When AKS creates a cluster, it also creates a second resource group, the **node resource group**,
and puts the cluster's infrastructure in it: the scale sets, their virtual machines, their disks.
Microsoft's example name for one is `MC_aks_myAKSCluster_westus2`, the prefix `MC_` followed by the
cluster's resource group, its name and its region. Those machines are billed as the virtual machines
of lessons 1 to 4. Above them sits everything Kubernetes leaves to whoever runs the workload: how
many replicas the shop has, whether it says when it is ready, and how much of it may be stopped at
once. **An upgrade managed by Microsoft still moves every one of your pods**, and whether the shop
notices is decided by those three things, which are yours.

## The lab: kind, which is not AKS

Lessons 11 to 14 run a Kubernetes cluster on your machine with kind and talk to it with `kubectl`,
both as the `kubernetes` course installed them in its lesson 1. If you kept that machine, nothing
needs installing; if not, that lesson's installation section is the place to go back to. The
transcripts were recorded with this kind:

```
ana@laptop:~/azure$ kind version
kind v0.33.0 go1.24.7 linux/amd64
```

Keep `kubectl` within one minor version of the cluster, which the `kubernetes` course's lesson 5
explains; the cluster below runs 1.37.

**kind is not AKS.** It is the Kubernetes AKS runs, the same API server, scheduler and kubelet, in
Docker containers on your laptop. Microsoft's control plane is not there, nor are node pools and the
scale sets behind them, the orchestration of an upgrade, or maintenance configuration.
What it lets you practise is the half Kubernetes itself does: nodes labelled and tainted the way AKS
labels and taints them, the cordon and drain that AKS performs on every node it upgrades, and a
PodDisruptionBudget answering yes or no. Everything Microsoft adds around those is taught from its
documentation, and the sections say which is which.

The cluster has a control plane and three workers. The labels on the workers are the subject of the
next section; save the file as `cluster.yaml`:

```yaml
# cluster.yaml: one control plane and three workers, labelled the way AKS
# labels the nodes of two node pools.
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
  labels:
    kubernetes.azure.com/agentpool: system
    kubernetes.azure.com/mode: system
- role: worker
  labels:
    kubernetes.azure.com/agentpool: apps
    kubernetes.azure.com/mode: user
- role: worker
  labels:
    kubernetes.azure.com/agentpool: apps
    kubernetes.azure.com/mode: user
```

The two patches near the top are needed on a machine with cgroup v1, which is what these transcripts
were recorded on. On cgroup v2, which is every current distribution and Docker Desktop, the two
patches are harmless, and the `kubernetes` course's lessons carry the same two. Create the cluster
and wait for its nodes:

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
node/shop-control-plane condition met
node/shop-worker condition met
node/shop-worker2 condition met
node/shop-worker3 condition met
```

## The half you would be paying for

On kind, the control plane is a node like the others, and what runs on it can be listed:

```
ana@laptop:~/azure$ kubectl get pods -n kube-system --field-selector spec.nodeName=shop-control-plane -o name
pod/coredns-559f6c778d-kszr5
pod/coredns-559f6c778d-qldhq
pod/etcd-shop-control-plane
pod/kindnet-v5tpf
pod/kube-apiserver-shop-control-plane
pod/kube-controller-manager-shop-control-plane
pod/kube-proxy-skzhw
pod/kube-scheduler-shop-control-plane
```

etcd, the API server, the controller manager and the scheduler are pods on `shop-control-plane`,
beside the two DaemonSets every node runs, and in this run CoreDNS as well, which tolerates the
control plane's taint. **On AKS, none of those four is on a node you can list.**
They run on Microsoft's side of the line, `kubectl get nodes` shows only the virtual machines of your
node pools, and the tier is what you pay for them to keep answering. In this lab the control plane is
yours to break, which is also why nothing here can show you what Microsoft's version does.

The AKS cluster this lesson declares is called `shop-aks`, in a resource group `shop`. Asking Azure
about it gives the answer lesson 1 explained:

```
ana@laptop:~/azure$ az aks show --resource-group shop --name shop-aks
ERROR: Please run 'az login' to setup account.
```

That refusal is what every `az aks` command that needs a subscription answers in this course. Those
commands are shown where they belong, marked as not run, with no output.
