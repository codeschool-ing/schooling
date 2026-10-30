---
title: Azure PowerShell, and the shell in the browser
version: 1
---

**There are two official command lines for Azure, and they reach the same API.** The Azure CLI is the
one this course uses. **Azure PowerShell** is the other: a set of modules for PowerShell, called `Az`,
whose commands are cmdlets in PowerShell's verb-noun form. Neither can do anything the other cannot,
because both turn what you type into the same requests to Resource Manager, which lesson 25 opens up.

## Azure PowerShell, side by side

PowerShell 7 runs on Linux, macOS and Windows, and `Az` is installed from the **PowerShell Gallery**,
PowerShell's package repository, with `Install-Module -Name Az -Repository PSGallery -Scope
CurrentUser`. **Nothing in this section was run for the course**: the machine the lessons were recorded
on cannot reach the PowerShell Gallery, so the module could not be installed, and there are no
transcripts here. The names below are from Microsoft's documentation.

| what | Azure CLI | Azure PowerShell |
|---|---|---|
| sign in | `az login` | `Connect-AzAccount` |
| which subscription | `az account show` | `Get-AzContext` |
| choose another | `az account set --subscription shop-staging` | `Set-AzContext -Subscription shop-staging` |
| list groups | `az group list` | `Get-AzResourceGroup` |
| create one | `az group create -n rg-shop-prod -l brazilsouth` | `New-AzResourceGroup -Name rg-shop-prod -Location brazilsouth` |
| deploy a Bicep file | `az deployment group create -g rg-shop-prod -f main.bicep` | `New-AzResourceGroupDeployment -ResourceGroupName rg-shop-prod -TemplateFile main.bicep` |

**The difference that matters is what comes back.** The CLI prints text, JSON by default, and you
filter it with `--query`. PowerShell returns **objects**: `Get-AzResourceGroup` hands the next command
in the pipeline a list of resource groups with typed properties, and `Where-Object` and
`Select-Object` work on those properties directly. Choose by what your team already writes: a team
of Bash scripts reads the CLI, a team that manages Windows servers in PowerShell reads `Az`. Mixing
both in one pipeline gains nothing.

## Cloud Shell

**Cloud Shell is a terminal in the browser, opened from the Azure portal**, with the Azure CLI, Azure
PowerShell, Terraform, `git` and the usual Linux tools already installed and kept current by
Microsoft. You choose Bash or PowerShell, and it is **already signed in as you**, with the identity you
used for the portal. That is what it is for: the five minutes when you need a command line and are at
somebody else's computer, or when you want to try a command against the latest CLI without updating
yours.

Its limits are documented, and each one decides how far to trust it:

- **the machine is temporary**, provided per session and per user, and a session ends after **20
  minutes** without interactive activity. Anything installed outside your home directory is gone the
  next time;
- **your files persist only if you give it storage**: it keeps `$HOME` on a **5 GB** file share in a
  storage account in your subscription. The machine is free; the storage account is billed at normal
  rates. An *ephemeral* session, with no storage, keeps nothing at all;
- **it needs an Azure account**, which is why lesson 1 left it out of this course's three paths.

**None of it was run for this course**, for the last of those reasons.

## More than one identity

Whichever command line you use, it holds a **sign-in** and a **current subscription**, and the second
is where a mistake lands. `az account show` and `Get-AzContext` answer which one is current. Two habits
keep two identities apart: name the subscription on every command that changes something
(`--subscription shop-staging`), and give each identity its own configuration directory, which is what
`AZURE_CONFIG_DIR` did for the lab in lesson 1. A terminal for production that has never signed in to
staging cannot be pointed at staging by mistake.
