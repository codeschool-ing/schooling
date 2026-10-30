---
title: Whose identity Terraform acts with
version: 1
---

**The provider block names no credentials, and it should not.** The `azurerm` provider looks for an
identity in a fixed order and uses the first that works. With nothing configured, it falls through to
the Azure command line's sign-in, and that is where the lab stops:

```
ana@laptop:~/azure/tf/shop$ terraform plan -input=false -no-color -var subscription_id=00000000-0000-0000-0000-000000000000 2>&1 | grep -v "^$"
Planning failed. Terraform encountered an error while generating this plan.
Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
  with provider["registry.terraform.io/hashicorp/azurerm"],
  on main.tf line 11, in provider "azurerm":
  11: provider "azurerm" {
```

Read the error from the right: the command line said `Please run 'az login'`, so the provider could not
find a tenant, so it could not build an authoriser for Resource Manager, so planning failed. **This is
the furthest Terraform goes in this lab.** `plan` and `apply` were not run against Azure anywhere in the
course; everything from here on about them is from the provider's documentation.

The ways the provider can sign in, and where each belongs:

| how | where it belongs |
|---|---|
| **the Azure command line**, after `az login` | your own laptop, acting as yourself |
| **OIDC**: a federated token, `ARM_USE_OIDC=true` | a pipeline; lesson 2's mechanism, no secret stored |
| **a managed identity**, `ARM_USE_MSI=true` | a self-hosted agent or a VM running inside Azure |
| a client secret or certificate | only where none of the above is possible |

In the shop's GitHub workflow, the job that runs Terraform sets four variables and nothing secret:

```sh
export ARM_CLIENT_ID=...          # the app registration, as in lesson 2
export ARM_TENANT_ID=...
export ARM_SUBSCRIPTION_ID=...
export ARM_USE_OIDC=true          # exchange the pipeline's token; no secret
```

The last row of the table is the one to avoid, for every reason lesson 2 gave. **A secret written into
the provider block is a secret in the repository**, and the repository outlives every rotation.

The identity decides what Terraform can change, so the same rule applies as for any pipeline: the
identity that plans pull requests needs only to read, and the one that applies `main` gets Contributor
on the resource groups it manages, not Owner on the subscription.
