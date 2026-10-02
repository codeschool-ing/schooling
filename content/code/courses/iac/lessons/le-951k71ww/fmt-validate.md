---
title: fmt and validate, the two checks that cost nothing
version: 1
---

The first two rungs are commands you already know, and lesson 3 showed `validate` catching an
unquoted range. What changes in a test suite is how they are run: **as checks that fail, not as
commands that fix**. A pipeline cannot stop and ask, so each has to answer with an exit status.

## fmt: layout, as a yes or a no

`terraform fmt` on its own rewrites files into the canonical layout and prints the name of each
file it changed. With `-check` it changes nothing and exits with a non-zero status if any file
would change; `-diff` shows what the change would be. Ana's `outputs.tf` was typed in a hurry:

```
ana@laptop:~/shop/modules/network$ terraform fmt -check -diff; echo "exit $?"
outputs.tf
--- old/outputs.tf
+++ new/outputs.tf
@@ -1,7 +1,7 @@
 output "vpc_id" {
-    value = aws_vpc.this.id
+  value = aws_vpc.this.id
 }
 
 output "subnet_ids" {
-  value = {for k, s in aws_subnet.this: k => s.id}
+  value = { for k, s in aws_subnet.this : k => s.id }
 }
exit 3
```

The status is `3`, where a tidy directory answers `0`, and the diff says exactly why: four spaces
where two belong, and no spaces inside the braces of a `for`. Anything other than `0` stops a pipeline. Fixing it is the command without the flag:

```
ana@laptop:~/shop/modules/network$ terraform fmt
outputs.tf
ana@laptop:~/shop/modules/network$ terraform fmt -check; echo "exit $?"
exit 0
```

Both forms look at one directory. `-recursive` extends them to every directory below it, which is
how a pipeline covers the test files under `tests/` and every configuration in a repository with
one command.

## validate: consistent, and with what

`validate` needs the providers, because the schema it checks against is inside them. In a fresh
checkout it says so:

```
ana@laptop:~/shop/modules/network$ terraform validate
╷
│ Error: Missing required provider
│ 
│ This configuration requires provider registry.terraform.io/hashicorp/aws,
│ but that provider isn't available. You may be able to install it
│ automatically by running:
│   terraform init
╵
```

So a pipeline runs `terraform init` first, and when a configuration has a remote backend, `terraform
init -backend=false`, which installs providers and modules without touching the state. After
that, the same command answers:

```
ana@laptop:~/shop/modules/network$ terraform validate
Success! The configuration is valid.
```

Here is what it catches. Ana mistypes one argument of the VPC:

```
ana@laptop:~/shop/modules/network$ terraform validate
╷
│ Error: Unsupported argument
│ 
│   on main.tf line 6, in resource "aws_vpc" "this":
│    6:   cidr_blocks          = var.cidr
│ 
│ An argument named "cidr_blocks" is not expected here. Did you mean
│ "cidr_block"?
╵
```

The provider's schema has no `cidr_blocks` on `aws_vpc`, and Terraform suggests the nearest name
it does have. A misspelled reference, an argument of the wrong type and a block in the wrong place
are refused the same way, with the file and the line.

**Look at what `validate` did not ask for.** The module has three variables and none has a
default. A plan would ask for all three, and in a pipeline, with nobody to answer, it would stop. `validate` printed `Success!`
without any, because it checks the configuration and never the values that will go through it.
So it cannot know that a subnet is meant for a zone in another region, or for a range outside the
VPC, and **every check from here down the ladder exists to ask about values**.

So the two cheapest rungs make sure the files are tidy and
internally consistent, with no account and no network. They prove nothing about what the
module will do with a particular input, and a suite that stops at them has tested the spelling.
