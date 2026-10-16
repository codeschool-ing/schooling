---
title: The value changes, the commit does not
version: 1
---

**The ExternalSecret reads Vault every minute**, so a new value in Vault reaches the cluster with
nothing in Git changing. A new token is put in Vault:

```
ana@laptop:~/fleet$ kubectl -n production get pods -o name
pod/bulletin-55bcbd4ddb-5swsk
pod/bulletin-55bcbd4ddb-8dz75
pod/bulletin-55bcbd4ddb-d56sj
ana@laptop:~/fleet$ vault kv put secret/bulletin/production token=$(openssl rand -hex 16) | grep -E "^(version|created_time)"
created_time       2026-10-16T03:52:57.270537885Z
version            2
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-55bcbd4ddb-5swsk
token: sha256:b92fc7e037ca
ana@laptop:~/fleet$ kubectl -n production get pods -o name
pod/bulletin-55bcbd4ddb-5swsk
pod/bulletin-55bcbd4ddb-8dz75
pod/bulletin-55bcbd4ddb-d56sj
ana@laptop:~/fleet$ vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12
b92fc7e037ca
```

Version 2 of the entry, and the pod prints its fingerprint, `b92fc7e037ca`, which is what Vault now
holds. The three pods have the names they had before the change.

Two delays add up, and both are worth knowing before an incident. The operator notices at its next
refresh, up to the `refreshInterval`. Then the kubelet updates the file in every pod that mounts the
Secret, at its next sync, which is about a minute by default. **No pod restarted**: the name in the
`pod:` line did not change. A program that reads the file on every request, as `bulletin` does, sees
the new value; a program that read it once at start keeps the old one until it restarts, and that is
a property of the program, not of the operator. Environment variables are the worst case: they are
fixed when the container starts, whatever the Secret says afterwards.

What Git records is that production reads `bulletin/production` from Vault, every minute. What the
value was at three in the afternoon, and who changed it, is in Vault's history and in its audit log,
which lesson 12 turns on.
