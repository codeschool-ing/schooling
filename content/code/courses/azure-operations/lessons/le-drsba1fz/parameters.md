---
title: Parameter files, and the password that is not in them
version: 1
---

**A `.bicepparam` file holds the values for one deployment of one template**, and names the template it
belongs to with `using`. The shop keeps one per environment beside `main.bicep`:

```bicep
// main.prod.bicepparam
using 'main.bicep'

param environment = 'prod'
```

Because it names its template, the compiler checks it against that template, which is the improvement
over the older JSON parameter files, where a misspelt parameter was simply ignored. Building it writes
that older format, which is what Resource Manager receives:

```
ana@laptop:~/azure/infra$ bicep build-params main.prod.bicepparam --outfile main.prod.parameters.json
ana@laptop:~/azure/infra$ jq . main.prod.parameters.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "prod"
    }
  }
}
```

A wrong value and an undeclared parameter, in `main.wrong.bicepparam`:

```bicep
// main.wrong.bicepparam
using 'main.bicep'

param environment = 'production'
param region = 'brazilsouth'
```

```
ana@laptop:~/azure/infra$ bicep build-params main.wrong.bicepparam --outfile wrong.json; echo "exit status $?"
/home/ana/azure/infra/main.wrong.bicepparam(4,21) : Error BCP033: Expected a value of type "'dev' | 'prod'" but the provided value is of type "'production'". [https://aka.ms/bicep/core-diagnostics#BCP033]
/home/ana/azure/infra/main.wrong.bicepparam(5,1) : Error BCP259: The parameter "region" is assigned in the params file without being declared in the Bicep file. [https://aka.ms/bicep/core-diagnostics#BCP259]
exit status 1
ana@laptop:~/azure/infra$ ls
main.bicep
main.json
main.prod.bicepparam
main.prod.parameters.json
main.wrong.bicepparam
modules
```

Both are **errors**, the exit status is 1, and no file was written: `production` is not one of the
values `@allowed` lets through, and `region` is not a parameter the template has. Compare lesson 4, where
a misspelt property was a warning with an exit status of 0. Parameter files are the place this
strictness pays most, because they are what changes between one environment and the next.

## A secret is a parameter that is not written down

A database password is a parameter like any other, and it must never be in the file. Bicep marks it
**`@secure()`**, which keeps it out of the deployment history and out of logs, and the parameter file
reads it from the environment at build time:

```bicep
// modules/db.bicep
@secure()
param adminPassword string
param location string = 'brazilsouth'

resource sql 'Microsoft.Sql/servers@2023-08-01' = {
  name: 'sql-shop-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: 'shopadmin'
    administratorLoginPassword: adminPassword
  }
}
```

```bicep
// db.bicepparam
using 'modules/db.bicep'

param adminPassword = readEnvironmentVariable('SHOP_DB_PASSWORD')
```

```
ana@laptop:~/azure/infra$ bicep build-params db.bicepparam --outfile db.parameters.json; echo "exit status $?"
/home/ana/azure/infra/db.bicepparam(4,47) : Error BCP427: Environment variable "SHOP_DB_PASSWORD" does not exist and there's no default value set. [https://aka.ms/bicep/core-diagnostics#BCP427]
exit status 1
ana@laptop:~/azure/infra$ SHOP_DB_PASSWORD='not-a-real-one' bicep build-params db.bicepparam --outfile db.parameters.json
ana@laptop:~/azure/infra$ jq .parameters db.parameters.json
{
  "adminPassword": {
    "value": "not-a-real-one"
  }
}
```

Without the variable, the build stops and says which variable it wanted. With it, the value lands in
`db.parameters.json` **in plain text**, which is the part to remember: `@secure()` protects the value
inside Azure, not on your disk. So a generated parameters file is never committed, and in a pipeline the
variable comes from the pipeline's secret store, or better, from Key Vault, which lesson 17 is about.
The password here, `not-a-real-one`, is exactly that.
