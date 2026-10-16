---
title: Security Hub, one queue in one format
version: 1
---

Security Hub is enabled once per account and region. The flag keeps it from turning on the default
standards, whose checks would find nothing to check in moto:

```
ana@laptop:~/aws/findings$ aws securityhub enable-security-hub --no-enable-default-standards
ana@laptop:~/aws/findings$ aws securityhub describe-hub --query '[HubArn,ControlFindingGenerator]' --output text
arn:aws:securityhub:sa-east-1:123456789012:hub/default	SECURITY_CONTROL
```

`SECURITY_CONTROL` means that a failed control produces **one finding per control and resource**, not
one per standard: a bucket failing the same check in two standards is one finding, not two. On AWS, the
standards then run their checks every twelve hours or on every configuration change, depending on the
control, and the findings appear without anybody importing them.

## Findings, in the format

The lab has to bring its own. `mk-findings.py`, in `~/aws/findings`, writes six made-up findings in ASFF,
two in the shape GuardDuty writes, two in Inspector's, two in Security Hub's own:

```python
# mk-findings.py: six made-up findings in AWS's finding format, for the lab
import json

ACCOUNT = "123456789012"
PRODUCT = f"arn:aws:securityhub:sa-east-1:{ACCOUNT}:product/{ACCOUNT}/default"
# id, imitating, type, severity, title, resource type, resource id, exploit available
rows = [
    ("gd-1", "guardduty", "TTPs/Initial Access/UnauthorizedAccess:IAMUser-InstanceCredentialExfiltration.OutsideAWS",
     "HIGH", "Instance credentials used from outside AWS", "AwsIamRole", "shop-api-task", None),
    ("gd-2", "guardduty", "TTPs/Discovery/Recon:EC2-PortProbeUnprotectedPort",
     "LOW", "Port 22 probed on an instance", "AwsEc2Instance", "i-0lab1", None),
    ("in-1", "inspector", "Software and Configuration Checks/Vulnerabilities/CVE",
     "CRITICAL", "CVE in a library of the api image", "AwsEcrContainerImage", "shop/api:9f1c2ab34de5", "YES"),
    ("in-2", "inspector", "Software and Configuration Checks/Vulnerabilities/CVE",
     "CRITICAL", "CVE in a build tool of the worker image", "AwsEcrContainerImage", "shop/worker:77ad01", "NO"),
    ("sh-1", "security-hub", "Software and Configuration Checks/Industry and Regulatory Standards",
     "HIGH", "S3 bucket allows public read", "AwsS3Bucket", "shop-exports", None),
    ("sh-2", "security-hub", "Software and Configuration Checks/Industry and Regulatory Standards",
     "MEDIUM", "CloudTrail log file validation is off", "AwsCloudTrailTrail", "shop-trail", None),
]
findings = []
for fid, gen, ftype, sev, title, rtype, rid, exploit in rows:
    f = {
        "SchemaVersion": "2018-10-08", "Id": fid, "ProductArn": PRODUCT, "GeneratorId": f"lab-{gen}",
        "AwsAccountId": ACCOUNT, "Types": [ftype], "Title": title, "Description": title,
        "CreatedAt": "2026-10-16T10:00:00Z", "UpdatedAt": "2026-10-16T10:00:00Z",
        "Severity": {"Label": sev}, "Resources": [{"Type": rtype, "Id": rid}],
    }
    if exploit:
        f["Vulnerabilities"] = [{"Id": "CVE-lab", "ExploitAvailable": exploit}]
    findings.append(f)
json.dump(findings, open("findings.json", "w"), indent=1)
print(len(findings), "findings written")
```

The fields every finding carries are the ones the program fills: an `Id` unique within its product, the
`ProductArn` of who produced it, the `Types` in a three-level taxonomy, a `Severity` label, a `Title`, and
the `Resources` it is about. Inspector's add `Vulnerabilities`, and `ExploitAvailable` there says whether
an exploit for the CVE is published: two critical CVEs, one with an exploit and one without, which the
next section treats very differently.

```
ana@laptop:~/aws/findings$ python3 mk-findings.py
6 findings written
ana@laptop:~/aws/findings$ aws securityhub batch-import-findings --findings file://findings.json --query '[SuccessCount,FailedCount]' --output text
6	0
ana@laptop:~/aws/findings$ aws securityhub get-findings --query 'Findings[].[Id,Severity.Label,Title]' --output text
gd-1	HIGH	Instance credentials used from outside AWS
gd-2	LOW	Port 22 probed on an instance
in-1	CRITICAL	CVE in a library of the api image
in-2	CRITICAL	CVE in a build tool of the worker image
sh-1	HIGH	S3 bucket allows public read
sh-2	MEDIUM	CloudTrail log file validation is off
```

On AWS every finding also gets a **workflow status**, `NEW` until somebody sets it to `NOTIFIED`,
`SUPPRESSED` or `RESOLVED`, and a record state, `ACTIVE` until the producer archives it. moto sets
neither, and does not have `batch-update-findings`, the call that moves a finding through its workflow.

## The filter that is not applied

```
ana@laptop:~/aws/findings$ aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}' --query 'Findings[].Id' --output text
gd-1	gd-2	in-1	in-2	sh-1	sh-2
```

A filter on `CRITICAL` returned all six. **moto ignores the filters of `get-findings`**; AWS applies
them, and on an account with thousands of findings they are the only practical way to ask. The program
in the next section filters on AWS's terms and sorts on its own, so it reads the same either way.
