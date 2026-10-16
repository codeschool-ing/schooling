---
title: Versioning, and the delete that deletes nothing
version: 1
---

**A versioned bucket never overwrites and never deletes unless you name a version.** Every `PUT`
to a key adds a version on top of the ones before it, and a `DELETE` with no version adds one more,
an empty one called a delete marker, which makes the key look absent while every byte it ever held
stays in the bucket and on the bill. People switch versioning on to protect data and are surprised
twice: first that a deleted file can come back, and then by what keeping every version costs.

Lesson 1 ended on an overwrite that could not be undone, because that bucket kept no versions. This
lesson starts from an empty moto, as every lesson does, with moto running in its own terminal and
the four lines of lesson 1's "Your lab, in brief" typed in this one. The curated bucket gets versioning
before its first object:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-curated-prod
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-curated-prod --versioning-configuration Status=Enabled
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-curated-prod
{
    "Status": "Enabled"
}
```

A new bucket answers `get-bucket-versioning` with nothing at all, which means versioning has never
been turned on; that state is called unversioned. `Enabled` is the second state, and the third,
`Suspended`, comes at the end of this section. **There is no way back to unversioned**: once a bucket
has had versioning on, it can only be suspended.

## Two writes, two versions

Quitanda's curated customer table is rewritten whole every night. Write it twice:

```
ana@laptop:~/aws$ printf 'customer_id,city\nc-17,Santos\n' > customers.csv && aws s3 cp customers.csv s3://quitanda-curated-prod/customers/customers.csv
upload: ./customers.csv to s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ printf 'customer_id,city\nc-17,Campinas\n' > customers.csv && aws s3 cp customers.csv s3://quitanda-curated-prod/customers/customers.csv
upload: ./customers.csv to s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-curated-prod --query 'Versions[].[VersionId,IsLatest,Size,LastModified]' --output text
a55c0eb8-8736-4934-83b6-31b1aa70fe08	True	31	2026-10-16T16:11:06+00:00
fd4f0d85-b684-4c89-a9c4-5782a0a06eec	False	29	2026-10-16T16:11:05+00:00
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/customers/customers.csv -
customer_id,city
c-17,Campinas
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key customers/customers.csv --version-id fd4f0d85-b684-4c89-a9c4-5782a0a06eec old.csv --query VersionId && cat old.csv
"fd4f0d85-b684-4c89-a9c4-5782a0a06eec"
customer_id,city
c-17,Santos
```

**Both versions are there**, each with its own `VersionId`, and the newer one says `IsLatest`. A plain
`GET` of the key returns the latest; a `GET` with `--version-id` returns any of them. The older one is
now a noncurrent version, and it is billed exactly like the current one: same class, same price per
GB, for as long as it exists.

## A delete, and the way back

```
ana@laptop:~/aws$ aws s3 rm s3://quitanda-curated-prod/customers/customers.csv
delete: s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod --recursive
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key customers/customers.csv out.csv

aws: [ERROR]: An error occurred (NoSuchKey) when calling the GetObject operation: The specified key does not exist.
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-curated-prod --query '{versions: Versions[].[VersionId,IsLatest], markers: DeleteMarkers[].[VersionId,IsLatest]}'
{
    "versions": [
        [
            "a55c0eb8-8736-4934-83b6-31b1aa70fe08",
            false
        ],
        [
            "fd4f0d85-b684-4c89-a9c4-5782a0a06eec",
            false
        ]
    ],
    "markers": [
        [
            "93880f0d-43ff-43e0-955f-00f8dab8a298",
            true
        ]
    ]
}
```

**The key has gone from the listing and from `GET`, and nothing was removed.** `aws s3 rm` sent a
`DELETE` with no version, so S3 added a delete marker on top: a version with no bytes whose only job
is to make the key answer `NoSuchKey`. The two real versions are still listed, now both with
`IsLatest` false. That is why versioning protects against the commonest accident, a script that
deletes the wrong prefix: the marker can itself be deleted.

```
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-curated-prod --key customers/customers.csv --version-id 93880f0d-43ff-43e0-955f-00f8dab8a298
{
    "VersionId": "93880f0d-43ff-43e0-955f-00f8dab8a298"
}
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/customers/customers.csv -
customer_id,city
c-17,Campinas
```

**Deleting the marker brings the key back**, with the bytes of the last version written. A `DELETE`
that names a version is the only kind that removes anything for good, and it removes that one
version and nothing else. An identity policy, which lesson 4 puts to work, can allow
`s3:DeleteObject`, which places markers, and deny `s3:DeleteObjectVersion`, which destroys versions; that pair is how a bucket lets
a pipeline tidy up without letting it destroy anything.

## Suspended is not off

Suspending is the third state, and here moto and S3 part ways:

```
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-curated-prod --versioning-configuration Status=Suspended
ana@laptop:~/aws$ printf 'customer_id,city\nc-17,Sorocaba\n' > customers.csv && aws s3 cp customers.csv s3://quitanda-curated-prod/customers/customers.csv
upload: ./customers.csv to s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-curated-prod --query 'Versions[].[VersionId,IsLatest,Size]' --output text
null	True	31
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key customers/customers.csv --version-id fd4f0d85-b684-4c89-a9c4-5782a0a06eec old.csv --query VersionId

aws: [ERROR]: An error occurred (NoSuchVersion) when calling the GetObject operation: The specified version does not exist.
```

**On S3 a suspended bucket still holds every version it had.** New writes get the version id `null`,
which each later write replaces, and the two versions written before the suspension stay where they
were, listed and billed. Suspending stops the growth and keeps the history, so it is not a way to
save money on versions already stored; removing those takes a `DELETE` per version, or the life-cycle
rule of the section after next.

**moto threw the history away.** The listing shows only the `null` version, and the older version
whose id the earlier `get-object` used is now `NoSuchVersion`. That is a defect of moto 5.2.3, the
opposite of what S3 does, and it errs in the dangerous direction. A cleanup script tested here would
look as if suspension had deleted the old versions, and on AWS they would still be there, and on the
bill.
