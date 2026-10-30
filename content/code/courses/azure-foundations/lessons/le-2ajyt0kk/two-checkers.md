---
title: Two checkers, and what each one knows
version: 1
---

**A budget with a typo in it is worse than no budget, because it looks like protection.** If
`Forecasted` is spelt `Forecast`, the forecast alert is never created, and nobody finds out until the
month a forecast would have warned them. So it is worth knowing which mistakes the lab can catch
before Azure ever sees the file, and the answer is different for the two tools.

## What Bicep checks

Make two broken copies of the budget: one with the threshold type misspelt, one with the amount
written as text. `sed` writes each copy without touching the original:

```
ana@laptop:~/azure/cost$ sed "s/'Forecasted'/'Forecast'/" budget.bicep > typo.bicep
ana@laptop:~/azure/cost$ az bicep build --file typo.bicep --stdout > /dev/null
ana@laptop:~/azure/cost$ sed "s/amount: 50/amount: '50'/" budget.bicep > text.bicep
ana@laptop:~/azure/cost$ az bicep build --file text.bicep --stdout > /dev/null
WARNING: /home/ana/azure/cost/text.bicep(10,13) : Warning BCP036: The property "amount" expected a value of type "int" but the provided value is of type "'50'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**The misspelt threshold type compiled without a word.** The second copy compiled too, with a
warning, `BCP036`: the amount is meant to be a number and was given a string. Bicep knows the *type*
of every property from Microsoft's description of the API: that `amount` is a number, that
`notifications` is an object. Where that description says a property is a string and lists no
allowed values, Bicep accepts any string, and `thresholdType` is one of those. The template that
came out is a perfectly valid ARM template with a value in it that Resource Manager would refuse,
or worse, store.

Note also that `BCP036` is a **warning**, not an error: `az bicep build` still wrote the template.
The message says why: Bicep's types are generated from the API's own specification, and when the two
disagree, Microsoft would rather you were warned than blocked. Read the warnings; a build that
prints one has not passed.

## What Terraform checks

Terraform's provider for Azure is written by hand, by people who added their own validation to many
fields. The same budget in Terraform, saved as `main.tf` in a directory of its own:

```sh
mkdir -p ~/azure/cost/tf && cd ~/azure/cost/tf
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

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-shop-monthly"
  subscription_id = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff"
  amount          = 50
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 80
    threshold_type = "Actual"
    contact_emails = ["billing@shop.example"]
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 100
    threshold_type = "Forecasted"
    contact_emails = ["billing@shop.example"]
  }
}
```

The subscription is named by its full id, the one lesson 2 took apart, and the start date carries a
time because the provider asks for one. Initialise, validate, then make the same typo, validate again,
and put it back:

```
ana@laptop:~/azure/cost/tf$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "5.12.0"...
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)

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
ana@laptop:~/azure/cost/tf$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/cost/tf$ sed -i 's/"Forecasted"/"Forecast"/' main.tf
ana@laptop:~/azure/cost/tf$ terraform validate
╷
│ Error: expected notification.0.threshold_type to be one of ["Actual" "Forecasted"], got Forecast
│ 
│   with azurerm_consumption_budget_subscription.monthly,
│   on main.tf line 14, in resource "azurerm_consumption_budget_subscription" "monthly":
│   14: resource "azurerm_consumption_budget_subscription" "monthly" {
│ 
╵
ana@laptop:~/azure/cost/tf$ sed -i 's/"Forecast"/"Forecasted"/' main.tf
ana@laptop:~/azure/cost/tf$ terraform validate
Success! The configuration is valid.
```

`init` printed what it printed in lesson 2, and behind those lines it linked the provider from the
cache lesson 2 filled rather than fetching it again. **The typo, this time, was caught, with the
allowed values in the message.** The provider's authors
wrote down that `threshold_type` is one of `Actual` and `Forecasted`, so `validate` refuses
anything else before a request exists. It calls the block `notification.0` although the typo was in
the second one: Terraform keeps these blocks as a set, which has no order, and numbers what it
reports from zero.

Neither tool is the stricter one in general. Bicep knows every property of every API version the day
it is published, and Terraform knows only the resources its provider has written; Terraform's
provider knows rules about values that Bicep's generated types do not. **Which one catches a mistake
depends on the field**, and the only check that knows everything is Resource Manager, when the
request arrives.

## Deploying it, and making a budget act

With an account, the Bicep file is deployed at the scope of the subscription, as lesson 2 showed:
`az deployment sub create --location brazilsouth --template-file budget.bicep`. The Terraform file is
`terraform apply`. **Neither was run**: both are requests to Resource Manager.

A budget on its own only notifies. **To make it act, a budget at the scope of a subscription or a
resource group can call an action group**, Azure Monitor's list of things to do when an alert fires:
send a text message, call a webhook, start an automation runbook that deallocates every machine in a
resource group. That turns a warning into a brake, and the brake is a program somebody wrote and
tested, not a setting. The `azure-operations` course, in the tracks that include it, builds action
groups in its lesson 12. Here the point is the limit of the thing: **a budget does not stop spending unless you build the part that does**, and a
budget at the scope of a management group or a billing account cannot call an action group at all.
