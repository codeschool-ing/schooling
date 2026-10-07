---
title: When the lab does not work
version: 1
---

Almost every failure in this lab is one of five, and each has a message you can recognise. Read
them now, once, so that the day one of them appears it is a sentence you have seen before.

**The installation stops halfway.** `setup-iac.sh` starts with `set -e`, so it stops at the first
command that fails. The last thing it printed is the step that broke: an `apt-get` that could not
reach the archive, a key that `curl` could not download, a `pip install` that found no network.
Fix that, and run the whole script again; every step in it can be repeated safely.

**The shell does not know `aws`.** Each new terminal starts without the lab's environment:

```
ana@laptop:~$ aws sts get-caller-identity
bash: aws: command not found
```

The command is in `~/iac-venv`, and nothing has put that directory on the `PATH` yet. Read the
environment in, `. ~/iac-env.sh`, and try again. If Ubuntu offers to install an `aws` package for
you instead, decline: it would be a second AWS CLI, outside the environment, and it does not fix
the terminal you are in.

**The CLI is found but has no credentials.** This is the terminal where only the Python environment
was activated, and the four variables were not set:

```
ana@laptop:~$ . ~/iac-venv/bin/activate
ana@laptop:~$ aws sts get-caller-identity
Unable to locate credentials. You can configure credentials by running "aws configure".
```

It also means the CLI did not know where moto is, so it was about to ask the real AWS. The cure is
the same line, `. ~/iac-env.sh`, which does both.

**Nothing answers at the endpoint.** With moto stopped, or listening on a different port from the
one the variable names, the CLI says so in one line:

```
ana@laptop:~$ AWS_ENDPOINT_URL=http://localhost:4567 aws sts get-caller-identity

Could not connect to the endpoint URL: "http://localhost:4567/"
```

Look at moto's terminal: if it shows a prompt rather than a running server, start it again. If it is
running, compare the port it printed when it started with the one in `AWS_ENDPOINT_URL`.

**Something exists that you did not make in this lesson.** moto left running from an earlier lesson
still holds what that lesson made. The first sign is usually a lookup that finds two things where
the lesson expected one. Here the shop's network script from this lesson has run twice, and a
configuration then asks for *the* VPC named `shop`:

```
ana@laptop:~/lookup$ terraform plan
data.aws_vpc.shop: Reading...

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: multiple EC2 VPCs matched; use additional constraints to reduce matches to a single EC2 VPC
│ 
│   with data.aws_vpc.shop,
│   on main.tf line 5, in data "aws_vpc" "shop":
│    5: data "aws_vpc" "shop" {
│ 
╵
```

Nothing is wrong with the configuration. Restart moto, run `fresh-lesson.sh`, and begin the lesson
again from its first command.

**Two more, which only some computers meet.** Terraform's AWS provider names a bucket as
`<bucket>.localhost`, and on Ubuntu Server the system's resolver, systemd-resolved, answers every name that ends in
`.localhost` with your own computer. Some other systems do not; there, creating a bucket fails with
an error saying that name could not be looked up. Add `s3_use_path_style = true` to the
`provider "aws"` block, and `use_path_style = true` to any `backend "s3"` block, and the provider
puts the bucket in the path instead of in the name. And if `terraform init` says it cannot reach
`registry.terraform.io`, the problem is your network, not the lab: lesson 10 shows what that failure
looks like, and what it means.
