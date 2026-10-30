---
title: Deployment safeguards, and the manifests they refuse
version: 1
---

Two pictures of deployment safeguards are common. One is a linter, something that reads your
YAML in a pipeline and prints advice. The other is Kubernetes being strict: surely a cluster
refuses a pod that says nothing about memory. Neither is right. Kubernetes accepts that pod, as
this section shows, and nothing in your pipeline is involved. **Deployment safeguards are Azure
Policy rules that the API server consults as an admission check, every time an object is created
or updated.** Microsoft's documentation says Azure Policy extends Gatekeeper, the Open Policy
Agent's admission controller for Kubernetes, to do it. The rule runs inside the cluster, at the
moment of `kubectl apply`, whoever is typing.

## Warn and Enforce

Safeguards have two levels:

- `Warn` lets the request through and prints a warning in the terminal of whoever sent it;
- `Enforce` refuses a request that breaks a rule and, for some rules, **mutates** it first:
  changes the object so that it complies, then lets it through.

On Standard they are an option, at either level. **On Automatic they are on, at `Enforce`, and
cannot be moved to `Warn`.** You may exclude namespaces, and that is the only way round them. The
baseline Pod Security Standard is enforced as well, and the documentation says it cannot be turned
off on Automatic: no privileged containers, no host network or host process namespaces, no
`hostPort`. Microsoft's documentation, read on 30 October 2026, lists the safeguards as follows:

| safeguard | what it asks of a workload |
|---|---|
| resource requests | every container has CPU and memory requests; mutated |
| anti-affinity or topology spread | a workload with several replicas says how to spread them over nodes; mutated |
| probes | every container has a readiness and a liveness probe |
| no `latest` | an explicit image tag, other than `latest` or none |
| allowed images | containers use only images an allow list permits |
| unique selectors | no two services select with the same selector |
| CSI storage classes | storage classes use the CSI drivers, not the old in-tree provisioners |
| no AKS labels | no workload carries a label in `kubernetes.azure.com` |
| no edits to single nodes | nodes are labelled and tainted by pool, not one at a time |
| reserved system taints | `CriticalAddonsOnly` stays on system pools |

The last two would have refused part of lesson 11: `kubectl taint nodes shop-worker` is exactly an
edit to one node, refused with *Tainting or labeling individual nodes is not recommended. Please
use Azure CLI to taint/label node pools instead*.

The level is set from the command line on a cluster where you may change it; this lists the values:

```
ana@laptop:~/azure$ az aks safeguards update --help | grep -A1 -- "^    --level"
    --level                             : The deployment safeguards level. Possible values are Warn
                                          and Enforce.  Allowed values: Enforce, Warn.
```

## The shop as it is often first written

A manifest written in a hurry looks like this one: the shop's image by the tag `latest`, nothing
about resources, no probes. Save it as `hurried.yaml`:

```yaml
# hurried.yaml: the shop as it is often first written.
apiVersion: v1
kind: Pod
metadata:
  name: hurried
spec:
  containers:
  - name: shop
    image: shop:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
```

`imagePullPolicy: IfNotPresent` is there for kind's sake, as in lesson 11, and the next part of
this section shows what leaving it out does. The image needs its second tag, and the nodes need
the tagged copy:

```
ana@laptop:~/azure$ docker tag shop:1.0 shop:latest
ana@laptop:~/azure$ kind load docker-image shop:latest --name shop
Image: "shop:latest" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-worker2", loading...
Image: "shop:latest" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-worker", loading...
Image: "shop:latest" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-control-plane", loading...
ana@laptop:~/azure$ kubectl apply -f hurried.yaml
pod/hurried created
ana@laptop:~/azure$ kubectl wait --for=condition=Ready pod/hurried --timeout=60s
pod/hurried condition met
ana@laptop:~/azure$ kubectl get pod hurried -o custom-columns=POD:.metadata.name,STATUS:.status.phase,QOS:.status.qosClass
POD       STATUS    QOS
hurried   Running   BestEffort
```

**Kubernetes accepted it without a word, and the pod is running.** What it did with the missing
requests is in the last line: the pod's quality-of-service class is `BestEffort`, the class of a
pod whose containers ask for nothing and are limited by nothing. Three things follow from that,
and each is a safeguard's reason:

- the scheduler counts its requests as zero, so it can be put on a node that is already full;
- when that node runs short of memory, the kubelet evicts `BestEffort` pods first;
- node auto-provisioning sizes machines from requests, so a pod that asks for nothing gives it
  nothing to size, which defeats the mechanism of the previous section.

The tag has a cost of its own, and the API server shows it once the line that kind needs is taken
out. The copy gets another name, because a running pod's containers cannot be changed and the
server would compare it with `hurried`. `--dry-run=server` returns the object as it would be
stored, defaults filled in:

```
ana@laptop:~/azure$ sed -e '/imagePullPolicy/d' -e 's/name: hurried/name: hurried-2/' hurried.yaml > nopolicy.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f nopolicy.yaml -o jsonpath='{.spec.containers[0].imagePullPolicy}{"\n"}'
Always
ana@laptop:~/azure$ sed -i 's/shop:latest/shop:1.0/' nopolicy.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f nopolicy.yaml -o jsonpath='{.spec.containers[0].imagePullPolicy}{"\n"}'
IfNotPresent
```

**A tag of `latest` changes the default pull policy to `Always`**, while the pinned tag `1.0`
defaults to `IfNotPresent`. Every new pod of the first kind asks the registry again, and whatever
the tag points at on that day is what runs. Two replicas started a week apart can run two
different programs under one name, and a rollback has nothing to roll back to, which is the
argument lesson 10 made for digests.

