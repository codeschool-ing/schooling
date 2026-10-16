---
title: How AWS decides, in one rule and two kinds of layer
version: 1
---

**Every request starts denied. An explicit `Deny` in any policy that applies ends it there. Then
every layer that can only limit has to allow it, and at least one layer that grants has to allow
it.** Lesson 7 showed the vocabulary; this is the sentence it is written for, and the rest of the
lesson takes its parts one at a time.

The wrong picture is the firewall again, now with an extra mistake: that an `Allow` somewhere
overrides a `Deny` somewhere else, or that the most specific statement wins. **Specificity counts
for nothing.** A `Deny` on `s3:*` for one bucket beats an `Allow` on `s3:GetObject` for the same
bucket, and it beats `AdministratorAccess`, which allows `*` on `*`.

## Two kinds of layer

The policies that can apply to one request are of two kinds, and the difference is the whole
point of the rule:

| layer | who writes it | what it can do |
|---|---|---|
| identity-based policy (lesson 7) | the account's administrators | **grant** |
| resource-based policy, such as a bucket policy | whoever owns the resource | **grant** |
| service control policy, resource control policy (lesson 4) | the organisation | only limit |
| permission boundary | an administrator, on a user or role | only limit |
| session policy | whoever assumes a role, for that session | only limit |

**A layer that only limits never grants anything by itself.** An SCP that allows `s3:*` gives
nobody S3; it says S3 is as far as the account's own policies may go. So a request has to pass
every limiting layer that is in place and find an `Allow` in a granting layer. Missing either is
an implicit deny.

**Across accounts, both sides have to grant.** When a principal of one account uses a resource of
another, the caller's own identity policy has to allow the action **and** the resource's policy, or
a role's trust policy, has to allow that caller. Within one account, one granting layer is enough.
That rule was not run here: moto does not judge resource-based policies, as the last section shows.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 510\" role=\"img\" data-fig=\"l08-evaluation\" aria-label=\"How AWS judges a request inside one account, simplified from its documentation, with what moto checks marked on the left. The request starts denied. First: is there an explicit Deny in any policy? If yes, it is denied; moto checks this in identity policies only. Then: do the organisation's SCPs and RCPs allow it? If not, denied; moto ignores them. Then: does an identity-based or a resource-based policy allow it? If not, denied; moto checks identity policies and ignores resource policies. Then: does the permission boundary allow it, if one is set? Then: does the session policy allow it, if one was passed? moto ignores both. Only a request that passes every step is allowed.\"><defs><marker id=\"l08-evaluation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-evaluation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-evaluation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"85.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">moto</text><rect x=\"170.0\" y=\"30.0\" width=\"300.0\" height=\"40.0\" rx=\"18\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the request starts denied</text><rect x=\"560.0\" y=\"98.0\" width=\"130.0\" height=\"324.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">denied</text><path d=\"M320.0 72.0 L320.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"98.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an explicit Deny in any policy?</text><path d=\"M472.0 120.0 L558.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">yes</text><text x=\"85.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">identity: checks</text><text x=\"85.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">resource: ignores</text><path d=\"M320.0 144.0 L320.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no</text><rect x=\"170.0\" y=\"168.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">do the SCPs and RCPs allow it?</text><text x=\"320.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">in a member account</text><path d=\"M472.0 190.0 L558.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no</text><text x=\"85.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ignores</text><path d=\"M320.0 214.0 L320.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">yes</text><rect x=\"170.0\" y=\"238.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">does an identity or resource policy allow it?</text><path d=\"M472.0 260.0 L558.0 260.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no</text><text x=\"85.0\" y=\"252.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">identity: checks</text><text x=\"85.0\" y=\"267.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">resource: ignores</text><path d=\"M320.0 284.0 L320.0 306.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"295.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">yes</text><rect x=\"170.0\" y=\"308.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"323.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">does the permission boundary allow it?</text><text x=\"320.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">if one is set</text><path d=\"M472.0 330.0 L558.0 330.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"321.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no</text><text x=\"85.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ignores</text><path d=\"M320.0 354.0 L320.0 376.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"365.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">yes</text><rect x=\"170.0\" y=\"378.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"393.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">does the session policy allow it?</text><text x=\"320.0\" y=\"410.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">if one was passed</text><path d=\"M472.0 400.0 L558.0 400.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"391.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no</text><text x=\"85.0\" y=\"400.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ignores</text><path d=\"M320.0 424.0 L320.0 452.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-phosphor)\"></path><text x=\"330.0\" y=\"437.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">yes</text><rect x=\"170.0\" y=\"454.0\" width=\"300.0\" height=\"40.0\" rx=\"18\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"474.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">allowed</text></svg>", "caption": "Every step can only refuse; a request is allowed by surviving all of them. Of all these layers, moto judges the identity policies alone."}
```

## The three outcomes, in moto

Restart moto in the first terminal with the count, as lesson 7 did, so this lesson starts from an
empty AWS with its checking on:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

In the second terminal, the same three requests make `admin`, and the same `export` moves the
terminal onto admin's key. The fourth request is the proof the checking is on:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

Type lesson 7's `with_key` again, and a second function beside it for the role sessions of the next
section. **`with_session` does for `assume-role`'s answer what `with_key` does for a user's key**,
and it carries the session token as well:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

caio, the shop's analyst, gets a user, a key and nothing else. Two buckets give him something to
ask for:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-assets
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-backups
ana@laptop:~/aws$ aws s3api put-object --bucket shop-assets --key logo.png --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
ana@laptop:~/aws$ aws s3api put-object --bucket shop-backups --key orders-2026-10-15.dump --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
```

**With no policy at all, everything is refused.** That is the implicit deny, and it needs no
statement anywhere: it is where every request starts.

```
ana@laptop:~/aws$ with_key "$caio" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ with_key "$caio" aws iam list-users

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:iam::123456789012:user/caio is not authorized to perform: iam:ListUsers
```

**An `Allow` in a granting layer opens it.** AWS's `AmazonS3ReadOnlyAccess` on caio's user:

```
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
ana@laptop:~/aws$ with_key "$caio" aws s3 ls
2026-10-16 13:39:04 shop-assets
2026-10-16 13:39:04 shop-backups
ana@laptop:~/aws$ with_key "$caio" aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text
orders-2026-10-15.dump
```

**An explicit `Deny` closes it again, whatever allows it.** The backups are not an analyst's
business, so an inline policy denies them, while the managed policy that allows every bucket stays
attached:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name caio --policy-name no-backups --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"s3:*","Resource":["arn:aws:s3:::shop-backups","arn:aws:s3:::shop-backups/*"]}]}'
ana@laptop:~/aws$ with_key "$caio" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
logo.png
ana@laptop:~/aws$ with_key "$caio" aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
```

`shop-assets` still lists, because nothing denies it; `shop-backups` is refused, because something
does. **This part moto judges exactly as AWS does**, and it is the part that matters most: a
`Deny` is how a guardrail is written, because no `Allow` added later undoes it; only removing the `Deny` does.
