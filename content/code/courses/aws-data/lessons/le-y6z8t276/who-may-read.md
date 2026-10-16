---
title: An identity policy that really denies
version: 1
---

**An identity policy says what one user or role may do, and everything it does not allow is denied.**
`aws-foundations` lesson 8 is where that evaluation was taught; here it meets S3. The one thing this
lab could not show until now is a denial, because by default moto evaluates no policy: lesson 1
listed a bucket with a key nobody had issued.

moto has a second mode that does evaluate identity policies. It is turned on by a variable on the
server, `INITIAL_NO_AUTH_ACTION_COUNT`, which is the number of requests moto lets through unchecked
before it starts checking every one. Those first requests are the setup: a bucket, a report, a user,
the user's policy and the user's key, five requests in all. Stop moto with `Ctrl+C` in its terminal
and start it again like this:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=5 moto_server -p 4567
```

From the sixth request on, moto checks that the key exists in its IAM, and that the key's user is
allowed the action. The key `test` is in nobody's IAM, so it works only for the first five.

## The setup, five requests

The dashboard that shows Quitanda's reports needs to read them and nothing else. Its policy:

`reader.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::quitanda-curated-prod/reports/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::quitanda-curated-prod"
    }
  ]
}
```

`GetObject` is allowed on the objects under `reports/` and `ListBucket` on the bucket itself, which is
a different resource: an object's ARN carries its key, the bucket's does not. Now the five requests:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3 cp daily.csv s3://quitanda-curated-prod/reports/daily.csv
upload: ./daily.csv to s3://quitanda-curated-prod/reports/daily.csv
ana@laptop:~/aws$ aws iam create-user --user-name dashboard --query User.Arn --output text
arn:aws:iam::123456789012:user/dashboard
ana@laptop:~/aws$ aws iam put-user-policy --user-name dashboard --policy-name read-reports --policy-document file://reader.json
```

The fifth request creates the dashboard's access key, and **the secret key is never printed**: a
secret on a screen is a secret in a terminal's history, in a recording, in a screenshot. The command
below reads both halves into variables and puts them where the command line looks for keys, so that
the rest of this terminal speaks as the dashboard:

```sh
read -r AK SK < <(aws iam create-access-key --user-name dashboard \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)
export AWS_ACCESS_KEY_ID=$AK AWS_SECRET_ACCESS_KEY=$SK
```

## The dashboard's view of the bucket

```
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/dashboard
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
day,orders,total_cents
2026-10-15,412,5108840
ana@laptop:~/aws$ aws s3 cp daily.csv s3://quitanda-curated-prod/reports/edited.csv
upload failed: ./daily.csv to s3://quitanda-curated-prod/reports/edited.csv An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
ana@laptop:~/aws$ aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
download failed: s3://quitanda-curated-prod/reports/daily.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
```

**The read succeeded and the write was refused with `AccessDenied`.** Nothing in the policy names
`PutObject`, so it is denied without a `Deny` anywhere, which is the default every policy starts from.
`ListBuckets`, the request behind a bare `aws s3 ls`, was refused for the same reason. And
`get-caller-identity` names the user, which is the first thing to check whenever a permission behaves
unexpectedly: the question is always which identity asked. The last command signs with `test` again,
and is refused, because from the sixth request on that key belongs to nobody.

## The SignatureDoesNotMatch that is moto's

Listing the bucket is where this mode trips over itself, with an error that has nothing to do with
permissions:

```
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod

aws: [ERROR]: An error occurred (SignatureDoesNotMatch) when calling the ListObjectsV2 operation: The request signature we calculated does not match the signature you provided. Check your key and signing method.
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod --recursive
2026-10-16 13:26:15         46 reports/daily.csv
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-curated-prod --prefix reports/ --query 'Contents[].Key'

aws: [ERROR]: An error occurred (SignatureDoesNotMatch) when calling the ListObjectsV2 operation: The request signature we calculated does not match the signature you provided. Check your key and signing method.
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-curated-prod --prefix reports --query 'Contents[].Key'
[
    "reports/daily.csv"
]
ana@laptop:~/aws$ url=$(aws s3 presign s3://quitanda-curated-prod/reports/daily.csv); curl -s -o /dev/null -w '%{http_code}\n' "$url"
500
```

**`--recursive` worked and the plain listing did not, with the same key, for the same bucket.** The
difference is a slash. A plain `aws s3 ls` sends `delimiter=/` in its query string, to group keys into
the `PRE` lines of lesson 1, and the `--prefix reports/` of the third command puts another one there.
In this mode moto recomputes each request's signature to compare it with the one sent, and its
recomputation goes wrong when a query value contains `/`: the two signatures differ and moto blames
the client. S3 accepts the same requests. The way round it here is to list with `--recursive`, or
with a prefix that has no slash.

moto in this mode also fails to serve presigned URLs at all, with an internal error, which is why the
previous section ran in the default mode.

## Back to the default mode

The terminal now holds the dashboard's keys, and moto refuses `test`. Stop moto with `Ctrl+C`, start
it the usual way, `moto_server -p 4567`, and put the keys back:

```sh
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
```

The rest of this lesson runs in the default mode, and the next sections say where that hides what S3
would do.
