---
title: Where a module comes from
version: 1
---

A module in `modules/network` serves one repository. The day another team wants the same network,
copying the directory gives them a fork that drifts from Ana's on the first fix either side makes.
**A module meant for several configurations lives somewhere they can all fetch from, at a version
each of them chooses.** The `source` argument says where, and its shape says how Terraform fetches
it. Three shapes cover nearly every case:

| `source` looks like | where it comes from | how a version is chosen |
|---|---|---|
| `./modules/network` | a directory beside the caller | it is whatever the files say now |
| `git::https://…/terraform-aws-network.git?ref=v1.0.0` | a Git repository | `?ref=`: a tag, a branch or a commit |
| `terraform-aws-modules/vpc/aws` | a module registry | the `version` argument |

A path is recognised by its leading `./` or `../`. Terraform also understands archives over HTTPS,
S3 and GCS buckets and a shorthand for GitHub, but Git and a registry are the two you will meet in
most configurations, and "the-registry" covers the second.

## Publishing to Git

The module moves to a repository of its own. In this lab the shop's Git server is played by a bare
repository in Ana's home, `~/git/terraform-aws-network.git`; on a real team it is the same commands
against GitHub, GitLab or whatever the company runs. She commits the three files and tags the
commit:

```
ana@laptop:~/src/terraform-aws-network$ git tag v1.0.0
ana@laptop:~/src/terraform-aws-network$ git push -q origin main v1.0.0
ana@laptop:~/src/terraform-aws-network$ git ls-remote --tags origin
0c03bf66fe57ec3ec6a31c86e8275f51a09142c9	refs/tags/v1.0.0
```

**A tag is a name for one commit**, and `v1.0.0` is what the callers will ask for. Then the root
changes its two `source` lines to point at the repository:

```
ana@laptop:~/shop$ grep -n "source =" *.tf
analytics.tf:2:  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
main.tf:15:  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
ana@laptop:~/shop$ terraform plan
╷
│ Error: Module source has changed
│ 
│   on analytics.tf line 2, in module "analytics":
│    2:   source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
│ 
│ The source address was changed since this module was installed. Run
│ "terraform init" to install all modules required by this configuration.
╵
╷
│ Error: Module source has changed
│ 
│   on main.tf line 15, in module "shop":
│   15:   source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
│ 
│ The source address was changed since this module was installed. Run
│ "terraform init" to install all modules required by this configuration.
╵
```

`git::` tells Terraform to use Git, the URL is anything `git clone` accepts, and `?ref=v1.0.0` is
handed to Git as the thing to check out. As in "what-a-module-is", the plan refuses before an
`init`, and this time the message says why: the call's source is not the one that was installed.
The `init` downloads:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0 for shop...
- shop in .terraform/modules/shop
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0 for analytics...
- analytics in .terraform/modules/analytics

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.67.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

`Downloading … for shop...` is a real clone, once per call. And the plan afterwards:

```
ana@laptop:~/shop$ terraform plan
module.analytics.aws_vpc.this: Refreshing state... [id=vpc-460ca2ff2e1284aa0]
module.shop.aws_vpc.this: Refreshing state... [id=vpc-e73ad3e5038785a73]
module.shop.aws_subnet.this["c"]: Refreshing state... [id=subnet-3ac6009e35ad91b30]
aws_security_group.web: Refreshing state... [id=sg-80b18f85d20bd68e4]
module.shop.aws_subnet.this["a"]: Refreshing state... [id=subnet-1c6d0ef9160885f9f]
module.analytics.aws_subnet.this["a"]: Refreshing state... [id=subnet-80ae92981cef43bdb]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

**No changes, although every file the module is made of was just replaced by a copy from
somewhere else.** The resources' addresses are `module.shop.…` and `module.analytics.…`, built from
the calls' names, and neither name changed. Where a module's files come from is not part of the
address, so moving a module from a path to Git costs the state nothing.

The copies are under `.terraform`, where `modules.json` now points:

```
ana@laptop:~/shop$ jq -c ".Modules[] | {Key, Source, Dir}" .terraform/modules/modules.json
{"Key":"","Source":"","Dir":"."}
{"Key":"analytics","Source":"git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0","Dir":".terraform/modules/analytics"}
{"Key":"shop","Source":"git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0","Dir":".terraform/modules/shop"}
ana@laptop:~/shop$ ls .terraform/modules/shop
main.tf
outputs.tf
variables.tf
```

That directory is a cache of the source, rebuilt by `init`, and it belongs in `.gitignore` with the
rest of `.terraform/`. The truth is the `source` line.

## `version` is for registries only

The obvious way to ask for a version is the `version` argument, and with a Git source Terraform
refuses it:

```
ana@laptop:~/shop$ grep -A1 "source =" main.tf
  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
  version = "1.0.0"
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
╷
│ Error: Invalid registry module source address
│ 
│   on main.tf line 15, in module "shop":
│   15:   source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
│ 
│ Failed to parse module registry address: a module registry source address
│ must have either three or four slash-separated components.
│ 
│ Terraform assumed that you intended a module registry source address
│ because you also set the argument "version", which applies only to registry
│ modules.
╵
```

The message reads `version` as a sign that the source must have been meant as a registry address,
and fails to parse it as one. **For Git, the version is the `ref`.** That also decides how firm the
pin is. A branch moves whenever somebody pushes to it, so `?ref=main` gives a different module on a
different day. A tag is meant to stay put, but whoever can push to the repository can move it. A
full commit hash cannot be moved at all, at the cost of a source line nobody can read at a glance.
Tags are the usual compromise, with the rule that a published tag is never moved.
