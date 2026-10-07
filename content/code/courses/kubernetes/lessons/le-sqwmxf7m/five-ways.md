---
title: Five pods, five ways to fail
version: 1
---

One file, five pods, each wrong in its own way:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: typo
spec:
  containers:
  - name: shop
    image: shop:1.O
---
apiVersion: v1
kind: Pod
metadata:
  name: crashing
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: CRASH
      value: "yes"
---
apiVersion: v1
kind: Pod
metadata:
  name: greedy
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: "64"
---
apiVersion: v1
kind: Pod
metadata:
  name: unconfigured
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: GREETING
      valueFrom:
        configMapKeyRef:
          name: shop-settings
          key: greeting
---
apiVersion: v1
kind: Pod
metadata:
  name: never-ready
spec:
  containers:
  - name: shop
    image: shop:1.0
    readinessProbe:
      httpGet:
        path: /ready
        port: 9090
      periodSeconds: 3
```

```
ana@laptop:~/shop$ kubectl apply -f broken.yaml
pod/typo created
pod/crashing created
pod/greedy created
pod/unconfigured created
pod/never-ready created
ana@laptop:~/shop$ kubectl get pods
NAME           READY   STATUS                       RESTARTS      AGE
crashing       0/1     Error                        3 (45s ago)   60s
greedy         0/1     Pending                      0             60s
never-ready    0/1     Running                      0             60s
typo           0/1     ErrImagePull                 0             60s
unconfigured   0/1     CreateContainerConfigError   0             60s
```

**`kubectl get pods` is the first look, and its STATUS column already sorts the problems into
families.** Each name says which part of the pod's life failed:

| status | the pod got as far as | look next at |
|---|---|---|
| `Pending` | being stored; no node accepted it | the scheduler's events |
| `ErrImagePull`, `ImagePullBackOff` | a node, which could not fetch the image | the pod's events |
| `CreateContainerConfigError` | a node and an image; the container could not be configured | the waiting message |
| `Error`, `CrashLoopBackOff` | a running process, which exited | the container's logs |
| `Running` but `0/1` ready | a running process the readiness probe rejects | the probe's events |

## The image that does not exist

`shop:1.O`, with a capital letter O where a zero belongs. The node tried to fetch it from Docker Hub,
the registry an image name with no host means:

```
ana@laptop:~/shop$ kubectl describe pod typo | sed -n '/^Events/,$p'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  60s                default-scheduler  Successfully assigned default/typo to shop-worker2
  Normal   Pulling    20s (x3 over 59s)  kubelet            spec.containers{shop}: Pulling image "shop:1.O"
  Warning  Failed     20s (x3 over 59s)  kubelet            spec.containers{shop}: Failed to pull image "shop:1.O": failed to pull and unpack image "docker.io/library/shop:1.O": failed to resolve reference "docker.io/library/shop:1.O": failed to do request: Head "https://registry-1.docker.io/v2/library/shop/manifests/1.O": tls: failed to verify certificate: x509: certificate signed by unknown authority
  Warning  Failed     20s (x3 over 59s)  kubelet            spec.containers{shop}: Error: ErrImagePull
  Normal   BackOff    7s (x3 over 59s)   kubelet            spec.containers{shop}: Back-off pulling image "shop:1.O"
  Warning  Failed     7s (x3 over 59s)   kubelet            spec.containers{shop}: Error: ImagePullBackOff
```

**The events tell the whole story in order**: scheduled, pulling, failed, back-off. The failure
message names the reference it tried, `docker.io/library/shop:1.O`. The nodes of the machine this course
was recorded on cannot reach any registry at all, so the request fails before the registry could
answer. On your nodes, which do reach Docker Hub, the end of the line says instead that there is no
such image. Either way the fix is the same, and the
reference in the message is where the typo shows.

`ImagePullBackOff` means the kubelet is waiting longer between attempts, up to five minutes. It keeps
trying, because a missing image is sometimes only not pushed yet.

## The process that exits

```
ana@laptop:~/shop$ kubectl logs crashing
2026-10-06T21:28:47Z shop 1.0: CRASH is set, exiting with status 1
ana@laptop:~/shop$ kubectl get pod crashing -o jsonpath="{.status.containerStatuses[0].lastState.terminated.exitCode} {.status.containerStatuses[0].restartCount}"; echo
1 3
```

**`kubectl logs` shows what the process wrote before it died**, and the shop says why itself. Exit
code 1 and three restarts within the minute: the kubelet restarts it with growing pauses, which is
what `CrashLoopBackOff` means. When the current container has just restarted and has written nothing
yet, `kubectl logs --previous` reads the one before.
