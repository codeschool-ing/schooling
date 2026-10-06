---
title: A LimitRange fills in what the author left out
version: 1
---

A quota on CPU or memory has a consequence that surprises everybody once: **in a namespace whose quota
counts requests, a pod that declares no requests cannot be counted, and is refused.** Nobody writes
requests for every container on day one, so a quota alone would turn every forgotten field into a
failed deploy. The LimitRange is what prevents that. Its `defaultRequest` and `default` are written
into any container that left them out, before the quota is checked.

The team's deployment, created with `kubectl create deployment`, which writes no resources at all:

```
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0 --replicas=2 -n team-a
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pod -n team-a -l app=shop -o jsonpath="{.items[0].spec.containers[0].resources}"; echo
{"limits":{"memory":"128Mi"},"requests":{"cpu":"100m","memory":"64Mi"}}
```

**Requests and a limit appeared that nobody typed**: `100m` of CPU and `64Mi` of memory requested, a
`128Mi` memory limit, exactly the LimitRange's values. That is also why the quota's `Used` column grew
by 100m and 64Mi per pod in the previous section.

## A ceiling per container

`max` caps what any single container may ask for, whatever the namespace still has free:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: greedy
  namespace: team-a
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      limits:
        memory: 512Mi
```

```
ana@laptop:~/shop$ kubectl apply -f greedy.yaml
Error from server (Forbidden): error when creating "greedy.yaml": pods "greedy" is forbidden: maximum memory usage per Container is 256Mi, but limit is 512Mi
```

**Refused at once, with the reason in the message**: the namespace had 512 MiB of limits left, but no
one container may have more than 256. This one is a direct `kubectl apply` of a pod, so the error
comes straight back; inside a Deployment it would be an event on the ReplicaSet, like the quota's.

| object | applies to | answers |
|---|---|---|
| ResourceQuota | the namespace's total | how much may this team use altogether? |
| LimitRange `defaultRequest`, `default` | each container that left them out | what does a container get if its author did not say? |
| LimitRange `min`, `max` | each container | how small or large may one container be? |

Setting both on every team's namespace is ordinary practice, and the values are a conversation
between the people who pay for the cluster and the people who deploy to it. Lesson 21 measures what
pods actually use, which is the evidence that conversation needs.
