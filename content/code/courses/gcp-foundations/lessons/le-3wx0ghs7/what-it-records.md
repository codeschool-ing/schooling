---
title: What the inventory records
version: 1
---

**Cloud Asset Inventory is Google's own record of what exists in an estate**: every resource, with its
metadata, and every policy on it, across the organisation, its folders and its projects, kept up to date by
Google as things change. It is the answer to a question no other tool in this course answers well: *what is
actually there?* Terraform knows what it made, gcloud lists one kind of thing in one project at a time, and the
console shows what somebody clicks on. The inventory sees all of it from the top of lesson 2's tree.

It records four kinds of thing, and each is a search of its own:

| content | what it is | an example question |
|---|---|---|
| **resources** | every asset and its metadata: type, name, location, labels, state, creation time | which topics have no `team` label? |
| **IAM policies** | the allow policies on every node and resource, lesson 7 | where is `roles/owner` granted, and to whom? |
| **organisation policies** | the constraints in force, lesson 4 | which projects allow external IP addresses? |
| **relationships and history** | how assets are linked, and how each changed over the last five weeks | who changed this firewall rule last Tuesday? |

Every asset has a **type**, written as the service and the kind: `pubsub.googleapis.com/Topic`,
`compute.googleapis.com/Firewall`, `cloudresourcemanager.googleapis.com/Project`. Searches name types the same
way, which is how one query covers every project's topics at once.

## gcloud's commands for it

```
ana@laptop:~/gcp$ gcloud asset --help | sed -n "/^GROUPS/,/^NOTES/p" | grep -E "^     [a-z]"
     feeds
     operations
     saved-queries
     analyze-iam-policy
     analyze-iam-policy-longrunning
     analyze-move
     analyze-org-policies
     analyze-org-policy-governed-assets
     analyze-org-policy-governed-containers
     export
     get-effective-iam-policy
     get-history
     list
     query
     search-all-iam-policies
     search-all-resources
```

Three groups and the commands. The ones this lesson uses are **`search-all-resources`** and
**`search-all-iam-policies`**, which answer questions across a whole organisation in seconds. `export` writes a
full snapshot to Cloud Storage or BigQuery, for questions too big for a search. `get-history` returns an
asset's past states. And **feeds** publish every change to a Pub/Sub topic, which is lesson 12's machinery
pointed at the estate instead of the bill.

Reading the inventory needs a role where the search starts: `roles/cloudasset.viewer` on the organisation
reads all of it, and the same role on a folder reads that branch. The planner grants it to the security team
and to the platform team's service account that runs the nightly checks of the last section.
