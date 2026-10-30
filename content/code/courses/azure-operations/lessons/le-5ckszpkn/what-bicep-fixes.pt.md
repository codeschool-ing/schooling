---
title: O que o Bicep conserta, e no que ele continua compilando
version: 1
---

Esta é a mesma conta de armazenamento com o contêiner, escrita em Bicep desde o começo:

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

Três coisas mudaram, e cada uma remove um tipo de erro.

- **Um recurso tem um nome simbólico**, `account`, `blobs`, `state`, que o resto do arquivo usa para se referir
  a ele. `account.properties.primaryEndpoints.blob` é um acesso a propriedade que o compilador consegue
  conferir, onde a versão do ARM era uma chamada `reference(resourceId(...))` dentro de uma string.
- **`parent: account` diz a quem o contêiner pertence**, e o nome é só `'tfstate'`. O Bicep monta o nome
  completo, com as barras, sozinho.
- **Não existe `dependsOn`.** Toda referência simbólica é uma dependência, então o Bicep descobre a ordem a
  partir do que o arquivo já diz.

Compilar escreve o JSON ao lado, e é no JSON que essas afirmações podem ser conferidas:

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

O `bicep build` não imprime nada quando dá certo. As 26 linhas de Bicep viraram 57 de JSON, e cada recurso que
se refere a outro tem um `dependsOn` que ninguém escreveu, apontando exatamente para o recurso que o `parent`
nomeou. A saída é uma expressão `reference(...)` com uma `apiVersion` preenchida. **O JSON é o que o Resource
Manager recebe, e ele não faz ideia de que o Bicep existiu.** Por isso o Bicep não precisa de serviço novo nem
de permissão nova: um deploy feito a partir de Bicep é um deploy ARM.

É também por isso que a próxima coisa a dizer sobre o Bicep é um limite. O Bicep confere o arquivo com o
esquema de cada tipo de recurso, até onde esse esquema é conhecido. Ele não tem como saber se o nome está
livre, se o seu papel permite o deploy ou se uma política recusa a região, porque só o Resource Manager sabe
essas coisas, na hora do deploy.
