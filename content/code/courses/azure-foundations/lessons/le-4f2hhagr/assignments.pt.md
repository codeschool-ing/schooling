---
title: Atribuições, escopo e herança
version: 1
---

**Uma atribuição de papel junta três coisas: quem, qual papel, e onde.** O quem é uma entidade de
segurança: um usuário, um grupo, um service principal ou uma identidade gerenciada, todos objetos do
tenant das lições 6 a 8. O qual é uma definição de papel. O onde é um escopo, uma das caixas da
lição 2: um grupo de gerenciamento, uma assinatura, um grupo de recursos ou um recurso só.

**Uma atribuição alcança para baixo, nunca para cima.** Reader no `rg-shop-prod` deixa uma pessoa
ver todo recurso daquele grupo e nada fora dele. Reader na assinatura deixa ver todo grupo dela.
Reader no `mg-shop` deixa ver toda assinatura do ramo da loja na árvore. É por isso que a árvore foi
desenhada em torno de como as coisas são governadas: uma atribuição num grupo de gerenciamento é
herdada por tudo o que está debaixo dele, hoje e no dia em que uma assinatura nova for acrescentada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-scope\" aria-label=\"Herança de uma atribuição de papel pelas caixas da lição 2. Reader é atribuído a um grupo na assinatura shop-prod. Ele alcança os grupos de recursos rg-shop-prod-app e rg-shop-prod-data e todo recurso dentro deles, mas não o grupo de gerenciamento mg-shop-prod acima da assinatura, nem a assinatura shop-staging ao lado.\"><defs><marker id=\"l09-scope-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"220.0\" y=\"20.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-prod</text><text x=\"440.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não alcançado</text><path d=\"M320.0 56.0 L320.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200.0\" y=\"84.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"320.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><text x=\"320.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Reader atribuído aqui</text><rect x=\"500.0\" y=\"84.0\" width=\"190.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><text x=\"595.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não alcançado</text><path d=\"M320.0 129.0 L320.0 150.0 L200.0 150.0 L200.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"110.0\" y=\"172.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"200.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rg-shop-prod-app</text><path d=\"M200.0 213.0 L200.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"120.0\" y=\"240.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vnet-shop-prod</text><path d=\"M320.0 129.0 L320.0 150.0 L440.0 150.0 L440.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"350.0\" y=\"172.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"440.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rg-shop-prod-data</text><path d=\"M440.0 213.0 L440.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"360.0\" y=\"240.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sql-shop-prod</text><text x=\"360.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma atribuição alcança para baixo, nunca para cima nem para o lado</text></svg>", "caption": "Reader na assinatura é Reader em tudo dentro dela, e em nada mais."}
```

## Três hábitos que tornam isto administrável

**Atribua a grupos, não a pessoas.** `bia` entra na equipe e é acrescentada ao grupo que tem Reader
em produção; no dia em que `bia` sai, o grupo perde um membro. As atribuições não mudam, e a pergunta
"quem pode ler produção?" vira "quem está naquele grupo?", que o Entra ID responde. Há também um
motivo duro: **uma assinatura guarda no máximo 5.000 atribuições de papel**, um limite que a
Microsoft diz que não vai aumentar, e uma empresa que atribui papéis pessoa por pessoa chega nele.

**Atribua no menor escopo que funciona.** Contributor na assinatura é a resposta que sempre funciona
e a que deixa todo erro do maior tamanho possível. Contributor num grupo de recursos, ou um papel
específico num recurso, é o que menor privilégio quer dizer na prática.

**Prefira um papel específico a um geral.** Network Contributor gerencia redes e nada mais; Storage
Blob Data Reader lê blobs e nada mais. Quando nenhum papel nativo for estreito o bastante, escreva o
seu.

## Um papel personalizado, em Bicep

Um papel personalizado é uma definição de papel que você escreve, com os mesmos campos dos nativos.
Os desenvolvedores de plantão da loja precisam reiniciar o web app às três da manhã, e nada mais,
então o papel permite ler o app, reiniciá-lo e ler as métricas dele. Salve isto como `role.bicep`:

```bicep
targetScope = 'subscription'

resource restarter 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'shop-app-restarter')
  properties: {
    roleName: 'Shop App Restarter'
    description: 'Reads the shop\'s web apps and restarts them; changes nothing else.'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.Web/sites/read'
          'Microsoft.Web/sites/restart/action'
          'Microsoft.Insights/metrics/read'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

output id string = restarter.id
```

O nome da própria definição de papel precisa ser um GUID, e `guid(...)` faz um: ele transforma os
argumentos num GUID, **o mesmo toda vez para os mesmos argumentos**. Implante o arquivo duas vezes e a
segunda implantação atualiza o papel em vez de criar outro. O `assignableScopes` mantém o papel nesta
assinatura; um tenant pode ter 5.000 papéis personalizados, e um atribuível em qualquer lugar é mais
uma coisa que todo mundo pode conceder.

## Uma atribuição, em Bicep

Depois a atribuição, mirada num grupo de recursos, o escopo padrão. Salve isto como `assign.bicep`:

```bicep
@description('The object id of the group whose members may read the resource group.')
param groupId string

var readerId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource readers 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, groupId, readerId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerId)
    principalId: groupId
    principalType: 'Group'
  }
}
```

Compile os dois e leia os nomes:

```
ana@laptop:~/azure/rbac$ az bicep build --file role.bicep --stdout | jq '{schema: ."$schema", name: .resources[0].name, scopes: .resources[0].properties.assignableScopes}'
{
  "schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
  "name": "[guid(subscription().id, 'shop-app-restarter')]",
  "scopes": [
    "[subscription().id]"
  ]
}
ana@laptop:~/azure/rbac$ az bicep build --file assign.bicep --stdout | jq '.resources[0] | {name, roleDefinitionId: .properties.roleDefinitionId}'
{
  "name": "[guid(resourceGroup().id, parameters('groupId'), variables('readerId'))]",
  "roleDefinitionId": "[subscriptionResourceId('Microsoft.Authorization/roleDefinitions', variables('readerId'))]"
}
```

**O nome da atribuição é montado com as três coisas que ela junta**: o escopo, a entidade e o papel.
Esse é o hábito que vale copiar. O nome de uma atribuição de papel também precisa ser um GUID, e o
Resource Manager recusa uma segunda atribuição do mesmo papel à mesma entidade no mesmo escopo; um
nome derivado dessas três coisas faz uma implantação repetida cair na atribuição existente em vez de
falhar. Um nome como `readers-of-rg-shop-prod` compila sem reclamação, porque o compilador não conhece
a regra, e **o Resource Manager o recusaria** quando a implantação chegasse. Essa recusa não foi
executada aqui.

O papel Reader é citado pelo id, com `subscriptionResourceId`, e não pelo nome de exibição. Nomes de
exibição podem mudar; o id é o mesmo em todo tenant, que é aquilo em que a tabela da primeira seção
desta lição se apoia.

Implantar qualquer um dos arquivos é `az deployment sub create` e `az deployment group create`, como a
lição 2 listou, e **nenhum dos dois foi executado**. Criar uma atribuição de papel precisa de
`Microsoft.Authorization/roleAssignments/write` no escopo, o que quer dizer Owner, User Access
Administrator ou Role Based Access Control Administrator ali: a mesma operação que o `can.py` negou ao
Contributor.
