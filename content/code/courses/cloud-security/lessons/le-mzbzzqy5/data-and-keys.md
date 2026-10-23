---
title: Storage, keys and secrets, three ways
version: 1
---

**Object storage, key management and secret storage exist at all three providers, and all three
encrypt stored data by default. Where they differ is in how many switches stand between a private
object and the internet, and in what "a key we manage" means.** Lessons 9 to 11 go deep on AWS; this
section is the map for the other two, from their documentation and not run.

## How an object becomes public

| | where the switch is | the guardrail above it |
|---|---|---|
| AWS S3 | a bucket policy granting `"Principal": "*"`, or an ACL granting *All Users* | **Block Public Access**, on the bucket and on the account; on for new buckets since 2023 |
| Azure Blob Storage | a container's access level, *Blob* or *Container*, which only works if the storage account allows anonymous access | the account's `allowBlobPublicAccess` property, and Azure Policy to keep it false |
| Google Cloud Storage | an IAM binding of `allUsers` or `allAuthenticatedUsers` on the bucket | **public access prevention** on the bucket, or the `storage.publicAccessPrevention` constraint on the organisation |

**Azure's path needs two switches set, one on the account and one on the container**, which is a
safety in itself: turning on anonymous access for the account exposes nothing until a container also
opts in. Google Cloud's **uniform bucket-level access** switches off per-object ACLs, so that a
bucket's IAM policy is the only thing that decides who reads it; AWS reaches the same place by
setting object ownership to *bucket owner enforced*, which disables ACLs. In every case the defence
is the same shape: **one setting high up that refuses publication, so nobody has to get every bucket
right**.

## Links that carry their own permission

Each provider can sign a URL that grants access to whoever holds it, for a time:

| | the link | signed with |
|---|---|---|
| AWS | a presigned URL | the credentials of whoever generated it |
| Azure | a shared access signature (SAS) | an account key, or a user delegation key from Entra ID |
| Google Cloud | a signed URL | a service account's key, or the signing API |

**Anybody who holds the link can use it until it expires**, and the link appears in browser history,
chat logs and e-mail. Lesson 10 runs the AWS one. On Azure, a SAS signed with the storage account's
own key has no revoke button of its own. Microsoft's documentation gives two ways out: tie the SAS to
a stored access policy beforehand, so that deleting the policy kills it, or rotate the account key,
which kills every SAS signed with that key at once. A user delegation SAS, signed through Entra ID,
is the option Microsoft recommends.

## Keys and secrets

| | keys for encryption | secrets for programs |
|---|---|---|
| AWS | AWS KMS | AWS Secrets Manager |
| Azure | Azure Key Vault keys, or Managed HSM | Azure Key Vault secrets |
| Google Cloud | Cloud KMS, in key rings | Secret Manager |

**Encryption at rest is on by default at all three, with keys the provider manages.** Choosing a key
you manage, in the services above, changes who can switch the data off and who can see every use of
the key, not whether the disk is encrypted. Lesson 11 makes that distinction concrete on AWS.

The access models differ in one way worth knowing. An AWS KMS key has a **key policy** of its own,
and unless that policy lets the account's IAM decide, IAM permissions alone do not open the key.
Azure Key Vault offers two models, the older vault access policies and Azure RBAC, and Microsoft
recommends RBAC; a vault still on access policies has a second list of who may read secrets, in a
place an RBAC review never looks. Google Cloud KMS uses ordinary IAM roles on the key ring or key.
