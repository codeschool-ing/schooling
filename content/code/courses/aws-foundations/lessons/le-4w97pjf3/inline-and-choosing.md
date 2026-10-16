---
title: Inline policies, and choosing between the three
version: 1
---

**An inline policy is written into one user, group or role and belongs to nothing else.** It has
a name but no ARN, so no other identity can be given it; it has no versions, so an edit overwrites
it; and it lives exactly as long as the identity that holds it. The wrong picture is that inline is
the quick, informal kind, for when a managed policy feels like too much ceremony. **Inline is the
strict kind**: it is the one way to make sure a permission can never be attached to a second
identity by somebody tidying up.

## A policy for edu, the contractor

edu joins the shop for two months to redesign the storefront, and needs to upload images to one
prefix of `shop-assets`. A permission that must leave with him is the case inline is for. Save this
as `~/aws/edu-uploads.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UploadStorefrontImages",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::shop-assets/storefront/*"
    }
  ]
}
```

`put-user-policy` writes it into edu's user. **There is no `create-policy` step**, because the
policy has no existence apart from him:

```
ana@laptop:~/aws$ aws iam create-user --user-name edu --query User.Arn --output text
arn:aws:iam::123456789012:user/edu
ana@laptop:~/aws$ aws iam put-user-policy --user-name edu --policy-name storefront-uploads --policy-document file://edu-uploads.json
ana@laptop:~/aws$ aws iam list-user-policies --user-name edu
{
    "PolicyNames": [
        "storefront-uploads"
    ]
}
ana@laptop:~/aws$ aws iam list-attached-user-policies --user-name edu
{
    "AttachedPolicies": []
}
```

`list-user-policies` lists only inline policies; the managed ones attached to a user are a
different list, `list-attached-user-policies`, and an audit that reads one and not the other misses
half of what a user can do.

When edu leaves, his user goes, and the API makes the order visible:

```
ana@laptop:~/aws$ aws iam delete-user --user-name edu

aws: [ERROR]: An error occurred (DeleteConflict) when calling the DeleteUser operation: Cannot delete entity, must delete policies first.
ana@laptop:~/aws$ aws iam delete-user-policy --user-name edu --policy-name storefront-uploads
ana@laptop:~/aws$ aws iam delete-user --user-name edu
ana@laptop:~/aws$ aws iam get-user --user-name edu

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the GetUser operation: The user with name edu cannot be found.
```

**The refusal is a safeguard, not a leftover.** AWS will not delete a user who still holds a
policy, so the command line names each one first; the console's delete button does the same steps
for you. Either way, once the user is gone **the inline policy is gone with it**: there is no copy
anywhere to attach to the next contractor by accident. A managed policy would have outlived him,
still attachable, which is sometimes what you want and here is not.

## A principal where none belongs

The first section said AWS refuses an identity policy that names a `Principal`. moto does not:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name bia --policy-name with-principal --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"*"},"Action":"s3:ListBucket","Resource":"arn:aws:s3:::shop-backups"}]}'
ana@laptop:~/aws$ with_key "$bia" aws s3api list-objects-v2 --bucket shop-backups
{
    "RequestCharged": null,
    "Prefix": ""
}
ana@laptop:~/aws$ aws iam delete-user-policy --user-name bia --policy-name with-principal
```

**moto stored it, and then obeyed it**: the second command is bia listing `shop-backups`, which
her customer-managed policy never allowed. AWS would have refused the document as malformed before
storing anything; that was not run here. In a lab, it means a policy that works in moto is not yet a
policy AWS accepts, and lesson 8 names the tool that checks a document against AWS's grammar.

## The limits, as moto reports them

```
ana@laptop:~/aws$ aws iam get-account-summary --query "SummaryMap.{PolicySizeQuota:PolicySizeQuota,UserPolicySizeQuota:UserPolicySizeQuota,GroupPolicySizeQuota:GroupPolicySizeQuota,AttachedPoliciesPerUserQuota:AttachedPoliciesPerUserQuota,VersionsPerPolicyQuota:VersionsPerPolicyQuota}"
{
    "PolicySizeQuota": 6144,
    "UserPolicySizeQuota": 2048,
    "GroupPolicySizeQuota": 5120,
    "AttachedPoliciesPerUserQuota": 10,
    "VersionsPerPolicyQuota": 5
}
```

The numbers are characters, apart from the last two. **A managed policy may hold 6,144 characters,
an inline policy on a user only 2,048**, and a user may have ten managed policies attached; these
match the quotas in AWS's documentation, where the last one can be raised on request. The small
size of a user's inline policies is a hint about what they are for: a short, specific permission,
not a library.

## Choosing

| | AWS-managed | customer-managed | inline |
|---|---|---|---|
| written by | AWS | you | you |
| has an ARN, can be attached to many | yes | yes | no |
| versions | AWS's, with no say from you | up to five, and you choose the default | none: an edit overwrites |
| changes when | AWS decides | you publish a version | you rewrite it |
| goes away when | never, while AWS keeps it | you delete it | its identity is deleted |
| use it for | a starting point, or a job function AWS describes well | **almost everything you write** | a permission that must belong to one identity only |

**Write customer-managed policies by default.** They are reviewed once, attached where needed, and
rolled back by moving the default version. Take an AWS-managed policy when its scope is truly what
you want, knowing it will grow without asking, as `ReadOnlyAccess` has, to 188 versions. Keep inline for the
cases where a second attachment would be the bug, such as edu's uploads or the permissions of a
role that exists for one machine.
