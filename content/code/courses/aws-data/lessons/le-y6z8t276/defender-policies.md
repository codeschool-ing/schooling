---
title: Bucket policies from the defender's side
version: 1
---

**A bucket policy is a resource policy: it is attached to the bucket and names who may do what to
it.** An identity policy travels with a user or a role; a bucket policy stays with the data, and it
is the place to write rules that hold whoever asks. The defender's use of it is mostly `Deny`, because
an explicit deny wins over every allow anywhere, as `aws-foundations` lesson 8 showed. A `Deny` in a
bucket policy is a rule nobody's identity policy can get round.

Quitanda's curated bucket gets two such rules. The first refuses any request that did not arrive over
TLS. The second refuses any principal outside Quitanda's AWS organisation, so that a key from some
other account, granted access by a mistake elsewhere, still cannot read:

`curated-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyOverTls",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::quitanda-curated-prod",
        "arn:aws:s3:::quitanda-curated-prod/*"
      ],
      "Condition": {"Bool": {"aws:SecureTransport": "false"}}
    },
    {
      "Sid": "OnlyOurOrganisation",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::quitanda-curated-prod",
        "arn:aws:s3:::quitanda-curated-prod/*"
      ],
      "Condition": {"StringNotEquals": {"aws:PrincipalOrgID": "o-quitanda01"}}
    }
  ]
}
```

**`"Principal": "*"` in a `Deny` is not public access, it is the opposite**: it says the rule applies
to everybody. Public access is `"Principal": "*"` with `"Effect": "Allow"`, the line of the next
section. Each statement covers two resources, the bucket for actions such as listing and every
object under it for reads and writes. `o-quitanda01` stands for the organisation's id, which on AWS is
`o-` followed by ten or more characters that Organizations assigns.

A third rule worth knowing replaces the second where traffic should come only from inside a VPC:
`aws:SourceVpce`, the id of a VPC endpoint, from `aws-foundations` lesson 19. A bucket that may be
read only through its endpoint cannot be read from a laptop on the internet, even with good keys.

## In moto

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-curated-prod --policy file://curated-policy.json
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket quitanda-curated-prod --query Policy --output text | python3 -m json.tool | head -12
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "OnlyOverTls",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::quitanda-curated-prod",
                "arn:aws:s3:::quitanda-curated-prod/*"
            ],
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
download failed: s3://quitanda-curated-prod/reports/daily.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
```

**moto stored the policy, and then refused Quitanda's own read.** That looks right at first: the
lab's requests go to moto over plain HTTP, so `aws:SecureTransport` is false and the first statement
should deny them. The way to find out whether moto understood that is to reverse the condition, so
that the policy denies only requests made over TLS, which this lab never sends:

```
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-curated-prod
ana@laptop:~/aws$ jq '.Statement |= [.[0] | .Condition.Bool."aws:SecureTransport" = "true"]' curated-policy.json > tls-true.json && jq -c .Statement[0].Condition tls-true.json
{"Bool":{"aws:SecureTransport":"true"}}
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-curated-prod --policy file://tls-true.json
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
download failed: s3://quitanda-curated-prod/reports/daily.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-curated-prod
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
day,orders,total_cents
2026-10-15,412,5108840
```

**moto refused the read just the same**, under a policy that on AWS would have let a plain HTTP
request through. So the refusal above was not moto reading the condition; whatever moto does with a
`Condition`, it is not what S3 does, and a denial from moto under a conditional policy proves no more
than a success would. Deleting the policy gave the read back, and moto let the owner delete it even
though the policy denies `s3:*`.

What the two conditions do on AWS is taught from AWS's documentation of the global condition keys,
not from this lab. **A `Deny` with `aws:PrincipalOrgID` also catches AWS services that act for you**,
such as a log delivery or a replication, whose principal is not in your organisation. The usual fix
is a second condition that lets those through, `aws:PrincipalIsAWSService`; a policy that forgets it
works for every person and breaks the first service that writes to the bucket.
