---
title: Public access prevention
version: 1
---

**Public access prevention is a setting that makes `allUsers` and `allAuthenticatedUsers` stop
working on a bucket**, whatever IAM or an ACL says. A policy can be wrong in one line and an ACL can
be set on one object by anybody allowed to write it; public access prevention sits above both, so
that a mistake in either does not reach the internet. The common belief is that a bucket is private
because nobody made it public. A bucket is private because something refuses to let it be made
public, and this is that something.

Google's documentation, cloud.google.com/storage/docs/public-access-prevention, gives the setting two
values:

| value | what it means |
|---|---|
| `enforced` | no grant to `allUsers` or `allAuthenticatedUsers` can be added, by IAM or ACL, and any that already exists stops working |
| `inherited` | the bucket follows the organisation policy above it, if there is one, and is otherwise unprotected |

**The second half of `enforced` is the part that matters on the day it is switched on.** It does not
only refuse new public grants: an existing grant to `allUsers` stays written in the policy and
grants nothing, so turning prevention on closes a leak at once, without anybody first finding every
grant that caused it. The documentation adds that a signed URL is not public access: it is a request
made with the signer's authority, and it keeps working on a bucket with prevention enforced.

## In this lab

```
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-logs-prod --public-access-prevention=enforced 2>&1 | head -1
ERROR: (gcloud.storage.buckets.update) argument --public-access-prevention/--pap: ignored explicit argument 'enforced'
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-logs-prod --public-access-prevention
  
Updating gs://quitanda-logs-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-logs-prod --format='value(public_access_prevention,uniform_bucket_level_access)'
	
ana@laptop:~/gcp$ gcloud storage cp access.log gs://quitanda-logs-prod/web/public.log --predefined-acl=publicRead
Copying file://access.log to gs://quitanda-logs-prod/web/public.log
  

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-logs-prod/web/public.log --format='json(acl)'
{
  "acl": [
    {
      "entity": "allUsers",
      "projectTeam": {},
      "role": "READER"
    }
  ]
}
```

**The first command shows how this version of the command line spells it.** In Google Cloud CLI
591.0.0 `--public-access-prevention` is a switch: written on its own it sets `enforced`, and
`--no-public-access-prevention` sets `inherited`. The form with `=enforced` that older examples use
is refused before anything is sent. The second command was accepted, and the `describe` after it
printed nothing for either public access prevention or uniform bucket-level access: the emulator
kept neither. Then an object was written with `--predefined-acl=publicRead`, a shortcut for "grant
`READER` to `allUsers`", and the emulator recorded exactly that grant.

On Cloud Storage that upload would have been refused, twice over: by uniform bucket-level access,
which refuses any ACL, and by public access prevention, which refuses a public one. Quitanda wants
both, on every bucket, and does not want to depend on whoever creates the next bucket remembering
two flags. That is what the next section's organisation policies are for.

## The bucket that is meant to be public

Quitanda has one: the product photos its website shows, which every visitor's browser downloads with
no credentials. Public access prevention on it would break the shop. **The answer is to make the
exception visible rather than to weaken the rule**:

- the photos live in a bucket of their own, `quitanda-web-public-prod`, that holds nothing else, so
  that a public grant on it cannot reach an order, a log or a customer;
- that bucket sits in a project of its own, and the organisation policy that enforces prevention
  everywhere else is overridden for that one project, with the reason written in the policy's
  history;
- nothing is written into it by a pipeline that also writes private data, because the commonest leak
  of all is the right file uploaded to the wrong bucket.

A reviewer then has one question to ask of the whole organisation, "which projects override
prevention, and why", instead of one per bucket. The section on the bucket that leaked shows how to
ask it.

## Reading the setting back

On Cloud Storage, the check after any change is to read the two settings back from the bucket,
together, because each is half of the answer:

```sh
gcloud storage buckets describe gs://quitanda-curated-prod \
  --format='value(public_access_prevention,uniform_bucket_level_access)'
```

The transcript above ran the same command against the log bucket, and it printed two empty fields. On Cloud Storage
it prints `enforced` for prevention, or `inherited` when the bucket follows the organisation, and the
uniform access setting with its lock time. **`inherited` is not a promise of safety**: it is safe
only if an organisation policy above the bucket enforces prevention, and the bucket alone cannot say
whether one does.
