---
title: Scaling down, and scaling on something other than CPU
version: 1
---

The load stopped after two and a half minutes. A minute and a half later:

```
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 0%/50%   1         6         1          5m
ana@laptop:~/shop$ kubectl describe hpa shop | sed -n '/^Conditions/,/^Events/p'
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  True    TooFewReplicas    the desired replica count is less than the minimum replica count
  ScaledToZero    False   NotScaledToZero   the HPA controller did not scale the workload to zero
Events:
```

**Back to one replica.** Scaling down is deliberately slower than scaling up: by default the
autoscaler takes the highest recommendation of the last five minutes, so that a traffic dip of a few
seconds does not remove pods that will be needed again at once. This lesson shortened that window to 30
seconds in `behavior.scaleDown.stabilizationWindowSeconds`, so that the capture fits in a page; in
production the default is usually right.

The conditions are the autoscaler's own account of itself. `ScalingLimited True, TooFewReplicas` says
the formula wanted fewer than one replica and was held at `minReplicas`. When something is wrong,
`ScalingActive False` with its reason, a missing metric for example, is where to look first.

## Memory, and metrics from outside

**CPU is the usual metric because it rises and falls with load.** Memory can be used the same way,
with `name: memory`, but most programs do not hand memory back when the load goes, so an autoscaler
on memory often scales up and never down.

Two more kinds of metric need an adapter that serves them through the API, the way metrics-server
serves CPU. This course installs none, so these are described and not run:

| metric type | example | served by |
|---|---|---|
| `Resource` | CPU or memory per pod | metrics-server |
| `Pods` or `Object` | requests per second, measured by the application | a custom metrics adapter, such as the Prometheus adapter |
| `External` | messages waiting in a queue outside the cluster | an external metrics adapter; KEDA is the common one |

Scaling on a queue's length is often the better signal for workers: the queue says how much work is
waiting, where CPU only says how hard the current workers are trying. KEDA can also scale a
Deployment to zero while the queue is empty, which the plain autoscaler does not do by default.

The autoscaler adds pods only while nodes have room for them. When they do not, the new pods stay
`Pending`, and adding nodes is the cluster autoscaler's job, in lesson 34.
