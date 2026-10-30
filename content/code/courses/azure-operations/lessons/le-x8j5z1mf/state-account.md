---
title: The state, in a blob of its own
version: 1
---

**On Azure, Terraform's remote state is a blob in a storage account.** The `azurerm` backend reads and
writes one blob per configuration, under the key you name, in a container you created beforehand. The
account is the one lesson 5's `modules/state.bicep` describes, with blob versioning and thirty days of
soft delete, and it lives in a resource group of its own, `rg-tfstate`, that no other configuration
manages. That separation is the point: the configuration that might one day delete `rg-shop` must not
be the one that owns the record of what `rg-shop` contains.

Azurite stands in for the account here. A real state file, written by Terraform for a configuration with
one `terraform_data` resource (which needs no provider and no cloud), uploaded where the backend would put
it:

```
ana@laptop:~/azure/tf/release$ az storage container create --name tfstate -o tsv
True
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file terraform.tfstate --no-progress -o none
ana@laptop:~/azure/tf/release$ az storage blob list --container-name tfstate --query "[].{name:name, size:properties.contentLength}" -o table
Name          Size
------------  ------
shop.tfstate  861
```

The backend block names the same place in a real subscription:

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stshoptfstate"
    container_name       = "tfstate"
    key                  = "shop.tfstate"
    use_azuread_auth     = true
  }
}
```

**`use_azuread_auth = true` reads and writes the blob as the identity Terraform already signed in with**,
which needs the role *Storage Blob Data Contributor* on the account. Without it, the backend fetches the
account's **access key** and uses that; anybody who can list keys can then read every state file in the
account, and the state file is where Terraform keeps every value it knows, including the ones marked
sensitive. So the shop turns key access off on the state account altogether.

Initialising with that backend asks Azure for the storage endpoint and fails in the lab the same way
`plan` did, this time naming the Storage API:

```
ana@laptop:~/azure/tf/shop$ terraform init -input=false -no-color -reconfigure 2>&1 | grep -v "^$" | head -6
Initializing the backend...
Error: unable to build authorizer for Storage API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
```

The two failures are worth seeing side by side: state and resources are reached through two different
APIs, with two different roles, and an identity can have one and not the other.
