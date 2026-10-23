---
title: The cloud engineer's share button
version: 1
---

**S3 has its own *anyone with the link*: a presigned URL.** It is an ordinary address for one object,
with a signature appended that was computed from somebody's access key. Whoever holds the address can
download that object, without an AWS account, until the time written into it runs out. It is the
right tool for handing one file to one person outside the company, and it has every property of the
links in the section before: it is a bearer key, it travels, and the bucket keeps no list of the
links that were made.

caio uses one to send patients their exam results. Start moto in the first terminal, read `env.sh`
in both, and build the result he is about to send:

```sh
cat > result.txt <<'EOF'
patient: Maria Souza
exam: complete blood count
result: within the reference range
EOF
```

Then a bucket, with the result in it:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-results --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-results
ana@laptop:~/aws$ aws s3 cp --no-progress result.txt s3://clinic-results/maria-souza/2026-10-23.txt
upload: ./result.txt to s3://clinic-results/maria-souza/2026-10-23.txt
```

The bucket is private, and an anonymous request for the object proves it:

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-results/maria-souza/2026-10-23.txt
403
```

## Making the link

`aws s3 presign` signs the address locally, with the key in your environment, and prints it. It
sends nothing to AWS: the signature is arithmetic on the key, the object's name and the time.

```
ana@laptop:~/aws$ aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 900
http://localhost:4567/clinic-results/maria-souza/2026-10-23.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261023%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261023T034331Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8cb1e1853a2701505dd4ffacb3baa056b797ef85712933405fc5890fba667f9b
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l10-presigned\" aria-label=\"The parts of the presigned URL the lab printed, one per row. The address names the bucket and the object. X-Amz-Algorithm says how it was signed. X-Amz-Credential names the access key that signed it, with the date, the region and the service: on AWS this is the key id, which says whose key is handing the file out. X-Amz-Date is when it was signed and X-Amz-Expires how many seconds it lasts from then. X-Amz-SignedHeaders lists what else the signature covers. X-Amz-Signature is computed from the secret key over everything above it, so changing any part breaks it.\"><defs><marker id=\"l10-presigned-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"22.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost:4567/clinic-results/maria-souza/…</text><text x=\"430.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">which object</text><rect x=\"30.0\" y=\"66.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Algorithm=AWS4-HMAC-SHA256</text><text x=\"430.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">how it was signed</text><rect x=\"30.0\" y=\"110.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Credential=test/20261023/sa-east-1/s3</text><text x=\"430.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">whose key signed it</text><rect x=\"30.0\" y=\"154.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Date=20261023T…</text><text x=\"430.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">when it was signed</text><rect x=\"30.0\" y=\"198.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Expires=900</text><text x=\"430.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">seconds it lasts from then</text><rect x=\"30.0\" y=\"242.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-SignedHeaders=host</text><text x=\"430.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what else is covered</text><path d=\"M418 22 L424 22 L424 278 L418 278\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"30.0\" y=\"292.0\" width=\"380.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"44.0\" y=\"310.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-Amz-Signature=…</text><text x=\"430.0\" y=\"302.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">computed from the secret key</text><text x=\"430.0\" y=\"319.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">over every row above</text><path d=\"M424.0 290.0 L424.0 280.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-presigned-af-ah-phosphor)\"></path></svg>", "caption": "Everything a defender can learn from a link is in it: the key that signed it, and when it stops working. Nothing about it is stored in the bucket."}
```

**`X-Amz-Credential` names the key that signed it**, and that is the handle a defender gets. Here it
is moto's `test`; against AWS it is an access key id such as `AKIA…`, which is not secret and is
exactly what tells you whose key is giving files away. `X-Amz-Expires=900` is fifteen minutes,
counted from `X-Amz-Date`. The signature covers all of them, so changing the expiry in the address
breaks the signature, and AWS refuses the request.

Anybody with the address can now read the file, with no credentials of their own:

```
ana@laptop:~/aws$ url=$(aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 900)
ana@laptop:~/aws$ curl -s "$url"
patient: Maria Souza
exam: complete blood count
result: within the reference range
```

## Where the lab stops being AWS

Make a link that lasts ten seconds, wait fifteen, and use it:

```
ana@laptop:~/aws$ url=$(aws s3 presign s3://clinic-results/maria-souza/2026-10-23.txt --expires-in 10); sleep 15; curl -s -w " %{http_code}\n" "$url"
patient: Maria Souza
exam: complete blood count
result: within the reference range
 200
```

**moto served it.** moto 5.2.3 does not check a presigned URL's expiry, and it does not check its
signature either. AWS checks both: past the expiry it answers `403` with the error code
`AccessDenied` and the message *Request has expired*, and an address whose signature does not match
gets `SignatureDoesNotMatch`. **Those two refusals come from AWS's documentation and were not run
here.** What the lab shows truly is the half that matters most to a defender: until it expires, a
presigned URL works for anybody, and nothing in the bucket records that it was made.

## How long a link can live, and how to take one back

Three rules from AWS's documentation, none of them run here:

- **A link signed with an IAM user's long-lived key can last at most seven days**, 604,800 seconds.
  The command line will print a longer one, and AWS refuses it when it is used.
- **A link signed with temporary credentials dies when they do.** A role session of one hour makes
  links that stop working within the hour, whatever `--expires-in` said. That is a reason to sign
  from a role rather than from a user.
- **A link carries the signer's permissions at the moment it is used, not at the moment it was
  made.** Deactivate or delete the key that signed it, or take away that identity's permission to
  read the object, and every link it ever signed stops working. That is the only way to revoke one,
  because there is no list of links to delete from.

Which is why the clinic should never sign result links with a person's own key. **A dedicated role
that may read `clinic-results` and nothing else**, used only for signing, can be revoked in one step
without locking anybody out, and its key id in a log says at once what the link was for. Lesson 6 is
about building identities that narrow; this is one of them.
