---
title: What a running pod sees when the ConfigMap changes
version: 1
---

The shop is closing on Sunday, so Ana changes the greeting file and the greeting variable, both
the declarative way: generate the object, then apply it.

```
Closed for stocktaking on Sunday.
```

```
ana@laptop:~/shop$ kubectl create configmap shop-files --from-file=greeting=greeting.txt --dry-run=client -o yaml | kubectl apply -f -
Warning: resource configmaps/shop-files is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
configmap/shop-files configured
ana@laptop:~/shop$ kubectl create configmap shop-config --from-literal=GREETING="Ana's new shop" --from-literal=CURRENCY=BRL --dry-run=client -o yaml | kubectl apply -f -
Warning: resource configmaps/shop-config is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
configmap/shop-config configured
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's shop
/etc/shop/greeting: Welcome back. Orders placed before 18:00 ship today.
```

Both ConfigMaps say `configured`. The warnings are about the earlier `kubectl create`, which kept no
copy of the file for `apply` to compare against (lesson 7), and they are harmless here. **And the
running shop still says exactly what it said before**, variable and file alike.

## The file follows, eventually

The script kept asking until the file changed, and timed it: **about 86 seconds**. Then:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's shop
/etc/shop/greeting: Closed for stocktaking on Sunday.
```

The file now says `Closed for stocktaking on Sunday`, with nobody restarting anything. The kubelet
refreshes mounted ConfigMaps on its own schedule, by default within about a minute plus the time its
cache takes to notice, so a delay of a minute or two is normal and nothing promises it shorter.
**The variable has not changed, and it never will in this container**: an environment variable is
copied into a process when it starts, and no process anywhere can have its environment changed from
outside.

## The variable follows a new pod

```
ana@laptop:~/shop$ kubectl rollout restart deployment/shop
deployment.apps/shop restarted
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's new shop
/etc/shop/greeting: Closed for stocktaking on Sunday.
```

`rollout restart` replaces the pods with new ones from the same template, the way an update would,
and the new container started with `GREETING=Ana's new shop`. So a change of configuration needs
one of two things: **a program that rereads its files**, or **a rollout**. Doing a rollout on every
ConfigMap change is common enough that lesson 38's Kustomize can name each version of a ConfigMap
after a hash of its content, so that a change makes a new name, which changes the template, which
starts a rollout by itself.

## A ConfigMap that cannot change

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prices-2026-10
immutable: true
data:
  shipping: "19.90"
```

```
ana@laptop:~/shop$ kubectl apply -f frozen.yaml
configmap/prices-2026-10 created
ana@laptop:~/shop$ kubectl patch configmap prices-2026-10 -p '{"data":{"shipping":"0.00"}}'
The ConfigMap "prices-2026-10" is invalid: data: Forbidden: field is immutable when `immutable` is set
```

**`immutable: true` turns the ConfigMap into a fact.** The API server refuses to edit its data; the
only way to change it is to delete it and create another, which is the same thing as making a new
version with a new name. It costs nothing to read and the kubelet stops watching it for changes, which
matters in a cluster with thousands of pods, and it removes the case where a running pod's file
changes under it unexpectedly.
