---
title: GuardDuty, and the findings it would raise
version: 1
---

GuardDuty is turned on per account and per region by creating a **detector**. Work in `~/aws/findings`
(`mkdir -p ~/aws/findings && cd ~/aws/findings`):

```
ana@laptop:~/aws/findings$ aws guardduty create-detector --enable --finding-publishing-frequency FIFTEEN_MINUTES --query DetectorId --output text
5374de5f88855167531a59bc4dc21987
ana@laptop:~/aws/findings$ DETECTOR=$(aws guardduty list-detectors --query "DetectorIds[0]" --output text)
ana@laptop:~/aws/findings$ aws guardduty get-detector --detector-id $DETECTOR --query '[Status,FindingPublishingFrequency,DataSources.CloudTrail.Status]' --output text
ENABLED	FIFTEEN_MINUTES	DISABLED
```

The detector is enabled, and publishes updates to its findings every fifteen minutes rather than the
default six hours, which matters when the findings go to a person. moto reports the CloudTrail source
as `DISABLED`; on AWS the foundational sources, CloudTrail management events, VPC Flow Logs and DNS
logs, are always on with the detector, and the optional protections are listed as **features**.

## What a finding looks like

A finding has a **type**, written `ThreatPurpose:ResourceType/ThreatFamily`, a severity from 1 to 10, and
the resource and evidence. A few of the types worth recognising, from AWS's documentation:

| type | what it says |
|---|---|
| `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS` | an instance's temporary credentials were used from an address outside AWS |
| `CryptoCurrency:EC2/BitcoinTool.B!DNS` | an instance is resolving names of cryptocurrency mining pools |
| `Recon:EC2/PortProbeUnprotectedPort` | something on the internet is probing an open port on an instance |
| `Policy:IAMUser/RootCredentialUsage` | the root user was used |
| `Discovery:S3/AnomalousBehavior` | an unusual pattern of listing and reading S3, for this principal |

Severity is a number in bands: **low** below 4, **medium** from 4 to 6.9, **high** from 7. The first row
is high and urgent, because a credential that left its instance is in somebody else's hands now. The
third is low and constant: every instance with an open port on the internet is probed all day.

## Suppression, with a reason

A finding the team has decided is expected, the office's security scanner probing the shop's own
instances every night, should not reach a person. A **filter** with the action `ARCHIVE` is a
suppression rule: matching findings are archived as they arrive.

```
ana@laptop:~/aws/findings$ aws guardduty create-filter --detector-id $DETECTOR --name office-scanner --action ARCHIVE --rank 1 --finding-criteria '{"Criterion":{"type":{"Eq":["Recon:EC2/PortProbeUnprotectedPort"]},"service.action.networkConnectionAction.remoteIpDetails.ipAddressV4":{"Eq":["198.51.100.10"]}}}' --query Name
"office-scanner"
```

The filter names the type **and** the scanner's address. A suppression on the type alone would archive
every port probe from anybody, which is how a real probe gets hidden. The rule for suppression is the
same as lesson 14's for alarms: narrow, written down, and with a reason somebody can read.

## What moto does not do

```
ana@laptop:~/aws/findings$ aws guardduty list-findings --detector-id $DETECTOR 2>&1 | grep -m1 -o "Not Found"
Not Found
ana@laptop:~/aws/findings$ aws inspector2 enable --resource-types ECR EC2 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the Enable operation (reached max retries: 2): <!doctype html>
```

moto has no `list-findings` for GuardDuty and no Inspector to enable: the first is a 404, the second a
500. On AWS, `create-sample-findings` makes one example finding of every type, which is the honest way
to test the route from a finding to a phone before a real one arrives. The next section puts findings
into Security Hub instead, where moto keeps them.
