---
title: Dry run first, and reading the violations
version: 1
---

**A perimeter turned on without a dry run breaks something nobody remembered.** A nightly job in another project
that reads the exports, a dashboard tool calling BigQuery from outside, a support engineer's laptop: each is a
legitimate request the perimeter would refuse, and each is found out by the people it breaks. The shop's
configuration uses `use_explicit_dry_run_spec = true` and puts everything in `spec`, which is the **dry-run**
configuration: Cloud Audit Logs records every request the perimeter *would* refuse, and nothing is refused. This
section is from Google's documentation; nothing ran.

## Reading the would-be refusals

A dry-run violation is an audit log entry, found in Cloud Logging with a filter of lesson 9's kind:

```localised
protoPayload.metadata.@type="type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata"
protoPayload.metadata.dryRun=true
```

Each entry names the perimeter, the service and method, the caller and where the request came from, and a
`violationReason`. A week of dry run gives a list to read with three columns in mind: **who, from where, doing
what**. Each line is one of three things:

- **a legitimate request**, which becomes an access level (a known address range) or an ingress or egress rule
  (one identity, one service, one method);
- **a request nobody can explain**, which is the perimeter doing its job early, and an incident (lesson 15);
- **noise from a tool that probes everything**, which is fixed at the tool.

When a week passes with only the second and third kinds left, the configuration moves from `spec` to `status`, the
enforced configuration, and the same entries start appearing without `dryRun=true`, now as refusals.

## The perimeter in an incident

An enforced refusal returns `403` with an error that names VPC Service Controls and a unique id. Somebody whose job
breaks after enforcement sees that id; searching the audit logs for it gives the exact rule that refused the
request. **That id is the first thing to ask for** when somebody reports "permission denied but I have the role":
it says whether IAM or the perimeter refused, which are two different conversations.

## What it costs and what it asks

VPC Service Controls itself has no charge. What it costs is attention: every new integration that crosses the line
needs a rule, written and reviewed, and a team that adds rules without reading the dry-run logs ends up with a
perimeter full of holes, which is a perimeter in name. **For the shop, the order exports are the only data worth the
cost**: payment details are not stored at all, and the price list is public. Drawing the line around everything
would mean maintaining rules for everything; drawing it around the one project that holds personal data keeps the
list short enough to read.
