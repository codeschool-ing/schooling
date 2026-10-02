---
title: OpenTofu, the same program under its old licence
version: 1
---

A fork sounds like a second tool with a second manual. **OpenTofu is closer to a second maintainer
for the first tool.** It began as Terraform's own source code, it reads the same HCL, it runs the
same commands under another name, and it writes the same state file. What separates the two is a
licence, who decides what goes in next, and a growing list of features each has added since.

## Why there are two

Until August 2023 Terraform was published under the Mozilla Public License 2.0, an open-source
licence. That month HashiCorp moved it to the Business Source License 1.1. The release Ana
installed carries the new terms, and the lab has the original download to read them from:

```
ana@laptop:~/shop$ unzip -p /opt/iac/dl/terraform_1.16.4_linux_amd64.zip LICENSE.txt | sed -n "6,7p;43,44p"
Licensor:             International Business Machines Corporation (IBM)
Licensed Work:        Terraform Version 1.6.0 or later. The Licensed Work is (c) 2024
Change Date:          Four years from the date the Licensed Work is published.
Change License:       MPL 2.0
```

Three lines say most of it. The licensor named today is **IBM**, which owns HashiCorp. The terms
apply from **Terraform 1.6.0 on**, so 1.5 and everything before it stay under the MPL. And each
version turns into MPL 2.0 itself four years after it is published. In between, the licence allows
production use and excludes one thing: offering Terraform to others, hosted or embedded, in a
product that competes with IBM's paid versions. A shop that runs Terraform on its own network is
not doing that. A company that sells "Terraform as a service" is.

Several of those companies answered by forking the code from before the change. The fork was renamed
OpenTofu, placed under the Linux Foundation, and released its first stable version in early 2024.
Its licence file still begins with HashiCorp's copyright, because most of the code is still theirs:

```
ana@laptop:~/shop$ sed -n "1,4p" /opt/iac/src/tofu/LICENSE
Copyright (c) The OpenTofu Authors
Copyright (c) 2014 HashiCorp, Inc.

Mozilla Public License, version 2.0
```

## Running lesson 2's configuration with it

The two programs no longer share version numbers, which is the first sign they are maintained
separately:

```
ana@laptop:~/shop$ terraform version
Terraform v1.16.4
on linux_amd64
ana@laptop:~/shop$ tofu version
OpenTofu v1.13.1
on linux_amd64
```

Ana copies the network from lesson 2 into `~/shop/tofu`, unchanged: the same `main.tf` with its VPC,
subnet, security group and rule, and the same `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

`required_version = ">= 1.10"` passes, because OpenTofu checks that line against its own version, and
1.13.1 is above it. Then the same first command lesson 2 ran, with `tofu` in place of `terraform`:

```
ana@laptop:~/shop/tofu$ tofu init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
╷
│ Error: Failed to query available provider packages
│ 
│ Could not retrieve the list of available versions for provider
│ hashicorp/aws: provider registry.opentofu.org/hashicorp/aws was not found
│ in any of the search locations
│ 
│   - /opt/iac/unpacked
╵
```

**The configuration did not change, and it failed.** Nothing is wrong with it: Terraform
initialised these same two files in lesson 2. The difference is in how each program reads the
`source` line, and that is the one thing about OpenTofu you have to understand before anything
else, because it decides where every provider comes from. The next section is about that line.

What does not differ is everything lessons 2 to 16 taught: plans, the symbols in them, state and its
commands, backends and locking, modules, workspaces, `tofu test`, and the scanners, which read the
same files. Lesson 12 showed the main thing OpenTofu has that Terraform lacks, encryption of the state
inside the program, and that Terraform refused the block that turns it on. That refusal is the
fork's price: **once a configuration uses something only one of them has, it belongs to that one.**
