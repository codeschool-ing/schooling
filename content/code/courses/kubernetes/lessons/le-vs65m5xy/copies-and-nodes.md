---
title: A copy to take apart, and a look at the node
version: 1
---

A pod that crashes on start is gone before anybody can attach anything to it. **`kubectl debug
--copy-to` makes a new pod from the broken one's spec, with changes**, and leaves the original alone:

```
ana@laptop:~/shop$ kubectl get pod crashing
NAME       READY   STATUS   RESTARTS     AGE
crashing   0/1     Error    1 (8s ago)   9s
ana@laptop:~/shop$ kubectl debug crashing --copy-to=crashing-debug --container=shop --image=busybox:1.37 -- sleep 600
ana@laptop:~/shop$ kubectl exec crashing-debug -c shop -- env | grep -E "CRASH|GREETING"
GREETING=hello
CRASH=yes
ana@laptop:~/shop$ kubectl get pods
NAME                    READY   STATUS    RESTARTS     AGE
crashing                0/1     Error     1 (8s ago)   9s
crashing-debug          1/1     Running   0            0s
shop-774b84ff8c-q4fjf   1/1     Running   0            9s
```

The copy, `crashing-debug`, kept the original's environment, the variables and everything else in its
spec, but its container named `shop` now runs busybox with `sleep`, so it stays up. Inside it, the
cause is in plain view: `CRASH=yes`. Changing the image and command of a copy, not of the original, is
the point: the broken pod stays as evidence, and the copy is deleted when you are done.

The copy is a separate pod with no owner, so no Service selects it unless its labels say so, and no
Deployment replaces it; it is not part of the application. `--copy-to` can also keep the original
image and change only the command, or add a debug container with `--share-processes`.

## The node itself

Some problems are on the node, not in a pod: the kubelet's settings, a full disk, a certificate.
**`kubectl debug node/NAME` starts a pod on that node with the node's filesystem mounted at
`/host`**:

```
ana@laptop:~/shop$ kubectl debug node/shop-worker --image=busybox:1.37 -- sleep 600
Creating debugging pod node-debugger-shop-worker-k5g5t with container debugger on node shop-worker.
ana@laptop:~/shop$ kubectl exec node-debugger-shop-worker-k5g5t -- ls /host/etc/kubernetes
kubelet.conf
manifests
pki
ana@laptop:~/shop$ kubectl exec node-debugger-shop-worker-k5g5t -- sh -c 'cat /host/var/lib/kubelet/config.yaml | grep -E "^(cgroupDriver|serverTLSBootstrap|failCgroupV1):"'
cgroupDriver: systemd
failCgroupV1: false
serverTLSBootstrap: true
```

The kubelet's configuration file, read from the laptop with no SSH: `failCgroupV1: false` and
`serverTLSBootstrap: true` are the two settings lab.sh changed, and here they are on the node. That
pod runs with access to the node's files, so it is as powerful as a login on the machine, and RBAC
should treat the right to create it that way.

| tool | changes the running pod? | needs in the image | right for |
|---|---|---|---|
| `kubectl exec` | no | a shell and tools | images that have them |
| `kubectl port-forward` | no | nothing | calling one pod from the laptop |
| `kubectl debug --target` | adds an ephemeral container | nothing | inspecting a running pod without tools |
| `kubectl debug --copy-to` | no, makes a copy | nothing | pods that crash on start |
| `kubectl debug node/…` | no, adds a pod on the node | nothing | the node's own files and settings |

Whatever was started for debugging is deleted afterwards. A forgotten debug pod with a node's
filesystem mounted is exactly the kind of thing an attacker hopes to find.
