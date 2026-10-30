---
title: Módulos, e no que um módulo compila
version: 1
---

**Um módulo é um arquivo Bicep chamado por outro arquivo Bicep**, com parâmetros entrando e saídas saindo. O
armazenamento da loja para o estado do Terraform, da lição 4, vira um, em `modules/`, agora com versionamento e
trinta dias de exclusão reversível nos blobs, coisa pela qual a lição 7 vai agradecer:

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

O `main.bicep` o chama, e decide o nome a partir do ambiente e de um sufixo:

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

Três coisas nele merecem uma frase cada. **`@allowed`** restringe `environment` a dois valores, e a próxima seção
o mostra recusando um terceiro. **`uniqueString(resourceGroup().id)`** é um hash determinístico: o mesmo grupo
de recursos dá sempre os mesmos 13 caracteres, então o nome é estável entre deploys e ainda assim dificilmente
colide com uma conta de armazenamento que outra pessoa no mundo já batizou. E o **`name`** do módulo,
`state-prod`, não é nome de recurso; é o nome de um deploy, que a próxima transcrição torna visível:

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

**Um módulo compila num deploy aninhado**: um recurso do tipo `Microsoft.Resources/deployments`, que leva o
template inteiro do módulo dentro de si, com três recursos. O Resource Manager o registra como um deploy próprio,
com histórico e saídas próprios, sob o nome `state-prod`. Por isso os nomes de módulo devem ser estáveis e únicos
dentro de um grupo de recursos: implantar dois módulos diferentes sob um nome faz o segundo sobrescrever o
registro do primeiro.

Um módulo também pode vir de outro lugar que não um caminho local: de um **registro** (`br:` seguido do endereço
de um Azure Container Registry) ou de um **template spec** (`ts:`). As duas são a forma de uma equipe de
plataforma publicar módulos como a lição 1 a fez publicar templates de esteira: versionados, referenciados e com
dono. Nenhuma foi usada aqui, porque as duas moram numa assinatura.
