---
title: A release, its revisions and its rollback
version: 1
---

Installing a chart makes a **release**: a name, the rendered objects, and a record of what was
installed.

```
ana@laptop:~/shop$ helm install shop shop-chart
NAME: shop
LAST DEPLOYED: Tue Oct  6 18:05:37 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
ana@laptop:~/shop$ helm list
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART     	APP VERSION
shop	default  	1       	2026-10-06 18:05:37.112905566 -0300 -03	deployed	shop-0.1.0	1.0        
```

```
ana@laptop:~/shop$ kubectl get deployment,service -l app.kubernetes.io/instance=shop
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/shop   2/2     2            2           1s
ana@laptop:~/shop$ kubectl get secret -l owner=helm
NAME                         TYPE                 DATA   AGE
sh.helm.release.v1.shop.v1   helm.sh/release.v1   1      1s
```

**The Deployment came back and the Service did not**, because the Service template carries no labels
at all, so a selector on `app.kubernetes.io/instance` cannot find it. Nothing is broken, the Service
exists, but every tool that finds a release's objects by label will miss it. The fix is to give every
template the same labels, which charts usually do with a shared helper template. This chart was
written by hand for this lesson, and the omission is kept because it is the most common one.

The last command shows where Helm keeps its record: a Secret per revision, in the release's
namespace, holding the rendered chart and the values. There is no Helm server; the cluster is the
database.

## Upgrade and history

```
ana@laptop:~/shop$ helm upgrade shop shop-chart --set image.tag=1.1 --set replicas=3
Release "shop" has been upgraded. Happy Helming!
NAME: shop
LAST DEPLOYED: Tue Oct  6 18:05:38 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete
TEST SUITE: None
ana@laptop:~/shop$ helm get values shop
USER-SUPPLIED VALUES:
image:
  tag: "1.1"
replicas: 3
ana@laptop:~/shop$ kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image} {.spec.replicas}"; echo
shop:1.1 3
```

`helm get values` shows only what was supplied on the command line, not the defaults, which is the
first thing to check when a release behaves differently from its chart.

```
ana@laptop:~/shop$ helm history shop
REVISION	UPDATED                 	STATUS    	CHART     	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 18:05:37 2026	superseded	shop-0.1.0	1.0        	Install complete
2       	Tue Oct  6 18:05:38 2026	deployed  	shop-0.1.0	1.0        	Upgrade complete
```

## Rollback

```
ana@laptop:~/shop$ helm rollback shop 1
Rollback was a success! Happy Helming!
ana@laptop:~/shop$ kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image} {.spec.replicas}"; echo
shop:1.0 2
ana@laptop:~/shop$ helm history shop
REVISION	UPDATED                 	STATUS    	CHART     	APP VERSION	DESCRIPTION     
1       	Tue Oct  6 18:05:37 2026	superseded	shop-0.1.0	1.0        	Install complete
2       	Tue Oct  6 18:05:38 2026	superseded	shop-0.1.0	1.0        	Upgrade complete
3       	Tue Oct  6 18:05:40 2026	deployed  	shop-0.1.0	1.0        	Rollback to 1   
```

**Back to 1.0 and two replicas, as revision 3.** A rollback does not rewind the history; it installs
an old revision's values and templates as a new revision, so the record stays complete. The Deployment
underneath did an ordinary rolling update, lesson 35's, in each direction.

## The same chart, twice

```
ana@laptop:~/shop$ helm install shop-staging shop-chart --set greeting=staging
NAME: shop-staging
LAST DEPLOYED: Tue Oct  6 18:05:42 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
ana@laptop:~/shop$ helm list
NAME        	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART     	APP VERSION
shop        	default  	3       	2026-10-06 18:05:40.841301695 -0300 -03	deployed	shop-0.1.0	1.0        
shop-staging	default  	1       	2026-10-06 18:05:42.414062852 -0300 -03	deployed	shop-0.1.0	1.0        
ana@laptop:~/shop$ helm uninstall shop-staging
release "shop-staging" uninstalled
ana@laptop:~/shop$ kubectl get deployment
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
shop   2/2     2            2           6s
```

A second release from the same chart, with its own name and its own greeting, lived beside the first
without touching it, because every name in the templates comes from the release. Uninstalling it
removed its objects and its history Secrets, and left `shop` alone.

| command | does |
|---|---|
| `helm template` | renders, touches nothing |
| `helm install NAME CHART` | renders and creates revision 1 |
| `helm upgrade NAME CHART --set …` | renders with new values, creates the next revision |
| `helm history NAME` | lists revisions |
| `helm rollback NAME N` | re-applies revision N as a new revision |
| `helm uninstall NAME` | deletes the objects and the history |

Charts are also how most third-party software is installed into clusters, from public repositories.
That is convenient and it is trust: a chart can create any object its installer is allowed to, so it
deserves the same reading as any other code you run, and `helm template` is how to read it.
