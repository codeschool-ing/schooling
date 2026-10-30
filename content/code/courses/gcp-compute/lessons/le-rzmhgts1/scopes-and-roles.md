---
title: Access scopes and IAM roles
version: 1
---

The `service_account` block has a second line that looks as if it decides what the machine may do:
`scopes`. **It does not, on its own. Two separate checks stand between the machine's token and a
Google API, and both must say yes.** Getting that wrong produces either a machine that cannot do
its job or a token that can do far more than anybody intended.

## Two checks

An **access scope** is a property of the token. When the metadata server mints a token for the
machine, it limits it to the scopes the instance was created with: a token scoped to Cloud Storage
read-only cannot call Pub/Sub, whatever the service account is allowed. Scopes are older than IAM,
coarse, and set per instance.

An **IAM role** is a property of the identity. The service account `shop-web` holds roles on
resources, `roles/storage.objectViewer` on one bucket for instance, and the API checks the
account's roles on every call.

So a call succeeds only when **the scope covers the API and a role covers the action on that
resource**. Each check can fail alone, with an error that names only its own half, which is how
teams lose afternoons to a machine that "has the role".

## Scopes in the plan

Section 02's machine asked for `cloud-platform`. Here is the same block changed to two narrower
aliases, and what the plan shows:

```
ana@laptop:~/gcp/meta$ sed -i 's/"cloud-platform"\]/"storage-ro", "logging-write"]/' main.tf
ana@laptop:~/gcp/meta$ terraform plan -no-color | grep 'auth/'
              + "https://www.googleapis.com/auth/devstorage.read_only",
              + "https://www.googleapis.com/auth/logging.write",
```

**The provider expanded every alias into the full scope it stands for**, so the plan shows what
the token will actually carry: `storage-ro` is `devstorage.read_only`, and `logging-write` is
`logging.write`. The `cloud-platform` line of the previous section was one of these expansions
too: `https://www.googleapis.com/auth/cloud-platform`, the scope that covers every Google Cloud
API.

## Which to use

Google's current recommendation is short: **give the machine the `cloud-platform` scope and
control everything with IAM roles.** Scopes cannot say "this bucket and not that one"; roles can,
and they can be changed without touching the machine. Narrow scopes still have one use, as a
second fence on a machine whose account you do not control well, but a fence you have to remember
on every instance is not where the decision should live.

Two operational facts follow, both from Google's documentation and not run here. **Changing an
instance's service account or scopes requires stopping it**: the provider will refuse the change
on a running machine unless `allow_stopping_for_update = true` is set, and then it stops and starts
the machine to apply it. And **removing a role takes effect within minutes, while a token already
issued keeps its scopes until it expires**, up to an hour. When a machine is compromised, the fast
way to cut it off is to disable the service account, after which Google refuses its credentials.

| what you want to restrict | where it lives |
|---|---|
| which buckets, topics and tables the machine may touch | IAM roles on those resources |
| which actions on them | the roles' permissions |
| which APIs any token from this machine can reach at all | access scopes, kept at `cloud-platform` |
| whether this machine has any identity | no `service_account` block, or one with no roles |
