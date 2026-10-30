---
title: Who may read: IAM, ACLs and uniform bucket-level access
version: 1
---

**Cloud Storage has two permission systems, and a bucket is safest with one of them switched off.**
IAM is the one `gcp-foundations` lessons 5 to 7 taught: a policy on the project or on the bucket
that grants a role to a principal, inherited downwards, with a deny policy able to override it. ACLs
are the older one: a list of grants on the bucket and on each object, with three permissions,
`READER`, `WRITER` and `OWNER`. Either can make an object readable, and somebody checking only one of
them has checked half.

**Uniform bucket-level access turns ACLs off.** With it on, Cloud Storage ignores every ACL and
refuses requests that try to set one, and IAM on the bucket and above it is the only place access is
granted. Google's documentation, cloud.google.com/storage/docs/uniform-bucket-level-access,
recommends it for every bucket, and it is needed for two things this lesson uses: IAM conditions on
a bucket, and the organisation policy two sections on. Once it has been on for 90 days it cannot be
turned off again; before that, it can.

## Two principals that mean "everybody"

IAM and ACLs both have two special principals, and they are the whole of public access:

- **`allUsers` is anybody on the internet**, signed in or not. A grant to it makes an object
  readable by a `curl` with no credentials;
- **`allAuthenticatedUsers` is anybody signed in to any Google account**: not anybody in Quitanda,
  anybody with a Gmail address. Its name made it sound like the safe one, and it has never been.

Granting `roles/storage.objectViewer` to `allUsers` on a bucket is one command, and it makes every
object in it public, including the ones written next year.

## What the emulator does with all of it

Create Quitanda's log bucket with uniform bucket-level access, and ask the curated bucket from the
previous section for its IAM policy:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-logs-prod --location=southamerica-east1 --uniform-bucket-level-access
Creating gs://quitanda-logs-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-logs-prod --format=json
{
  "creation_time": "2026-10-30T15:53:38-0300",
  "default_storage_class": "STANDARD",
  "location": "southamerica-east1",
  "location_type": "region",
  "metageneration": 1,
  "name": "quitanda-logs-prod",
  "storage_url": "gs://quitanda-logs-prod/",
  "update_time": "2026-10-30T15:53:38-0300",
  "versioning_enabled": false
}
ana@laptop:~/gcp$ gcloud storage buckets get-iam-policy gs://quitanda-curated-prod
ERROR: (gcloud.storage.buckets.get-iam-policy) gs://quitanda-curated-prod not found: 404.
ana@laptop:~/gcp$ gcloud storage buckets add-iam-policy-binding gs://quitanda-curated-prod --member=allUsers --role=roles/storage.objectViewer
ERROR: (gcloud.storage.buckets.add-iam-policy-binding) gs://quitanda-curated-prod not found: 404.
```

**The emulator accepted `--uniform-bucket-level-access` and kept none of it**: the `describe` has no
such field, where Cloud Storage would show the setting on. And it has no IAM at all. A request for a
bucket's IAM policy, or to add a binding to it, is answered `404`, as if the bucket were missing,
though the bucket is there. Nothing about IAM can be practised against fake-gcs-server, so the
binding above is a command to read rather than to run:

```sh
gcloud storage buckets add-iam-policy-binding gs://quitanda-curated-prod \
  --member=serviceAccount:dashboard@planner-dev.iam.gserviceaccount.com \
  --role=roles/storage.objectViewer \
  --condition='expression=resource.name.startsWith("projects/_/buckets/quitanda-curated-prod/objects/reports/"),title=reports-only'
```

It was not run here, and the service account in it is as invented as the signer of the previous
section. **It grants the dashboard read access to `reports/` and nothing else in the bucket**: the
condition is evaluated on every request, against the object's full resource name, and a request for
any other object finds no grant. Conditions on a bucket need uniform bucket-level access, which is
one more reason to turn it on.

ACLs, which the emulator does keep:

```
ana@laptop:~/gcp$ printf '203.0.113.7 GET /checkout 200\n' > access.log && gcloud storage cp access.log gs://quitanda-logs-prod/web/access.log
Copying file://access.log to gs://quitanda-logs-prod/web/access.log
  

ana@laptop:~/gcp$ gcloud storage objects update gs://quitanda-logs-prod/web/access.log --add-acl-grant=entity=allUsers,role=READER
  
Patching gs://quitanda-logs-prod/web/access.log...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-logs-prod/web/access.log --format='json(acl)'
{
  "acl": [
    {
      "entity": "projectOwner-test-project",
      "projectTeam": {},
      "role": "OWNER"
    },
    {
      "entity": "allUsers",
      "projectTeam": {},
      "role": "READER"
    }
  ]
}
```

**An ACL granting `READER` to `allUsers` was accepted on a bucket created with uniform
bucket-level access**, and recorded beside the emulator's own owner entry, `projectOwner-test-project`.
On Cloud Storage the request would have been refused, because with uniform access on no ACL can be
set. And the grant made no difference here either way: the next transcript asks for two objects with
no credentials at all, one with the public ACL and one without.

```
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' http://localhost:4443/storage/v1/b/quitanda-logs-prod/o/web%2Faccess.log?alt=media
203.0.113.7 GET /checkout 200
200
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' http://localhost:4443/storage/v1/b/quitanda-curated-prod/o/reports%2Fdaily.csv?alt=media
day,orders,total_cents
2026-10-29,412,5108840
200
```

**Both came back, the public log and the private report alike.** fake-gcs-server checks no
credentials on any request, which lesson 1 said and which matters most here: in this lab every object
is public to anybody who can reach port 4443, and only the fact that the port listens on your own
laptop keeps it private. The permission decisions of this lesson are taught from Google's
documentation, and the lab can show only what the requests look like.
