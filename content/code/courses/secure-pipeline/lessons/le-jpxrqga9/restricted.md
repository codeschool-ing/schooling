---
title: A namespace that refuses what a pod does not set
version: 1
---

Kubernetes, left to itself, runs a pod the way `docker run` runs a container: as whatever user the
image names, with the runtime's default capabilities and a writable root. **Pod Security Admission
is the part of the API server that can refuse such a pod**, and it is switched on per namespace with
a label. `kubernetes` lesson 25 compared its three profiles, `privileged`, `baseline` and
`restricted`; linkbox gets the strictest one, and the interesting part is what it refuses and where.

### The label

```
ana@vm:~/linkbox$ kubectl create namespace linkbox
namespace/linkbox created
ana@vm:~/linkbox$ kubectl label namespace linkbox pod-security.kubernetes.io/enforce=restricted
namespace/linkbox labeled
```

`enforce` is one of three modes. `enforce` refuses, `warn` lets the object in and prints a warning to
whoever applied it, and `audit` writes an entry in the cluster's audit log. A namespace can carry
all three at different levels, which is how a team moves an existing namespace to `restricted`:
warn first, read the warnings, then enforce.

### A pod refused for what it does not say

Start linkbox in the namespace the quickest way, as a bare pod with nothing but the image:

```
ana@vm:~/linkbox$ kubectl run probe -n linkbox --image=localhost:5000/linkbox:main
Error from server (Forbidden): pods "probe" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "probe" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "probe" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "probe" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "probe" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

**Refused, with a list of four things the pod did not set.** None of them is wrong in the image:
lesson 8 made it run as 65532, and it needs no capability and no writable root. The profile does
not inspect the image, though. It reads the pod's specification, and a pod that does not *say*
it will not escalate, will drop its capabilities, will run as non-root and will use the default
seccomp profile is a pod that could do all four. **The restricted profile asks for statements, not
for good behaviour.**

### A Deployment let in, and its pods refused

The same image as a Deployment, which is how linkbox will really run:

```
ana@vm:~/linkbox$ kubectl create deployment plain -n linkbox --image=localhost:5000/linkbox:main
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "linkbox" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "linkbox" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "linkbox" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "linkbox" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
deployment.apps/plain created
ana@vm:~/linkbox$ kubectl get deployment,replicaset,pod -n linkbox
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/plain   0/1     0            0           3s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/plain-5bfc78fc94   1         0         0       3s
ana@vm:~/linkbox$ kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{.items[0].message}{"\n"}'
Error creating: pods "plain-5bfc78fc94-k7nrf" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "linkbox" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "linkbox" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "linkbox" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "linkbox" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
ana@vm:~/linkbox$ kubectl delete deployment plain -n linkbox
deployment.apps "plain" deleted from linkbox namespace
```

This is the case that catches people. **`kubectl` printed a warning and created the Deployment**,
because Pod Security Admission judges pods, and a Deployment is not one. Its ReplicaSet then tried
to create the pod and was refused, out of sight: the Deployment shows `0/1`, there is no pod at
all, and the reason is only in the namespace's events. Nobody watching the `kubectl apply` in a
pipeline sees a failure. A deploy step that checks nothing after `apply` would report success for a
service that is not running.

Two habits follow. **Wait for the rollout, and fail if it does not finish**, which `kubectl rollout
status` does and which the next section uses. And when something must be refused at the moment it
is applied, check the Deployment itself, which is what this lesson's own admission rule does in the
section after next.

