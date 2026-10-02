---
title: Every directory is a module
version: 1
---

The word *module* suggests something special: a package somebody publishes, downloads and installs,
the way a library is. **In Terraform a module is any directory of `.tf` files**, and you have been
writing them since lesson 2. The directory you run `terraform` in is the **root module**. A
directory that the root module calls is a **child module**, and the call is a `module` block.

Ana's shop needs a VPC with two subnets, and soon a second network beside it for the analytics
team. Instead of writing the VPC and its subnets twice, she moves them into a directory of their
own:

```
ana@laptop:~/shop$ tree --noreport
.
├── main.tf
└── modules
    └── network
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

`modules/network` holds an ordinary configuration: resources, variables and outputs, the same
blocks lesson 2 taught, and the next section opens each file. What changes is the root's `main.tf`. It
no longer declares a VPC; it asks for one:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

module "shop" {
  source = "./modules/network"

  name = "shop"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.20.1.0/24" }
    c = { az = "sa-east-1c", cidr = "10.20.2.0/24" }
  }
}
```

**The `module` block is a call, and its arguments are the child's variables.** `name`, `cidr` and
`subnets` are not keywords of Terraform; they exist because `modules/network/variables.tf` declares
three variables with those names. `source` is the one argument that belongs to Terraform itself: it
says where the child's files are. A handful of others are Terraform's too, and you have met most of
them on resources: `count`, `for_each` and `depends_on`, plus `providers` and `version`, which this
lesson reaches two and three sections on.

Before anything can be planned, the child has to be found. A plan straight after writing the block
refuses:

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Module not installed
│ 
│   on main.tf line 14:
│   14: module "shop" {
│ 
│ This module is not yet installed. Run "terraform init" to install all
│ modules required by this configuration.
╵
```

**`terraform init` installs modules as well as providers.** Lesson 2 ran it for the providers; with
a `module` block in the configuration it has a second job, and it says so before the first:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
- shop in modules/network
```

`- shop in modules/network` is the whole installation for a local directory: Terraform records
where the call's files are and reads them from there. It keeps that record in a file of its own:

```
ana@laptop:~/shop$ jq . .terraform/modules/modules.json
{
  "Modules": [
    {
      "Key": "",
      "Source": "",
      "Dir": "."
    },
    {
      "Key": "shop",
      "Source": "./modules/network",
      "Dir": "modules/network"
    }
  ]
}
```

One entry per module, the root included as `Key: ""`. For a local path, `Dir` is the directory
itself, so an edit to `modules/network/main.tf` is seen by the next plan with no new `init`. A
module that comes from somewhere else is copied into `.terraform/modules/` instead, and three
sections on you see that copy being made.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two panels. On the left, the root module in ~/shop, holding two module blocks, shop and analytics, and the security group web. On the right, the child module in modules/network: its variables name, cidr and subnets at the top, its resources aws_vpc.this and aws_subnet.this in the middle, its outputs vpc_id and subnet_ids at the bottom. An arrow carries values from the module block into the variables; another carries the outputs back to the root, where the security group reads module.shop.vpc_id. Nothing else crosses between the panels.\"><defs><marker id=\"bd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"bd-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"280\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">root module</text><text x=\"40.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/shop</text><rect x=\"40\" y=\"75\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">module \"shop\"</text><rect x=\"40\" y=\"135\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">module \"analytics\"</text><rect x=\"40\" y=\"205\" width=\"240\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.web</text><text x=\"160.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">module.shop.vpc_id</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">child module</text><text x=\"440.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">modules/network</text><rect x=\"440\" y=\"75\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">variables</text><text x=\"560.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">name · cidr · subnets</text><rect x=\"440\" y=\"135\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resources, out of reach</text><text x=\"560.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_vpc.this</text><text x=\"560.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_subnet.this[…]</text><rect x=\"440\" y=\"205\" width=\"240\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outputs</text><text x=\"560.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">vpc_id · subnet_ids</text><path d=\"M282 97 L437 97\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bd-ah-phosphor)\"></path><text x=\"360.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">values in</text><path d=\"M438 230 L283 230\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bd-ah-amber)\"></path><text x=\"360.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">outputs out</text></svg>", "caption": "A module call: values go in through variables and come out through outputs. The resources in between are out of the caller's reach."}
```

The picture is the contract every later section relies on. **Values go into a module through its
variables and come out through its outputs, and nothing else crosses the line.** The root cannot
read a resource inside the child, and the child cannot read anything in the root that was not
passed to it. That boundary is what lets the same directory be called twice with different values,
and it is also what makes changing a module a matter of care: whoever calls it depends on exactly
those names.

Two more facts to carry forward. Every resource a child creates gets an address with the call's
name in front, `module.shop.aws_vpc.this`, which is where the state records it. And a child can call
children of its own; the addresses simply grow another `module.` prefix. Most teams stop at one
level, because each level is another place a reader has to open to find out what a plan will do.
