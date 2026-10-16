---
title: IAMAllowedPrincipals, hybrid mode and the door left open
version: 1
---

**Turning Lake Formation on changes nothing until somebody takes IAM's grant away.** The defaults of
the previous section give every new database and table an `ALL` grant to `IAM_ALLOWED_PRINCIPALS`,
and with that grant in place Lake Formation answers "yes" to anybody IAM already lets in. The column
grant on `orders` would then hide nothing: the analyst's IAM policy, which allows Athena and the
bucket, is enough for every column. It is a compatibility setting, and a lake can run on it for
years with everybody believing its column grants are in force.

## Taking a table over

**Moving a table to Lake Formation is two steps, in this order.** First grant, in Lake Formation,
what each principal that uses the table needs, as the previous section did for the analysts. Then
revoke `ALL` from `IAM_ALLOWED_PRINCIPALS` on that table. Done the other way round, every query on
the table fails between the two steps, because IAM's door has closed and Lake Formation's has not
opened. For the tables created afterwards, the change is in the settings: leave the two default
grants out, as the administrator's `put-data-lake-settings` did, and new tables start with no grant
at all.

moto does not reproduce the first half of this. On AWS, `orders`, created while the defaults were
in force, would carry the grant to `IAM_ALLOWED_PRINCIPALS`, and `list-permissions` would show it
beside the analyst's; moto applied no default, and its list holds only the grants this lesson made,
as the LF-tags section shows. So the revoke has nothing to remove here, and is described rather
than run.

## Hybrid access mode

**Hybrid access mode lets IAM and Lake Formation decide side by side, for one location at a time.**
A location registered with hybrid access keeps answering IAM's permissions for everybody, and the
principals that have been opted in, one by one, are judged by Lake Formation's grants instead. It is
the gentle way to move a lake that many teams use: opt in the analysts, check that their reports
still run, then the next team, and only at the end revoke IAM's grant. moto accepts the registration
and keeps none of it:

```
ana@laptop:~/aws$ aws lakeformation register-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/marketing --use-service-linked-role --hybrid-access-enabled
ana@laptop:~/aws$ aws lakeformation describe-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/marketing
{
    "ResourceInfo": {
        "ResourceArn": "arn:aws:s3:::quitanda-curated-prod/marketing"
    }
}
ana@laptop:~/aws$ aws lakeformation create-lake-formation-opt-in --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --resource '{"Table":{"DatabaseName":"curated","Name":"orders"}}'

aws: [ERROR]: An error occurred (404) when calling the CreateLakeFormationOptIn operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

**The registration succeeded, `describe-resource` says nothing about hybrid access, and the opt-in
answered 404**, because moto does not implement it. Everything about hybrid mode here comes from
AWS's documentation and was not run.

## The door Lake Formation does not guard

**Lake Formation governs the engines that ask it, and S3 has never heard of it.** A principal whose
IAM policy still allows `s3:GetObject` on `quitanda-curated-prod/curated/*` reads the files directly,
with `aws s3 cp`, exactly as the first section of this lesson did, phone numbers included. No grant
in Lake Formation stops that, because no engine is involved to ask.

So the second half of taking over a lake is on the IAM side. **The people and roles that consume
the data lose their direct permission on the registered buckets**; their policies keep Athena, the
catalogue and `lakeformation:GetDataAccess`, and the bytes reach them only through an engine that
checks the grants. The only principals left with `s3:GetObject` on the curated layer are the ones
that write it, such as the Glue jobs of lesson 17, and Lake Formation's own role. A bucket policy
that denies reads to everybody else makes that a rule rather than a habit, and lesson 4's Block
Public Access stays on underneath it all.
