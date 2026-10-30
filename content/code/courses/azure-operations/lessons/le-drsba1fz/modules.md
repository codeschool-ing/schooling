---
title: Modules, and what a module compiles to
version: 1
---

**A module is a Bicep file called from another Bicep file**, with parameters in and outputs out. The
shop's storage for Terraform state, from lesson 4, becomes one, in `modules/`, now with versioning and
thirty days of soft delete on its blobs, which lesson 7 will be grateful for:

```bicep
// modules/state.bicep
@minLength(3)
@maxLength(24)
param accountName string
param location string

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: { name: 'Standard_ZRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: account
  name: 'default'
  properties: {
    isVersioningEnabled: true
    deleteRetentionPolicy: { enabled: true, days: 30 }
  }
}

resource state 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobs
  name: 'tfstate'
}

output accountId string = account.id
```

`main.bicep` calls it, and decides the name from the environment and a suffix:

```bicep
// main.bicep
@allowed([ 'dev', 'prod' ])
param environment string
param location string = 'brazilsouth'

var suffix = uniqueString(resourceGroup().id)

module state 'modules/state.bicep' = {
  name: 'state-${environment}'
  params: {
    accountName: 'stshop${environment}${take(suffix, 6)}'
    location: location
  }
}

output stateAccountId string = state.outputs.accountId
```

Three things in it are worth a sentence each. **`@allowed`** restricts `environment` to two values, and
the next section shows it refusing a third. **`uniqueString(resourceGroup().id)`** is a deterministic
hash: the same resource group always gives the same 13 characters, so the name is stable between
deployments and still unlikely to clash with a storage account somebody else in the world already
named. And the module's **`name`**, `state-prod`, is not a resource name; it is the name of a
deployment, which the next transcript makes visible:

```
ana@laptop:~/azure/infra$ bicep build main.bicep
ana@laptop:~/azure/infra$ jq '.resources | map({type, name})' main.json
[
  {
    "type": "Microsoft.Resources/deployments",
    "name": "[format('state-{0}', parameters('environment'))]"
  }
]
ana@laptop:~/azure/infra$ jq '.resources[0].properties.template.resources | length' main.json
3
```

**A module compiles to a nested deployment**: one resource of type `Microsoft.Resources/deployments`,
carrying the module's whole template inside it, three resources deep. Resource Manager records it as a
deployment of its own, with its own history and its own outputs, under the name `state-prod`. That is
why module names should be stable and unique within a resource group: deploying two different modules
under one name makes the second overwrite the record of the first.

A module can also come from somewhere other than a local path: a **registry** (`br:` followed by an
Azure Container Registry address) or a **template spec** (`ts:`). Both are how a platform team publishes
modules the way lesson 1 had it publish pipeline templates: versioned, referenced, and owned by
somebody. Neither was used here, because both live in a subscription.
