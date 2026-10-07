---
title: What a container may do by default, and how to take it away
version: 1
---

Start with a pod nobody has thought about:

```
ana@laptop:~/shop$ kubectl run plain --image=busybox:1.37 --restart=Never --command -- sleep 3600
pod/plain created
ana@laptop:~/shop$ kubectl exec plain -- id
uid=0(root) gid=0(root) groups=0(root),10(wheel)
ana@laptop:~/shop$ kubectl exec plain -- sh -c "grep Cap /proc/1/status"
CapInh:	0000000000000000
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
ana@laptop:~/shop$ kubectl exec plain -- sh -c "touch /etc/written-by-the-pod && echo written"
written
```

**Root, with fourteen capabilities, and a writable filesystem.** The capability set is a bitmask:
`a80425fb` is the container runtime's default list, which includes changing file ownership, binding
low ports and sending raw network packets. None of them makes a container escape on its own. Each one
is something an attacker who gets into the process can use, and the shop needs none of them.

Root inside a container is not root on the node, because the kernel's namespaces and the missing
capabilities stand in between. But it is one kernel bug away from mattering, and taking it away costs
almost nothing.

## Raising the walls

The `securityContext` sets these per pod and per container:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hardened
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

| field | what it does |
|---|---|
| `runAsUser`, `runAsGroup` | the process's user and group ids |
| `runAsNonRoot: true` | refuse to start the container if it would run as user 0 |
| `seccompProfile: RuntimeDefault` | the runtime's list of allowed system calls; the rest are refused |
| `allowPrivilegeEscalation: false` | no set-uid binary can give the process more than it started with |
| `readOnlyRootFilesystem: true` | the image's files cannot be changed |
| `capabilities.drop: ["ALL"]` | not one capability |

The `emptyDir` mounted at `/tmp` gives the program one writable place, because many programs need to
write somewhere, and a scratch directory that disappears with the pod is the safe place for it.

```
ana@laptop:~/shop$ kubectl apply -f hardened.yaml
pod/hardened created
ana@laptop:~/shop$ kubectl exec hardened -- id
uid=10001 gid=10001 groups=10001
ana@laptop:~/shop$ kubectl exec hardened -- sh -c "grep Cap /proc/1/status"
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	0000000000000000
CapAmb:	0000000000000000
ana@laptop:~/shop$ kubectl exec hardened -- sh -c "touch /etc/written-by-the-pod"
touch: /etc/written-by-the-pod: Read-only file system
command terminated with exit code 1
ana@laptop:~/shop$ kubectl exec hardened -- sh -c "touch /tmp/scratch && echo /tmp is writable"
/tmp is writable
```

User 10001, every capability set empty, `/etc` read-only and `/tmp` writable. The same busybox image,
doing the same `sleep`, with nothing left to misuse.

## An image that insists on root

`runAsNonRoot` without a `runAsUser` trusts the image to name a non-root user. When it does not, the
kubelet refuses to start the container:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx:1.29
```

```
ana@laptop:~/shop$ kubectl apply -f root-image.yaml
pod/web created
ana@laptop:~/shop$ kubectl get pod web
NAME   READY   STATUS                       RESTARTS   AGE
web    0/1     CreateContainerConfigError   0          9s
ana@laptop:~/shop$ kubectl get pod web -o jsonpath="{.status.containerStatuses[0].state.waiting.message}"; echo
container has runAsNonRoot and image will run as root (pod: "web_default(5ba43b42-957c-4319-8337-f87a9abf8510)", container: nginx)
```

**`CreateContainerConfigError`, and the reason in the waiting message.** The official nginx image
starts as root, so this is a fault in the combination, not in either half. The fixes are an image
built to run as another user (nginx publishes an unprivileged variant), or a `runAsUser` plus
whatever directories the program writes to. The shop image this course uses is built to run as user
65532, so every shop pod in it could have carried `runAsNonRoot: true`.
