---
title: Tags, e a política que as põe lá
version: 1
---

**Uma tag é um nome e um valor num recurso, e é a única coisa no Azure que diz de quem um recurso é.** O grupo de recursos diz onde
ele mora, a assinatura diz quem paga a assinatura, e nenhum dos dois diz qual equipe decidiu que ele deveria existir. A loja usa duas
tags em tudo: `team`, a equipe que responde por ele, e `env`, `prod` ou `dev`.

Tags só funcionam quando ninguém precisa lembrar delas. **Duas políticas as tornam automáticas**:

```bicep
// tag-policies.bicep
targetScope = 'subscription'

resource requireTeam 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'require-team-tag-on-groups'
  properties: {
    displayName: 'Resource groups must carry a team tag'
    policyType: 'Custom'
    mode: 'All'
    policyRule: {
      if: {
        allOf: [
          { field: 'type', equals: 'Microsoft.Resources/subscriptions/resourceGroups' }
          { field: 'tags[\'team\']', exists: 'false' }
        ]
      }
      then: { effect: 'deny' }
    }
  }
}

resource inheritTeam 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'inherit-team-tag'
  properties: {
    displayName: 'Resources inherit the team tag from their resource group'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          { field: 'tags[\'team\']', exists: 'false' }
          { value: '[resourceGroup().tags[\'team\']]', notEquals: '' }
        ]
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [ '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' ]
          operations: [
            { operation: 'add', field: 'tags[\'team\']', value: '[resourceGroup().tags[\'team\']]' }
          ]
        }
      }
    }
  }
}
```

```
ana@laptop:~/azure/tags$ bicep build tag-policies.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/tags$ jq -r '.resources[] | [.name, .properties.policyRule.then.effect] | @tsv' tag-policies.json
require-team-tag-on-groups	deny
inherit-team-tag	modify
```

A primeira **nega** criar um grupo de recursos sem tag `team`, então todo grupo já nasce com dono. A segunda **modifica**: um recurso
criado sem tag `team` ganha a do seu grupo, acrescentada pelo Azure Policy na criação. Uma política `modify` muda a requisição, então
precisa de uma identidade com um papel que possa escrever tags; o GUID em `roleDefinitionIds` é o papel interno *Contributor*, dado à
identidade gerenciada da atribuição. As duas compilaram; nenhuma foi atribuída, porque não há assinatura.

Juntas, elas tornam o caso comum de graça: uma equipe cria `rg-search` com `team: search`, e tudo dentro dele recebe a tag sem ninguém
pensar nisso. Recursos que existiam antes das políticas não são mudados pelo `modify` até uma **tarefa de correção** (remediation) rodar
sobre eles, um trabalho único depois da atribuição.

Três regras mantêm as tags úteis. **Poucas**: duas tags que todo mundo define valem mais que doze em que ninguém confia. **Valores
fixos**: `shop`, e não `Shop`, `shop-team` ou `a loja`, o que uma política com `allowedValues` consegue impor. E **nada de segredos**:
tags são legíveis por qualquer um com leitura no recurso, e aparecem na exportação de custos.
