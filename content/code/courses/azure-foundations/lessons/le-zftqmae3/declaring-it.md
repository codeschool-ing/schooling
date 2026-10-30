---
title: An eligible assignment, written down
version: 1
---

**PIM is usually driven from the portal, and it does not have to be.** An eligible assignment is a
resource of Resource Manager like any other, `Microsoft.Authorization/roleEligibilityScheduleRequests`,
and Microsoft's Terraform provider has a resource for it. Writing the shop's eligibility down in a
file puts it where a pull request can review it, and that review is one more person agreeing.

## The shop's eligibility, in Terraform

Make the lesson's directory and save this as `main.tf` in it:

```sh
mkdir -p ~/azure/pim && cd ~/azure/pim
```

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff"
}

resource "azurerm_pim_eligible_role_assignment" "ana_prod" {
  scope              = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod"
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb"
  justification      = "On call for the shop's production"

  schedule {
    expiration {
      duration_days = 180
    }
  }
}
```

This one makes `ana` eligible for Contributor on `rg-shop-prod`. Three pieces carry the meaning. The **`data` block** looks a role up by name at a scope: Terraform
asks Resource Manager for Contributor's id when it plans, instead of the file carrying the GUID.
The **resource** joins a principal, a role and a scope, exactly as lesson 9's assignment did, with
one more word in its type. And **`schedule`** is the duration of the eligibility, here 180 days:
the time-bound shape the first section recommended. The principal is `ana`'s object id in the
tenant, a made-up value in the documentation's pattern.

Run `terraform init` once in the directory, then check the file:

```
ana@laptop:~/azure/pim$ terraform validate
Success! The configuration is valid.
```

## Saying when it ends, once

An eligibility ends either after a number of days or on a date, and a file that says both is a file
whose meaning depends on which one wins. Add an end date under the duration:

```sh
sed -i 's/      duration_days = 180/      duration_days = 180\n      end_date_time = "2027-04-30T00:00:00Z"/' main.tf
```

```
ana@laptop:~/azure/pim$ terraform validate
╷
│ Error: Conflicting configuration arguments
│ 
│   with azurerm_pim_eligible_role_assignment.ana_prod,
│   on main.tf line 27, in resource "azurerm_pim_eligible_role_assignment" "ana_prod":
│   27:       duration_days = 180
│ 
│ "schedule.0.expiration.0.duration_days": conflicts with
│ schedule.0.expiration.0.end_date_time
╵
╷
│ Error: Conflicting configuration arguments
│ 
│   with azurerm_pim_eligible_role_assignment.ana_prod,
│   on main.tf line 28, in resource "azurerm_pim_eligible_role_assignment" "ana_prod":
│   28:       end_date_time = "2027-04-30T00:00:00Z"
│ 
│ "schedule.0.expiration.0.end_date_time": conflicts with
│ schedule.0.expiration.0.duration_days
╵
```

**The provider refuses the pair**, at both lines, before anything is sent anywhere. That is the
kind of mistake a schema catches, and it catches it on your computer. Take the line out again with
`sed -i '/end_date_time/d' main.tf` and the file is valid once more.

## Where the lab stops

```
ana@laptop:~/azure/pim$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azurerm"],
│   on main.tf line 10, in provider "azurerm":
│   10: provider "azurerm" {
│ 
╵
```

`plan` would need Resource Manager twice here: once for the identity of whoever runs it, and once
for the `data` block, which asks what Contributor's id is. It stopped at the first, for want of a
sign-in, so **the eligibility was never created**, and neither was the activation it would allow.

The settings of the previous section, the maximum duration, the approvers, the second factor, are
**a separate object**: a role management policy, attached to the role at a scope. Microsoft's
provider has a resource for that too, `azurerm_role_management_policy`, and a team that declares its
eligibilities in a file should declare the policies beside them. It was not written here, because
an activation policy that has never been tried against a real tenant is the kind of file whose
mistakes only the tenant shows.

**A PIM eligibility is not a substitute for the narrow role.** Making Owner eligible instead of
active is a good change. Making `Shop App Restarter` eligible instead of handing out Owner at all is
a better one. Lesson 9 decides how much power a role holds; this lesson decides for how many hours.
