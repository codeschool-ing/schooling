---
title: The kubelet protects its node
version: 1
---

Every kubelet watches its node for running out of something, and reports what it sees as conditions:

```
ana@laptop:~/shop$ kubectl describe node shop-worker | grep -A 7 "^Conditions"
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:12 -0300   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:12 -0300   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:12 -0300   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:27 -0300   KubeletReady                 kubelet is posting ready status
Addresses:
```

**`MemoryPressure`, `DiskPressure` and `PIDPressure` are the three a kubelet acts on.** When one turns
`True`, the kubelet evicts pods until the node is safe again, starting with the pods using most above
what they requested; that is the ordering lesson 19's quality-of-service classes described. A node
under pressure also gets a taint, so nothing new is placed there meanwhile.

Filling a whole node to watch that would take minutes and disturb every other capture. A single pod
can show the same mechanism against its own limit, on the resource people forget: the disk a
container writes to outside any volume.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scribbler
spec:
  restartPolicy: Never
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "dd if=/dev/zero of=/tmp/fill bs=1M count=80; sleep 3600"]
    resources:
      limits:
        ephemeral-storage: 50Mi
```

`ephemeral-storage` is the third resource a container can request and limit, after CPU and memory.
It covers the container's writable layer, its logs and any `emptyDir`. This pod writes 80 MiB into
`/tmp` against a limit of 50.

```
ana@laptop:~/shop$ kubectl apply -f scribbler.yaml
pod/scribbler created
ana@laptop:~/shop$ kubectl get pod scribbler
NAME        READY   STATUS   RESTARTS   AGE
scribbler   0/1     Error    0          30s
ana@laptop:~/shop$ kubectl get pod scribbler -o jsonpath="{.status.reason}: {.status.message}"; echo
Evicted: Pod ephemeral local storage usage exceeds the total limit of containers 50Mi. 
```

**`Evicted`, with the reason spelled out.** The kubelet measures disk use every few seconds, saw the
pod over its limit and removed it. Unlike a memory limit, which the kernel enforces the instant it is
crossed, this is a check by the kubelet, which is why the pod could write past the limit first. The
pod is not restarted in place: an evicted pod is finished, and only a controller such as a Deployment
would replace it, with a new pod.

| what runs out | who acts | what the pod sees |
|---|---|---|
| a container's memory limit | the kernel | `OOMKilled`, restarted in place (lesson 19) |
| a container's ephemeral-storage limit | the kubelet | `Evicted`, pod finished |
| the node's memory or disk | the kubelet | `Evicted`, pods over their requests first, then lower priority |
