---
title: What terraform init installs
version: 2
---

**`terraform init` prepares a directory, and it does not touch the cloud.** It reads
`required_providers`, finds a release of each provider that meets its constraint, installs it, and
writes down what it chose. Nothing in AWS is created, read or changed. You run it once when you
start, again whenever the list of providers changes, and on every fresh checkout of somebody else's
configuration.

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.67.0...
- Installed hashicorp/aws v6.67.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│ 
│ Due to your customized provider installation methods, Terraform was forced
│ to calculate lock file checksums locally for the following providers:
│   - hashicorp/aws
│ 
│ The current .terraform.lock.hcl file only includes checksums for
│ linux_amd64, so Terraform running on another platform will fail to install
│ these providers.
│ 
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

The three lines starting with a dash carry the news: Terraform looked for releases of `hashicorp/aws`
matching `~> 6.0`, picked 6.67.0 and installed it. **The word `(unauthenticated)` comes from the
machine these lessons were recorded on.** It had no internet, so it installed providers from a
local directory of packages, and a directory has no signature to check. Your `init` downloads from
the Terraform Registry, checks the provider's signature and prints `(signed by HashiCorp)` in that
place. It may also pick a newer 6.x than 6.67.0, which `~> 6.0` allows. The warning box is the
recording machine's too, and yours has none; the lock file below says why.

Two things appeared beside Ana's files:

```
ana@laptop:~/shop$ ls -A
.terraform
.terraform.lock.hcl
main.tf
versions.tf
ana@laptop:~/shop$ find .terraform
.terraform
.terraform/providers
.terraform/providers/registry.terraform.io
.terraform/providers/registry.terraform.io/hashicorp
.terraform/providers/registry.terraform.io/hashicorp/aws
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0/linux_amd64
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0/linux_amd64/terraform-provider-aws_v6.67.0_x5
.terraform/providers/registry.terraform.io/hashicorp/aws/6.67.0/linux_amd64/LICENSE.txt
ana@laptop:~/shop$ du -sh .terraform
789M	.terraform
```

**`.terraform/` holds the provider itself, and it is not small**: 789M, nearly all of it the one
file `terraform-provider-aws_v6.67.0_x5`. That is the program Terraform will start and talk to on
every plan. Each working directory gets its own copy unless a plugin cache is configured, and the
directory can be deleted and rebuilt with `init` at any time. It never goes into git. Yours has a
cache, set by the last two lines of lesson 1's `iac-env.sh`, so on your screen `linux_amd64` is a
link into `~/.terraform.d/plugin-cache`, `find` stops at it, and `du` counts a few kilobytes.

**`.terraform.lock.hcl` is the opposite: small, and it does go into git.**

```
ana@laptop:~/shop$ cat .terraform.lock.hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.67.0"
  constraints = "~> 6.0"
  hashes = [
    "h1:EB9ixYOZrSlYD7wtJxf88qwoyyWrlKDKxhzaCLIb3t4=",
  ]
}
```

It records the exact version init selected, the constraint it was selected under, and a checksum
of the package. The next `init`, on any machine, installs 6.67.0 and nothing else, even after 6.68
is published, and refuses a package whose checksum does not match. Without the file, two people
running `init` a week apart could get two provider versions and two different plans from the same
configuration. Moving to a newer version becomes a deliberate act, which the providers section
performs.

**This file is where your screen and the page differ most.** Installed from the registry, as
yours was, `hashes` carries an `h1:` line for your platform and a `zh:` line for every platform
HashiCorp builds the provider for, over a dozen, so a lock file written on Linux also works on a
colleague's Mac. The recording machine's local copy held only the Linux package, so init could hash
only `linux_amd64`, and the warning in its output said so: a Mac would refuse this lock file. The
command the warning names, `terraform providers lock`, downloads the other platforms' packages to
hash them, and on the recording machine it failed, because the registry was out of reach:

```
ana@laptop:~/shop$ terraform providers lock -platform=darwin_arm64
╷
│ Error: Could not retrieve providers for locking
│ 
│ Terraform failed to fetch the requested providers for darwin_arm64 in order
│ to calculate their checksums: some providers could not be installed:
│ - registry.terraform.io/hashicorp/aws: could not connect to
│ registry.terraform.io: failed to request discovery document: GET
│ https://registry.terraform.io/.well-known/terraform.json giving up after 4
│ attempt(s): Get "https://registry.terraform.io/.well-known/terraform.json":
│ dial tcp: lookup registry.terraform.io on 127.0.0.1:53: server misbehaving.
╵
```

Run it yourself and it succeeds: it fetches the Mac package, adds that platform's `h1:` hash to
the file and says the lock file was updated. Yours already worked on a Mac through its `zh:` lines,
so all it gains is a second kind of hash for one more platform.

What goes into git, then, is the configuration and the lock file, and not the providers. Ana makes
the directory a repository with `git init`, and her `.gitignore` says so before her first commit:

```
.terraform/
*.tfstate
*.tfstate.*
```

```
ana@laptop:~/shop$ git add . && git status --short
A  .gitignore
A  .terraform.lock.hcl
A  main.tf
A  versions.tf
```

She commits with `git commit -m "The shop network, first configuration"`, and the `git diff` in
later sections compares against commits like it. The two `tfstate` patterns are for a file that
does not exist yet. The first apply writes it, and lesson 7 explains why it belongs somewhere
safer than a repository.
