---
title: The registry, and reading a module before you trust it
version: 2
---

A Git URL works for modules your own company writes. For modules other people publish, there is
the **Terraform Registry** at `registry.terraform.io`, the same service `terraform init` asks for
providers. A registry source has three parts, `NAMESPACE/NAME/PROVIDER`, and a separate `version`
argument that takes a constraint like a provider's:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "shop"
  cidr = "10.20.0.0/16"
}
```

`terraform-aws-modules` is the publisher, `vpc` the module and `aws` the provider it is for.
`~> 6.0` means any `6.x` from `6.0` up, and not `7.0`: when it installs the module, Terraform picks
the newest version the registry lists inside that range. **This is the one step in the lesson
that needs the internet.** On your computer, `terraform init` in a new directory, `~/try-registry`,
with this `main.tf` reaches the registry, which hands out the module from its GitHub repository; it
prints `Downloading` and the version it chose, and succeeds. The lessons were recorded on a machine
with no internet, and what `init` printed there is worth seeing once, because it is what it says on
any computer that cannot reach the registry:

```
ana@laptop:~/try-registry$ terraform init
Initializing the backend...

Initializing modules...
╷
│ Error: Error accessing remote module registry
│ 
│   on main.tf line 1:
│    1: module "vpc" {
│ 
│ Failed to retrieve available versions for module "vpc" (main.tf:1) from
│ registry.terraform.io: failed to request discovery document: GET
│ https://registry.terraform.io/.well-known/terraform.json giving up after 4
│ attempt(s): Get "https://registry.terraform.io/.well-known/terraform.json":
│ dial tcp: lookup registry.terraform.io on 127.0.0.1:53: server misbehaving.
╵
```

It shows the first step of the protocol. Terraform asks the host for
`/.well-known/terraform.json`, a small document saying where that host's module and provider APIs
live; with the answer it would list the module's versions, choose one, and ask where to download it
from. The recording machine could not resolve `registry.terraform.io`, so the first question never
left it. On yours the question is answered, and the module lands in `.terraform/modules/vpc` just as
the Git copy did two sections back.

**Nothing of that module is quoted in this lesson**, because the machine that recorded it never
downloaded it. On yours, its files are in `.terraform/modules/vpc` after the `init`, and its
inputs, its outputs and what it creates are also on its page in the registry.

A registry address can also have four parts, with a host name in front:
`app.terraform.io/shop/network/aws`. That is a **private registry**, such as the one HCP Terraform
gives an organisation, and it is why the error two sections back said a registry address has "three or
four" components. Publishing to the public registry has rules of its own: a public GitHub
repository named `terraform-<PROVIDER>-<NAME>`, releases tagged with semantic versions, and the file
layout the next section describes. The tags become the versions the registry lists.

## A module runs with your credentials

**Calling somebody's module is running their code with your access to your account.** Everything it
declares, it creates, changes or destroys as you. The registry shows who published a module and how
often it is downloaded; neither says the code does only what its page describes, and a popular
module is still a module whose next version you have not read.

So before a third-party module goes into a configuration, read it, the way you would read a pull
request. Once it is installed, `.terraform/modules` holds the files `init` fetched, so the reading
can start with a list of everything the module declares:

```
ana@laptop:~/shop$ grep -rhE "^(resource|data|module|provider)" --include="*.tf" .terraform/modules/shop
resource "aws_vpc" "this" {
resource "aws_subnet" "private" {
ana@laptop:~/shop$ grep -rnE "provisioner|\"external\"|\"http\"" --include="*.tf" .terraform/modules/shop || echo "none"
none
```

Here that is the network module from Git, two resources and nothing surprising. The second command
looks for the three things that let a module do more than create resources: a `provisioner`, which
runs commands, an `external` data source, which runs a program during the plan, and an `http` data
source, which fetches a URL. None of them is wrong in itself, and each one is worth a question.

Then pin it. **`.terraform.lock.hcl` records providers and not modules**, so a range is resolved
again by every fresh `init`, on a colleague's laptop or in a pipeline, and two of them can get two
versions. For a module you do not control, an exact `version = "…"` is safer: a new release reaches
your configuration only when you change the line, and the plan after that change is the review. When you upgrade, read the changelog first, then the
plan, and look for replacements the way the previous section did.
