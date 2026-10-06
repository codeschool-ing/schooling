---
title: Changing a running pod's requests
version: 1
---

For most of Kubernetes' life, a pod's resources were fixed when it was created: changing them meant a
new pod. **Since version 1.35, CPU and memory can be resized in place**, through a subresource of the
pod, which is what the VPA's `InPlaceOrRecreate` mode uses. By hand:

```
ana@laptop:~/shop$ kubectl get pod shop-8c87b866c-b4f85 -o jsonpath='{.spec.containers[0].resources} restarts={.status.containerStatuses[0].restartCount}'; echo
{"requests":{"cpu":"50m","memory":"256Mi"}} restarts=0
ana@laptop:~/shop$ kubectl patch pod shop-8c87b866c-b4f85 --subresource resize -p '{"spec":{"containers":[{"name":"shop","resources":{"requests":{"cpu":"200m","memory":"64Mi"}}}]}}'
pod/shop-8c87b866c-b4f85 patched
```

```
ana@laptop:~/shop$ kubectl get pod shop-8c87b866c-b4f85 -o jsonpath='{.spec.containers[0].resources} restarts={.status.containerStatuses[0].restartCount}'; echo
{"requests":{"cpu":"200m","memory":"64Mi"}} restarts=0
ana@laptop:~/shop$ kubectl get pod shop-8c87b866c-b4f85 -o jsonpath='{.status.containerStatuses[0].resources}'; echo
{"requests":{"cpu":"200m","memory":"64Mi"}}
```

**The new requests are in the spec, the status confirms the kubelet applied them, and `restarts` is
still 0.** The kubelet changed the container's cgroup settings while the process kept running. The CPU
request went up to 200m and the memory request down to 64Mi, closer to what the shop uses.

Whether a resize needs a restart is declared per resource, in the container's `resizePolicy`:

```
ana@laptop:~/shop$ kubectl explain pod.spec.containers.resizePolicy | sed -n "/FIELDS/,\$p"
FIELDS:
  resourceName	<string> -required-
    Name of the resource to which this resource resize policy applies. Supported
    values: cpu, memory.

  restartPolicy	<string> -required-
    Restart policy to apply when specified resource is resized. If not
    specified, it defaults to NotRequired.
```

The default is `NotRequired`, which suits a Go program like the shop: it reads its CPU allowance from
the kernel as it goes. A program that sizes its memory once at start, such as a JVM given a heap at
launch, should say `RestartContainer` for memory, because a larger limit means nothing to a process
that already decided how much to use.

Resizing changes one pod. The Deployment's template still says 50m and 256Mi, so the next pod it
creates starts with those again. **The template is still where requests live**; in-place resize is for
reacting without a restart, and the template is where the change is made to last.
