---
title: Atribuída pelo sistema e atribuída pelo usuário
version: 1
---

**Uma identidade gerenciada é um service principal que o Azure cria para um recurso, guarda a
credencial dele e a renova sozinho.** A lição 7 subiu uma escada de um segredo até uma credencial
federada, e uma identidade gerenciada é o mesmo degrau do topo com o outro lado preenchido pelo
Azure: o programa rodando num recurso do Azure pede um token, e ninguém, o programa incluído, nunca vê
uma credencial. **Não há nada para guardar, nada para renovar e nada para vazar.**

Isso só funciona para código rodando **no Azure**, num recurso que tem suporte: uma máquina virtual,
um web app do App Service, uma function, um container app, um pod do AKS por meio do workload
identity. Para qualquer coisa fora do Azure, o pipeline da loja no GitHub entre elas, a resposta é a
federação da lição 7.

Há dois tipos, e a diferença é **de quem é o tempo de vida que a identidade segue**:

| | atribuída pelo sistema | atribuída pelo usuário |
|---|---|---|
| criada | junto com o recurso, ao ser ligada nele | sozinha, como um recurso do tipo `userAssignedIdentities` |
| pertence a | exatamente um recurso | ninguém: é ligada a quantos recursos você quiser |
| apagada | quando o recurso é apagado | quando você a apaga |
| papéis | dados depois que o recurso existe | podem ser dados antes de qualquer recurso usá-la |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l08-two-kinds\" aria-label=\"Dois tipos de identidade gerenciada comparados pelo tempo de vida. À esquerda, o web app app-shop-prod contém a sua identidade atribuída pelo sistema dentro da própria caixa: apagar o app apaga a identidade e os papéis dela. À direita, a identidade atribuída pelo usuário id-shop-app é uma caixa própria, ligada a dois web apps por linhas; apagar qualquer um dos apps deixa a identidade e os papéis dela no lugar.\"><text x=\"175.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">atribuída pelo sistema</text><rect x=\"40.0\" y=\"50.0\" width=\"270.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-shop-prod</text><rect x=\"75.0\" y=\"96.0\" width=\"200.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a identidade dele</text><text x=\"175.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e os papéis dela</text><text x=\"175.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">apague o app: os dois vão embora</text><text x=\"530.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">atribuída pelo usuário</text><rect x=\"430.0\" y=\"50.0\" width=\"200.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">id-shop-app</text><text x=\"530.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e os papéis dela</text><rect x=\"365.0\" y=\"150.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app-shop-prod</text><rect x=\"565.0\" y=\"150.0\" width=\"125.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"627.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app-shop-prod-2</text><path d=\"M470.0 111.0 L445.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M590.0 111.0 L615.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"530.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">apague um app: a identidade fica</text></svg>", "caption": "A pergunta é de quem é o tempo de vida que a identidade segue: o de um recurso, ou o seu próprio."}
```

**Uma identidade atribuída pelo sistema morre com o recurso, e as atribuições de papel dela também.**
Reconstrua o web app e o novo tem uma identidade nova sem papel nenhum, e a implantação que o recriou
precisa dar os papéis de novo. Isso é certo para um recurso com permissões só dele. Uma identidade
**atribuída pelo usuário** sobrevive aos recursos que a usam: a loja dá os papéis ao `id-shop-app` uma
vez, e toda nova cópia da aplicação, em toda zona e em toda versão, já começa com eles. É também o
único jeito de vários recursos serem um principal só, o que mantém curta uma lista de papéis.

## O web app da loja, com as duas

Crie o diretório da lição:

```sh
mkdir -p ~/azure/identity && cd ~/azure/identity
```

e salve isto como `app.bicep`:

```bicep
param location string = resourceGroup().location

resource appId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-shop-app'
  location: location
}

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-shop-prod'
  location: location
  sku: {
    name: 'B1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource web 'Microsoft.Web/sites@2024-04-01' = {
  name: 'app-shop-prod'
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${appId.id}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      appSettings: [
        {
          name: 'AZURE_CLIENT_ID'
          value: appId.properties.clientId
        }
      ]
    }
  }
}

resource assets 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stshopassetsprod'
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
}

resource canRead 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(assets.id, appId.id, 'blob-reader')
  scope: assets
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalId: appId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output systemPrincipalId string = web.identity.principalId
output userClientId string = appId.properties.clientId
```

Cinco recursos: a identidade atribuída pelo usuário, um plano onde o web app roda, o web app com
**as duas** identidades ligadas, uma storage account para as imagens da loja, e uma **atribuição de
papel** que deixa o `id-shop-app` ler blobs nessa conta. O GUID nela é o papel nativo *Storage Blob
Data Reader*, da lista de papéis nativos da Microsoft, e a lição 9 explica de onde esses ids vêm.
Compile e olhe as duas identidades e as saídas:

```
ana@laptop:~/azure/identity$ az bicep build --file app.bicep --stdout | jq '{identity: .resources[] | select(.type == "Microsoft.Web/sites") | .identity, outputs}'
{
  "identity": {
    "type": "SystemAssigned, UserAssigned",
    "userAssignedIdentities": {
      "[format('{0}', resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', 'id-shop-app'))]": {}
    }
  },
  "outputs": {
    "systemPrincipalId": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Web/sites', 'app-shop-prod'), '2024-04-01', 'full').identity.principalId]"
    },
    "userClientId": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', 'id-shop-app'), '2023-01-31').clientId]"
    }
  }
}
```

A identidade atribuída pelo usuário é ligada **pelo id de recurso dela**, como uma chave cujo valor é
vazio. As duas saídas são expressões `reference(...)`: um principal id é um GUID que o Entra ID gera
quando a identidade é criada, então o template só consegue dizer onde lê-lo depois. **Uma identidade
sem papel não alcança nada.** Ligar uma dá ao recurso um nome no diretório e permissão nenhuma; a
atribuição de papel é o que o deixa ler as imagens, e a próxima seção é como o código pede o token.
