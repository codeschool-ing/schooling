---
title: No shell, and a tunnel instead
version: 1
---

This lesson needs two things to debug after `./up.sh`: the shop, whose image has no shell, and a pod
called `crashing` that exits the moment it starts, because `CRASH` is set.

`debug-apps.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop}
spec:
  replicas: 1
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec: {containers: [{name: shop, image: "shop:1.0"}]}
---
apiVersion: v1
kind: Pod
metadata: {name: crashing}
spec:
  containers: [{name: shop, image: "shop:1.0", env: [{name: CRASH, value: "yes"}, {name: GREETING, value: "hello"}]}]
```

```sh
kubectl apply -f debug-apps.yaml
```

The first reflex when a pod misbehaves is a shell inside it:

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -- sh -c 'echo hello'
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "4760325991634de719b65a77ab21417d11cd2f6944115e6fb7ded230739db94f": OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

**`"sh": executable file not found`.** The shop's image is built from `scratch`, with one file in it,
the program. There is no shell, no `ls`, no `curl`; nothing an attacker who got in could use, and
nothing you can use either. Images built on distroless or scratch bases are common in production for
exactly that reason, so `kubectl exec` is a tool that often is not there when it matters.

## `port-forward`: the pod on your laptop

To call the shop as if it were local, without a Service, an Ingress or any change to the cluster,
`kubectl port-forward` opens a tunnel from a port on the laptop to a port on one pod, through the API
server:

```
ana@laptop:~/shop$ kubectl port-forward deployment/shop 9090:8080 &
Forwarding from 127.0.0.1:9090 -> 8080
ana@laptop:~/shop$ curl -s localhost:9090/
shop 1.0 on shop-774b84ff8c-q4fjf
ana@laptop:~/shop$ curl -s localhost:9090/config
GREETING=
/etc/shop/greeting: (open /etc/shop/greeting: no such file or directory)
```

The Deployment name resolves to one of its pods, and the tunnel goes to that pod only, not through the
Service, so this is also how to talk to one particular copy. The shop's `/config` endpoint shows what
the process actually received: an empty greeting and no config file mounted, which is the kind of fact
that settles an argument quickly.

**The tunnel needs only `pods/portforward` permission**, lesson 23's subresource style, and nothing is
exposed beyond the laptop that opened it. It lasts as long as the command runs. That makes it the
right way to reach an admin page or a database inside the cluster for a few minutes, and the wrong
way to serve anything to anybody else.
