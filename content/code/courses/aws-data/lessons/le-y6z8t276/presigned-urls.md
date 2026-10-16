---
title: Presigned URLs, and what a URL carries
version: 1
---

**A presigned URL is a request that somebody signed in advance and handed over**: whoever holds the
URL can make that one request, with the signer's authority, until it expires. It is how Quitanda
lets a supplier download one invoice without an AWS account, and it is not a link to a public object.
The object stays private. What travels is permission, written into a string.

The wrong picture is that the URL is checked against something stored in S3, a list of links that
were issued. Nothing is stored. The command line computes the URL on your computer from your key,
and S3 checks it only when it is used, by repeating the same calculation.

This lesson starts from an empty moto, with moto running in its own terminal and the four lines of
lesson 1's "Your lab, in brief" typed in this one. Put a report in the curated bucket and presign it:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ printf 'day,orders,total_cents\n2026-10-15,412,5108840\n' > daily.csv && aws s3 cp daily.csv s3://quitanda-curated-prod/reports/daily.csv
upload: ./daily.csv to s3://quitanda-curated-prod/reports/daily.csv
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 300
http://localhost:4567/quitanda-curated-prod/reports/daily.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162605Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=028918085b4b621becb5ef8e0c0a01321cd2584af9492daecd84bc72d688ed21
ana@laptop:~/aws$ curl -s 'http://localhost:4567/quitanda-curated-prod/reports/daily.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162606Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=f1740fdcd82ed153929e93419e54eed0c820607234d007841ef57143557e848b'
day,orders,total_cents
2026-10-15,412,5108840
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 300 | tr '?&' '\n\n'
http://localhost:4567/quitanda-curated-prod/reports/daily.csv
X-Amz-Algorithm=AWS4-HMAC-SHA256
X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request
X-Amz-Date=20261016T162606Z
X-Amz-Expires=300
X-Amz-SignedHeaders=host
X-Amz-Signature=f1740fdcd82ed153929e93419e54eed0c820607234d007841ef57143557e848b
```

**The URL is the object's address with six parameters**, and they are the whole of the permission:

| parameter | what it says |
|---|---|
| `X-Amz-Algorithm` | the signing method, Signature Version 4 |
| `X-Amz-Credential` | the signer's access key id, the date, the region and the service |
| `X-Amz-Date` | the moment it was signed |
| `X-Amz-Expires` | how many seconds after that moment it stays valid |
| `X-Amz-SignedHeaders` | which headers the signature covers, here only `host` |
| `X-Amz-Signature` | the signature over all of it, made with the secret key |

Two consequences follow from that table. **The key id is in the URL**, here `test`, and on AWS that
is a real access key id, so a presigned URL pasted into a chat tells everybody who reads it which key
signed it. The secret key is not in it. And **the URL says nothing about who may use it**: no
address, no account, no password. Possession is the whole check.

## Making a URL checks nothing

```
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/no-such-report.csv
http://localhost:4567/quitanda-curated-prod/reports/no-such-report.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162607Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=ae0e056e32c1c1300a8c83be665e207aa60963eed821ee57918a512c2b7c2aeb
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' 'http://localhost:4567/quitanda-curated-prod/reports/no-such-report.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162608Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=36757897347ff035fa98212ceb794e46b6062834693319ded7ab3ecb36201c16'
404
```

**A URL for a key that does not exist was produced without complaint**, because producing it sent no
request at all. Only using it asked moto, which answered `NoSuchKey`. The same holds for
permissions: on AWS, a user who may not read the bucket can still produce a well-formed URL, and the
URL fails when used, because S3 checks **the signer's permissions at the moment of use**. Revoke the
signer's access, or deactivate the key that signed it, and every URL it signed stops working.

## Expiry, on AWS and in moto

`--expires-in` takes seconds and defaults to 3600, one hour. On AWS, a URL signed with an IAM user's
long-term key may live up to seven days, 604,800 seconds. One signed with temporary credentials, a
role's, stops working when those credentials expire, whatever `X-Amz-Expires` says, which for a
role's session is usually an hour or a few. After expiry S3 answers `403` with `Request has expired`.

moto does not enforce any of that:

```
ana@laptop:~/aws$ url=$(aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 1); sleep 3; curl -s -w '%{http_code}\n' "$url"
day,orders,total_cents
2026-10-15,412,5108840
200
ana@laptop:~/aws$ url=$(aws s3 presign s3://quitanda-curated-prod/reports/daily.csv); curl -s -w '%{http_code}\n' "${url%?}x"
day,orders,total_cents
2026-10-15,412,5108840
200
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 604801 | grep -o 'X-Amz-Expires=[0-9]*'
X-Amz-Expires=604801
```

**A URL valid for one second was used three seconds later, and moto served the report.** The URL with
the last character of its signature replaced by an `x` was served too, where S3 would answer
`SignatureDoesNotMatch`. And the command line produced a URL valid for 604,801 seconds, one more than
the limit, because the limit is S3's to enforce when the URL is used, not the command line's when it
is made. None of S3's answers here was produced; they are AWS's documented behaviour.

**So in this lab a presigned URL can show its shape and nothing about its safety.** The habits that
make one safe come from the documentation, and they are cheap. Use the shortest expiry that does the
job: minutes for a download a person clicks now, never days. Sign with a role that can read that one
prefix and nothing else, so that a leaked URL is worth one prefix. And never put a URL in a place
that is kept, such as a ticket, a log or a commit, because the URL is the permission.
