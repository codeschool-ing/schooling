---
title: One pod on every node
version: 1
---

**Some software belongs to the machine rather than to the application**: a log collector that reads
every container's output on that node, a metrics agent, the network plugin itself. Running it as a
Deployment would mean guessing a replica count and hoping the scheduler spreads it evenly. A
DaemonSet asks a different question — which nodes should have one? — and its answer is every node
that may run it.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      containers:
      - name: agent
        image: busybox:1.37
        command: ["sh", "-c", "echo watching $NODE; exec sleep 3600"]
        env:
        - name: NODE
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
```

There is no `replicas`. The `env` entry uses the downward API to hand the container the name of the
node it landed on, which is what an agent usually needs first.

```
ana@laptop:~/shop$ kubectl apply -f node-agent.yaml
daemonset.apps/node-agent created
ana@laptop:~/shop$ kubectl get daemonset node-agent
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent   2         2         2       2            2           <none>          1s
ana@laptop:~/shop$ kubectl get pods -l app=node-agent -o wide
NAME               READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
node-agent-l4jtj   1/1     Running   0          1s    10.244.2.2   shop-worker2   <none>           <none>
node-agent-vbkc4   1/1     Running   0          1s    10.244.1.2   shop-worker    <none>           <none>
```

**Two pods, one on each worker, and none on the control plane.** That is not the DaemonSet's choice:

```
ana@laptop:~/shop$ kubectl describe node shop-control-plane | grep Taints
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
```

The control-plane node carries a **taint**, `NoSchedule`, which keeps ordinary pods off it, and a
DaemonSet's pods are ordinary unless they say they tolerate it. kindnet and kube-proxy do say so,
which is why lesson 4 found one of each on all three nodes. Lesson 30 is about taints and the
tolerations that cross them.

When a node joins the cluster, the DaemonSet controller gives it a pod at once; when a node leaves,
its pod goes with it. Updating a DaemonSet replaces its pods one node at a time by default, so an
agent is never missing from every node at once.
