---
title: The bucket that leaked
version: 1
---

**The S3 exposures that reached the news were, as a rule, a configuration somebody chose, not a
break-in.** Nobody guessed a password. A bucket was readable by anybody because a policy, an ACL or a URL said
so, and it stayed that way because nothing anybody looked at said otherwise. Reports of exposed
buckets holding customer records, backups and logs ran for years before AWS made Block Public Access
the default, and they share three shapes.

## Three ways a bucket became public

**A policy with `"Principal": "*"` and `"Effect": "Allow"`.** Typically written to make one folder
of images public for a website, with a `Resource` of `bucket/*` instead of `bucket/images/*`, which made
every object public. It takes one line:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-logs-prod
make_bucket: quitanda-logs-prod
ana@laptop:~/aws$ printf '203.0.113.7 GET /checkout 200\n' > access.log && aws s3 cp access.log s3://quitanda-logs-prod/web/access.log
upload: ./access.log to s3://quitanda-logs-prod/web/access.log  
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/quitanda-logs-prod/web/access.log
403
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-logs-prod --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::quitanda-logs-prod/*"}]}'
ana@laptop:~/aws$ curl -s -w '%{http_code}\n' http://localhost:4567/quitanda-logs-prod/web/access.log
203.0.113.7 GET /checkout 200
200
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-logs-prod
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/quitanda-logs-prod/web/access.log
403
```

**The `curl` has no credentials, and it got the file.** That is the test of whether something is
public, and the only one worth trusting: a request from outside, signed by nobody. Removing the policy
makes the same request fail again. moto evaluates this kind of `Allow`, which is why the demonstration
works here; what moto does not do is let Block Public Access stop it, as the section on the switches
showed.

**An ACL granting `READ` to everybody.** The group `AllUsers` in an ACL is the whole internet. There
was a worse one, `AuthenticatedUsers`, whose name made it sound safe: it means any AWS account in the
world, not any user of yours. ACLs could be set object by object, so a bucket whose policy was
perfectly private could hold public objects nobody had noticed. `BucketOwnerEnforced` ends this
shape entirely.

**A presigned URL that lived too long.** A URL valid for seven days, pasted into a support ticket, a
chat channel or a public issue, is a seven-day public link to the object, readable by anybody who
finds the text. Nothing in the bucket's configuration shows it, because nothing is stored.

## Preventing it

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"Four nested layers around one object, which a request with no credentials from outside has to cross: the account Block Public Access, the bucket Block Public Access, the bucket policy where a Deny wins, and Object Ownership with ACLs off. Beside each layer, what moto does with it: stores both Block Public Access settings without enforcing them; applies a Deny without reading its condition; stores Object Ownership and still takes ACLs.\" data-fig=\"l04-layers\"><defs><marker id=\"bpa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"200.0\" y=\"20.0\" width=\"500.0\" height=\"330.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">account Block Public Access</text><text x=\"688.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: stored, not enforced</text><rect x=\"222.0\" y=\"56.0\" width=\"456.0\" height=\"278.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bucket Block Public Access</text><text x=\"666.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: stored, not enforced</text><rect x=\"244.0\" y=\"92.0\" width=\"412.0\" height=\"226.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"256.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bucket policy: a Deny wins</text><text x=\"644.0\" y=\"106.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: applies a Deny, not its condition</text><rect x=\"266.0\" y=\"128.0\" width=\"368.0\" height=\"174.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Object Ownership: ACLs off</text><text x=\"622.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: stored, still takes ACLs</text><rect x=\"308.0\" y=\"184.0\" width=\"284.0\" height=\"82.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the object</text><text x=\"20.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a request</text><text x=\"20.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">with no credentials</text><path d=\"M150.0 190.0 L306.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#bpa-ah)\"></path></svg>", "caption": "What stands between the internet and an object, from the outside in, and what moto does with each layer. On AWS each one refuses on its own; in moto, of the four, only the bucket policy's Deny refuses anything."}
```

The order matters, from the broadest net to the narrowest:

1. **Block Public Access on the account**, all four switches, so that no bucket created later can be
   made public by a policy or an ACL.
2. **Object Ownership `BucketOwnerEnforced` on every bucket**, so that ACLs are not a second place
   where access is granted.
3. **Bucket policies that deny**: TLS only, own organisation only, from the previous section.
4. **Presigned URLs short and narrow**: minutes, signed by a role that can read one prefix.

In an organisation, a service control policy of the kind `aws-foundations` lesson 4 described can
deny `s3:PutAccountPublicAccessBlock` to everybody but a security role, so that the first switch
cannot be turned off from inside an account.

## Detecting it

Prevention fails, so somebody has to be told when it does. AWS's documentation describes four
services for this, and none of them can be run against moto:

| service | what it answers |
|---|---|
| IAM Access Analyzer for S3 | which buckets are shared outside the account or organisation, and through what: a policy, an ACL, an access point |
| Amazon Macie | which objects hold sensitive data, such as names, tax ids and card numbers, by sampling their contents |
| CloudTrail data events | who read or wrote which object, and when; off by default and billed per event, because a busy bucket produces millions |
| AWS Config rules | whether each bucket keeps a stated configuration, such as the managed rules `s3-bucket-public-read-prohibited` and `s3-bucket-level-public-access-prohibited` |

**They answer different questions, and the difference is the point.** Access Analyzer says a door
is open. Macie says what is behind it. CloudTrail data events say who walked through, which is the
question that decides whether an exposure became a leak, and they only answer it if they were on
before it happened. Config says the door was closed yesterday and is open today.

None of this was run here; it is described from AWS's documentation. The one check this lab can run,
and the one to keep doing on a real account, is the anonymous `curl` above: ask for an object with no
credentials, from outside, and expect `403`.
