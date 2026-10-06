---
title: Refusing the pods that forget
version: 1
---

A security context protects the pods that carry one. **The cluster's job is to refuse the ones that
do not**, and the built-in way is Pod Security Admission: a check inside the API server that compares
every pod with one of three published levels, the Pod Security Standards.

| level | what it refuses |
|---|---|
| `privileged` | nothing |
| `baseline` | the known escalations: privileged containers, the host's network or processes, host paths, added dangerous capabilities |
| `restricted` | everything `baseline` refuses, plus root, privilege escalation, any capability but `NET_BIND_SERVICE`, and a missing seccomp profile |

The level is chosen per namespace, with a label. There are three modes, and a namespace can carry all
three at different levels: `enforce` refuses, `warn` lets the pod in and prints a warning, `audit`
writes it to the audit log.

```
ana@laptop:~/shop$ kubectl create namespace payments
namespace/payments created
ana@laptop:~/shop$ kubectl label namespace payments pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/warn=restricted
namespace/payments labeled
```

`payments` now enforces `restricted`. The plain busybox pod from the previous section tries to run
there:

```
ana@laptop:~/shop$ kubectl -n payments run plain --image=busybox:1.37 --restart=Never --command -- sleep 3600
Error from server (Forbidden): pods "plain" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "plain" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "plain" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "plain" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "plain" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

**Refused, with every reason in one message**, which reads like a checklist of the hardened pod's
fields. And that pod, unchanged except for its namespace, is let in:

```
ana@laptop:~/shop$ sed "s/name: hardened/name: hardened\n  namespace: payments/" hardened.yaml | kubectl apply -f -
pod/hardened created
```

## Trying a level before enforcing it

Labelling an existing namespace does not touch the pods already running in it; it applies to new
ones. To find out what a level would break before switching it on, ask the API server with a dry run:

```
ana@laptop:~/shop$ kubectl label --dry-run=server --overwrite namespace default pod-security.kubernetes.io/enforce=baseline
namespace/default labeled (server dry run)
ana@laptop:~/shop$ kubectl label --dry-run=server --overwrite namespace default pod-security.kubernetes.io/enforce=restricted
Warning: existing pods in namespace "default" violate the new PodSecurity enforce level "restricted:latest"
Warning: plain: allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
namespace/default labeled (server dry run)
```

`baseline` would accept everything already in `default`. `restricted` would not, and the warning
names `plain` and why. **A dry run on the server is the safe way to roll this out**: label each
namespace with `warn` first, read what it reports for a while, and only then add `enforce`.

Pods are not the only way in. With `warn` on, a Deployment's pod template is checked too and the
warning comes back at once; `enforce` acts on pods only, so its refusal happens when the ReplicaSet
tries to create them, and shows up as an event on it, like the quota refusals in lesson 20.
