---
title: Administrative units, and writing the directory down
version: 1
---

**An administrative unit is a slice of the directory that an administrator's role can be limited
to.** It answers a question the tree of lesson 2 does not reach: management groups divide Azure's
resources, and nothing in that tree divides the directory. Without administrative units, a helpdesk
person who resets passwords resets them for everybody, the chief executive included.

The shop has staff in its offices and staff in its physical stores, and the store managers reset
passwords for their own people. So:

- an administrative unit `au-shop-stores` holds the store staff;
- the role **User Administrator** is given to the store managers **scoped to that unit**, not to the
  tenant;
- a store manager can now reset `bia`'s password only if `bia` is in the unit, and she is not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-au-scope\" aria-label=\"The shop's tenant holds the office staff, among them bia, and an administrative unit called au-shop-stores holding the store staff. A store manager holds the role User Administrator scoped to the unit. An arrow from the manager reaches into the unit and resets passwords there; a second arrow towards bia, outside the unit, is refused.\"><defs><marker id=\"l06-au-scope-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-au-scope-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"14.0\" width=\"680.0\" height=\"272.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tenant</text><text x=\"684.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop.example</text><rect x=\"270.0\" y=\"52.0\" width=\"180.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">store manager</text><text x=\"360.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">User Administrator</text><rect x=\"44.0\" y=\"150.0\" width=\"250.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"169.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">office staff</text><rect x=\"70.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bia</text><rect x=\"175.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ana</text><rect x=\"420.0\" y=\"150.0\" width=\"256.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"548.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">au-shop-stores</text><rect x=\"448.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"493.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lia</text><rect x=\"553.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rui</text><path d=\"M400.0 109.0 L500.0 149.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-au-scope-af-ah-amber)\"></path><text x=\"498.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">resets passwords</text><path d=\"M320.0 109.0 L190.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-au-scope-af-ah-paper-dim)\"></path><text x=\"212.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refused: outside the scope</text></svg>", "caption": "A directory role scoped to a unit reaches the unit's members and nobody else."}
```

Three properties are worth knowing. An administrative unit **cannot contain another one**: they are
flat. A user may be in several. And a **restricted management** administrative unit goes further:
administrators whose role covers the whole tenant can no longer change its members, and only those
given a role on the unit itself can. It is how a company protects its executives' accounts from its
own helpdesk.

## Two kinds of role, which share nothing

**The roles of Entra ID and the roles of Azure are two separate systems**, and the same word hides
that. *User Administrator*, *Global Administrator* and the other **directory roles** decide what
somebody may do to the directory: create users, reset passwords, register applications. **Azure
roles**, *Owner*, *Contributor*, *Reader* and the rest of lesson 9, decide what somebody may do to
resources in a subscription. A Global Administrator has no access to a single virtual machine until
an Azure role says so, and an Owner of every subscription cannot reset one password.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-two-role-systems\" aria-label=\"Two separate role systems side by side. On the left, directory roles of Entra ID, such as Global Administrator and User Administrator, act on users, groups and applications, and are scoped to the tenant or an administrative unit. On the right, Azure roles such as Owner, Contributor and Reader act on resources, and are scoped to a management group, a subscription, a resource group or a resource. Nothing crosses between them.\"><rect x=\"30.0\" y=\"20.0\" width=\"310.0\" height=\"210.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">directory roles</text><rect x=\"70.0\" y=\"60.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Global Administrator</text><rect x=\"70.0\" y=\"94.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">User Administrator</text><text x=\"185.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">act on users, groups, applications</text><text x=\"185.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">scope: tenant or administrative unit</text><rect x=\"380.0\" y=\"20.0\" width=\"310.0\" height=\"210.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Azure roles</text><rect x=\"420.0\" y=\"60.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Owner</text><rect x=\"420.0\" y=\"94.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Contributor</text><rect x=\"420.0\" y=\"128.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Reader</text><text x=\"535.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">act on resources</text><text x=\"535.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">scope: group, subscription, resource</text></svg>", "caption": "A Global Administrator reads no virtual machine until an Azure role says so; an Owner resets no password."}
```

**One bridge exists, and it is meant for emergencies.** A Global Administrator can switch on
*elevate access* and become User Access Administrator over every subscription in the tenant, which is
how a company recovers a subscription whose owners have all left. The switch is recorded in the
tenant's logs, and it should be switched off again the same day. Administrative units scope
directory roles; lesson 9's scopes are the boxes of lesson 2.

## The shop's directory, in Terraform

The Azure provider of lesson 2 does not reach the directory: Entra ID has a provider of its own,
`azuread`, which writes to Microsoft Graph. Save this as `main.tf` in `~/azure/entra`:

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.10.0"
    }
  }
}

provider "azuread" {
  tenant_id = "aaaabbbb-0000-cccc-1111-dddd2222eeee"
}

resource "azuread_user" "bia" {
  user_principal_name = "bia@shop.example"
  display_name        = "Bia Souza"
  department          = "Engineering"
}

resource "azuread_group" "engineering" {
  display_name     = "grp-shop-engineering"
  security_enabled = true
  types            = ["DynamicMembership"]

  dynamic_membership {
    enabled = true
    rule    = "user.department -eq \"Engineering\""
  }
}

resource "azuread_administrative_unit" "stores" {
  display_name = "au-shop-stores"
  description  = "Staff of the physical stores"
}

resource "azuread_invitation" "accountant" {
  user_email_address = "carla@accounting.example"
  redirect_url       = "https://myapps.microsoft.com"
}
```

A user, the dynamic group with the rule above, the administrative unit, and an invitation for the
accountant, who becomes a guest when she accepts it. Putting a store manager's role on the unit is
one more resource, `azuread_administrative_unit_role_member`, left out to keep the file short.
**There is no password in the file, on purpose**: a password in a configuration is a password in
the repository's history and in Terraform's state. In a company most users are not created here at
all; they arrive from the HR system or the office's own directory, which is lesson 12. Then:

```
ana@laptop:~/azure/entra$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azuread versions matching "3.10.0"...
- Installing hashicorp/azuread v3.10.0...
- Installed hashicorp/azuread v3.10.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/entra$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/entra$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer: could not configure AzureCli Authorizer: obtaining subscription ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azuread"],
│   on main.tf line 10, in provider "azuread":
│   10: provider "azuread" {
│ 
╵
```

`init` downloaded the second provider of the course, the one lesson 1 said this lesson would add.
`validate` checked every block against Graph's schema as the provider knows it. **It did not check
the rule**: `user.department -eq "Engineering"` is a string to Terraform, and a misspelt attribute in
it would be refused by Entra ID when the group was created, not here. And `plan` stopped where every
plan in this lab stops, at the sign-in, because what exists in the directory is Microsoft Graph's to
say.