On an Automatic cluster this pod would not have been stored. The resource requests rule mutates,
so missing requests are filled in, but the probes rule and the `latest` rule only refuse. The API
server's answer would start *Error from server (Forbidden)* with the safeguard's message in it,
such as *Container shop in your Pod hurried has no livenessProbe. Required probes: readinessProbe,
livenessProbe*. Nothing in this lab enforces that: kind has no Azure Policy. The message is quoted
from Microsoft's documentation.

## What the mutation would have chosen

When a container has no requests and no limits, the resource requests mutator writes them, and
the documentation gives the values:

| | request | limit |
|---|---|---|
| CPU | `500m` | `500m` |
| memory | `2048Mi` | `2048Mi` |

Where a value is given but small, it is raised to a minimum of `100m` of CPU and `100Mi` of
memory. Requests equal to limits put the pod in the `Guaranteed` class, so the mutation does make
the pod well-behaved. **It also makes it expensive.** The shop is a small Python server; ten replicas
mutated to 2 GiB each ask NAP for 20 GiB of memory, and NAP buys nodes to match. A
request written by somebody who measured the program is the cheaper answer, and the only one the
mutator cannot write for you.

The anti-affinity mutator does the same for spreading: a workload with no pod anti-affinity and no
topology spread constraint gets both, preferring one replica per node and never refusing to
schedule because of it.

## The shop as the safeguards ask for it

The shop's Deployment, rewritten to pass every rule, which is also how it should have been written
for lesson 11. Save it over lesson 11's `shop.yaml`:

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "# shop.yaml\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\nspec:\n  replicas: 3\n  selector:\n    matchLabels:\n      app: shop\n  template:\n    metadata:\n      labels:\n        app: shop\n    spec:\n", "note": "The Deployment of lesson 11, without its `nodeSelector`: an Automatic cluster has no pool called `apps` to select, and the node a pod gets is NAP's to choose."}, {"code": "      topologySpreadConstraints:\n      - maxSkew: 1\n        topologyKey: kubernetes.io/hostname\n        whenUnsatisfiable: ScheduleAnyway\n        labelSelector:\n          matchLabels:\n            app: shop\n", "note": "**The spreading rule, written by you rather than added by the mutator.** No node may hold more than one replica more than another, and when that cannot be met the pod is scheduled anyway: these are the settings the documentation says the mutator uses."}, {"code": "      containers:\n      - name: shop\n        image: shop:1.0\n        imagePullPolicy: IfNotPresent\n        ports:\n        - containerPort: 8080\n", "note": "A pinned tag. `IfNotPresent` is the default for it anyway, and stays written for kind, which has no registry to ask."}, {"code": "        resources:\n          requests:\n            cpu: 100m\n            memory: 128Mi\n          limits:\n            cpu: 100m\n            memory: 128Mi\n", "note": "**Requests equal to limits**, at the mutator's minimum for CPU and a little above it for memory: enough for a small Python server, and a sixteenth of what the mutator would have asked for."}, {"code": "        readinessProbe:\n          httpGet:\n            path: /healthz\n            port: 8080\n          periodSeconds: 2\n        livenessProbe:\n          httpGet:\n            path: /healthz\n            port: 8080\n          periodSeconds: 10\n          failureThreshold: 3\n", "note": "Both probes on the shop's `/healthz`. Readiness decides whether the pod receives traffic and counts as available; liveness restarts a container that stopped answering for thirty seconds."}]}
```

The hurried pod goes, and the shop arrives:

```
ana@laptop:~/azure$ kubectl delete pod hurried
pod "hurried" deleted from default namespace
ana@laptop:~/azure$ kubectl apply -f shop.yaml
deployment.apps/shop created
ana@laptop:~/azure$ kubectl rollout status deployment/shop --timeout=120s
Waiting for deployment "shop" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 2 of 3 updated replicas are available...
deployment "shop" successfully rolled out
ana@laptop:~/azure$ kubectl get pods -l app=shop -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,QOS:.status.qosClass,READY:.status.containerStatuses[0].ready
POD                     NODE           QOS          READY
shop-6897f59f8b-69bgk   shop-worker2   Guaranteed   true
shop-6897f59f8b-hm6fq   shop-worker    Guaranteed   true
shop-6897f59f8b-kjvgw   shop-worker    Guaranteed   true
```

**`Guaranteed`, ready, and spread over both workers.** Nothing here was checked by a safeguard:
kind has none, and the manifest would have been accepted without any of these lines. The
transcript shows something else: the manifest the safeguards ask for is also the one Kubernetes
treats best. Its pods are the last to be evicted, the scheduler and NAP know their size, and a node
lost takes at most two of the three replicas with it.

## Labelling a node

One more edit to a single node, the kind lesson 11 made with its taint, which Kubernetes allows:

```
ana@laptop:~/azure$ kubectl label node shop-worker team=shop
node/shop-worker labeled
```

On Automatic, that command is refused by the safeguard on single nodes, and the managed system
nodes have a restriction of their own against exactly this. A label meant for a group of nodes belongs on a
NodePool, in its template, where NAP writes it on every node it creates.

That is everything this lesson needs the cluster for. Delete it:

```
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-worker2" "shop-worker" "shop-control-plane"]
```

## Where the rules stop

Two limits are in the documentation and worth knowing before you rely on the rules. **The
safeguards are all or nothing**: once they are on, every rule is active, and you cannot pick some
of them. And **Gatekeeper fails open**: if the admission webhook does not answer the API server in
time, the check is skipped and the object is admitted, so that a slow policy service never blocks
every deployment in the cluster. A safeguard is therefore a strong default and not a proof: a
noncompliant workload can be in the cluster, and Azure Policy's compliance view, not the
admission answer, is where you find it.
