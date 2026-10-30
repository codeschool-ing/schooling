---
title: How the Azure CLI is put together
version: 1
---

**The Azure CLI is not a thin wrapper that sends whatever you type to Azure. It is a large program
that knows every command, every parameter and every default before anything leaves your computer**,
and most of the mistakes people make with it are caught there, in your terminal. That is why this
lab, with no account at all, can show most of how it behaves.

Every command has the same shape: `az`, a **group**, sometimes a subgroup, a **command**, then
parameters. `az group create`, `az network vnet subnet list`, `az account show`. The groups follow
Azure's services, and the commands are verbs that mean the same thing everywhere: `create`, `show`,
`list`, `update`, `delete`.

## The help is in the program

Make the lesson's directory first:

```sh
mkdir -p ~/azure/cli && cd ~/azure/cli
```

Then ask a command what it takes. The help is part of the installation, so it answers here exactly
as it would with an account:

```
ana@laptop:~/azure/cli$ az group create --help | sed -n '1,12p'

Command
    az group create : Create a new resource group.

Arguments
    --name --resource-group -g -n [Required] : Name of the new resource group.
    --location -l                            : Location. Values from: `az account list-locations`.
                                               You can configure the default location using `az
                                               configure --defaults location=<location>`.  Config:
                                               brazilsouth.
    --managed-by                             : The ID of the resource that manages this resource
                                               group.
```

Two details are worth noticing. A parameter often has several spellings, `--name`, `--resource-group`,
`-g` and `-n`, and the short ones are what you will see in other people's scripts. And the help for
`--location` ends with **`Config: brazilsouth.`**: the CLI has already found the default that
`env.sh` set, and will use it for any command where you leave the location out.

**A missing parameter is refused before Azure is asked anything**:

```
ana@laptop:~/azure/cli$ az group create
ERROR: the following arguments are required: --name/--resource-group/-n/-g

Examples from command's help:
az group create -l westus -n MyResourceGroup
Create a new resource group in the West US region.

https://aka.ms/cli_ref
Read more about the command in reference docs
```

The CLI parsed the line, found no name, and stopped with the first example from the help. Nothing was
sent, and nobody needed to sign in for that answer. Compare it with lesson 1's `az group list`, which
was a valid command refused for want of an identity: two different stops, at two different places.

## Defaults, and where each setting came from

A default saves typing the same parameter on every command, and **a default you forgot about is the
commonest way to run a command against the wrong thing**. The CLI keeps them in its configuration,
which `az config` reads and writes:

```
ana@laptop:~/azure/cli$ az config set defaults.group=rg-shop-prod
WARNING: Command group 'config' is experimental and under development. Reference and support levels: https://aka.ms/CLI_refstatus
ana@laptop:~/azure/cli$ az config get defaults
WARNING: Command group 'config' is experimental and under development. Reference and support levels: https://aka.ms/CLI_refstatus
[
  {
    "name": "location",
    "source": "AZURE_DEFAULTS_LOCATION",
    "value": "brazilsouth"
  },
  {
    "name": "group",
    "source": "/home/ana/azure/.azure/config",
    "value": "rg-shop-prod"
  }
]
ana@laptop:~/azure/cli$ az config unset defaults.group
WARNING: Command group 'config' is experimental and under development. Reference and support levels: https://aka.ms/CLI_refstatus
```

`az config get` names the **source** of every value, and that is its most useful feature. The
location came from the environment variable `env.sh` exports, the group from the file
`~/azure/.azure/config` that `az config set` wrote, and `az config unset` took it out again. When a command lands somewhere unexpected, this
is the first thing to read. The warning on every line says that `az config` is still marked
experimental; its older sibling, `az configure --defaults group=rg-shop-prod`, writes the same file.

Settings reach the CLI from three places, and the later one wins:

| place | example | lasts |
|---|---|---|
| the configuration file in `AZURE_CONFIG_DIR` | `az config set defaults.group=rg-shop-prod` | until unset |
| an environment variable, `AZURE_<SECTION>_<NAME>` | `AZURE_DEFAULTS_LOCATION=brazilsouth` | for that terminal |
| a parameter on the command line | `--location southcentralus` | for that one command |

**A parameter on the line always wins**, so a script that must act on one particular group names it
every time, and does not lean on a default somebody may have changed.

## Extensions

Some commands are not in the CLI itself but in **extensions**, separate packages it installs on
demand: `az extension add --name <name>`, or automatically the first time you type a command that
needs one. They land inside `AZURE_CONFIG_DIR`, so the lab's are kept apart from any other CLI on the
machine:

```
ana@laptop:~/azure/cli$ az extension list
[]
```

None yet. **Adding one was not run for this course**: the CLI downloads its index of extensions from
a Microsoft storage address that the machine the lessons were recorded on cannot reach. On your
machine it works, and `az extension list` will then name it with its version. Nothing in this course
needs an extension.

## When a command misbehaves

`--debug` makes the CLI print every step it takes: which modules it loaded, which parameters it
parsed, which client it built, every request it sent and every answer it received, headers
included. Lesson 25 uses it to watch a command get as far as it can without an account. Two smaller
flags are for scripts: `--only-show-errors` silences warnings such as the one on `az config`, and
`--output none` prints nothing at all when the exit code is all a script needs.
