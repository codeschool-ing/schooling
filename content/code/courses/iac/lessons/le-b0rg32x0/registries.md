---
title: Two registries, and the address of a provider
version: 1
---

`hashicorp/aws` looks like a name. **It is the short form of an address**, and the short form
leaves out the part where the two programs disagree. A provider's full address has three parts:
the hostname of a registry, a namespace, and a type. When `source` gives only the last two, each
program fills in the first one, and each fills in its own. Both will tell you which, without
downloading anything:

```
ana@laptop:~/shop/tofu$ terraform providers

Providers required by configuration:
.
└── provider[registry.terraform.io/hashicorp/aws] ~> 6.0

ana@laptop:~/shop/tofu$ tofu providers

Providers required by configuration:
.
└── provider[registry.opentofu.org/hashicorp/aws] ~> 6.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A provider address in three parts: the registry's hostname registry.terraform.io, the namespace hashicorp and the type aws. Below, the short form hashicorp/aws is completed differently by each program: Terraform fills in registry.terraform.io, which the lab's mirror holds, and OpenTofu fills in registry.opentofu.org, which the lab's mirror does not hold.\"><defs><marker id=\"ad-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ad-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"110\" y=\"24\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">registry.terraform.io</text><rect x=\"350\" y=\"24\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hashicorp</text><rect x=\"480\" y=\"24\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"230.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the registry's hostname</text><text x=\"415.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace</text><text x=\"545.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">type</text><path d=\"M20 104 L700 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what the short form becomes</text><rect x=\"30\" y=\"174\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/aws</text><path d=\"M160 186 L240 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ad-ah-phosphor)\"></path><path d=\"M160 206 L240 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ad-ah-amber)\"></path><text x=\"200.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">terraform</text><text x=\"200.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tofu</text><rect x=\"244\" y=\"146\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"369.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">registry.terraform.io/hashicorp/aws</text><rect x=\"244\" y=\"208\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"369.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">registry.opentofu.org/hashicorp/aws</text><text x=\"514.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">in the lab's mirror</text><text x=\"514.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">not in the lab's mirror</text></svg>", "caption": "A provider's address names a registry. Written short, each program completes it with its own."}
```

Terraform's default registry is `registry.terraform.io`, run by HashiCorp. OpenTofu's is
`registry.opentofu.org`, run by the OpenTofu project. On a computer with internet access the
difference is invisible: the OpenTofu registry lists the providers you know by the same names,
`hashicorp/aws` among them, so the short form works with either program and you never think about
it.

## Why the lab notices

The lab has no internet access. As lesson 2 explained, its providers come from a directory on the
laptop, a **filesystem mirror**, and the CLI configuration says where it is:

```
ana@laptop:~/shop/tofu$ cat $TF_CLI_CONFIG_FILE
provider_installation {
  filesystem_mirror {
    path = "/opt/iac/unpacked"
  }
}
ana@laptop:~/shop/tofu$ find /opt/iac/unpacked -maxdepth 3
/opt/iac/unpacked
/opt/iac/unpacked/registry.terraform.io
/opt/iac/unpacked/registry.terraform.io/hashicorp
/opt/iac/unpacked/registry.terraform.io/hashicorp/aws
/opt/iac/unpacked/registry.terraform.io/hashicorp/random
/opt/iac/unpacked/registry.terraform.io/hashicorp/local
/opt/iac/unpacked/registry.terraform.io/hashicorp/tls
/opt/iac/unpacked/registry.terraform.io/hashicorp/null
```

A mirror is laid out by address, one directory level per part, and this one holds a single
hostname: the packages were downloaded from HashiCorp, so they were filed under HashiCorp's
registry. Read the error from the previous section again with that in mind. OpenTofu was looking for
`registry.opentofu.org/hashicorp/aws`, which is a directory this mirror does not have, and it said
exactly that.

**The fix is to stop leaving the hostname out.** Written in full, the address means the same thing
to both programs, so neither has a default to apply:

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

This is the line lesson 12 used when it ran `tofu`, for the same reason. Now `init` finds the
provider and installs it:

```
ana@laptop:~/shop/tofu$ tofu init

Initializing the backend...

Initializing provider plugins...
- Finding registry.terraform.io/hashicorp/aws versions matching "~> 6.0"...
- Installing registry.terraform.io/hashicorp/aws v6.67.0...
- Installed registry.terraform.io/hashicorp/aws v6.67.0 (unauthenticated)
```

The lock file and the provider list carry the full address too. A lock file is keyed by address,
which is why it records the hostname even where you did not write one:

```
ana@laptop:~/shop/tofu$ cat .terraform.lock.hcl
# This file is maintained automatically by "tofu init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.67.0"
  constraints = "~> 6.0"
  hashes = [
    "h1:EB9ixYOZrSlYD7wtJxf88qwoyyWrlKDKxhzaCLIb3t4=",
  ]
}
ana@laptop:~/shop/tofu$ tofu providers

Providers required by configuration:
.
└── provider[registry.terraform.io/hashicorp/aws] ~> 6.0
```

Keep this in proportion. **The full address is a property of this lab's mirror, not something
OpenTofu needs.** On your own computer, with the registries reachable, `hashicorp/aws` is the normal
way to write it. What the lab does show is that the address is part of a provider's identity, and
the state records it in full for every resource:

```
ana@laptop:~/shop/tofu$ jq ".version, .terraform_version" terraform.tfstate
4
"1.13.1"
ana@laptop:~/shop/tofu$ jq -r ".resources[].provider" terraform.tfstate
provider["registry.terraform.io/hashicorp/aws"]
provider["registry.terraform.io/hashicorp/aws"]
provider["registry.terraform.io/hashicorp/aws"]
provider["registry.terraform.io/hashicorp/aws"]
```

## The same state, read by both

The apply is lesson 2's, with `OpenTofu` where the plan said `Terraform`. Its last lines:

```
Plan: 4 to add, 0 to change, 0 to destroy.
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 1s [id=vpc-b17a06333dab7d3bc]
aws_security_group.web: Creating...
aws_subnet.web_a: Creating...
aws_subnet.web_a: Creation complete after 0s [id=subnet-5bab265bf5df3006f]
aws_security_group.web: Creation complete after 1s [id=sg-37f699b3a9928e46e]
aws_vpc_security_group_ingress_rule.https: Creating...
aws_vpc_security_group_ingress_rule.https: Creation complete after 0s [id=sgr-46d0049e11c08a17f]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

The state above says `version` 4, the format Terraform also writes, and the field that records the
program's version is still called `terraform_version` while it holds OpenTofu's 1.13.1. So Terraform,
asked to plan in the same directory, reads that state, refreshes the four resources and finds nothing
to do:

```
ana@laptop:~/shop/tofu$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-b17a06333dab7d3bc]
aws_subnet.web_a: Refreshing state... [id=subnet-5bab265bf5df3006f]
aws_security_group.web: Refreshing state... [id=sg-37f699b3a9928e46e]
aws_vpc_security_group_ingress_rule.https: Refreshing state... [id=sgr-46d0049e11c08a17f]

No changes. Your infrastructure matches the configuration.
```

That is the extent of the compatibility, measured: **today, for a configuration that uses only what
both understand**, you can move between them in either direction. It is not a promise for the
future, and lesson 12's encrypted state has already shown where it ends.
