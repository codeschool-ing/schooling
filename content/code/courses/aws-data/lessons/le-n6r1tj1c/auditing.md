---
title: Auditing the grants
version: 1
---

**A permission system is only as good as the last time somebody read it.** Grants accumulate: a
contractor's role kept after the contract, a table granted to a team for one investigation, a tag
added to a table by somebody who did not know what it opened. None of them fails anything, and all
of them are found the same way, by listing what is granted and asking why each line is there.

## A grant that names nothing

Before listing, one more grant, with a typing mistake in the table's name:

```
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions SELECT --resource '{"Table":{"DatabaseName":"curated","Name":"ordres"}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --resource '{"Table":{"DatabaseName":"curated","Name":"ordres"}}' --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,Permissions[0]]' --output text
arn:aws:iam::123456789012:role/analyst	SELECT
ana@laptop:~/aws$ aws glue get-table --database-name curated --name ordres

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetTable operation: Table ordres not found.
```

**moto accepted a grant on `ordres`, a table that does not exist**, and listed it, while Glue, asked
for the same table, says it is not there. moto keeps the grant as a record and checks nothing
against the catalogue. It is one more of this lesson's reminders that **moto enforces none of Lake
Formation**: it stores grants, tags and settings faithfully, and no engine ever asks it about them,
so it can neither refuse a query nor show one being refused. On AWS a grant names a resource in the
catalogue. In an audit, a line naming a table nobody can find is the kind that deserves the first
question.

## The list as an audit

`list-permissions` with no filter is every grant in the account's catalogue. A `--query` that keeps
the principal, the permissions and the resource's name turns it into a table a person can read:

```
ana@laptop:~/aws$ aws lakeformation list-permissions --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,join(`,`,Permissions),Resource.TableWithColumns.Name || Resource.Table.Name || Resource.Database.Name || `tag policy`]' --output table
----------------------------------------------------------------------
|                           ListPermissions                          |
+-----------------------------------------+-----------+--------------+
|  arn:aws:iam::123456789012:role/analyst |  SELECT   |  ordres      |
|  arn:aws:iam::123456789012:role/analyst |  SELECT   |  orders      |
|  arn:aws:iam::123456789012:role/analyst |  DESCRIBE |  curated     |
|  arn:aws:iam::123456789012:role/support |  SELECT   |  tag policy  |
+-----------------------------------------+-----------+--------------+
```

**Four lines, and each one can be questioned.** Does the support role still need every `internal`
and `pii` table? Is `ordres` a mistake? The answer to the second is yes, and the fix is a revoke
with exactly the arguments of the grant:

```
ana@laptop:~/aws$ aws lakeformation revoke-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions SELECT --resource '{"Table":{"DatabaseName":"curated","Name":"ordres"}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --query 'length(PrincipalResourcePermissions)'
3
```

Three grants are left. On AWS the same review would also show any `IAM_ALLOWED_PRINCIPALS` line
still standing on a table, and each of those is a table whose column grants are not in force.

## Who granted what, and when

**Every grant and revoke is an API call, and CloudTrail records it**: who called
`GrantPermissions`, on which resource, for which principal, from where. So does every
`GetDataAccess` an engine makes when a query reads a table, which makes CloudTrail the record of
who read what, as well as who changed what. An alert on `GrantPermissions` for a tag value such as
`pii` is how a new reader of phone numbers is noticed on the day it happens. moto's CloudTrail
cannot be asked:

```
ana@laptop:~/aws$ aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=GrantPermissions --max-results 5

aws: [ERROR]: An error occurred (500) when calling the LookupEvents operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**`lookup-events` failed with a 500 inside moto**, so this lab cannot show an audit trail of the
grants above. What CloudTrail records about Lake Formation comes from AWS's documentation and was
not run.

## The defender's list

- Grant to roles, never to individual users, so that people come and go without grants left behind.
- Prefer tags to grants per table, and grant the permission to tag as carefully as the data.
- Revoke `IAM_ALLOWED_PRINCIPALS` from every table whose column grants matter, and leave the
  defaults out of the settings.
- Take direct S3 access to the registered locations away from everybody who reads through an
  engine.
- Read the list of grants on a schedule, and alert on the grants that open the sensitive tags.

## What it costs

The price sheet has no line for Lake Formation's permissions, and this course quotes none. The
queries are billed by the engine that runs them, Athena or Redshift Spectrum per terabyte scanned,
and the data by S3, exactly as without Lake Formation.
