---
title: A trail that its subjects cannot switch off
version: 1
---

**The people a trail records are the people who can most easily stop it.** Whoever holds
`AdministratorAccess` can call `StopLogging`, `DeleteTrail`, or delete the records from the bucket,
and a careful intruder holding such a key does exactly that before anything else. So the trail is
protected in three layers: a refusal before the change, records kept where the account cannot reach
them, and proof that what is there was not edited.

## A refusal that outranks AdministratorAccess

Lesson 6 showed that an explicit `Deny` beats every `Allow`. Written on the people who administer
the account, it removes the four calls that would blind the trail, and leaves everything else they
do untouched. Save it as `keep-the-trail.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail",
        "cloudtrail:PutEventSelectors"
      ],
      "Resource": "*"
    }
  ]
}
```

caio administers the account, so he gets `AdministratorAccess` and the guardrail beside it. To send
a command with his key and not admin's, type lesson 13's `with_key` again if this terminal does not
have it:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam put-user-policy --user-name caio --policy-name keep-the-trail --policy-document file://keep-the-trail.json
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
ana@laptop:~/aws$ with_key "$caio" aws cloudtrail stop-logging --name clinic-trail

aws: [ERROR]: An error occurred (403) when calling the StopLogging operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:iam::123456789012:user/caio is not authorized to perform: cloudtrail:StopLogging</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
ana@laptop:~/aws$ with_key "$caio" aws cloudtrail get-trail-status --name clinic-trail --query IsLogging
true
ana@laptop:~/aws$ with_key "$caio" aws cloudtrail describe-trails --query "trailList[].[Name,IsMultiRegionTrail,LogFileValidationEnabled]" --output text
clinic-trail	True	True
```

**The trail is still logging, and caio can still read its configuration.** He was refused the one
thing the guardrail names, despite a policy that allows `*`.

A guardrail on each user is a guardrail somebody forgets on the next user. On AWS the same `Deny` is
written once, as a service control policy on the organisation, where it binds every identity in
every member account, administrators and the root user of the member account included. moto stores
service control policies and enforces none of them, so that version was **not run here**; the
identity policy above is the part moto judges.

## Records the account cannot reach

A trail writing into a bucket of the same account can be emptied by anybody allowed to delete that
bucket's objects. Two things from AWS's documentation, **not run here**, put the records out of
reach:

- **a separate account for logs.** An organisation trail, created in the management account,
  records every member account into a bucket owned by a log-archive account that nobody uses for
  anything else. An administrator of the clinic's production account then has no permission on the
  bucket at all;
- **S3 Object Lock** on that bucket, in compliance mode with a retention period. An object under
  that lock cannot be deleted or overwritten by any user until the period ends, the root user
  included, and the period cannot be shortened.

## Proof that what is there was not changed

`--enable-log-file-validation`, set in the previous section, makes CloudTrail write a **digest file**
every hour: the SHA-256 hash of each log file delivered in that hour, signed with a private key
CloudTrail holds, and chained to the previous digest. `aws cloudtrail validate-logs` checks the chain
for a period, and reports a log file that was changed, deleted or never delivered. moto writes no
logs and no digests, so it was **not run here**.

::: track security
The `soc-response` course's lesson 3 proved a log unchanged with a chain of hashes and shipped it off
the machine that wrote it. Digest files and a log-archive account are the same two ideas, done for
you by the provider, once you switch them on.
:::

::: track *
The idea is older than the cloud: hash every file, sign the hashes, chain each signature to the one
before, and keep the result somewhere the recorded people cannot write. A missing or altered file
then breaks the chain where it happened. The `soc-response` course's lesson 3 builds the same chain
by hand for ordinary log files.
:::

## An alarm on the attempt

The last layer is noticing. dani's refused `StopLogging` in the previous section did no harm, and it
is still the most important line of the afternoon: a former contractor's key, trying to blind the
account. **An alarm on `StopLogging`, `DeleteTrail` and `PutEventSelectors`, refused or not, belongs
on the short list of alarms that wake somebody up.** On AWS the trail also sends its records to a
CloudWatch Logs group, a metric filter there counts the records with those `eventName` values, and
an alarm on the metric reaches a person. The CIS AWS Foundations Benchmark lists that filter and
alarm among its checks. None of it was run here, since moto produces no records to count.
