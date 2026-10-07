---
title: A clean shutdown and a copy somewhere else
version: 1
---

The volume survived a deleted pod. **It does not survive a deleted claim, a lost node, a bad migration
or somebody's `DROP TABLE`**, and none of those is rare. A database needs a copy of its data that
lives somewhere else and that has been tested by restoring it.

## A backup as a Job

PostgreSQL's own tool for a logical copy is `pg_dump`, and a Job, from lesson 12, is the natural way
to run it in the cluster: it connects to `pg-0` by its own DNS name and exits.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pg-dump
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: dump
        image: postgres:18
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: pg
              key: password
        command: ["sh", "-c", "pg_dump -h pg-0.pg -U postgres -t orders postgres | grep -E 'CREATE TABLE|^COPY|^[0-9]'"]
```

The `grep` is there so the capture fits on a screen; a real backup Job writes the whole dump to a
place outside the cluster, such as an object storage bucket, and a CronJob runs it on a schedule.

```
ana@laptop:~/shop$ kubectl apply -f backup.yaml
job.batch/pg-dump created
ana@laptop:~/shop$ kubectl logs job/pg-dump
CREATE TABLE public.orders (
COPY public.orders (id, total_cents) FROM stdin;
1	4990
2	12900
```

The table's definition and both rows, as text that `psql` can replay into an empty database. A dump
like this is consistent, small and portable between versions. For large databases, physical backups
with continuous archiving of the write-ahead log restore faster and to any moment, and that is the
work of a dedicated tool or of an operator, below.

## Shutting down cleanly

When `pg-0` was deleted, the kubelet sent PostgreSQL a SIGTERM and waited. Its log, followed from a
second terminal while the pod went away, shows what PostgreSQL did with that time:

```
ana@laptop:~/shop$ grep -E "fast shutdown|checkpoint starting: shutdown|database system is shut down" pg-0.log | tail -n 3
2026-10-06 20:43:45.967 UTC [1] LOG:  received fast shutdown request
2026-10-06 20:43:45.977 UTC [72] LOG:  checkpoint starting: shutdown immediate
2026-10-06 20:43:46.007 UTC [1] LOG:  database system is shut down
```

**A fast shutdown with a checkpoint**: PostgreSQL wrote everything in memory to disk and stopped, in
forty milliseconds here. A large, busy database can take far longer, which is why the manifest
raised the grace period. If the grace period runs out, the kubelet sends SIGKILL, and the next start
has to recover from the write-ahead log: no committed data is lost, but start-up is slower, and a
failure during that recovery is one more thing to go wrong.
