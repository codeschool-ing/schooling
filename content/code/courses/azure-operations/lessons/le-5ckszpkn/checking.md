---
title: What the compiler catches, and the linter beside it
version: 1
---

Two deliberate mistakes, each in a copy of `shop.bicep`. In `typo.bicep` the SKU is `Standard_LRSS` and
the TLS version `TLS1_3`, which is not a value the storage API offers. In `typo2.bicep` the output reads
`primaryEndpoint`, without the final `s`:

```
ana@laptop:~/azure/bicep$ bicep build typo.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/bicep$ bicep build typo2.bicep; echo "exit status $?"
/home/ana/azure/bicep/typo2.bicep(26,49) : Warning BCP083: The type "StorageAccountPropertiesCreateParametersOrStorageAccountProperties" does not contain property "primaryEndpoint". Did you mean "primaryEndpoints"? [https://aka.ms/bicep/core-diagnostics#BCP083]
exit status 0
```

**The first compiled cleanly, and the second compiled with a warning.** Both are worth reading slowly.
The SKU and the TLS version are typed as strings in the schema Bicep has for this API version, so any
string passes, and Resource Manager is the one that will refuse them, at deployment, after the pipeline
has already gone green. The misspelt property is caught because the shape of a storage account's
properties is known, and Bicep even suggests the right name. But it is a **warning**, the exit status is
still 0, and a pipeline that only looks at the exit status ships it.

So two habits follow. In a pipeline, run Bicep so that warnings fail the step, and read every warning
the first time it appears rather than learning to scroll past them. And never take a clean compile as
evidence that a value is right; it is evidence that the file has the right shape.

## The linter

`bicep lint` runs the compiler's checks plus a set of rules about practice rather than syntax. This file
has two problems a compiler has no reason to mind:

```bicep
// lint.bicep
param accountName string
param environment string

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: 'brazilsouth'
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

output connection string = 'DefaultEndpointsProtocol=https;AccountName=${accountName};AccountKey=${account.listKeys().keys[0].value}'
```

```
ana@laptop:~/azure/bicep$ bicep lint lint.bicep; echo "exit status $?"
/home/ana/azure/bicep/lint.bicep(3,7) : Warning no-unused-params: Parameter "environment" is declared but never used. [https://aka.ms/bicep/linter-diagnostics#no-unused-params]
/home/ana/azure/bicep/lint.bicep(15,100) : Warning outputs-should-not-contain-secrets: Outputs should not contain secrets. Found possible secret: function 'listKeys' [https://aka.ms/bicep/linter-diagnostics#outputs-should-not-contain-secrets]
exit status 0
```

`no-unused-params` caught a parameter nobody reads, which in a template means somebody will one day
supply a value and wonder why nothing changed. **`outputs-should-not-contain-secrets` caught the serious
one**: the output builds a connection string with the account key in it, and a deployment's outputs are
stored in the deployment history, readable by anyone with read access to the resource group. Rules are
switched on, off or up to errors in a `bicepconfig.json` beside the files, and the shop raises that
second rule to an error so that it fails the build.

Notice that the location written as a literal, `'brazilsouth'`, raised nothing. The rule for that,
`no-hardcoded-location`, exists and is off unless `bicepconfig.json` turns it on. A linter is only the
rules it was told to run.
