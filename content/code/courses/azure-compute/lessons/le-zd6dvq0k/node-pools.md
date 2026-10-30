---
title: Node pools, system and user, and the scale set behind each
version: 1
---

A laptop cluster has nodes, and it is easy to carry that picture over: a cluster is a set of
interchangeable machines. **On AKS the nodes come in node pools, and the pool is the unit of every
decision about them.** A pool has one virtual machine size, one operating system, one set of labels
and taints, one upgrade setting and one scale set behind it. Microsoft's documentation says node
pools use Virtual Machine Scale Sets by default, the scale sets of lesson 4, with AKS managing them
for you. Its example node name shows the arrangement: `aks-nodepool1-12345678-vmss000001` is
instance `000001` of the scale set behind the pool `nodepool1`. To give the shop bigger machines you
do not resize a node; you add a pool.

## System and user

Every pool has a **mode**. A *system* pool exists to run the cluster's own pods, CoreDNS and the
metrics server among them; a *user* pool runs your applications. A cluster needs at least one
system pool, and the pool created with the cluster is a system pool. Microsoft's documentation,
read on 30 October 2026, puts more restrictions on a system pool than on a user one:

- it runs Linux, Ubuntu or Azure Linux, never Windows;
- it has at least two nodes, and three are recommended;
- its virtual machines have at least 4 vCPUs and 4 GB of memory, and the B series of lesson 1 is
  not allowed;
- it has room for at least 30 pods;
- it cannot run on Spot capacity, which only a user pool can.

AKS labels every node with its pool and its mode, `kubernetes.azure.com/agentpool` and
`kubernetes.azure.com/mode`, and prefers to schedule system pods on nodes labelled `system`. A
preference is all it is. **The label does not keep your pods off a system pool; a taint does**, and
the documentation names it: `CriticalAddonsOnly=true:NoSchedule`. Kubernetes then schedules onto that
pool only the pods that tolerate the taint, and the system pods do.

## The two pools, in kind

The `cluster.yaml` of the previous section gave the first worker the labels of a system pool and the
other two those of a pool called `apps`, in user mode. That is the half kind can reproduce: the
labels are ordinary Kubernetes labels, and the API server does not care who wrote them.

```
ana@laptop:~/azure$ kubectl get nodes -L kubernetes.azure.com/agentpool,kubernetes.azure.com/mode
NAME                 STATUS   ROLES           AGE   VERSION   AGENTPOOL   MODE
shop-control-plane   Ready    control-plane   37s   v1.37.0               
shop-worker          Ready    <none>          23s   v1.37.0   system      system
shop-worker2         Ready    <none>          23s   v1.37.0   apps        user
shop-worker3         Ready    <none>          23s   v1.37.0   apps        user
```

What kind cannot reproduce is the pool itself. The three workers are Docker containers kind
started, not instances of a scale set, and no `apps` object exists anywhere that could be resized
or upgraded as one. On AKS the taint would be declared on the pool when it is created and written
by AKS on every node it adds; here it is put on the one node by hand:

```
ana@laptop:~/azure$ kubectl taint nodes shop-worker CriticalAddonsOnly=true:NoSchedule
node/shop-worker tainted
ana@laptop:~/azure$ kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINTS:.spec.taints[*].key
NODE                 TAINTS
shop-control-plane   node-role.kubernetes.io/control-plane
shop-worker          CriticalAddonsOnly
shop-worker2         <none>
shop-worker3         <none>
```

`shop-control-plane` carries a taint of its own, which is how kind keeps workloads off its control
plane. On AKS there is no such node to taint. CoreDNS, which kind installs, already tolerates the
system pool's taint, the same way the system pods on AKS do:

```
ana@laptop:~/azure$ kubectl get deployment coredns -n kube-system -o jsonpath='{range .spec.template.spec.tolerations[*]}{.key}{" "}{.operator}{"\n"}{end}'
CriticalAddonsOnly Exists
node-role.kubernetes.io/control-plane 
```

## The shop, on the user pool

The shop's image is the one lesson 7 built, `shop:1.0`. A kind node cannot see the images on your
machine, so the first step copies it into every node; on AKS the nodes would pull it from the
registry of lesson 10:

