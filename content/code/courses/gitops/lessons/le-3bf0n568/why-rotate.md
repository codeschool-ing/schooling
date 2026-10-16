---
title: A credential's life is its risk
version: 1
---

**A credential that leaks is dangerous for as long as it keeps working.** Nobody notices most leaks
when they happen: a token pasted into a ticket, a laptop backup in the wrong bucket, a log line that
printed a header. What limits the damage is not detection but expiry, and a credential that never
expires turns every past leak into a present one.

This course has made a dozen credentials so far, and they are not all alike:

| credential | made in | lives | if it leaks |
|---|---|---|---|
| Gitea tokens, Ana's and the bots' | lessons 2, 3, 4, 7 | until revoked | push and merge as that account |
| the cosign private key and its password | lesson 8 | until replaced | sign anything as the release key |
| the Sealed Secrets keys | lesson 9 | renewed every 30 days, old ones kept | open every seal ever made |
| the age private key | lesson 9 | until replaced | read every SOPS file in the history |
| Vault's unseal key and root token | lesson 9 | until revoked | everything Vault holds |
| `vault-auth`'s long-lived token | lesson 9 | as long as its Secret exists | ask the API server about any token |
| a ServiceAccount token from `kubectl create token` | lesson 9 | one hour | act as that ServiceAccount |
| a Vault token from the Kubernetes login | lesson 9 | ten minutes | read production's token |

**The last two are the shape to aim for**: made on demand, for one purpose, gone before anybody
could use a copy. Everything above them is a credential somebody has to rotate by hand, on a
schedule, and revoke on the day it leaks. Each rotation is a small project: make the new one,
deliver it everywhere the old one was used, check nothing still uses the old one, and only then
revoke it.

This lesson does three things about that. It makes a database password that lives an hour, so there
is nothing to rotate. It rotates the ones that have to be static, and revokes some. And it narrows
what each identity may do, so that the one that leaks next can do less.
