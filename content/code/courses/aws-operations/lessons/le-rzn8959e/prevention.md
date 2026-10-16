---
title: Making the accident hard to have
version: 1
---

The accident in this lesson needed one ordinary command from somebody with permission to delete an
object in a bucket. **Prevention is mostly about that permission**, and partly about making the
mistake recoverable when the permission is there anyway.

## Fewer people who can delete it

The state bucket's policy can refuse deletion of state objects to everyone except a named role used
for genuine maintenance:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "StateIsNotDeletedByHand",
      "Effect": "Deny",
      "Principal": "*",
      "Action": ["s3:DeleteObject", "s3:DeleteObjectVersion"],
      "Resource": "arn:aws:s3:::shop-tfstate-123456789012/*.tfstate",
      "Condition": {
        "ArnNotEquals": {
          "aws:PrincipalArn": "arn:aws:iam::123456789012:role/state-maintenance"
        }
      }
    }
  ]
}
```

An explicit deny beats any allow (`aws-foundations` lesson 8), so somebody with full S3 permissions
still cannot delete a `.tfstate` object, and the lock files, which Terraform deletes on every run, are
untouched because they end in `.tflock`. **moto does not evaluate bucket policies**, so this policy
was not tested here; on AWS it would have refused the `aws s3 rm` in the first section.

## Versions that cannot be removed early

Versioning made the restore possible, and a lifecycle rule that expires **noncurrent** versions after
some days keeps the history from growing for ever. Choose the days with the accident in mind: the
history has to outlast the time it takes somebody to notice. Ninety days of a state written forty times
a day is a few thousand small objects, a negligible cost for that protection.

For a stronger guarantee, **S3 Object Lock** in governance mode refuses the deletion of any version
for a fixed time, even to administrators without a special permission. It must be chosen when the
bucket is created, and it is worth it for the state of production.

## Habits

- `terraform state pull` before anything unusual: a `state mv`, a provider upgrade, an import;
- **never edit state by hand** in the bucket; the `terraform state` subcommands exist so that every
  change goes through a lock and leaves a serial behind;
- one state per environment and per team, so an accident costs one of them and not all;
- an alert when a state object is deleted: CloudTrail records S3 data events if asked (lesson 20),
  and a delete of `shop/terraform.tfstate` is worth a page at any hour.
