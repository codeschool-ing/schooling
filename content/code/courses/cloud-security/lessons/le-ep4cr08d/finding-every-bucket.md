---
title: Asking every bucket
version: 1
---

**The four routes of the second section can all be read from the API, and one of them can only be
proved by asking.** A short program that reads every bucket's guardrail, policy and access lists, and
then requests every object without credentials, finds every exposure this lesson has shown. It is
the bucket version of lesson 8's network checker, and it has the same limit: it says where something
is open, and only somebody who knows the clinic says whether it should be.

## The checker

Save this as `public_buckets.py` in `~/aws`:

```schooling-example
{"language": "python", "file": "public_buckets.py", "parts": [{"code": "import json\nimport os\nimport urllib.error\nimport urllib.parse\nimport urllib.request\n\nimport boto3\n\ns3 = boto3.client(\"s3\")\nEVERYONE = {\"http://acs.amazonaws.com/groups/global/AllUsers\": \"everyone\",\n            \"http://acs.amazonaws.com/groups/global/AuthenticatedUsers\": \"every AWS account\"}\n", "note": "Only the standard library and boto3, which came with moto. The two group URIs are the only grantees in an ACL that mean somebody outside your account; both count as public."}, {"code": "\n\ndef public_grants(acl):\n    return [f\"{EVERYONE[g['Grantee']['URI']]} may {g['Permission']}\"\n            for g in acl[\"Grants\"] if g[\"Grantee\"].get(\"URI\") in EVERYONE]\n", "note": "Turns an access list, of a bucket or of an object, into sentences. A grant to a person or an account carries no URI and is left alone."}, {"code": "\n\ndef anonymous_status(bucket, key):\n    endpoint = os.environ.get(\"AWS_ENDPOINT_URL\")\n    base = f\"{endpoint}/{bucket}\" if endpoint else f\"https://{bucket}.s3.amazonaws.com\"\n    try:\n        with urllib.request.urlopen(f\"{base}/{urllib.parse.quote(key)}\") as answer:\n            return answer.status\n    except urllib.error.HTTPError as refused:\n        return refused.code\n", "note": "The stranger's question: a plain GET with no credentials, against moto in the lab and against the bucket's real address otherwise. Ask it only of buckets that are yours."}, {"code": "\n\nfor bucket in [b[\"Name\"] for b in s3.list_buckets()[\"Buckets\"]]:\n    findings = []\n    try:\n        block = s3.get_public_access_block(Bucket=bucket)[\"PublicAccessBlockConfiguration\"]\n        if not all(block.values()):\n            findings.append(\"Block Public Access is partly off\")\n    except s3.exceptions.ClientError:\n        findings.append(\"no Block Public Access\")\n", "note": "First the guardrail. A bucket with no configuration at all answers with an error, which here is a finding rather than a failure."}, {"code": "    try:\n        policy = json.loads(s3.get_bucket_policy(Bucket=bucket)[\"Policy\"])\n        for st in policy[\"Statement\"]:\n            if st[\"Effect\"] == \"Allow\" and st.get(\"Principal\") in (\"*\", {\"AWS\": \"*\"}):\n                findings.append(f\"policy allows {st['Action']} to everyone\")\n    except s3.exceptions.ClientError:\n        pass\n    findings += [\"bucket ACL: \" + g for g in public_grants(s3.get_bucket_acl(Bucket=bucket))]\n", "note": "Then the bucket's two documents. A policy statement with a condition is still reported: the condition may narrow it, and that is a reading for a person. No policy is an error too, and the right answer."}, {"code": "    for obj in s3.list_objects_v2(Bucket=bucket).get(\"Contents\", []):\n        key = obj[\"Key\"]\n        findings += [f\"{key} ACL: \" + g for g in public_grants(s3.get_object_acl(Bucket=bucket, Key=key))]\n        if anonymous_status(bucket, key) == 200:\n            findings.append(f\"{key} ANSWERS AN ANONYMOUS REQUEST\")\n    print(bucket)\n    for finding in findings or [\"nothing found\"]:\n        print(\"   \", finding)\n", "note": "Then every object, which is the route a bucket-level review misses. That is two requests an object, and `list_objects_v2` returns at most a thousand keys, which is all this loop reads; a bucket of millions wants S3 Inventory instead."}]}
```

**Read the anonymous probe as what it is.** Sending an unsigned request to your own bucket is the
same test lesson 1 taught, done for every object. It is not a tool for anybody else's storage, and
it needs nothing from anybody else's: the program only probes the buckets your own credentials list.

## Running it

A third bucket, holding the patient records the clinic actually has to protect, is set up the way
every bucket should be, and it is there so the checker has something to pass:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-records --key referrals/referral-0412.txt --body referral-0412.txt --query ETag --output text
"5b9687d0219a87fd262f5fe3c05e716f"
```

```
ana@laptop:~/aws$ python3 public_buckets.py
clinic-referrals
    referral-0412.txt ACL: everyone may READ
    referral-0412.txt ANSWERS AN ANONYMOUS REQUEST
clinic-reports
    no Block Public Access
    report-2026-09.csv ACL: every AWS account may READ
clinic-records
    nothing found
```

Three buckets, three different stories:

- **`clinic-records`** has the guardrail on and grants nobody outside the account anything.
  *Nothing found* is the answer to want, and it is worth seeing once, so that you trust the checker
  when it says it;
- **`clinic-referrals`** has all four switches on and is still flagged twice: the letter's ACL says
  `everyone may READ`, and the letter answered an anonymous request. On AWS, `IgnorePublicAcls`
  would have made that request fail, and only the ACL line would remain, as a grant written down and
  ignored. moto enforces neither, so the lab shows the worse case;
- **`clinic-reports`** has no guardrail and a grant to every AWS account, and it **did not answer**
  the anonymous request. Only the ACL line catches it. That is why the checker reads the lists as
  well as asking: a probe without a signature cannot see the grant that needs one.
