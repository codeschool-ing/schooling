---
title: Four scopes a deployment can aim at
version: 1
---

**Every request to create something in Azure is aimed at a scope, and the scope is one of the four
boxes.** A management group is created at the scope of the tenant, a resource group at the scope of
a subscription, a network at the scope of a resource group. Bicep makes the scope the first line of
a file, and its compiler refuses a resource aimed at the wrong one, so this is the part of the
hierarchy the lab can check for real.

## The tree, in Bicep

Bicep is a language for describing Azure resources, and `az bicep build` compiles a `.bicep` file
into an **ARM template**, the JSON document Resource Manager actually receives. Lesson 26 compares
it with the other ways in; here it is a way of writing the shop's tree down. Save this as
`tree.bicep` in `~/azure/hierarchy`:

```bicep
targetScope = 'tenant'

@description('The id of the management group the shop hangs under: the tenant root, by default.')
param rootId string = tenant().tenantId

resource shop 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: 'mg-shop'
  properties: {
    displayName: 'Shop'
    details: {
      parent: {
        id: '/providers/Microsoft.Management/managementGroups/${rootId}'
      }
    }
  }
}

resource prod 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: 'mg-shop-prod'
  properties: {
    displayName: 'Shop production'
    details: {
      parent: {
        id: shop.id
      }
    }
  }
}
```

`targetScope = 'tenant'` says where the deployment is aimed. Each `resource` names a type, a
**version of its API** after the `@`, and the properties. The parent of `mg-shop` defaults to the
root, whose id is the tenant's id, and the parent of `mg-shop-prod` is `mg-shop`'s own id, which
Bicep works out. Compile it and look at three things in the template:

```
ana@laptop:~/azure/hierarchy$ az bicep build --file tree.bicep --stdout | jq '{schema: ."$schema", resources: [.resources[] | {type, name, parent: .properties.details.parent.id}]}'
{
  "schema": "https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#",
  "resources": [
    {
      "type": "Microsoft.Management/managementGroups",
      "name": "mg-shop",
      "parent": "[format('/providers/Microsoft.Management/managementGroups/{0}', parameters('rootId'))]"
    },
    {
      "type": "Microsoft.Management/managementGroups",
      "name": "mg-shop-prod",
      "parent": "[tenantResourceId('Microsoft.Management/managementGroups', 'mg-shop')]"
    }
  ]
}
```

**The `$schema` names the scope**: a template aimed at the tenant is a
`tenantDeploymentTemplate`. And the parents are not values but **expressions in square brackets**,
`format(...)` and `tenantResourceId(...)`. They are evaluated by Resource Manager when the template
arrives, because only Resource Manager knows the tenant's id. That is the line between what the lab
can check and what it cannot: the shape is settled here, the values there.

## A resource group, at the scope of a subscription

Save this as `rg.bicep`:

```bicep
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-shop-prod'
  location: 'brazilsouth'
  tags: {
    environment: 'prod'
  }
}

output id string = rg.id
```

And then the same group in a file that says nothing about its scope, saved as `wrong.bicep`:

```bicep
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-shop-prod'
  location: 'brazilsouth'
}
```

```
ana@laptop:~/azure/hierarchy$ az bicep build --file rg.bicep --stdout | jq -c '."$schema", .outputs'
"https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
{"id":{"type":"string","value":"[subscriptionResourceId('Microsoft.Resources/resourceGroups', 'rg-shop-prod')]"}}
ana@laptop:~/azure/hierarchy$ az bicep build --file wrong.bicep --stdout
ERROR: /home/ana/azure/hierarchy/wrong.bicep(1,63) : Error BCP135: Scope "resourceGroup" is not valid for this resource type. Permitted scopes: "subscription". [https://aka.ms/bicep/core-diagnostics#BCP135]
```

The first is a `subscriptionDeploymentTemplate`, and its output is an expression that will become
`/subscriptions/<the subscription>/resourceGroups/rg-shop-prod` when it runs. **The second was
refused, with the rule in the message**: a file with no `targetScope` is aimed at a resource group,
and a resource group cannot be created inside a resource group. `BCP135` is the code, and the
address after it is its documentation.

Deploying either file is one command per scope, each taking the file and the place it is aimed at:

| scope | command |
|---|---|
| tenant | `az deployment tenant create --location brazilsouth --template-file tree.bicep` |
| management group | `az deployment mg create --management-group-id mg-shop --location brazilsouth --template-file ...` |
| subscription | `az deployment sub create --location brazilsouth --template-file rg.bicep` |
| resource group | `az deployment group create --resource-group rg-shop-prod --template-file ...` |

**None of the four was run**, for the same reason as `az group create`: each is a request to Resource
Manager. The `--location` on the first three is not where resources go; it is where Azure keeps the
record of the deployment itself, since a tenant or a subscription has no location of its own.

## The same tree, in Terraform

Terraform describes the same resources in its own language, with Microsoft's provider supplying
the types. Make a directory for it and save this as `main.tf`:

```sh
mkdir -p ~/azure/hierarchy/tf && cd ~/azure/hierarchy/tf
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

resource "azurerm_management_group" "shop" {
  name         = "mg-shop"
  display_name = "Shop"
}

resource "azurerm_management_group" "prod" {
  name                       = "mg-shop-prod"
  display_name               = "Shop production"
  parent_management_group_id = azurerm_management_group.shop.id
}

resource "azurerm_management_group_subscription_association" "prod" {
  management_group_id = azurerm_management_group.prod.id
  subscription_id     = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff"
}

resource "azurerm_resource_group" "prod" {
  name     = "rg-shop-prod"
  location = "brazilsouth"
}
```

Terraform has no `targetScope`: each resource type knows its own scope, and the association between
a subscription and a management group is a resource of its own. `init` fetches the provider from
HashiCorp's registry and keeps it in the cache `env.sh` set up, linked into this directory; `validate`
checks every block against the provider's schema; and `plan` is where it would ask Azure what
exists:

```
ana@laptop:~/azure/hierarchy/tf$ terraform init -input=false
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
ana@laptop:~/azure/hierarchy/tf$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/hierarchy/tf$ terraform plan -input=false

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

`validate` passed and `plan` stopped at the first thing it needed from Azure: an identity, which it
asks the Azure CLI for. **The same line divides the two tools**: both check the shape on your
computer, and both need Resource Manager for everything after it.