```
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:567bcd65e3e080ec2ccac97a6be0885b176edd7091c5be2e77d359f915b9cb41" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:567bcd65e3e080ec2ccac97a6be0885b176edd7091c5be2e77d359f915b9cb41" not yet present on node "shop-worker3", loading...
Image: "shop:1.0" with ID "sha256:567bcd65e3e080ec2ccac97a6be0885b176edd7091c5be2e77d359f915b9cb41" not yet present on node "shop-control-plane", loading...
Image: "shop:1.0" with ID "sha256:567bcd65e3e080ec2ccac97a6be0885b176edd7091c5be2e77d359f915b9cb41" not yet present on node "shop-worker2", loading...
```

Before the shop arrives, `shop-worker3` is cordoned, which marks it unschedulable and moves nothing.
In the section on upgrades it plays the surge node AKS adds at the start of an upgrade, and until
then nothing should run on it:

```
ana@laptop:~/azure$ kubectl cordon shop-worker3
node/shop-worker3 cordoned
```

The manifest is the `kubernetes` course's Deployment with three lines added. Save it as
`shop.yaml`:

```yaml
# shop.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      nodeSelector:
        kubernetes.azure.com/agentpool: apps
      containers:
      - name: shop
        image: shop:1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          periodSeconds: 2
```

`nodeSelector` sends every replica to a node of the pool `apps`, by the label AKS writes; it is how a
workload asks for a pool on AKS too, and the `kubernetes` course's lesson 29 teaches the selector in
full. `imagePullPolicy: IfNotPresent` uses the copy that was loaded rather than asking a registry.
The readiness probe asks the shop's `/healthz` every two seconds, and it matters more than it looks:
a pod counts as available only once it is ready, and that is what the next section's budget counts.

```
ana@laptop:~/azure$ kubectl apply -f shop.yaml
deployment.apps/shop created
ana@laptop:~/azure$ kubectl rollout status deployment/shop --timeout=120s
Waiting for deployment "shop" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 2 of 3 updated replicas are available...
deployment "shop" successfully rolled out
ana@laptop:~/azure$ kubectl get pods -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[0].ready
POD                     NODE           READY
shop-7d76d574f5-8wfqp   shop-worker2   true
shop-7d76d574f5-l2w4c   shop-worker2   true
shop-7d76d574f5-rgn8q   shop-worker2   true
```

**All three replicas are on `shop-worker2`**: the system node is tainted against them, the control
plane is tainted against everybody, and `shop-worker3` is cordoned.

## The same pools in Bicep

On Azure, the two pools are part of the cluster's declaration. Save this as `aks.bicep`:

```schooling-example
{"language": "bicep", "file": "aks.bicep", "parts": [{"code": "// aks.bicep\nparam location string = 'brazilsouth'\n\nresource aks 'Microsoft.ContainerService/managedClusters@2026-01-01' = {\n  name: 'shop-aks'\n  location: location\n", "note": "**The cluster, as Resource Manager names it**: `Microsoft.ContainerService/managedClusters`, called `shop-aks`, in São Paulo. The first line is a comment naming the file."}, {"code": "  sku: {\n    name: 'Base'\n    tier: 'Standard'\n  }\n", "note": "**The tier of the previous section.** `Standard` buys the uptime SLA on the API server; `Free` and `Premium` are the other two values."}, {"code": "  identity: {\n    type: 'SystemAssigned'\n  }\n", "note": "**The cluster's own identity**, a managed identity of `azure-foundations` lesson 8, which AKS uses to create the scale sets and disks in the node resource group."}, {"code": "  properties: {\n    kubernetesVersion: '1.36'\n    dnsPrefix: 'shop'\n    autoUpgradeProfile: {\n      upgradeChannel: 'stable'\n      nodeOSUpgradeChannel: 'NodeImage'\n    }\n", "note": "**The version, and who moves it.** `1.36` is the minor version the cluster starts on; the two channels are the subject of the last section of this lesson, and decide whether AKS upgrades the cluster and its node images on its own."}, {"code": "    agentPoolProfiles: [\n      {\n        name: 'system'\n        mode: 'System'\n        count: 3\n        vmSize: 'Standard_D4s_v5'\n        osType: 'Linux'\n        osSKU: 'AzureLinux'\n        availabilityZones: [ '1', '2', '3' ]\n        nodeTaints: [ 'CriticalAddonsOnly=true:NoSchedule' ]\n        upgradeSettings: {\n          maxSurge: '1'\n        }\n      }\n", "note": "**The system pool**: three nodes of 4 vCPUs, one in each zone, on Azure Linux, with the taint that keeps the shop out. `maxSurge` is one extra node during an upgrade, the default, written down so a reader does not have to know it."}, {"code": "      {\n        name: 'apps'\n        mode: 'User'\n        count: 3\n        vmSize: 'Standard_D4s_v5'\n        osType: 'Linux'\n        osSKU: 'Ubuntu'\n        maxPods: 110\n        availabilityZones: [ '1', '2', '3' ]\n", "note": "**The user pool `apps`**, where the shop runs: Ubuntu, and `maxPods` fixed at 110 for as long as the pool exists."}, {"code": "        upgradeSettings: {\n          maxSurge: '33%'\n          drainTimeoutInMinutes: 30\n          nodeSoakDurationInMinutes: 5\n          undrainableNodeBehavior: 'Cordon'\n        }\n      }\n    ]\n  }\n}\n", "note": "**How this pool is upgraded**, one setting per line, each explained in the next section: how many extra nodes, how long a drain may take, how long to wait after one, and what to do with a node that cannot be drained."}]}
```

