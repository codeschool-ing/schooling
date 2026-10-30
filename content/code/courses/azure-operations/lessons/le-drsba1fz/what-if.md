---
title: What-if: the change, before it happens
version: 1
---

**What-if asks Resource Manager what a deployment would change, without changing anything.** It is the
Azure equivalent of `terraform plan`, and it needs the real resource group to compare against, so it was
**not run** here:

```sh
az deployment group what-if -g rg-shop -f main.bicep -p main.prod.bicepparam
```

The answer is a list of resources, each with a **change type**, and for a modified one the properties
that would change, with their old and new values. The change types are documented as six:

| change type | what it means |
|---|---|
| **Create** | the resource does not exist and will be created |
| **Delete** | the resource exists and would be deleted; only in *complete* mode or with a stack |
| **Modify** | the resource exists and some properties will change |
| **NoChange** | the resource exists and matches the template |
| **Ignore** | the resource exists in the scope and the template does not mention it; left alone |
| **Deploy** | the resource exists, and what-if cannot tell whether properties will change |

Two of those deserve attention every time. **Modify** on a property you did not touch is the interesting
line: it means the resource has drifted from what the file says, perhaps because somebody changed it
by hand in the portal, and the deployment is about to undo that change. Read it before you deploy, not
after. And **Ignore** is the reminder of what incremental deployment means: a resource you deleted from
the file is not deleted from Azure. It is merely no longer mentioned, and it is still billed.

What-if has a known weakness, and Microsoft documents it: **noise**. Some resource providers report
properties as changing when they are not, because the template and the stored resource express the same
value differently. A team learns which lines are noise for its resources, and the habit to avoid is the
one that grows from that: approving a what-if without reading it because it is always long.

In a pipeline, what-if goes in the stage before the deployment, with its output attached to the
approval from lesson 3, so that whoever approves is approving a list of changes rather than a commit
hash.
