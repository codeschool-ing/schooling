---
title: An ephemeral container beside the one without tools
version: 1
---

**An ephemeral container is a temporary container added to a running pod**, with an image of your
choice. It shares the pod's network, and with `--target` it also shares the process namespace of one
container, so it sees that container's processes:

```
ana@laptop:~/shop$ kubectl debug shop-774b84ff8c-q4fjf --image=busybox:1.37 --target=shop --container=dbg -- sleep 600
Targeting container "shop". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
```

The pod was not restarted and its shop container was not touched; a busybox container was added
beside it, running `sleep` so that it stays up to be used.

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -c dbg -- ps
PID   USER     TIME  COMMAND
    1 65532     0:00 /shop
   22 root      0:00 sleep 600
   32 root      0:00 ps
```

**PID 1 is `/shop`, running as user 65532**: the debug container sees the shop's process, which is
what `--target` bought. From inside the same network namespace, `localhost:8080` is the shop itself:

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -c dbg -- wget -qO- localhost:8080/
shop 1.0 on shop-774b84ff8c-q4fjf
```

And `/proc/1/root` is the shop's own filesystem, seen from outside it:

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -c dbg -- ls /proc/1/root/
dev
etc
proc
product_uuid
shop
sys
var
```

`shop`, the program, and the directories the runtime mounts; nothing else, as the failed `exec`
suggested. Reading files through `/proc/1/root` is the way to inspect a scratch image's container
without adding anything to the image.

```
ana@laptop:~/shop$ kubectl get pod shop-774b84ff8c-q4fjf -o jsonpath='{.spec.ephemeralContainers[*].name}'; echo
dbg
```

**An ephemeral container cannot be removed**; it stays in the pod's spec until the pod is replaced.
It also cannot have ports or probes, and its resources count against the node. That is the price, and
it is why the next section's alternative exists.
