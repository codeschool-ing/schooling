---
title: Um template ARM, lido de cima
version: 1
---

**Um template ARM é um documento JSON que descreve recursos e deixa o Resource Manager descobrir como
criá-los.** Você o envia a um escopo, aqui um grupo de recursos, e o Resource Manager compara com o que existe,
cria ou atualiza o que difere e deixa em paz o que o template não menciona (no modo padrão, *incremental*).
Este é um template da conta de armazenamento onde a loja vai guardar o estado do Terraform, na lição 6:

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

Cinco seções, das quais três importam mais. **`parameters`** são o que quem implanta fornece, com restrições
que o Resource Manager confere antes de criar qualquer coisa: um nome entre 3 e 24 caracteres. **`resources`** é
a lista, cada um com um `type`, uma `apiVersion` que fixa qual versão do esquema daquele tipo as propriedades
seguem, e um `name`. **`outputs`** são valores devolvidos depois do deploy, como o endpoint de que um passo
seguinte precisa.

Agora repare em como tudo é dito. Todo valor que não é constante é uma **string com uma expressão entre
colchetes**: `"[parameters('accountName')]"`, `"[format('{0}/default/tfstate', …)]"`. O JSON não tem
expressões, então o ARM pôs uma linguagem dentro das strings, e um erro de digitação nela é uma string JSON
válida que só falha quando o Resource Manager a avalia. E o contêiner nomeia a conta de que depende **duas
vezes**: uma no próprio nome e outra em `dependsOn`, onde você precisa lembrar de escrever, porque o Resource
Manager cria recursos em paralelo a menos que alguém diga o contrário.

O Bicep consegue ler este arquivo e escrevê-lo na própria linguagem:

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

O aviso é honesto: descompilar é um esforço sem garantia, e o resultado é um ponto de partida para ler, e não
um arquivo para confiar. Aqui saiu limpo. Os colchetes sumiram, as restrições do parâmetro viraram decoradores
(`@minLength`), e `parameters('accountName')` virou só `accountName`. O `dependsOn` veio junto, e o nome do
contêiner continua montado com barras; a próxima seção escreve a mesma coisa do jeito que o Bicep prefere.
