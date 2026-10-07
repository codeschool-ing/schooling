---
title: "Versioning: getting back what was deleted"
version: 2
---

With versioning off, which is how a new bucket starts, a `PUT` to an existing key replaces the object
and a `DELETE` removes it, and both are final whatever the durability figure says. **With versioning
on, the bucket keeps every version of every key**, and neither request destroys anything.

Two rules describe all of it:

- An overwrite adds a new version, and the one it replaced becomes **noncurrent**. A plain `GET`
  returns the current version; any version can still be read by its version id.
- A `DELETE` that names no version removes nothing. It adds a **delete marker**, an empty version
  that becomes the current one and makes the key look absent. Remove the marker and the object is
  back.

The moto session from earlier shows both, with the same caveat: this is a program imitating the
interface on a laptop. Versioning is switched on, a file is written, changed and written again under
the same key, and then deleted:

```
ana@laptop:~/cloud$ aws s3api put-bucket-versioning --bucket ana-uploads --versioning-configuration Status=Enabled
ana@laptop:~/cloud$ aws s3 cp --no-progress report.txt s3://ana-uploads/notes.txt
upload: ./report.txt to s3://ana-uploads/notes.txt
ana@laptop:~/cloud$ echo 'hello, again' > report.txt
ana@laptop:~/cloud$ aws s3 cp --no-progress report.txt s3://ana-uploads/notes.txt
upload: ./report.txt to s3://ana-uploads/notes.txt
ana@laptop:~/cloud$ aws s3 rm s3://ana-uploads/notes.txt
delete: s3://ana-uploads/notes.txt
ana@laptop:~/cloud$ aws s3 ls s3://ana-uploads/notes.txt
```

The last `ls` printed nothing. As far as a listing can tell, `notes.txt` is gone. The bucket still
holds both versions, and the marker standing in front of them:

```
ana@laptop:~/cloud$ aws s3api list-object-versions --bucket ana-uploads --prefix notes.txt --query 'Versions[].[Key,Size,IsLatest]' --output text
notes.txt	13	False
notes.txt	6	False
ana@laptop:~/cloud$ aws s3api list-object-versions --bucket ana-uploads --prefix notes.txt --query 'DeleteMarkers[].[Key,VersionId,IsLatest]' --output text
notes.txt	bb803601-dec0-45f2-89d0-c8174c000a93	True
```

The two versions are the 6-byte first write and the 13-byte second, and neither is the latest,
because the marker is. **Deleting the marker, by its version id, brings the last version back:**

```
ana@laptop:~/cloud$ aws s3api delete-object --bucket ana-uploads --key notes.txt --version-id bb803601-dec0-45f2-89d0-c8174c000a93
{
    "VersionId": "bb803601-dec0-45f2-89d0-c8174c000a93"
}
ana@laptop:~/cloud$ aws s3 cp s3://ana-uploads/notes.txt -
hello, again
```

The version ids are moto's. S3 makes its own, and its reply to that delete also says that the version
deleted was a delete marker, which moto's reply leaves out. The sequence is the same.

## What keeping everything costs

**Every version is stored and billed like a current object.** A 1 GB export overwritten once a day
leaves about 30 GB in the bucket after a month with versioning on, and keeps adding a gigabyte a day for as
long as nobody removes the old ones. Deleting does not help either, because a delete only adds a
marker. So versioning is almost always paired with a lifecycle rule for the noncurrent versions,
which turns "keep everything" into "keep a window to recover in":

```json
{
  "Rules": [
    {
      "ID": "old-versions-go-after-30-days",
      "Filter": {},
      "Status": "Enabled",
      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 },
      "Expiration": { "ExpiredObjectDeleteMarker": true }
    }
  ]
}
```

The empty `Filter` applies the rule to the whole bucket. A version is deleted 30 days after it stopped
being current, so a mistake has a month to be noticed. The last line removes delete markers left with
no versions behind them, which would otherwise pile up as clutter in every listing of versions.

Two limits are worth knowing before relying on it. **Once versioning has been on, a bucket can be
suspended but never returned to unversioned**; the versions already kept stay until something deletes
them. And versioning protects against mistakes, not against someone allowed to delete versions: a
caller with that permission can remove every version one by one. Who may do that is a policy
question for lesson 7, and making versions undeletable is the object lock that `cloud-security`
covers.
