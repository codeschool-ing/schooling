---
title: Blue-green is one selector
version: 1
---

Blue-green takes the opposite bet from a canary. **Both versions run in full, and all traffic moves in
one step**, so the new version is never half-deployed, and going back is the same step in reverse.
The price is running two full copies of the application while the switch is pending.

In Kubernetes the switch can be the one field a Service already has, its selector. Two Deployments,
labelled `colour: blue` and `colour: green`, and one Service pointing at blue:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-blue
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
      colour: blue
  template:
    metadata:
      labels:
        app: shop
        colour: blue
    spec:
      containers:
      - name: shop
        image: shop:1.1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-green
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
      colour: green
  template:
    metadata:
      labels:
        app: shop
        colour: green
    spec:
      containers:
      - name: shop
        image: shop:2.0
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
    colour: blue
  ports:
  - port: 80
    targetPort: 8080
```

The route from the previous section now sends everything to this Service.

```
ana@laptop:~/shop$ kubectl apply -f blue-green.yaml
deployment.apps/shop-blue created
deployment.apps/shop-green created
service/shop created
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/
shop 1.1 on shop-blue-5cb5cf758-h2pzq
```

Blue, version 1.1, is live. Green, version 2.0, is running and ready, and receives nothing, so it can be
tested directly, through its own Service or a port-forward, before anybody depends on it. Then the
switch:

```
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"selector":{"app":"shop","colour":"green"}}}'
service/shop patched
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    200 shop 2.0
```

**All 200 on 2.0, from one patch.** And the way back:

```
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"selector":{"app":"shop","colour":"blue"}}}'
service/shop patched
ana@laptop:~/shop$ for i in $(seq 200); do curl -s -H "Host: shop.example.test" localhost:8080/; done | cut -d" " -f1,2 | sort | uniq -c
    200 shop 1.1
```

Blue was never touched, so the rollback took as long as the switch: one field. A rolling update cannot
do that, because by the time a problem shows, the old pods are gone and have to be started again.

| | rolling update (lesson 35) | canary | blue-green |
|---|---|---|---|
| who sees the new version first | everybody, a pod at a time | a chosen share | everybody, at once |
| extra capacity needed | one surge pod or so | the canary's pods | a whole second copy |
| going back | another rollout | weight to zero | one selector |
| needs | a Deployment | a router that splits by weight | two Deployments and a Service |

**What none of the three solves is the database.** Two versions serving at once, or switching back
after the new one has written data, both assume the schema works for old and new code alike. Changes
to the schema are made in steps that keep that true, which is a matter of how the application is
written rather than of how it is deployed.
