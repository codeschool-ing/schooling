---
title: A name that survives the pod
version: 1
---

**A Deployment's promise is a number; a StatefulSet's promise is a set of names.** Ask for three
replicas of `db` and you get exactly `db-0`, `db-1` and `db-2`, never a random suffix, and if `db-1`
disappears the pod that replaces it is called `db-1` again. That is what a replicated database, a
message broker or anything that elects a leader needs: every member knows which member it is, and
the others can find it by that name.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db
spec:
  clusterIP: None
  selector:
    app: db
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: db
        image: busybox:1.37
        command: ["sh", "-c", "[ -f /data/born ] || hostname > /data/born; exec sleep 3600"]
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 64Mi
```

Two objects again, and the first is what makes the names reachable. A Service with
`clusterIP: None` is **headless**: it gets no address of its own, and its DNS name answers with the
pods' addresses instead, one record per pod. `serviceName: db` ties the StatefulSet to it. The
container is a stand-in for a database: on its first start it writes its own hostname into
`/data/born`, and then waits.

```
ana@laptop:~/shop$ kubectl apply -f db.yaml
service/db created
statefulset.apps/db created
ana@laptop:~/shop$ kubectl get pods -l app=db -o custom-columns=NAME:.metadata.name,STARTED:.status.startTime,NODE:.spec.nodeName
NAME   STARTED                NODE
db-0   2026-10-06T16:49:56Z   shop-worker
db-1   2026-10-06T16:50:00Z   shop-worker2
db-2   2026-10-06T16:50:05Z   shop-worker2
```

**The pods started one at a time, in order**: `db-0` at 16:49:56, `db-1` four seconds later, `db-2`
five after that. A StatefulSet does not start a pod until the one before it is running and ready,
which is what a database cluster wants when the first member has to exist before the others can
join it. Scaling down goes the other way, from the highest number.

## Finding a member by name

```
ana@laptop:~/shop$ kubectl run probe --image=busybox:1.37 --restart=Never --command -- sleep 600
pod/probe created
ana@laptop:~/shop$ kubectl exec probe -- nslookup db-1.db.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	db-1.db.default.svc.cluster.local
Address: 10.244.1.3


ana@laptop:~/shop$ kubectl exec probe -- nslookup db.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	db.default.svc.cluster.local
Address: 10.244.2.3
Name:	db.default.svc.cluster.local
Address: 10.244.1.5
Name:	db.default.svc.cluster.local
Address: 10.244.1.3
```

`db-1.db.default.svc.cluster.local` is one pod — the first label is the pod's name, the second the
headless Service, then the namespace — and it answers with that pod's address and nothing else. The
Service's own name answers with all three. The address behind `db-1` will change the next time the
pod is replaced; **the name will not**, and that is the whole point of using it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The headless Service db has no address of its own. Its DNS name lists three pods, and each pod has a name of its own: db-0.db, db-1.db and db-2.db. Below each pod is its own claim, data-db-0, data-db-1 and data-db-2. Arrows show the order the pods start in, 0 then 1 then 2.\"><defs><marker id=\"sts-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sts-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sts-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"220\" y=\"16\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db</text><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">headless Service: no address of its own</text><rect x=\"40\" y=\"110\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db-0</text><text x=\"130.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">db-0.db</text><path d=\"M360 62 L130 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-amber)\"></path><rect x=\"40\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-db-0</text><text x=\"130.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own claim</text><path d=\"M130 156 L130 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222 132 L268 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-phosphor)\"></path><rect x=\"270\" y=\"110\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db-1</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">db-1.db</text><path d=\"M360 62 L360 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-amber)\"></path><rect x=\"270\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-db-1</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own claim</text><path d=\"M360 156 L360 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M452 132 L498 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-phosphor)\"></path><rect x=\"500\" y=\"110\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db-2</text><text x=\"590.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">db-2.db</text><path d=\"M360 62 L590 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sts-ah-amber)\"></path><rect x=\"500\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-db-2</text><text x=\"590.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own claim</text><path d=\"M590 156 L590 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">starts after the one before is ready</text></svg>", "caption": "Each name has its own address record and its own disk. The pod behind a name can be replaced; the name and the disk stay."}
```
