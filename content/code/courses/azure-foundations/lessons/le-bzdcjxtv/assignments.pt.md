---
title: Atribuições, e como uma regra desce pela árvore
version: 1
---

**Uma atribuição vale no seu escopo e em todo escopo abaixo dele.** Atribuída a `mg-shop`, a *Allowed
locations* governa toda assinatura debaixo de `mg-shop`, todo grupo de recursos dessas assinaturas e
todo recurso desses grupos, inclusive os criados no ano que vem numa assinatura em que ninguém pensou
ainda. É por isso que os grupos de gerenciamento da lição 2 existem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l04-inheritance\" aria-label=\"Uma atribuição de Allowed locations em mg-shop alcança tudo abaixo dela: os grupos de gerenciamento mg-shop-prod e mg-shop-nonprod, as assinaturas shop-prod e shop-staging, e os grupos de recursos delas. Uma segunda atribuição em shop-staging acrescenta uma regra própria, e as duas valem ali. Uma isenção dispensa um grupo de recursos, rg-shop-lab, só da primeira atribuição, até uma data.\"><rect x=\"270.0\" y=\"20.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop</text><rect x=\"470.0\" y=\"18.0\" width=\"230.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">atribuição: Allowed locations</text><path d=\"M452.0 37.0 L468.0 37.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 54.0 L360.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200.0 72.0 L520.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200.0 72.0 L200.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"120.0\" y=\"86.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mg-shop-prod</text><path d=\"M200.0 116.0 L200.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"110.0\" y=\"134.0\" width=\"180.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><path d=\"M520.0 72.0 L520.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"440.0\" y=\"86.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mg-shop-nonprod</text><path d=\"M520.0 116.0 L520.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"430.0\" y=\"134.0\" width=\"180.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-staging</text><text x=\"140.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma regra vale</text><path d=\"M200.0 166.0 L200.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"120.0\" y=\"222.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"200.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><rect x=\"620.0\" y=\"136.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"666.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2ª regra</text><path d=\"M611.0 150.0 L619.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 166.0 L470.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M570.0 166.0 L570.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"395.0\" y=\"222.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"470.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-staging</text><rect x=\"555.0\" y=\"222.0\" width=\"140.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"625.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-lab</text><text x=\"470.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as duas regras valem</text><text x=\"625.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">isento da primeira,</text><text x=\"625.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">até uma data</text></svg>", "caption": "Uma atribuição vale no seu escopo e em tudo abaixo dele; só uma isenção, por escrito, dispensa."}
```

Três regras decidem a que um recurso está sujeito, e nenhuma delas é "vale a atribuição mais
próxima":

- **toda atribuição acima de um recurso se aplica a ele, de forma independente.** Nada abaixo pode
  desligar uma regra atribuída acima. O dono de uma assinatura que discorda da política de `mg-shop`
  pode vê-la e não pode removê-la, e a ideia é essa;
- **o resultado é o mais restritivo, somado.** A documentação da Microsoft trabalha um exemplo: uma
  assinatura que recusa tudo fora de `westus` e um grupo dentro dela que recusa tudo fora de `eastus`
  juntos recusam tudo, nesse grupo;
- **a saída é escrita na atribuição**, não feita abaixo dela. Uma atribuição pode listar
  **`notScopes`**, escopos que ela pula; e uma **isenção** separada pode dispensar um recurso ou um
  escopo de uma atribuição, com uma categoria, *waiver* ou *mitigated*, e uma data em que expira.

## As duas regras da loja, em Bicep

A loja quer duas coisas debaixo de `mg-shop`: os recursos no Brasil, e todo grupo de recursos marcado
com o ambiente a que pertence. A primeira é a definição nativa da seção anterior; a segunda não tem
nativa que diga exatamente isso, então a loja escreve a sua, uma definição **personalizada**. Salve
isto como `policy.bicep` em `~/azure/policy`:

```bicep
targetScope = 'managementGroup'

@description('The regions the shop may put resources in.')
param allowedLocations array = [
  'brazilsouth'
  'brazilsoutheast'
]

var allowedLocationsDefinition = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'

resource environmentTag 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: 'shop-environment-tag'
  properties: {
    displayName: 'Resource groups must say their environment'
    policyType: 'Custom'
    mode: 'All'
    parameters: {
      effect: {
        type: 'String'
        defaultValue: 'Deny'
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            field: 'tags[environment]'
            notIn: [
              'prod'
              'staging'
              'shared'
            ]
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

resource locations 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: 'shop-locations'
  properties: {
    displayName: 'Shop resources stay in Brazil'
    policyDefinitionId: allowedLocationsDefinition
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

resource environment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: 'shop-environment-tag'
  properties: {
    displayName: 'Resource groups must say their environment'
    policyDefinitionId: environmentTag.id
    enforcementMode: 'DoNotEnforce'
  }
}
```

Três recursos: a definição personalizada, guardada no grupo de gerenciamento para que tudo abaixo
possa usá-la, e duas atribuições. A primeira atribui a nativa pelo id fixo, com as duas regiões
brasileiras como parâmetro. A segunda atribui a personalizada com **`enforcementMode:
'DoNotEnforce'`**: a política é avaliada e os recursos aparecem como conformes ou não, mas nada é
recusado. É assim que uma regra nova deve começar, para que o relatório mostre o que ela quebraria
antes de quebrar qualquer coisa.

```
ana@laptop:~/azure/policy$ az bicep build --file policy.bicep --stdout | jq -c '."$schema", [.resources[] | [.type, .name]]'
"https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#"
[["Microsoft.Authorization/policyDefinitions","shop-environment-tag"],["Microsoft.Authorization/policyAssignments","shop-locations"],["Microsoft.Authorization/policyAssignments","shop-environment-tag"]]
```

Um `managementGroupDeploymentTemplate`, mirado onde o `targetScope` disse. Dois detalhes do template
compilado mostram a linha entre o que o Bicep resolve e o que ele deixa para o Azure:

```
ana@laptop:~/azure/policy$ az bicep build --file policy.bicep --stdout | jq -c '.resources[0].properties.policyRule.then, .resources[2].properties.policyDefinitionId'
{"effect":"[[parameters('effect')]"}
"[extensionResourceId(managementGroup().id, 'Microsoft.Authorization/policyDefinitions', 'shop-environment-tag')]"
```

**O efeito saiu como `[[parameters('effect')]`, com dois colchetes.** Um texto que começa com `[` é
uma expressão para o Resource Manager, que tentaria avaliar `parameters('effect')` ao implantar o
template e falharia, já que o template não tem esse parâmetro. O colchete dobrado diz ao Resource
Manager que guarde o texto como está, com um colchete a menos, e **o Azure Policy o avalia depois,
toda vez que a regra roda**. Dois avaliadores leem esse texto, em dois momentos diferentes, e o Bicep
o escapou para o primeiro para que o segundo o receba. E a atribuição aponta para a definição com
`extensionResourceId(managementGroup().id, ...)`: o id da definição depende do grupo de gerenciamento
em que o template for implantado, que só o Resource Manager sabe.

Implantá-lo seria `az deployment mg create --management-group-id mg-shop --location brazilsouth
--template-file policy.bicep`. **Não foi executado.** O Bicep conferiu o formato; não conferiu o que só
o Azure confere, como que **uma atribuição de política num grupo de gerenciamento pode ter um nome de
no máximo 24 caracteres**, um limite que `shop-environment-tag` respeita com quatro de folga.
