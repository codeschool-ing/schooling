---
title: A scanner you can read in one sitting
version: 1
---

**A posture scanner is a loop over the API with a rule inside it.** The program below is one, short
enough to read whole: four rules, three services, one region. Save it as `~/aws/scan.py`.
Nothing needs installing, since boto3, the AWS library for Python, came with moto into `~/aws/venv`.

```schooling-example
{"language": "python", "file": "scan.py", "parts": [{"code": "import datetime\nimport json\nimport sys\n\nimport boto3\nfrom botocore.exceptions import ClientError\n\ns3 = boto3.client(\"s3\")\nec2 = boto3.client(\"ec2\")\niam = boto3.client(\"iam\")\nfindings = []\n\n", "note": "Three clients, one per service it reads. boto3 is the AWS library for Python, installed with moto in `~/aws/venv`, and it takes the endpoint, the region and the key from the same variables `env.sh` sets, so the program talks to moto with no address in it."}, {"code": "accepted = {}\ntry:\n    for line in open(\"accepted.txt\"):\n        rule, resource, until, reason = line.split(maxsplit=3)\n        accepted[(rule, resource)] = (datetime.date.fromisoformat(until), reason.strip())\nexcept FileNotFoundError:\n    pass\n\n", "note": "The exceptions somebody decided, one a line: the rule, the resource, the last day the decision holds and why. No file means no exceptions. The next section writes one."}, {"code": "for bucket in s3.list_buckets()[\"Buckets\"]:\n    name = bucket[\"Name\"]\n    try:\n        policy = json.loads(s3.get_bucket_policy(Bucket=name)[\"Policy\"])\n    except ClientError:\n        policy = {\"Statement\": []}\n    for st in policy[\"Statement\"]:\n        if st[\"Effect\"] == \"Allow\" and st.get(\"Principal\") in (\"*\", {\"AWS\": \"*\"}):\n            findings.append((\"public-bucket\", name, f\"{st['Action']} allowed to everybody\"))\n    try:\n        s3.get_bucket_encryption(Bucket=name)\n    except ClientError:\n        findings.append((\"unencrypted-bucket\", name, \"no default encryption\"))\n\n", "note": "Two rules per bucket. A policy statement that allows anything to `\"*\"` makes it public, which is lesson 9's fault. A bucket that answers `get-bucket-encryption` with an error has no default encryption, lesson 11's. An ACL can make an object public too, and this rule does not read ACLs: a real tool does."}, {"code": "for group in ec2.describe_security_groups()[\"SecurityGroups\"]:\n    for rule in group[\"IpPermissions\"]:\n        if not any(r[\"CidrIp\"] == \"0.0.0.0/0\" for r in rule.get(\"IpRanges\", [])):\n            continue\n        for port in (22, 3389):\n            if rule.get(\"FromPort\", 0) <= port <= rule.get(\"ToPort\", 65535):\n                findings.append((\"admin-port-open\", group[\"GroupId\"], f\"port {port} open to 0.0.0.0/0\"))\n\n", "note": "A rule open to `0.0.0.0/0` whose port range covers SSH or Windows remote desktop. A rule for every protocol carries no ports at all, so the missing `FromPort` and `ToPort` default to the whole range, and it is caught too."}, {"code": "for user in iam.list_users()[\"Users\"]:\n    if not iam.list_mfa_devices(UserName=user[\"UserName\"])[\"MFADevices\"]:\n        findings.append((\"user-without-mfa\", user[\"UserName\"], \"no MFA device\"))\n\n", "note": "Every user with no MFA device registered, lesson 6's rule. A user for a program has no second factor by design; the clinic's account has none of those, and a real rule would tell the two apart."}, {"code": "still_open = 0\nfor rule, resource, detail in findings:\n    until, reason = accepted.get((rule, resource), (None, None))\n    if until and until >= datetime.date.today():\n        print(f\"accepted  {rule:19} {resource:21} until {until}: {reason}\")\n    else:\n        still_open += 1\n        print(f\"OPEN      {rule:19} {resource:21} {detail}\")\nprint(f\"{still_open} open, {len(findings) - still_open} accepted\")\nsys.exit(1 if still_open else 0)\n", "note": "Each finding is open unless an exception covers it and has not expired; an expired one is open again without anybody remembering to reopen it. The exit code is 1 while anything is open, which is what lets lesson 14 put this program in a pipeline as a gate."}]}
```

Run it against the account the previous section built:

```
ana@laptop:~/aws$ python3 scan.py; echo "exit $?"
OPEN      public-bucket       clinic-web            s3:GetObject allowed to everybody
OPEN      unencrypted-bucket  clinic-exports        no default encryption
OPEN      admin-port-open     sg-d877b106d3b8c910b  port 22 open to 0.0.0.0/0
OPEN      user-without-mfa    bia                   no MFA device
4 open, 0 accepted
exit 1
```

**Four findings, the four faults, and nothing else.** caio has a second factor and is not listed.
`clinic-records` is encrypted and private and is not listed. The default security group has no rule
open to the world, so only `booking-admin` appears. And the exit code says what a person would
otherwise have to read the screen for: something is open.

## What the fifty-six lines leave out

This is where a real product earns its price, and where a home-made scanner gives false comfort if
you forget its edges:

- **One region.** The clients take `sa-east-1` from `env.sh` and read nothing else. Lesson 1 found a
  default network in each of moto's 38 regions; a security group opened in `us-east-1` is invisible
  to this program. A real tool asks every region the account has enabled.
- **Four rules.** The CIS AWS Foundations Benchmark has dozens, and a product carries hundreds, one
  for each setting of each service that can be set wrong.
- **One account.** The clinic has one. A company with an organisation of fifty accounts needs the
  scanner to assume a role into each, which lesson 6's federation makes possible.
- **No ACLs, no history.** The bucket rule reads policies and not access control lists, and the
  program remembers nothing between runs, so it cannot say when a fault appeared.

None of that makes it useless. It makes it a rule list you can read in full, which no product is,
and **every rule in it is a decision you can explain**. That is worth keeping even after a product
arrives: when a commercial tool and this program disagree, one of them has a rule you can check.
