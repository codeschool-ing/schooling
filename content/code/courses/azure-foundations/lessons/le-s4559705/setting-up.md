---
title: Installing the lab
version: 1
---

Everything below runs in a terminal on Ubuntu 24.04, as your own user, and only the first block asks
for `sudo`. **Everything else lands in two places: `~/azure`, where you work for the rest of the
course, and `~/.local/bin`, where Terraform goes.** Deleting those two, and Terraform's provider
cache in `~/.terraform.d`, removes the lab completely.

## The packages from Ubuntu

Python, `curl`, `jq` and `unzip` come from Ubuntu's own archive, and so does `dig`, which lesson 21
uses to ask the public DNS questions:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip bind9-dnsutils
```

**`python3-venv` is the one people leave out**, because Ubuntu ships Python without it. Without it
the next block fails, and the section on failures says what that looks like.

## The Azure CLI, in a virtual environment

A virtual environment is a directory holding its own copy of Python's package installer, so what you
install there touches nothing else on the machine. The Azure CLI is a Python program, and Microsoft
publishes it on the Python Package Index as `azure-cli`. It goes into a virtual environment at
`~/azure/venv`, pinned to the version the lessons were recorded with, together with the Azure
Identity library that lesson 8 uses:

```sh
mkdir -p ~/azure ~/.local/bin
python3 -m venv ~/azure/venv
~/azure/venv/bin/pip install -q 'azure-cli==2.91.0' 'azure-identity==1.27.0'
```

It takes a few minutes and about 700 MB, because the CLI carries a client for every Azure service.
Microsoft also packages it for Ubuntu's `apt`, which is the route its documentation puts first; the
package index is the one that lets the version be pinned in a directory of your own without `sudo`,
and both install the same program. A newer version works for everything this course does: the
version line and the wording of a few messages will differ from the lessons, and nothing else will.

## Terraform

Terraform is a single program, published by HashiCorp as a zip file. Lesson 26 compares it with the
other ways of describing Azure, and several lessons before that check a configuration with it. This
puts one fixed version in `~/.local/bin`:

```sh
cd ~/azure
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
unzip -q terraform.zip terraform -d ~/.local/bin
rm terraform.zip
```

On a computer with an Arm processor, which includes a virtual machine on a Mac with Apple silicon,
the file is `terraform_1.17.1_linux_arm64.zip` instead.

## One file that points everything at the lab

Both programs read their settings from environment variables. One short file sets them all, and
every lesson starts by reading it:

```sh
cat > ~/azure/env.sh <<'END'
# The Azure courses' lab. Read it into every terminal: source ~/azure/env.sh
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/azure/venv/bin/activate"
export AZURE_CONFIG_DIR="$HOME/azure/.azure"
export AZURE_CORE_COLLECT_TELEMETRY=no
export AZURE_DEFAULTS_LOCATION=brazilsouth
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
cd "$HOME/azure"
END
```

Line by line, after the comment:

| line | what it does |
|---|---|
| `PATH` | puts `~/.local/bin`, where `terraform` is, on the path |
| `activate` | switches to the virtual environment, which puts `az` on the path |
| `AZURE_CONFIG_DIR` | **keeps everything the Azure CLI stores, sign-ins included, in `~/azure/.azure`** instead of `~/.azure`. A terminal that never reads this file is a different Azure CLI with an empty memory, which the section on a real account uses |
| `AZURE_CORE_COLLECT_TELEMETRY` | stops the CLI sending Microsoft a record of each command you run |
| `AZURE_DEFAULTS_LOCATION` | `brazilsouth`, São Paulo, the region every lesson works in, used by any command that asks for a location and is not given one |
| `TF_PLUGIN_CACHE_DIR` | keeps one copy of each Terraform provider for every lesson, instead of one per directory |

**Never put a secret in this file**, or in any file this course asks you to create. There is none to
put: nothing in the course signs in to anything. A file in your home directory gets copied into
backups, shared folders and screenshots without anybody deciding to.

## Every time you open a terminal

One line:

```sh
source ~/azure/env.sh
```

Your prompt gains `(venv)` at the front; the transcripts in the lessons leave it out.

The first time, and only then, ask the Azure CLI to fetch the Bicep compiler, which lessons 2 to 26
use to turn a description of Azure resources into the JSON that Resource Manager reads. It goes into
`~/azure/.azure/bin`, inside the directory `env.sh` set aside:

```sh
az bicep install --version v0.48.1
```

Then check that each tool answers:

```
ana@laptop:~/azure$ az version
{
  "azure-cli": "2.91.0",
  "azure-cli-core": "2.91.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
ana@laptop:~/azure$ az bicep version
Bicep CLI version 0.48.1 (cec7951cf6)

ana@laptop:~/azure$ terraform version
Terraform v1.17.1
on linux_amd64

ana@laptop:~/azure$ az account show
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ cd ~ && du -sh azure/venv azure/.azure .local/bin/terraform
709M	azure/venv
117M	azure/.azure
124M	.local/bin/terraform
```

The Azure CLI reports its own version and those of its parts, Bicep the version it was asked for,
and Terraform the version from the zip file. `az account show` asks the question every Azure
session can answer once somebody has signed in: which subscription am I working in? Here nobody
has, and the CLI says so without sending anything anywhere. That refusal is the normal state of
this lab, and the next sections say why it stays that way.

The last three lines are the cost of the lab on disk, 950 MB between them: the Azure CLI in its
virtual environment, the Bicep compiler inside `~/azure/.azure`, and Terraform. The first lesson that
runs `terraform init`, lesson 2, adds Microsoft's provider to the cache, and lesson 6 adds the one
for Entra ID.
