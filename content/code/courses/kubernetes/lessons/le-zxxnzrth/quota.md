---
title: A ResourceQuota is a namespace's budget
version: 1
---

**A cluster shared by several teams fails in a predictable way: one team's runaway deployment takes
the capacity everybody else was counting on.** Namespaces give each team a place; a ResourceQuota
gives that place a ceiling. The API server checks it on every create, so nothing that would break the
budget is ever admitted.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a
  namespace: team-a
spec:
  hard:
    pods: "4"
    requests.cpu: "1"
    requests.memory: 512Mi
    limits.memory: 1Gi
---
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: team-a
spec:
  limits:
  - type: Container
    defaultRequest:
      cpu: 100m
      memory: 64Mi
    default:
      memory: 128Mi
    max:
      memory: 256Mi
```

The quota caps four totals for everything in `team-a`: at most four pods, one CPU and 512 MiB of
memory in requests, and 1 GiB in memory limits. The LimitRange below it is the next section's
subject.

```
ana@laptop:~/shop$ kubectl create namespace team-a
namespace/team-a created
ana@laptop:~/shop$ kubectl apply -f quota.yaml
resourcequota/team-a created
limitrange/defaults created
ana@laptop:~/shop$ kubectl describe resourcequota team-a -n team-a
Name:            team-a
Namespace:       team-a
Resource         Used  Hard
--------         ----  ----
limits.memory    0     1Gi
pods             0     4
requests.cpu     0     1
requests.memory  0     512Mi
```

`Used` is zero across the board. Every pod created in the namespace from now on is added to it, and
`Hard` is the line.

## Going over the line

The team deploys two copies, then asks for six:

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=6 -n team-a
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get deployment shop -n team-a
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
shop   4/6     4            4           10s
```

**Four of six, and the Deployment does not say why.** The refusal is not on the Deployment, which was
accepted, nor on a pending pod, because no pod was ever created. It happened when the ReplicaSet tried
to create the fifth pod and the API server refused it, so the evidence is an event on the ReplicaSet:

```
ana@laptop:~/shop$ kubectl get events -n team-a --field-selector reason=FailedCreate -o custom-columns=MESSAGE:.message | tail -n 1
(combined from similar events): Error creating: pods "shop-774b84ff8c-666qj" is forbidden: exceeded quota: team-a, requested: pods=1, used: pods=4, limited: pods=4
```

`requested: pods=1, used: pods=4, limited: pods=4`. Reading `kubectl describe` on the quota shows the
whole budget:

```
ana@laptop:~/shop$ kubectl describe resourcequota team-a -n team-a | tail -n 5
--------         ----   ----
limits.memory    512Mi  1Gi
pods             4      4
requests.cpu     400m   1
requests.memory  256Mi  512Mi
```

The pod count is at its limit; CPU and memory still have room. **Whichever line is reached first
stops the namespace**, so a quota is read as a set of independent ceilings rather than as a single
size.

## The rest of the cluster does not notice

```
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0 --replicas=6
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get deployments --all-namespaces -l app=shop
NAMESPACE   NAME   READY   UP-TO-DATE   AVAILABLE   AGE
default     shop   6/6     6            6           1s
team-a      shop   4/6     4            4           11s
```

The same Deployment, created in `default`, got all six pods. A quota is a property of one namespace
and constrains nothing outside it, which is what lets a cluster's operators hand each team its own
allowance and leave the teams to manage within it.
