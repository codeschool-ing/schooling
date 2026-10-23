---
title: Four ways a bucket answers everybody
version: 1
---

**An S3 object is readable by a stranger when any one of four grants says so: a bucket policy, a
bucket ACL, an object ACL, or a grant to "any authenticated AWS user", which is nearly the same
thing.** A review that reads only the bucket policy misses three of them, and the object ACL is the
one most often missed, because it is set file by file and never shows on the bucket.

The wrong picture is that a bucket is either public or private, as one switch. It is a bucket with
a policy and an access list, holding objects that each have an access list of their own. **Public
is a property of a request being answered**, and it can be true of one object and false of its
neighbour in the same bucket.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l09-paths\" aria-label=\"Four grants make an S3 object readable by somebody outside the account, and each lives in a different place. On the bucket: a bucket policy whose principal is a star, which answers everyone, and a bucket ACL granting READ to AllUsers, which lets everyone list the keys. On each object: an object ACL granting READ to AllUsers, which answers everyone, and an object ACL granting READ to AuthenticatedUsers, which answers anybody with an AWS account. Above all four sits Block Public Access, which refuses new public grants and ignores existing ones.\"><defs><marker id=\"l09-paths-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30.0\" y=\"16.0\" width=\"660.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Block Public Access, above every grant</text><text x=\"360.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refuses new public grants and ignores the ones already written</text><rect x=\"30.0\" y=\"84.0\" width=\"660.0\" height=\"262.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"46.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">the bucket</text><text x=\"470.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">who it answers</text><rect x=\"46.0\" y=\"222.0\" width=\"400.0\" height=\"112.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">each object, on its own</text><circle cx=\"70.0\" cy=\"130.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">1</text><text x=\"90.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bucket policy</text><text x=\"90.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Principal: &quot;*&quot;</text><path d=\"M400.0 130.0 L462.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">everyone</text><circle cx=\"70.0\" cy=\"178.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">2</text><text x=\"90.0\" y=\"171.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bucket ACL</text><text x=\"90.0\" y=\"187.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllUsers READ</text><path d=\"M400.0 178.0 L462.0 178.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">everyone, as a list of keys</text><circle cx=\"70.0\" cy=\"262.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">3</text><text x=\"90.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">object ACL</text><text x=\"90.0\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllUsers READ</text><path d=\"M400.0 262.0 L462.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">everyone</text><circle cx=\"70.0\" cy=\"310.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"310.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">4</text><text x=\"90.0\" y=\"303.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">object ACL</text><text x=\"90.0\" y=\"319.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AuthenticatedUsers READ</text><path d=\"M400.0 310.0 L462.0 310.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"310.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">anybody with an AWS account</text></svg>", "caption": "A review that reads only the bucket policy sees route 1. Routes 3 and 4 are set file by file and never show on the bucket, and route 4 refuses the anonymous test that would catch it."}
```

## The policy, which lesson 1 showed

`"Principal": "*"` with `s3:GetObject` on `bucket/*` made every object readable at once. That is the
route most write-ups describe and the one easiest to spot, since the policy is one document per
bucket. It is not repeated here.

## An object ACL

ACLs are older than bucket policies: a short list of grants attached to the bucket and to every
object, from the first years of S3. Start moto in the first terminal, empty, and read `env.sh` in
both. The clinic sends referral letters to partner hospitals through a bucket, and caio wrote the
upload so that the hospital could open the link without signing in. Create a letter:

```sh
cat > referral-0412.txt <<'EOF'
Referral 0412 — 2026-10-21
Patient: Maria Souza, born 1984-03-02
To: Hospital Central, cardiology
Reason: abnormal ECG at routine visit
EOF
```

Upload it the way caio's code does, and ask for it as a stranger, with `curl`:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-referrals --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-referrals
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-referrals --key referral-0412.txt --body referral-0412.txt --acl public-read --query ETag --output text
"5b9687d0219a87fd262f5fe3c05e716f"
ana@laptop:~/aws$ curl -s -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt
Referral 0412 — 2026-10-21
Patient: Maria Souza, born 1984-03-02
To: Hospital Central, cardiology
Reason: abnormal ECG at routine visit
200
```

**The bucket has no policy at all, and the letter is public.** `--acl public-read` on the upload gave
the object a grant to a group AWS calls `AllUsers`, which is everybody on the internet, signed in
or not. Read the object's access list:

```
ana@laptop:~/aws$ aws s3api get-object-acl --bucket clinic-referrals --key referral-0412.txt --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket clinic-referrals

aws: [ERROR]: An error occurred (NoSuchBucketPolicy) when calling the GetBucketPolicy operation: The bucket policy does not exist
```

The first grant, with no URI, is the owner's `FULL_CONTROL`. The second is the exposure. Nothing in
`get-bucket-policy` or in the bucket's own ACL would have shown it, since it lives on this one file.

## A bucket ACL

The same grant on the bucket gives everybody `READ` on the bucket itself, which for a bucket means
**listing its keys**: not the contents, but every file name in it, which for referral letters is a
list of patients' cases.

```
ana@laptop:~/aws$ aws s3api put-bucket-acl --bucket clinic-referrals --acl public-read
ana@laptop:~/aws$ aws s3api get-bucket-acl --bucket clinic-referrals --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
```

The listing itself is not shown here, and the reason is moto's: it answers an anonymous listing of
any bucket, even a private one, where AWS refuses. A transcript of it would prove nothing about the
grant. The grant itself, `AllUsers` with `READ`, is what a review looks for.

## Any authenticated AWS user

The fourth grant reads like a restriction and is not one. `authenticated-read` gives `READ` to the
group `AuthenticatedUsers`, and AWS's documentation is explicit about what that group is: **anybody
with an AWS account, in any organisation in the world**, not the users of yours. bia's monthly report
goes to a second bucket that way:

```sh
cat > report-2026-09.csv <<'EOF'
month,appointments,no_shows,new_patients
2026-09,1184,97,212
EOF
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-reports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-reports
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-reports --key report-2026-09.csv --body report-2026-09.csv --acl authenticated-read --query ETag --output text
"866b00c18f749ee66eef30bd0b8dd3d6"
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-reports/report-2026-09.csv
403
ana@laptop:~/aws$ aws s3api get-object-acl --bucket clinic-reports --key report-2026-09.csv --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AuthenticatedUsers	READ
```

**An anonymous request is refused, and that is exactly what makes this grant dangerous.** The
`403` is what somebody testing it with `curl` sees, and they conclude it is private. Anybody who
signs the same request with a key from their own AWS account is answered. moto, with its
checking off, accepts any signed request, so the lab cannot show the difference between your key
and a stranger's, and the claim rests on AWS's documentation.

Clean up the bucket ACL before going on, so that the next sections start from the object grants:

```
ana@laptop:~/aws$ aws s3api put-bucket-acl --bucket clinic-referrals --acl private
ana@laptop:~/aws$ aws s3api get-bucket-acl --bucket clinic-referrals --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
```
