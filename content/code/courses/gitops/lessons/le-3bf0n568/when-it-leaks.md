---
title: The day one leaks
version: 1
---

**A planned rotation and a leak use the same four steps in a different order.** Rotating on a
schedule, the old credential is revoked last, because nothing is wrong with it and an outage would
be the only harm. After a leak, somebody else may be using it right now, and the order turns around:

1. **revoke it first**, and accept that whatever used it stops working;
2. make the new one and deliver it, which is the outage ending;
3. find out what the leaked one was used for, while it worked;
4. write down how it leaked, so that step 1 is not needed again for the same reason.

The outage in step 1 is the price, and it is usually the smaller one: a broken image automation for
twenty minutes against somebody pushing to `fleet` as `image-bot` for as long as nobody notices.

Step 3 is lesson 12. Every record there answers part of it: Gitea's list of what an account pushed,
the API server's log of what it did in the cluster, Vault's log of what it read.

## A secret that reached Git

The leak this course is most exposed to is a secret committed by mistake: a token pasted into a
values file, a `.env` added with `git add .`. **Deleting it in the next commit does not remove it**,
and rewriting history does not either. Every clone made before the rewrite still has it, so does
every fork, every CI cache and every pull request page that showed the diff. The secret has to be
treated as read by everybody who could read the repository, which means it is revoked and replaced,
whatever happens to the history afterwards.

Two habits make this rarer, and both appeared earlier in the course. The pre-commit side: lesson 9's
`.sops.yaml` and Sealed Secrets keep the plain value off the disk of the repository in the first
place. The server side: a secret scanner in CI, run on every pull request like `validate.sh`,
refuses a diff that contains something shaped like a key. Neither is perfect, and **the rotation
procedure is what is left when both fail**, which is why it is worth having practised it on a quiet
afternoon.

## What this lab changed

| credential | before this lesson | after it |
|---|---|---|
| PostgreSQL's administrator | `initial-password`, typed by a person | rotated by Vault, known to nobody |
| the application's database access | none yet | an account per request, an hour each |
| `image-bot`'s token | `automation`, made in lesson 7 | `automation-2`; the first one refused |
| what staging's path may change | the whole cluster | its namespace, and two rules beyond it |

Lesson 12 starts from here, and its last step deals with the line this table leaves out: Vault's
root token.
