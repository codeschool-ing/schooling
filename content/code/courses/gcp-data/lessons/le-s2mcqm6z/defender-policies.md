---
title: Organisation policies from the defender's side
version: 1
---

**An organisation policy is a rule set on the organisation, or a folder, that every project below it
inherits and no project can switch off.** `gcp-foundations` lesson 4 taught the mechanism. For a
defender of Cloud Storage it is the answer to the question the previous section ended on: how to
make sure that the bucket somebody creates next year, in a project nobody has heard of yet, is
private without anybody remembering to make it so. A setting on a bucket protects that bucket. A
constraint on the organisation protects every bucket that will ever exist under it.

Each policy sets one constraint, and these are the ones that guard Quitanda's data, as Google's list
of constraints, cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints,
describes them:

| constraint | what it enforces |
|---|---|
| `storage.publicAccessPrevention` | public access prevention on every bucket below, whatever the bucket says |
| `storage.uniformBucketLevelAccess` | uniform bucket-level access on every new bucket, so ACLs never come back |
| `iam.allowedPolicyMemberDomains` | IAM grants only to principals of the organisation's own domains, which also rules out `allUsers` and `allAuthenticatedUsers` |
| `iam.disableServiceAccountKeyCreation` | no service account key can be downloaded, so signed URLs are made by impersonation |
| `gcp.resourceLocations` | resources only in the locations listed, such as `southamerica-east1` |

**The first two close the shapes of a leak; the third closes them again at the IAM layer**, for the
day somebody finds a way round the bucket settings. The fourth is about the signed URL of this lesson's
first section. With it, the `signer-key.json` that section made could not exist for a real account,
and every URL would be signed through `--impersonate-service-account`, for at most 12 hours, by a
service account somebody is allowed to impersonate. The fifth keeps the data in Brazil, which a privacy
law may ask for and which no setting on a single bucket can promise for the next one.

Google's documentation says that organisations created since 2024 start with several of these
enforced by default, the two storage constraints and the domain restriction among them. An older
organisation, which is most of them, has to set them itself.

## Writing one down

A policy is a short document. This one enforces public access prevention on Quitanda's whole
organisation, whose number here is invented:

`pap-policy.yaml`:

```yaml
name: organizations/123456789012/policies/storage.publicAccessPrevention
spec:
  rules:
  - enforce: true
```

And it is applied with one command:

```sh
gcloud org-policies set-policy pap-policy.yaml
```

**Neither was run here**: there is no organisation in this lab, and no emulator of the Resource
Manager. On a real organisation the command needs the role Organization Policy Administrator, which
Quitanda gives to two people and to no service account, because whoever can change a constraint can
also lift it. A policy can be tried before it is enforced: the documentation describes a dry run that
reports what a constraint would have refused without refusing it, which is the way to find the
pipeline that writes public objects on purpose before the policy breaks it.

## Two more layers, named and not built

**IAM deny policies** refuse a permission to a principal whatever the allow policies grant, and
`gcp-foundations` lesson 7 is where they are taught. For storage, the useful one denies
`storage.objects.delete` and `storage.buckets.setIamPolicy` to everybody but a break-glass group.

**VPC Service Controls** draw a perimeter around a set of projects and refuse requests to their
storage from outside it, even with valid credentials. It is the defence against a key that leaked: a
stolen key used from somebody else's laptop is outside the perimeter. It needs an organisation, a
network design and an access policy, and the network courses are where it belongs; here it is enough
to know it is the layer that does not trust credentials alone.

## The constraint that is overridden

Every one of these constraints can be overridden lower down the hierarchy, on a folder or a project,
by somebody with the administrator role, and that is deliberate: the public photo bucket of the
previous section needs it. **An override is the place to look first in a review**, because it is the
one place where the organisation's rule does not hold, and the place where a mistake would be
invisible from any bucket. The documentation's command to list the policies set on a project, `gcloud
org-policies list --project=PROJECT`, answers it per project, and Cloud Asset Inventory, `gcp-foundations`
lesson 25, answers it for the organisation in one search.
