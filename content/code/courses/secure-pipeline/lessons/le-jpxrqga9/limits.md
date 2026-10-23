---
title: Limits, LimitRange and ResourceQuota
version: 1
---

The admission rule makes every linkbox Deployment declare a memory limit. **What the limit may be,
and how much the namespace may use in total, are the cluster's decisions rather than the
application's**, and Kubernetes has an object for each. `kubernetes` lesson 19 showed what a limit
does to a pod that exceeds it; this section is about who sets the numbers and what happens at the
edges.

### Two objects, owned by whoever runs the cluster

A LimitRange sets defaults and bounds for each container in a namespace: the limit a container gets
if it declares none, and the largest it may declare. A ResourceQuota caps the namespace as a whole:
how many pods, how much memory requested and limited across all of them. Neither belongs in
linkbox's repository. In a company they are written by the team that runs the cluster, per
namespace, and the application team works inside them. In this lab you are both, so the file lives
in your home directory rather than in `k8s/`. Save it as `~/quota.yaml`:

```yaml
# What the linkbox namespace may use, set by whoever runs the cluster rather
# than by the application's repository. The LimitRange fills in a memory
# limit for a container that declares none and refuses one above 256Mi; the
# ResourceQuota caps the namespace as a whole.
apiVersion: v1
kind: LimitRange
metadata:
  name: linkbox
  namespace: linkbox
spec:
  limits:
    - type: Container
      default:
        memory: 128Mi
      defaultRequest:
        memory: 64Mi
      max:
        memory: 256Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: linkbox
  namespace: linkbox
spec:
  hard:
    pods: "4"
    requests.memory: 512Mi
    limits.memory: 512Mi
```

```
ana@vm:~/linkbox$ kubectl apply -f ~/quota.yaml
limitrange/linkbox created
resourcequota/linkbox created
ana@vm:~/linkbox$ kubectl describe resourcequota linkbox -n linkbox
Name:            linkbox
Namespace:       linkbox
Resource         Used   Hard
--------         ----   ----
limits.memory    128Mi  512Mi
pods             1      4
requests.memory  64Mi   512Mi
```

**The quota already counts linkbox's pod**: one of four pods, and 64Mi of requests and 128Mi of
limits out of 512Mi each, exactly what the Deployment declares.

### The quota at its edge

Ask for five replicas, where the quota allows four pods:

```
ana@vm:~/linkbox$ kubectl scale deployment linkbox -n linkbox --replicas=5
deployment.apps/linkbox scaled
ana@vm:~/linkbox$ kubectl get deployment linkbox -n linkbox
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
linkbox   4/5     4            4           19s
ana@vm:~/linkbox$ kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' | grep -m 1 'exceeded quota'
Error creating: pods "linkbox-56f7558485-g2nfb" is forbidden: exceeded quota: linkbox, requested: limits.memory=128Mi,pods=1, used: limits.memory=512Mi,pods=4, limited: limits.memory=512Mi,pods=4
ana@vm:~/linkbox$ kubectl scale deployment linkbox -n linkbox --replicas=1
deployment.apps/linkbox scaled
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"sp-l10-quota\" aria-label=\"The linkbox namespace's quota against five replicas of linkbox. The quota allows 4 pods and 512Mi of memory limits. Each pod declares a 128Mi limit, so four pods use the whole quota, 4 of 4 pods and 512Mi of 512Mi, and the fifth is refused.\"><defs></defs><rect x=\"15\" y=\"30\" width=\"520\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">quota: 4 pods, 512Mi of limits</text><rect x=\"30\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 1</text><text x=\"86.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"155\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"211.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 2</text><text x=\"211.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"280\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 3</text><text x=\"336.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"405\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"461.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 4</text><text x=\"461.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"565\" y=\"62\" width=\"140\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 5</text><text x=\"635.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><text x=\"635\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">refused: exceeded quota</text></svg>", "caption": "Four pods of 128Mi fill the namespace exactly. The fifth is the ReplicaSet's to create and the quota's to refuse."}
```

**`kubectl scale` succeeded, and four pods run.** Like Pod Security Admission, a ResourceQuota judges
pods, so the Deployment accepted the number and its ReplicaSet was refused the fifth pod, with a
message that names the quota and what was asked against what was left. The Deployment stays at four
ready out of five until the quota or the number changes, and nothing breaks for the four that run.
That is the purpose: one namespace's runaway scaling, or a mistake in a manifest, stops at the
namespace's budget instead of the cluster's.

### The LimitRange at its edge

Now a change that the admission rule accepts, because the Deployment does declare a limit, but that
the LimitRange refuses, because the limit is above its maximum:

```
ana@vm:~/linkbox$ kubectl set resources deployment linkbox -n linkbox --limits=memory=512Mi
deployment.apps/linkbox resource requirements updated
ana@vm:~/linkbox$ kubectl get pods -n linkbox
NAME                       READY   STATUS    RESTARTS   AGE
linkbox-56f7558485-dtb2v   1/1     Running   0          22s
ana@vm:~/linkbox$ kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' | grep -m 1 'maximum memory'
Error creating: pods "linkbox-5bc4f6895f-g58sl" is forbidden: maximum memory usage per Container is 256Mi, but limit is 512Mi
ana@vm:~/linkbox$ kubectl rollout undo deployment linkbox -n linkbox
Warning: resource deployments/linkbox was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/linkbox rolled back
ana@vm:~/linkbox$ kubectl rollout status deployment/linkbox -n linkbox --timeout=120s
deployment "linkbox" successfully rolled out
```

The Deployment was updated, and its new pod was refused with the LimitRange's own message: a
maximum of 256Mi per container, and 512Mi asked. The old pod kept running, because a rollout
removes old pods only as new ones become ready, and `kubectl rollout undo` took the Deployment back
to the previous version. **A bad change was stopped without an outage**, which is what a rollout
with a check at the pod's door gives you, provided somebody reads the rollout's status rather than
the `apply`'s. The warning on the undo is `kubectl` pointing at the cleaner fix: the file is the
source, so in real work the change is corrected in `k8s/linkbox.yaml` and applied again.

### Three checks on one number

| check | what it sees | where it refuses |
|---|---|---|
| the admission policy | the Deployment: is there a memory limit at all? | `kubectl apply`, immediately |
| the LimitRange | each container: is the limit within bounds? fills one in if missing | the pod, as an event |
| the ResourceQuota | the namespace: does this pod fit what is left? | the pod, as an event |

The three overlap on purpose. The policy catches the Deployment that forgot, at the moment somebody can fix it. The LimitRange catches a pod made by anything the policy does not match, a Job or a bare
pod, and fills in a default instead of refusing. The quota catches the total, which no single
manifest can see. **Lesson 19 adds a fourth, in the pipeline**: the same rule checked against
`k8s/` before anything reaches a cluster, so the refusal arrives in a build log rather than at
deploy time.

### Commit it

```
ana@vm:~/linkbox$ git add k8s
ana@vm:~/linkbox$ git commit -q -m "linkbox on Kubernetes, held to the restricted profile, and two admission rules"
9:57AM INF 0 commits scanned.
9:57AM INF scanned ~2980 bytes (2.98 KB) in 370ms
9:57AM INF no leaks found
```

`ci/stages` does not change in this lesson. The manifests are in the repository, reviewed with the
code, and lesson 19 is where the pipeline starts checking them.
