---
title: Three ways to describe the same bucket
version: 1
---

**The shop's assets bucket can be described three ways, and the bucket is identical in all three.** What
differs is who acts, when, where the record of what exists is kept, and what happens to a change made by
hand. None of the three is the right one in general; each fits a team that already works a certain way.

| | Terraform, run by you (lessons 5 and 6) | Infrastructure Manager | Config Connector |
|---|---|---|---|
| the language | HCL | HCL | Kubernetes YAML |
| who runs it | a person or a pipeline | Google, as a service account | a controller in a GKE cluster |
| the record of what exists | a state file in a bucket you manage | a state Google keeps per deployment | the objects in the cluster |
| the preview | `terraform plan` | a stored preview | the diff of the YAML |
| a change made by hand | stays until the next plan shows it | stays until the next revision | is undone |
| what it costs to run | the pipeline's minutes | Google's charge for the runs (not quoted in this course) | the cluster, all the time |
| other clouds | the same tool, other providers | Google only | Google only |

Read across a row rather than down a column. The last two rows are where teams usually decide: a team that
also runs AWS or Azure keeps Terraform because it is the one tool that speaks all three, and a team whose
whole world is GKE gets more from Config Connector than from a second tool and a second review flow.

## The shop's choice

The shop keeps Terraform, run by its own pipeline, for three reasons that come from earlier lessons rather
than from preference. Its build already runs in Cloud Build (lesson 1), so a Terraform step costs nothing new
to operate. Its state is protected by versioning and a lock (lesson 6), and it has rehearsed the restore.
And it runs on Cloud Run, not GKE, so Config Connector would mean running a cluster only to hold
descriptions of buckets.

**Infrastructure Manager is the step it would take next**, when the pipeline's service account becomes too
broad to be comfortable: moving the apply into a deployment with its own narrow account removes the
pipeline's need to hold infrastructure permissions at all, and the configuration does not change.

## What not to do

Do not describe one resource in two of these at once. A bucket in Terraform and in Config Connector is a
bucket with two owners: the controller undoes Terraform's changes, the next plan proposes to undo the
controller's, and each apply looks like it worked. Pick one owner per resource, and when a resource moves
from one to the other, remove it from the first (`terraform state rm`, or the `abandon` annotation) before
the second adopts it.
