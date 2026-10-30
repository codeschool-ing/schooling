---
title: What Bicep fixes, and what it still compiles to
version: 1
---

This is the same storage account and container, written in Bicep from the start:

```bicep
// shop.bicep
param accountName string
param location string = resourceGroup().location

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: account
  name: 'default'
}

resource state 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobs
  name: 'tfstate'
}

output blobEndpoint string = account.properties.primaryEndpoints.blob
```

Three things changed, and each removes a kind of mistake.

- **A resource has a symbolic name**, `account`, `blobs`, `state`, that the rest of the file uses to
  refer to it. `account.properties.primaryEndpoints.blob` is a property access the compiler can check,
  where ARM's version was a `reference(resourceId(...))` call inside a string.
- **`parent: account` says what the container belongs to**, and the name is just `'tfstate'`. Bicep
  builds the full name, with its slashes, itself.
- **There is no `dependsOn`.** Every symbolic reference is a dependency, so Bicep works the order out
  from what the file already says.

Compiling it writes the JSON beside it, and the JSON is where those claims can be checked:

```
ana@laptop:~/azure/bicep$ bicep build shop.bicep
ana@laptop:~/azure/bicep$ ls
shop.bicep
shop.json
storage.bicep
storage.json
ana@laptop:~/azure/bicep$ wc -l shop.bicep shop.json storage.json
  26 shop.bicep
  57 shop.json
  42 storage.json
 125 total
ana@laptop:~/azure/bicep$ jq '.resources[] | {type, name, dependsOn}' shop.json
{
  "type": "Microsoft.Storage/storageAccounts",
  "name": "[parameters('accountName')]",
  "dependsOn": null
}
{
  "type": "Microsoft.Storage/storageAccounts/blobServices",
  "name": "[format('{0}/{1}', parameters('accountName'), 'default')]",
  "dependsOn": [
    "[resourceId('Microsoft.Storage/storageAccounts', parameters('accountName'))]"
  ]
}
{
  "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
  "name": "[format('{0}/{1}/{2}', parameters('accountName'), 'default', 'tfstate')]",
  "dependsOn": [
    "[resourceId('Microsoft.Storage/storageAccounts/blobServices', parameters('accountName'), 'default')]"
  ]
}
ana@laptop:~/azure/bicep$ jq -r '.outputs.blobEndpoint.value' shop.json
[reference(resourceId('Microsoft.Storage/storageAccounts', parameters('accountName')), '2023-05-01').primaryEndpoints.blob]
```

`bicep build` prints nothing when it succeeds. The 26 lines of Bicep became 57 of JSON, and each
resource that refers to another has a `dependsOn` nobody wrote, pointing at exactly the resource its
`parent` named. The output is a `reference(...)` expression with an `apiVersion` filled in. **The JSON
is what Resource Manager receives, and it has no idea Bicep existed.** That is why Bicep needs no new
service and no new permission: a deployment from Bicep is an ARM deployment.

It is also why the next thing to say about Bicep is a limit. Bicep checks the file against the schema
of each resource type, as far as that schema is known. It cannot know whether the name is free, whether
your role allows the deployment, or whether a policy refuses the region, because only Resource Manager
knows those things, at deployment time.
