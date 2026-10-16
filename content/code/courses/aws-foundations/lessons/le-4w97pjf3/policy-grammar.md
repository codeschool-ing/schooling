---
title: The grammar of a policy document
version: 1
---

**A policy is a JSON document holding a list of statements, and each statement says one thing:
this effect, for these actions, on these resources, under these conditions.** That is the whole
language. What makes it hard is not the syntax but the reading: the common wrong picture is a
firewall, where rules are read from the top and the first match wins. **IAM has no order.** Every
statement of every policy that applies to a request is considered together, and lesson 8 gives the
rule that settles them. This section is the vocabulary that rule is written in.

Here is the policy this lesson gives bia, the shop's developer. It lets her list the `shop-assets`
bucket and read and write the objects inside it, and nothing else. Save it as
`~/aws/shop-assets-rw.json`; the section after next creates it in moto:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListTheAssetsBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::shop-assets"
    },
    {
      "Sid": "ReadAndWriteItsObjects",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::shop-assets/*"
    }
  ]
}
```

## Element by element

| element | what it says | in bia's policy |
|---|---|---|
| `Version` | the version of the policy **language**, not of your document | `2012-10-17`, which is the one to write |
| `Statement` | the list of statements, one object or an array of them | two statements |
| `Sid` | an optional label, unique inside the policy | `ListTheAssetsBucket` |
| `Effect` | `Allow` or `Deny`, and nothing else | `Allow` in both |
| `Action` | which API calls, as `service:Operation` | `s3:ListBucket`, `s3:GetObject`, `s3:PutObject` |
| `Resource` | which things, as ARNs | the bucket, and the objects in it |
| `Condition` | when the statement applies at all | none here |

**`Version` is the date AWS fixed the language, and it never changes with your edits.** The only
other value, `2008-10-17`, is the language before policy variables such as `${aws:username}`, which
are written in strings and are not read as variables under the old version. A document with no
`Version` is read as the old one, so writing the line every time costs nothing and avoids that.

**An action is a service prefix and an operation name**, and the name is case-insensitive. Two
wildcards work inside it: `*` for any run of characters and `?` for exactly one. `s3:Get*` covers
`GetObject`, `GetBucketPolicy` and every other S3 read whose name begins that way, including ones
AWS adds next year, which is the property to keep in mind before writing a wildcard. `NotAction`
inverts the list: the statement then covers every action except those named.

**A resource is an ARN, and S3's has no region and no account in it**, because bucket names are
unique across all of AWS: `arn:aws:s3:::shop-assets`. The bucket and its objects are different
resources, which is why bia's policy has two statements. **`s3:ListBucket` is an action on the
bucket**, so it needs the bucket's ARN; `GetObject` and `PutObject` act on objects, so they need
`shop-assets/*`. Swapping the two resources is one of the commonest mistakes in S3 policies, and
the result is a policy that grants nothing it was meant to.

**A condition is an operator, a key and a value**, such as `"IpAddress": {"aws:SourceIp":
"203.0.113.0/24"}`. Lesson 8 is about them, and says what moto does with one: it does not evaluate
it.

## The element that is not here

An identity policy has no `Principal`, because the principal is whoever the policy is attached to.
**`Principal` belongs to the two kinds of policy attached to something else**: a role's trust policy,
which lesson 6 wrote, and a resource-based policy such as a bucket policy, which lesson 8 reads.
AWS refuses an identity policy that names a principal; the last section of this lesson shows moto
accepting one.
