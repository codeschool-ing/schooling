---
title: Who read which secret
version: 1
---

**Vault answers the question no other record here can: who read a secret, and when.** An audit
device writes every request and every response, before Vault acts on it, to a file, a socket or the
system log. It is off until somebody turns it on, and the first thing to know about it is the
property that makes it trustworthy: **if Vault cannot write to any audit device, it refuses the
request.** An unrecorded read is not possible.

Vault runs in a container, so the file goes inside it, in the directory the image prepares for logs:

```
ana@laptop:~/setup$ vault audit enable file file_path=/vault/logs/audit.log
Success! Enabled the file audit device at: file/
ana@laptop:~/setup$ vault audit list
Path     Type    Description
----     ----    -----------
file/    file    n/a
```

Now a read, the one the operator of lesson 10 makes every minute for production's token, and the
entry it left:

```
ana@laptop:~/setup$ docker exec vault cat /vault/logs/audit.log | jq -c 'select(.type == "response" and .request.path == "secret/data/bulletin/production") | {time, op: .request.operation, path: .request.path, role: .auth.metadata.role, account: .auth.metadata.service_account_name, namespace: .auth.metadata.service_account_namespace, token: .response.data.data.token}' | tail -n 1
{"time":"2026-10-16T04:54:43.748291356Z","op":"read","path":"secret/data/bulletin/production","role":"bulletin-production","account":"bulletin","namespace":"production","token":"hmac-sha256:4450a34b53860338c73f2618c5b0176d61311e6ab6ccd78cf0d8c4216716257a"}
ana@laptop:~/setup$ vault write -field=hash sys/audit-hash/file input="$(vault kv get -field=token secret/bulletin/production)"; echo
hmac-sha256:4450a34b53860338c73f2618c5b0176d61311e6ab6ccd78cf0d8c4216716257a
```

A read of `secret/data/bulletin/production`, by the Kubernetes role `bulletin-production`, as the
ServiceAccount `bulletin` in `production`. Where the token's value would be there is an
`hmac-sha256:` string, and Vault computes the same string for the value it holds, so the entry is
about that value without containing it.

**The values are not in the log.** Every string that could be a secret, the token Vault handed out
and the data it returned, is replaced by an HMAC: a keyed hash that Vault can recompute. So the log
can be shipped to a log service and read by an auditor without becoming a copy of every secret. When
somebody asks "was this particular token ever read?", `vault write sys/audit-hash/file input=...`
computes the same HMAC for a value you hold and you search the log for it.

What the entry does name, in clear, is the path, the operation, the time, and the identity: the
Kubernetes auth role, the ServiceAccount and its namespace. That is the link from Vault back into
the cluster, and from there, through the ExternalSecret, back into Git.
