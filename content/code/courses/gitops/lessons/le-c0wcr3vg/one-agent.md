---
title: One agent at a time
version: 1
---

**Two reconcilers for the same objects is lesson 2's "two truths" with two machines doing the
fighting**, so Argo CD leaves before Flux arrives. This lesson starts from the cluster as lesson 3
left it, and the first job is retiring Argo CD without taking staging down with it.

The order matters. An Application deleted with Argo CD's cascade would delete the objects it
manages; these Applications were created without the finalizer that asks for that, so deleting
them leaves staging running. The root goes first, so that nothing recreates the others, then the
rest, then Argo CD itself:

```
ana@laptop:~$ kubectl delete -f ~/setup/root.yaml
application.argoproj.io "root" deleted from argocd namespace
ana@laptop:~$ kubectl -n argocd delete applications --all
application.argoproj.io "bulletin-staging" deleted from argocd namespace
ana@laptop:~$ kubectl delete -k ~/setup/argocd | tail -n 2
networkpolicy.networking.k8s.io "argocd-repo-server-network-policy" deleted from argocd namespace
networkpolicy.networking.k8s.io "argocd-server-network-policy" deleted from argocd namespace
ana@laptop:~$ kubectl get namespace argocd
NAME     STATUS   AGE
argocd   Active   79s
ana@laptop:~$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-657dd4685b-6jx4n   1/1     Running   0          82s
bulletin-657dd4685b-hdznv   1/1     Running   0          81s
bulletin-657dd4685b-zxh6n   1/1     Running   0          81s
```

`namespace "argocd" not found`: every part of it is gone, its resource types included. Staging's
three pods never noticed, because nothing deleted them. They still carry Argo CD's tracking
annotation, which nobody reads now and Flux will leave alone.

## Retiring a machine's access

Argo CD had a Gitea account with read access to `fleet`, and a token for it sits in `~/argocd.token`.
A retired system's credentials are one of the classic ways into an organisation: **nobody remembers
they exist, so nobody notices them being used.** Take the access away the day the system goes:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -X DELETE -H "$AS_ANA" $API/collaborators/argocd
204
```

`204`, and the token is now a key to nothing. Lesson 11 makes that a habit rather than a
remembered step.

The `argocd/` directory in `fleet` describes Applications nothing applies any more. A file in the
repository that no agent reads is a description that will silently stop being true, so it goes too,
in the same pull request that brings Flux in.
