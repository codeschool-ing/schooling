---
title: Triage, on a list of findings
version: 1
---

**Security Command Center does not run on your computer, but the findings it produces are data, and triage is
what you do with data.** The list below is **written by this course, not by Security Command Center**: eight
findings for the shop's project, using the field names and values Google's documentation gives for a finding
(`category`, `severity`, `state`, `mute`, `findingClass`, `resourceName`, `eventTime`), and no others. A real
export has many more fields; these are the ones triage reads. Save it as `~/gcp/findings.jsonl`, one finding per
line, exactly as here, `findings.jsonl`:

```
{"category": "PUBLIC_BUCKET_ACL", "severity": "HIGH", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//storage.googleapis.com/planner-dev-shop-assets", "eventTime": "2026-10-28T09:12:00Z"}
{"category": "OPEN_FIREWALL", "severity": "HIGH", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//compute.googleapis.com/projects/planner-dev/global/firewalls/allow-ssh-anywhere", "eventTime": "2026-10-27T17:40:00Z"}
{"category": "SERVICE_ACCOUNT_KEY_NOT_ROTATED", "severity": "MEDIUM", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//iam.googleapis.com/projects/planner-dev/serviceAccounts/legacy-batch@planner-dev.iam.gserviceaccount.com", "eventTime": "2026-10-20T08:00:00Z"}
{"category": "OS_VULNERABILITY", "severity": "CRITICAL", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "VULNERABILITY", "resourceName": "//compute.googleapis.com/projects/planner-dev/zones/southamerica-east1-a/instances/batch-1", "eventTime": "2026-10-29T03:15:00Z"}
{"category": "OS_VULNERABILITY", "severity": "CRITICAL", "state": "ACTIVE", "mute": "MUTED", "findingClass": "VULNERABILITY", "resourceName": "//compute.googleapis.com/projects/planner-dev/zones/southamerica-east1-a/instances/sandbox-ana", "eventTime": "2026-10-29T03:15:00Z"}
{"category": "MFA_NOT_ENFORCED", "severity": "HIGH", "state": "INACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//cloudresourcemanager.googleapis.com/organizations/123456789012", "eventTime": "2026-10-02T11:00:00Z"}
{"category": "AUDIT_LOGGING_DISABLED", "severity": "LOW", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "MISCONFIGURATION", "resourceName": "//cloudresourcemanager.googleapis.com/projects/planner-dev", "eventTime": "2026-10-15T10:30:00Z"}
{"category": "Persistence: IAM Anomalous Grant", "severity": "HIGH", "state": "ACTIVE", "mute": "UNMUTED", "findingClass": "THREAT", "resourceName": "//cloudresourcemanager.googleapis.com/projects/planner-dev", "eventTime": "2026-10-30T02:47:00Z"}
```

## How much, and how bad

```
ana@laptop:~/gcp$ wc -l findings.jsonl
8 findings.jsonl
ana@laptop:~/gcp$ jq -s -c 'group_by(.severity) | map({severity: .[0].severity, count: length})' findings.jsonl
[{"severity":"CRITICAL","count":2},{"severity":"HIGH","count":4},{"severity":"LOW","count":1},{"severity":"MEDIUM","count":1}]
```

Two critical and four high, out of eight. **A count by severity is where triage starts and never where it ends**:
one of the critical findings is muted, one of the high ones is no longer active. Keep only what is open:

```
ana@laptop:~/gcp$ jq -c 'select(.state == "ACTIVE" and .mute == "UNMUTED")' findings.jsonl | wc -l
6
ana@laptop:~/gcp$ jq -r 'select(.state == "ACTIVE" and .mute == "UNMUTED" and (.severity == "CRITICAL" or .severity == "HIGH")) | [.findingClass, .severity, .category] | @tsv' findings.jsonl
MISCONFIGURATION	HIGH	PUBLIC_BUCKET_ACL
MISCONFIGURATION	HIGH	OPEN_FIREWALL
VULNERABILITY	CRITICAL	OS_VULNERABILITY
THREAT	HIGH	Persistence: IAM Anomalous Grant
```

Six open, four of them high or critical. Now the order.

## What to act on first

Severity alone would put the critical vulnerability first. The shop's order puts the **threat** first, whatever its
severity, because it is the only finding that says something may be happening now rather than could happen:

```
ana@laptop:~/gcp$ jq -r 'select(.findingClass == "THREAT") | [.eventTime, .category, .resourceName] | @tsv' findings.jsonl
2026-10-30T02:47:00Z	Persistence: IAM Anomalous Grant	//cloudresourcemanager.googleapis.com/projects/planner-dev
```

An anomalous permission grant on the project, at 02:47 this morning. That is the start of an incident (lesson 15),
not a ticket: find who made the grant in the audit log, whether it was expected, and remove it if it was not. Then:

1. **`PUBLIC_BUCKET_ACL` on `planner-dev-shop-assets`.** A misconfiguration that exposes data to anybody, fixed in
   minutes. Check what the bucket holds: if it is the price list, which is public anyway, the fix still matters,
   because the next object somebody drops in it would be public too.
2. **`OS_VULNERABILITY` on `batch-1`.** Critical, on a machine that runs. The fix is the one lesson 2 described: a
   patched image, rebuilt and redeployed.
3. **`OPEN_FIREWALL`, `allow-ssh-anywhere`.** SSH open to the internet on a project whose services are Cloud Run.
   Nobody should need it; delete the rule.
4. **`SERVICE_ACCOUNT_KEY_NOT_ROTATED`** and **`AUDIT_LOGGING_DISABLED`**: tickets for the week. The key is better
   deleted than rotated (`gcp-foundations` lesson 8), and the logging gap is what would have made the threat finding
   impossible to investigate.

The muted critical vulnerability is on `sandbox-ana`. The mute is acceptable only if the sandbox holds nothing and
reaches nothing; **a muted finding is reviewed like a policy**, on a schedule, because the sandbox that held nothing
in March holds a copy of production data in June.
