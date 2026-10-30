---
title: O cofre, e quem pode lê-lo
version: 1
---

**O cofre da loja é declarado com tudo o que a lição 16 pediu, e dá um papel à aplicação.**

```bicep
// vault.bicep
param appPrincipalId string

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-shop-prod'
  location: 'brazilsouth'
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
  }
}

// Key Vault Secrets User: read secret values, nothing else
var secretsUser = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource appReads 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, appPrincipalId, secretsUser)
  scope: vault
  properties: {
    roleDefinitionId: secretsUser
    principalId: appPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output vaultUri string = vault.properties.vaultUri
```

```
ana@laptop:~/azure/vault$ bicep build vault.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/vault$ jq -r '.resources[] | .type' vault.json
Microsoft.KeyVault/vaults
Microsoft.Authorization/roleAssignments
```

Quatro configurações carregam as decisões. **`enableRbacAuthorization: true`** põe o acesso aos segredos sob o RBAC do Azure,
as mesmas atribuições de papel de todo o resto, em vez das *access policies* antigas do cofre, que são um segundo sistema de
permissões com uma lista própria que ninguém lembra de revisar. **Exclusão reversível por 90 dias** e **proteção contra
purga**, da seção anterior. E **`publicNetworkAccess: 'Disabled'`**: o cofre só responde num private endpoint, que a lição 20
monta.

A atribuição de papel dá à **identidade gerenciada** da aplicação o papel interno *Key Vault Secrets User*, identificado pelo
GUID fixo dele, no escopo deste cofre apenas. Esse papel lê valores de segredos e não faz mais nada: não lista chaves, não
escreve, não muda quem tem acesso. O `guid()` faz o nome da atribuição ser determinístico a partir do cofre, do principal e do
papel, então implantar duas vezes não cria duas atribuições. Identidades gerenciadas são a lição 8 de `azure-foundations`; o
ponto aqui é que **a aplicação não guarda credencial nenhuma para alcançar o cofre**: o Azure responde por ela.

## O segredo que não está no template

O Bicep consegue criar um segredo, e é por aí que cofres vazam. Este arquivo recebe a senha como parâmetro e a grava no
cofre:

```bicep
// leaky.bicep
param dbPassword string

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-shop-prod'
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'db-password'
  properties: {
    value: dbPassword
  }
}
```

```
ana@laptop:~/azure/vault$ bicep lint leaky.bicep; echo "exit status $?"
/home/ana/azure/vault/leaky.bicep(2,7) : Warning secure-secrets-in-params: Parameter 'dbPassword' may represent a secret (according to its name) and must be declared with the '@secure()' attribute. [https://aka.ms/bicep/linter-diagnostics#secure-secrets-in-params]
exit status 0
```

O linter percebeu o nome e pediu `@secure()`, e está certo, e continua sendo um aviso com código de saída 0. Mesmo com
`@secure()`, uma senha que passa por um template passou por uma esteira, um arquivo de parâmetros ou uma variável de ambiente
no caminho. **A loja nunca escreve valores de segredo em Bicep.** O template cria o cofre e o acesso; os valores são definidos
uma vez, por uma pessoa, com `az keyvault secret set`, ou gerados pelo serviço que é dono deles, como um banco que cria as
próprias credenciais. Esse comando não foi executado aqui: não há cofre.
