---
title: Three classes, decided by what you wrote
version: 1
---

Nobody sets a pod's quality-of-service class. **Kubernetes derives it from the requests and limits,
and writes it into the pod's status**, where it decides who suffers first when a node runs short:

```
ana@laptop:~/shop$ kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
NAME     QOS
capped   Guaranteed
free     Burstable
hungry   Burstable
probe    BestEffort
```

The rules are short:

| class | when | here |
|---|---|---|
| `Guaranteed` | every container has CPU and memory limits, and requests equal to them | `capped` |
| `Burstable` | at least one request or limit, but not Guaranteed | `free`, `hungry` |
| `BestEffort` | no requests and no limits anywhere | `probe` |

**`hungry` is the one worth a second look.** Its memory request equals its memory limit, which reads
like a guarantee, but it says nothing about CPU, so it is `Burstable`. Guaranteed needs both resources,
in every container, set the same.

The class matters in two places. When a node runs short of memory, the kubelet evicts pods to save the
node, and it starts with pods using more than they requested, which rules out a Guaranteed pod that
stays inside its limits; lesson 32 watches that happen. And the kernel's out-of-memory killer, when
it acts for the whole node rather than for one container, prefers BestEffort processes over
Burstable, and Burstable over Guaranteed.

A common starting point, not a rule: set memory request and limit equal, because running out of
memory kills; set a CPU request and often no CPU limit, because running out of CPU only waits, and a
limit would slow the pod even when the node has CPU to spare. Lesson 21 is how to choose the numbers.
