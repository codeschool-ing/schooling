---
title: Choosing a layout
version: 1
---

All three layouts give each environment its own state, which was the problem. **They differ in
where the choice of environment is made**, and almost every other difference follows from that.

| | workspaces | a directory per environment | Terragrunt |
| --- | --- | --- | --- |
| where the environment is chosen | a hidden file, `.terraform/environment` | the path you stand in | the path you stand in |
| what is shared | everything, configuration and backend block | modules; the root files are copies | modules and one `root.hcl` |
| what differs between environments | values only, unless the code tests `terraform.workspace` | anything, file by file | the inputs of each unit, or anything else in it |
| separate credentials per environment | awkward: one backend block, one bucket | natural: each directory configures its own | natural, per unit or per folder |
| holding prod back on an old module version | not possible: one `source` for all | `?ref=` per environment | `?ref=` per unit |
| tools to install | Terraform | Terraform | Terraform and Terragrunt |
| the classic mistake | applying in the wrong workspace | editing one copy and not the other | a `run --all` touching more than intended |

Read the first row and the advice from the last three sections falls out of it.
**Workspaces suit copies that are meant to be identical and short-lived**: a temporary environment
per branch, a scratch copy to test a change, the same stack for several customers on one set of
credentials. There, the hidden selection is a small risk because nothing precious lives in any of
them, and creating one is a single command rather than a new directory.

**Separate directories suit dev and prod**, the case this lesson started with. The environment is
visible in the path, each one can authenticate differently, and prod can stay on last month's
module while dev tries this month's. The price is the copied root files, and with a handful of
environments and states it is a small price that people overestimate.

**Terragrunt suits the same layout at a scale where the copies hurt**: many environments, regions or
accounts, each with several states that depend on each other. It removes the repetition and adds
ordering across states, and it costs a second tool that everybody has to know.

Two observations hold whichever you choose. First, the layouts combine: a team with prod and dev
in directories can still use workspaces inside dev for throwaway copies. Second, none of them
replaces the layer underneath. A state per environment keeps Terraform from mixing them up; only
separate credentials, ideally separate accounts, keep a person or a pipeline holding dev's access
from reaching prod at all.