It compiles with no warnings, and the template carries the two pools:

```
ana@laptop:~/azure$ bicep build aks.bicep
ana@laptop:~/azure$ jq -c '.resources[0].properties.agentPoolProfiles[] | [.name, .mode, .count, .osSKU]' aks.json
["system","System",3,"AzureLinux"]
["apps","User",3,"Ubuntu"]
```

**The compiler checks some of a pool's rules and not others.** Here is the same file with three
slips a person makes: a pool name with a hyphen in it, the mode in lower case, and more pods per
node than AKS allows. `sed` writes the slips into a copy, so `aks.bicep` stays as it was:

```
ana@laptop:~/azure$ sed -e "s/name: 'apps'/name: 'shop-apps'/" -e "s/mode: 'System'/mode: 'system'/" -e 's/maxPods: 110/maxPods: 300/' aks.bicep > slip.bicep
ana@laptop:~/azure$ bicep build slip.bicep
/home/ana/azure/slip.bicep(36,15) : Warning BCP416: The supplied string does not match the expected pattern of /$^[a-z][a-z0-9]{0,11}$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
```

One warning, for the name: the type carries the pattern `^[a-z][a-z0-9]{0,11}$`, which is the
documented rule of lowercase letters and digits, twelve at most. The other two passed in silence.
The type of `mode` is any string, with no list of values in it, and the type of `maxPods` is a
number with no ceiling, while the documented maximum is 250, as the end of this section says.
Whether Azure accepts `system` for `System` is the service's to decide, and a laptop cannot find
out. So lesson 1's rule stands, and it has a second half: **a clean compile is the least a
declaration needs, not proof that it is right.**

The command line lists the values it accepts, and the default:

```
ana@laptop:~/azure$ az aks nodepool add --help | grep -A4 -- "--mode "
    --mode                               : The mode for a node pool which defines a node pool's
                                           primary function. If set as "System", AKS prefers system
                                           pods scheduling to node pools with mode `System`. Learn
                                           more at https://aka.ms/aks/nodepool/mode.  Allowed
                                           values: Gateway, System, User.  Default: User.
```

## What a pool fixes when it is created

Some settings belong to the pool for good. The clearest is `maxPods`, the most pods one node will
run, which cannot be changed after the pool exists. Its default depends on the cluster's network
plugin, the piece that gives every pod an address in the network of `azure-foundations` lesson 16:

| network plugin | default `maxPods` |
|---|---|
| Azure CNI Overlay | 250 |
| Azure CNI with a pod subnet | 110 |
| Azure CNI, the legacy mode | 30 |
| kubenet | 110 |

The documented range is 10 to 250, and **raising it means a new pool**: add one with the value you
want, move the workloads, delete the old one. The operating system is chosen
with `osSKU`: `Ubuntu` is the default and `AzureLinux` is Microsoft's own distribution, built for
running containers. Spot capacity, the eviction of lesson 5, is a user pool with its
`scaleSetPriority` set to `Spot`, and a pool of that kind can never be the system pool.
