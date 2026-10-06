---
title: A StatefulSet keeps a name and a disk
version: 1
---

A Deployment's pods are interchangeable: random names, any node, and all of them sharing whatever
volume they mount. **A StatefulSet gives each pod an identity that survives replacement**: a fixed name
(`pg-0`, `pg-1`), a DNS name of its own, and a claim of its own that follows that name from one pod to
the next.

The password comes first, in a Secret as lesson 14 did it; this one is made up for the lab.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: pg
spec:
  clusterIP: None
  selector:
    app: pg
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pg
spec:
  serviceName: pg
  replicas: 1
  selector:
    matchLabels:
      app: pg
  template:
    metadata:
      labels:
        app: pg
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: postgres
        image: postgres:18
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pg
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres"]
          periodSeconds: 5
        resources:
          requests:
            cpu: 250m
            memory: 256Mi
          limits:
            memory: 512Mi
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

Three parts do the work:

- **`clusterIP: None`** makes `pg` a headless Service. It has no virtual address; instead, the DNS name
  `pg-0.pg` resolves straight to the pod, which is how a client, or a replica, reaches one particular
  copy.
- **`volumeClaimTemplates`** is a claim to be stamped out once per pod. `pg-0` gets `data-pg-0`, and
  if there were a `pg-1` it would get `data-pg-1`. The claims are never shared.
- **`terminationGracePeriodSeconds: 60`** gives PostgreSQL a minute to shut down cleanly, against the
  default of thirty seconds.

`PGDATA` points one level below the mount point, because the image's start-up script refuses a data
directory that already holds anything, and some volumes arrive with a `lost+found` in them.

```
ana@laptop:~/shop$ kubectl create secret generic pg --from-literal=password=lab-only-pg-91
secret/pg created
ana@laptop:~/shop$ kubectl apply -f postgres.yaml
service/pg created
statefulset.apps/pg created
ana@laptop:~/shop$ kubectl get pods,pvc -l app=pg
NAME       READY   STATUS    RESTARTS   AGE
pod/pg-0   1/1     Running   0          11s

NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-pg-0   Bound    pvc-08a1b18e-750d-42ca-a49e-08658371eddc   1Gi        RWO            standard       <unset>                 11s
```

One pod, `pg-0`, and one claim, `data-pg-0`, bound by kind's default class from lesson 26.

## The pod goes; the data stays

```
ana@laptop:~/shop$ kubectl exec pg-0 -- psql -U postgres -c "CREATE TABLE orders (id int PRIMARY KEY, total_cents int NOT NULL);"
CREATE TABLE
ana@laptop:~/shop$ kubectl exec pg-0 -- psql -U postgres -c "INSERT INTO orders VALUES (1, 4990), (2, 12900);"
INSERT 0 2
ana@laptop:~/shop$ kubectl delete pod pg-0
pod "pg-0" deleted from default namespace
ana@laptop:~/shop$ kubectl exec pg-0 -- psql -U postgres -c "SELECT * FROM orders;"
 id | total_cents 
----+-------------
  1 |        4990
  2 |       12900
(2 rows)
```

**The table and both rows came back.** The StatefulSet made a new `pg-0`, and the new `pg-0` mounted
`data-pg-0` again, because the claim belongs to the name and not to the pod. PostgreSQL started on
the files the old one left. Deleting the StatefulSet itself would not delete the claim either; claims
made from a template stay until somebody removes them, unless the StatefulSet's
`persistentVolumeClaimRetentionPolicy` says otherwise, because losing a database to a mistyped
`kubectl delete` is worse than tidying up by hand.
