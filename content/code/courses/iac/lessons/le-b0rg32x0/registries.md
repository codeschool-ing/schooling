---
title: Two registries, and the address of a provider
version: 2
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
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A provider address in three parts: the registry's hostname registry.terraform.io, the namespace hashicorp and the type aws. Below, the short form hashicorp/aws is completed differently by each program: Terraform fills in registry.terraform.io, which the recording machine's mirror holds, and OpenTofu fills in registry.opentofu.org, which that mirror does not hold.\"><defs><marker id=\"ad-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ad-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"110\" y=\"24\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">registry.terraform.io</text><rect x=\"350\" y=\"24\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hashicorp</text><rect x=\"480\" y=\"24\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"230.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the registry's hostname</text><text x=\"415.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace</text><text x=\"545.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">type</text><path d=\"M20 104 L700 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what the short form becomes</text><rect x=\"30\" y=\"174\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/aws</text><path d=\"M160 186 L240 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ad-ah-phosphor)\"></path><path d=\"M160 206 L240 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ad-ah-amber)\"></path><text x=\"200.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">terraform</text><text x=\"200.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tofu</text><rect x=\"244\" y=\"146\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"369.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">registry.terraform.io/hashicorp/aws</text><rect x=\"244\" y=\"208\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"369.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">registry.opentofu.org/hashicorp/aws</text><text x=\"514.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">in the recording machine's mirror</text><text x=\"514.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">not in the recording machine's mirror</text></svg>", "caption": "A provider's address names a registry. Written short, each program completes it with its own."}
```

Terraform's default registry is `registry.terraform.io`, run by HashiCorp. OpenTofu's is
`registry.opentofu.org`, run by the OpenTofu project. On a computer with internet access the
difference is invisible: the OpenTofu registry lists the providers you know by the same names,
`hashicorp/aws` among them, so the short form works with either program and you never think about
it.

## Why the recording machine noticed

The machine these lessons were recorded on has no internet access. As lesson 1 explained, its
providers come from a directory on that machine, a **filesystem mirror**, and its CLI configuration
says where it is. Your computer has no mirror and no such configuration, so these two commands
are there to be read:

```
ana@laptop:~/shop/tofu$ cat $TF_CLI_CONFIG_FILE
provider_installation {
  filesystem_mirror {
    path = "/home/ana/.terraform.d/mirror"
  }
}
ana@laptop:~/shop/tofu$ find ~/.terraform.d/mirror -maxdepth 3
/home/ana/.terraform.d/mirror
/home/ana/.terraform.d/mirror/registry.terraform.io
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/aws
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/random
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/local
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/tls
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/null
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
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

This is how lesson 12 wrote it when it ran `tofu`, for the same reason. Now `init` finds the
provider and installs it:

```
ana@laptop:~/shop/tofu$ tofu init

Initializing the backend...

Initializing provider plugins...
- Finding registry.terraform.io/hashicorp/aws versions matching "~> 6.0"...
- Installing registry.terraform.io/hashicorp/aws v6.67.0...
- Installed registry.terraform.io/hashicorp/aws v6.67.0 (unauthenticated)
```

**Make the same change on your computer**, although your first `init` worked, and run `tofu init`
again. Then your state records the same address as Ana's, which the end of this section relies on.
Where the page says `(unauthenticated)`, yours says who signed the provider, as lesson 1 explained.

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

Keep this in proportion. **The full address was a need of the recording machine's mirror, not of
OpenTofu.** With the registries reachable, as your first `tofu init` showed, `hashicorp/aws` is the
normal way to write it. What the mirror does show is that the address is part of a provider's
identity, and the state records it in full for every resource:

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

Ana runs `tofu apply -auto-approve`. The plan is lesson 2's, with `OpenTofu` where it said
`Terraform`, and the last lines are:

```
Plan: 4 to add, 0 to change, 0 to destroy.
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 1s [id=vpc-ce0a69d61dd9b7159]
aws_security_group.web: Creating...
aws_subnet.web_a: Creating...
aws_subnet.web_a: Creation complete after 0s [id=subnet-31656491034a98be8]
aws_security_group.web: Creation complete after 0s [id=sg-2961c0f1ab0a25c88]
aws_vpc_security_group_ingress_rule.https: Creating...
aws_vpc_security_group_ingress_rule.https: Creation complete after 0s [id=sgr-29314cbe34425491e]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

The state above says `version` 4, the format Terraform also writes, and the field that records the
program's version is still called `terraform_version` while it holds OpenTofu's 1.13.1. So Terraform,
after a `terraform init` of its own in the same directory, reads that state, refreshes the four resources and finds nothing
to do:

```
ana@laptop:~/shop/tofu$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-ce0a69d61dd9b7159]
aws_security_group.web: Refreshing state... [id=sg-2961c0f1ab0a25c88]
aws_subnet.web_a: Refreshing state... [id=subnet-31656491034a98be8]
aws_vpc_security_group_ingress_rule.https: Refreshing state... [id=sgr-29314cbe34425491e]

No changes. Your infrastructure matches the configuration.
```

That is the extent of the compatibility, measured: **today, for a configuration that uses only what
both understand**, you can move between them in either direction. It is not a promise for the
future, and lesson 12's encrypted state has already shown where it ends.

Before the next section Ana empties the account with `tofu destroy -auto-approve`, so that the
CloudFormation stack starts from nothing, as yours should.
