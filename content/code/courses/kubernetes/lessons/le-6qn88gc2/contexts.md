---
title: The file that knows where every cluster is
version: 1
---

kubectl does not know about clusters. It reads a **kubeconfig**, `~/.kube/config` unless told
otherwise, which holds three lists and a pointer: clusters (an address and a CA), users (a
credential), contexts (a cluster, a user and an optional namespace, under one name), and
`current-context`, the one used when you say nothing. Lesson 7 used one context. Here there are two
clusters, made one after the other, and kind added each to the same file:

```
ana@laptop:~/shop$ kubectl config get-contexts
CURRENT   NAME        CLUSTER     AUTHINFO    NAMESPACE
*         kind-eu     kind-eu     kind-eu     
          kind-shop   kind-shop   kind-shop   
ana@laptop:~/shop$ kubectl config current-context
kind-eu
ana@laptop:~/shop$ kubectl --context kind-shop get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   70s   v1.37.0
shop-worker          Ready    <none>          56s   v1.37.0
shop-worker2         Ready    <none>          56s   v1.37.0
ana@laptop:~/shop$ kubectl --context kind-eu get nodes
NAME               STATUS   ROLES           AGE   VERSION
eu-control-plane   Ready    control-plane   31s   v1.37.0
eu-worker          Ready    <none>          16s   v1.37.0
eu-worker2         Ready    <none>          16s   v1.37.0
```

**The current context is whichever was touched last**, which is `kind-eu` only because it was made
second. `--context` sends one command somewhere else without moving the pointer. The two clusters have
the same shape and nothing else in common, and the file shows the only thing that separates them for
kubectl, an address:

```
ana@laptop:~/shop$ kubectl config view -o jsonpath='{range .clusters[*]}{.name}{"  "}{.cluster.server}{"\n"}{end}'
kind-eu  https://127.0.0.1:46033
kind-shop  https://127.0.0.1:34351
```

## The command that went to the wrong cluster

The pointer is shared by every terminal that reads the file, and it changes silently. That is how the
classic incident happens: a person switches to look at production in one window, then runs a delete in
another, believing it still points at staging. First the same Deployment in both clusters, each
command sent with `--context`:

```
ana@laptop:~/shop$ for c in kind-shop kind-eu; do kubectl --context $c create deployment shop --image=shop:1.0 --replicas=2; done
deployment.apps/shop created
deployment.apps/shop created
ana@laptop:~/shop$ for c in kind-shop kind-eu; do echo "== $c"; kubectl --context $c get pods -l app=shop -o wide | cut -c1-90; done
== kind-shop
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOM
shop-774b84ff8c-f82k7   1/1     Running   0          3s    10.244.1.3   shop-worker    <no
shop-774b84ff8c-l68m9   1/1     Running   0          3s    10.244.2.3   shop-worker2   <no
== kind-eu
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE         NOMIN
shop-774b84ff8c-29x6l   1/1     Running   0          3s    10.244.1.3   eu-worker    <none
shop-774b84ff8c-dhw8l   1/1     Running   0          3s    10.244.2.3   eu-worker2   <none
```

Then the pointer is moved, and a delete is sent with no cluster named:

```
ana@laptop:~/shop$ kubectl config use-context kind-shop
Switched to context "kind-shop".
ana@laptop:~/shop$ kubectl delete deployment shop
deployment.apps "shop" deleted from default namespace
ana@laptop:~/shop$ for c in kind-shop kind-eu; do echo "$c: $(kubectl --context $c get deployments --no-headers 2>/dev/null | wc -l) deployment(s)"; done
kind-shop: 0 deployment(s)
kind-eu: 1 deployment(s)
```

The `delete` named no cluster, so it went to the current one. **It was right here only because the
line before it had just set the context.** Three habits keep this from going wrong:

- **Scripts and pipelines always pass `--context`**, or use a kubeconfig of their own with exactly one
  context in it. A pipeline that relies on the pointer depends on whatever ran before it.
- **The prompt shows the current context**, so the answer is on screen before the command is typed.
- **Production credentials live in a separate file**, set through `KUBECONFIG` for the session that
  needs them, so a stray command elsewhere cannot reach them.
