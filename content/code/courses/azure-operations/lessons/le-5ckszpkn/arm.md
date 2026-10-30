---
title: An ARM template, read from the top
version: 1
---

**An ARM template is a JSON document that describes resources and lets Resource Manager work out how
to create them.** You send it to a scope, a resource group here, and Resource Manager compares it with
what exists, creates or updates what differs, and leaves alone what the template does not mention
(in its default *incremental* mode). This is a template for the storage account the shop will keep
its Terraform state in, in lesson 6:

`storage.json`:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "accountName": {
      "type": "string",
      "minLength": 3,
      "maxLength": 24
    }
  },
  "variables": {
    "location": "brazilsouth"
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2023-05-01",
      "name": "[parameters('accountName')]",
      "location": "[variables('location')]",
      "sku": { "name": "Standard_LRS" },
      "kind": "StorageV2",
      "properties": {
        "minimumTlsVersion": "TLS1_2",
        "allowBlobPublicAccess": false
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "apiVersion": "2023-05-01",
      "name": "[format('{0}/default/tfstate', parameters('accountName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('accountName'))]"
      ]
    }
  ],
  "outputs": {
    "blobEndpoint": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Storage/storageAccounts', parameters('accountName'))).primaryEndpoints.blob]"
    }
  }
}
```

Five sections, of which three matter most. **`parameters`** are what the person deploying supplies,
with constraints that Resource Manager checks before creating anything: a name between 3 and 24
characters. **`resources`** is the list, each with a `type`, an `apiVersion` that fixes which version of
that type's schema the properties follow, and a `name`. **`outputs`** are values handed back after the
deployment, such as the endpoint a later step needs.

Then look at how anything is said. Every value that is not a constant is a **string containing an
expression in square brackets**: `"[parameters('accountName')]"`, `"[format('{0}/default/tfstate', …)]"`.
JSON has no expressions, so ARM put a language inside its strings, and a typo in it is a valid JSON
string that fails only when Resource Manager evaluates it. And the container names the account it
depends on **twice**: once in its own name and once in `dependsOn`, where you have to remember to write
it, because Resource Manager creates resources in parallel unless told otherwise.

Bicep can read this file and write it in its own language:

```
ana@laptop:~/azure/bicep$ bicep decompile storage.json
WARNING: Decompilation is a best-effort process, as there is no guaranteed mapping from ARM JSON to Bicep Template or Bicep Parameters.
You may need to fix warnings and errors in the generated bicep/bicepparam file(s), or decompilation may fail entirely if an accurate conversion is not possible.
If you would like to report any issues or inaccurate conversions, please see https://github.com/Azure/bicep/issues.
ana@laptop:~/azure/bicep$ cat storage.bicep
@minLength(3)
@maxLength(24)
param accountName string

var location = 'brazilsouth'

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource accountName_default_tfstate 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${accountName}/default/tfstate'
  dependsOn: [
    account
  ]
}

output blobEndpoint string = account.properties.primaryEndpoints.blob
```

The warning is honest: decompiling is best effort, and the result is a starting point to read rather
than a file to trust. Here it came out clean. The brackets are gone, the parameter's constraints became
decorators (`@minLength`), and `parameters('accountName')` became just `accountName`. The `dependsOn` came
along, and the container's name is still assembled from slashes; the next section writes the same thing
the way Bicep would rather have it.
