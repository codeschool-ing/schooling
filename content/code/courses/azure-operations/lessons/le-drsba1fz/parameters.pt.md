---
title: Arquivos de parâmetros, e a senha que não está neles
version: 1
---

**Um arquivo `.bicepparam` guarda os valores de um deploy de um template**, e nomeia o template a que pertence com
`using`. A loja mantém um por ambiente ao lado do `main.bicep`:

```bicep
// main.prod.bicepparam
using 'main.bicep'

param environment = 'prod'
```

Como ele nomeia o template, o compilador o confere com aquele template, e essa é a melhoria sobre os arquivos de
parâmetros JSON mais antigos, em que um parâmetro escrito errado era simplesmente ignorado. Compilar escreve
aquele formato antigo, que é o que o Resource Manager recebe:

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

Um valor errado e um parâmetro não declarado, em `main.wrong.bicepparam`:

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

Os dois são **erros**, o código de saída é 1, e nenhum arquivo foi escrito: `production` não é um dos valores que
o `@allowed` deixa passar, e `region` não é um parâmetro que o template tenha. Compare com a lição 4, em que uma
propriedade escrita errado era um aviso com código de saída 0. Arquivos de parâmetros são onde esse rigor mais
compensa, porque são o que muda de um ambiente para o outro.

## Um segredo é um parâmetro que não fica escrito

A senha de um banco é um parâmetro como outro qualquer, e nunca pode estar no arquivo. O Bicep a marca como
**`@secure()`**, o que a mantém fora do histórico de deploys e fora dos logs, e o arquivo de parâmetros a lê do
ambiente na hora do build:

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

Sem a variável, o build para e diz qual variável queria. Com ela, o valor vai para `db.parameters.json` **em
texto puro**, e é isso que importa lembrar: o `@secure()` protege o valor dentro do Azure, não no seu disco. Então
um arquivo de parâmetros gerado nunca entra num commit, e numa esteira a variável vem do cofre de segredos da
esteira, ou melhor, do Key Vault, que é o assunto da lição 17. A senha aqui, `not-a-real-one`, é exatamente isso.
