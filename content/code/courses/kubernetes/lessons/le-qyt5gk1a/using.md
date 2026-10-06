---
title: Creating Backups, and what the API server checks
version: 1
---

A Backup is written like any manifest, with the new group and kind:

```yaml
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: orders-nightly
spec:
  database: orders
  schedule: "0 3 * * *"
```

```
ana@laptop:~/shop$ kubectl apply -f nightly.yaml
backup.shop.example.test/orders-nightly created
ana@laptop:~/shop$ kubectl get backups
NAME             DATABASE   SCHEDULE    KEEP   LAST RUN
orders-nightly   orders     0 3 * * *   7      
ana@laptop:~/shop$ kubectl get bk orders-nightly -o jsonpath="{.spec}"; echo
{"database":"orders","keep":7,"schedule":"0 3 * * *"}
```

The printer columns from the definition make `kubectl get` useful, and `KEEP` says 7 although the
manifest never mentioned it: **the schema's default was written into the object when it was stored**,
as the `-o jsonpath` view of the spec confirms.

## Refused at the door

The schema is enforced by the API server on every write, before anything is stored:

```yaml
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: forever
spec:
  database: orders
  schedule: "0 3 * * *"
  keep: 365
  compress: true
```

```
ana@laptop:~/shop$ kubectl apply -f bad.yaml
Error from server (BadRequest): error when creating "bad.yaml": Backup in version "v1" cannot be handled as a Backup: strict decoding error: unknown field "spec.compress"
ana@laptop:~/shop$ sed '/compress/d' bad.yaml | kubectl apply -f -
The Backup "forever" is invalid: spec.keep: Invalid value: 365: spec.keep in body should be less than or equal to 30
```

Two problems, and two refusals. The first attempt names the unknown field, `compress`: kubectl asks
the server for strict validation, so a field the schema does not list is an error instead of being
silently dropped. With that line removed, the second attempt names the next problem, `keep` above its
maximum of 30. **A typo in a field name is the most common mistake in any manifest**, and a schema is
what turns it from a setting that quietly does nothing into an error with a line to fix.

## Spec and status

`spec` is what a person wants; `status` is what a program reports. With the status subresource
enabled, they are written through different routes:

```
ana@laptop:~/shop$ kubectl patch backup orders-nightly --subresource=status --type=merge -p '{"status":{"lastRun":"2026-10-06T03:00:00Z"}}'
backup.shop.example.test/orders-nightly patched
ana@laptop:~/shop$ kubectl get backups
NAME             DATABASE   SCHEDULE    KEEP   LAST RUN
orders-nightly   orders     0 3 * * *   7      2026-10-06T03:00:00Z
ana@laptop:~/shop$ kubectl patch backup orders-nightly --type=merge -p '{"status":{"lastRun":"never"}}'
backup.shop.example.test/orders-nightly patched (no change)
ana@laptop:~/shop$ kubectl get backups
NAME             DATABASE   SCHEDULE    KEEP   LAST RUN
orders-nightly   orders     0 3 * * *   7      2026-10-06T03:00:00Z
```

The first patch went through `--subresource=status` and the `LAST RUN` column filled in. The second
tried to set `status` through the main route and was ignored: `(no change)`. That separation is what
lets RBAC give a controller the right to report status without the right to change what people
asked for, and people the opposite.

## What a CRD does not do

```
ana@laptop:~/shop$ kubectl get jobs,cronjobs
No resources found in default namespace.
ana@laptop:~/shop$ kubectl get --raw /apis/shop.example.test/v1/namespaces/default/backups/orders-nightly | head -c 160; echo
{"apiVersion":"shop.example.test/v1","kind":"Backup","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"shop.examp
```

**No Job, no CronJob, nothing.** The Backup says a backup should run every night at three, and the
cluster has stored that sentence and will return it to anybody who asks. Nothing reads it. A CRD adds a
noun to the API; the verb, the program that watches Backups and makes backups happen, is a controller,
and writing one is lesson 44.
