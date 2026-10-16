---
title: Three kinds of key, and the policy that owns each
version: 1
---

Lesson 17's `SecureString` was encrypted with a key nobody created: `aws/ssm`. Most encryption in AWS
works that way, a checkbox on a bucket or a database that names a key in **KMS**, the Key Management
Service. KMS keeps keys in hardware security modules, and **a KMS key never leaves KMS**: nobody,
including AWS's own staff, gets its material out. What a program gets is the result of asking KMS to
use the key, encrypt this, decrypt that, and every one of those requests is checked against a policy
and recorded in CloudTrail, lesson 20's subject.

There are three kinds of key, by who manages them:

| kind | example | who decides its policy | what it costs |
|---|---|---|---|
| AWS owned | the key behind DynamoDB's default encryption | AWS; it is not in the account at all | nothing |
| AWS managed | `aws/ssm`, `aws/s3`, `aws/rds` | AWS; the account can read the policy, not change it | no monthly fee, requests are billed |
| customer managed | `alias/shop-orders`, made in this lesson | the team | a monthly fee per key, and requests |

The reason to pay for the third kind is **control**. An AWS managed key can be used by any principal in
the account that may use the service it belongs to, and nothing narrows that. A customer managed key has
a **key policy** the team writes, so it can say that only the orders service may decrypt, can be
disabled in an emergency, can be shared with another account, and can be scheduled for deletion, which
makes everything encrypted under it unreadable for ever.

## The key policy comes first

Every KMS key has exactly one key policy, and **it is the root of access to the key**. An IAM policy
that allows `kms:Decrypt` works only if the key policy lets IAM decide, which the default key policy
does with a single statement giving the account's root principal `kms:*`. That statement does not give
the root user anything special in practice; it hands the decision to the account's IAM policies. Remove
it, and the IAM policies stop mattering, for better and for worse: a key policy naming only one role is
a key that one role can use and that nobody else, administrators included, can manage until the policy
is changed by that role.

The next section creates a key and reads its default policy back, so that one statement is visible.
