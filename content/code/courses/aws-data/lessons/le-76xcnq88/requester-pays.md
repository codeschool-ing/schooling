---
title: Requester pays, and who the bill goes to
version: 1
---

**By default the owner of a bucket pays for everything done to it, including by others.** A partner
in us-east-1 who copies Quitanda's 5 TB of order history, with access Quitanda granted, moves 5 TB
out of the region, and the transfer lands on Quitanda's bill. Requester pays is the setting that
moves two of the three meters to whoever asks.

On a bucket with requester pays on, as AWS documents it:

- **the requester pays for the requests and the transfer**; the owner still pays for storage;
- **every request must say it accepts the charge**, with the header `x-amz-request-payer: requester`,
  which the command line sends for `--request-payer requester`. A request without it is refused
  with `403`;
- **anonymous requests are refused**, since there would be nobody to bill. A requester-pays bucket
  cannot also serve the public;
- the requester must be an AWS account, and its own bill shows the charges.

It fits data shared with other companies that read it on their own schedule: a dataset sold to
partners, or a public research dataset whose owner pays only to keep it. It does not fit anything
Quitanda's own teams read, since the charges would move from one of Quitanda's accounts to another
and nothing would be saved.

## In moto

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ printf 'order_id,customer_id,total_cents\nord-01-1,c-17,4590\n' > history.csv && aws s3 cp history.csv s3://quitanda-curated-prod/shared/history.csv
upload: ./history.csv to s3://quitanda-curated-prod/shared/history.csv
ana@laptop:~/aws$ aws s3api put-bucket-request-payment --bucket quitanda-curated-prod --request-payment-configuration Payer=Requester

aws: [ERROR]: An error occurred (IllegalLocationConstraintException) when calling the PutBucketRequestPayment operation: The unspecified location constraint is incompatible for the region specific endpoint this request was sent to.
ana@laptop:~/aws$ aws s3api get-bucket-request-payment --bucket quitanda-curated-prod
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key shared/history.csv history-copy.csv --request-payer requester --query ContentLength
52
```

**moto 5.2.3 does not implement the setting.** The `put-bucket-request-payment` failed with
`IllegalLocationConstraintException`, the error for creating a bucket in the wrong place, which is the
same misrouting lesson 2 met with Intelligent-Tiering: the request reached the code that creates
buckets. `get-bucket-request-payment` answered with nothing, where S3 answers `{"Payer":
"BucketOwner"}` for a bucket that has never been changed. And a `GET` with `--request-payer
requester` succeeded on a bucket that never required it, which on S3 succeeds too: the header is a
promise to pay, and a bucket that charges nothing ignores it.

So nothing of requester pays was run here beyond that. What it does to a bill is the arithmetic of
the previous sections with the payer changed: the partner's 5 TB copy to us-east-1 costs
5,120 × 0.13800 = 706.56 whoever pays, and requester pays decides whose bill it is on.
