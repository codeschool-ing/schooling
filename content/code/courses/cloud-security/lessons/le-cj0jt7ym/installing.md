---
title: Three tools for this lesson
version: 1
---

**When infrastructure is written as code, a security review can happen before anything exists.**
The bucket of lesson 1 went public the moment somebody sent one request. Written in Terraform instead,
the same mistake is a line in a file, and that file is read by a plan, by a scanner and by a person
before the request is ever sent. This lesson is about using that chance, and about the two places
infrastructure code leaks what it should not: the repository and the state file.

The `iac` course teaches Terraform from the start, and it is not in this course's tracks. What this
lesson needs of it is small. **A configuration is a set of `.tf` files describing resources.
`terraform plan` compares them with what exists and prints what it would change, and `terraform
apply` makes the change.** Everything else is introduced where it is used.

## Terraform, Checkov and git

Terraform is one program, published by HashiCorp as a zip file. It goes into `~/.local/bin`, beside
`aws`. **Checkov** is an open-source scanner for infrastructure code, written in Python, so it goes
into a virtual environment of its own at `~/aws/tools`, with a link on the path. Both are pinned to the
versions the transcripts were recorded with:

```sh
cd ~/aws
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
python3 -m venv ~/aws/tools
~/aws/tools/bin/pip install -q checkov==3.3.22
ln -sf ~/aws/tools/bin/checkov ~/.local/bin/checkov
```

On an Arm computer the Terraform file is `terraform_1.16.4_linux_arm64.zip`.

**The AWS provider is the large part**, a single program of over 800 MB, and Terraform downloads it
into every directory that uses it unless it is told to keep one copy for all of them. Two lines tell
it to:

```sh
mkdir -p ~/.terraform.d/plugin-cache
echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' > ~/.terraformrc
```

This lesson uses two Terraform directories, so the cache halves what the provider costs your disk.

The section on secrets in the repository also needs **git**. Ubuntu Server has it already; on Ubuntu
Desktop it may be missing:

```sh
sudo apt-get install -y git
```

Check all three:

```
ana@laptop:~/aws$ terraform version
Terraform v1.16.4
on linux_amd64
ana@laptop:~/aws$ checkov --version
3.3.22
ana@laptop:~/aws$ git --version
git version 2.43.0
```

## How Terraform reaches moto

Terraform talks to AWS through a **provider**, a plugin that `terraform init` downloads from the
Terraform Registry the first time a directory names it. The provider reads the same environment
variables the AWS command line does, so `env.sh` already points it at moto, with the `test` key and
the São Paulo region. One setting in each configuration, `s3_use_path_style = true`, is there for moto
alone: it makes the provider write a bucket's address as `localhost:4567/bucket` rather than as a name
of its own. Against AWS it is left out.

**A note on the recording.** The machine these lessons were recorded on could not reach the
Terraform Registry. Its `terraform init` was given the same provider, version 6.67.0, from a local
copy, downloaded from HashiCorp's release site and checked against the checksums HashiCorp publishes.
`terraform init` prints a few lines differently when it installs from a copy, which is why the
transcripts never show its output. On your computer it downloads the provider and ends with
*Terraform has been successfully initialized!*
