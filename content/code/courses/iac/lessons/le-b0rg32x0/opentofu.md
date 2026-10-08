---
title: OpenTofu, the same program under its old licence
version: 2
---

A fork sounds like a second tool with a second manual. **OpenTofu is closer to a second maintainer
for the first tool.** It began as Terraform's own source code, it reads the same HCL, it runs the
same commands under another name, and it writes the same state file. What separates the two is a
licence, who decides what goes in next, and a growing list of features each has added since.

**OpenTofu is the program lesson 12 installed.** If you skipped that lesson, its project's install
script adds OpenTofu's own package repository and installs from it:

```sh
curl -fsSLo install-opentofu.sh https://get.opentofu.org/install-opentofu.sh
sh install-opentofu.sh --install-method deb
```

The transcripts were recorded with OpenTofu 1.13.1, and a newer version shows its own number where
they show that one. Start the lesson as lesson 1 showed, with moto restarted and `fresh-lesson.sh` run, and
make the directory Ana works in with `mkdir ~/shop && cd ~/shop`.

## Why there are two

Until August 2023 Terraform was published under the Mozilla Public License 2.0, an open-source
licence. That month HashiCorp moved it to the Business Source License 1.1. The release Ana
installed carries the new terms, and HashiCorp's package puts the licence beside the program's
documentation:

```
ana@laptop:~/shop$ sed -n "6,7p;43,44p" /usr/share/doc/terraform/LICENSE.txt
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
Its licence file, which OpenTofu's package installs as `/usr/share/doc/opentofu/copyright`, still
begins with HashiCorp's copyright, because most of the code is still theirs:

```
ana@laptop:~/shop$ sed -n "1,4p" /usr/share/doc/opentofu/copyright
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

Ana copies the network from lesson 2 into `~/shop/tofu`, unchanged. Make the directory with
`mkdir tofu && cd tofu` and write the same two files: `main.tf`, with the VPC, the subnet, the
security group and its rule,

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "shop-web-a"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
```

and `versions.tf`:

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
│   - /home/ana/.terraform.d/mirror
╵
```

**The configuration did not change, and it failed.** Nothing is wrong with it: Terraform
initialised these same two files in lesson 2. **On your computer this command succeeds**, and
downloads the provider; the failure belongs to the machine these lessons were recorded on, which had
no internet access. It still shows something true about both programs: they read the `source` line,
which decides where every provider comes from, in different ways. The next section is about that line.

What does not differ is everything lessons 2 to 16 taught: plans, the symbols in them, state and its
commands, backends and locking, modules, workspaces, `tofu test`, and the scanners, which read the
same files. Lesson 12 showed the main thing OpenTofu has that Terraform lacks, encryption of the state
inside the program, and that Terraform refused the block that turns it on. That refusal is the
fork's price: **once a configuration uses something only one of them has, it belongs to that one.**
