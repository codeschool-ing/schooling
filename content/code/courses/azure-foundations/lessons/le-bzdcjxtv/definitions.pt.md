---
title: Uma definição de política é uma condição e um efeito
version: 1
---

**O Azure Policy não é sobre quem pode fazer alguma coisa. É sobre o que pode existir.** A imagem
errada o mistura com permissões: se a bia pode criar máquinas virtuais, uma política seria uma
permissão mais fina. Não é. O controle de acesso baseado em papéis da lição 9 responde *esta
identidade pode fazer este pedido*, e o Azure Policy responde *o recurso que este pedido descreve
pode existir aqui, com este formato*, seja quem for que peça. A bia pode ser Owner da assinatura
inteira e mesmo assim ter recusada uma máquina no Texas, porque a regra é sobre o Texas e não sobre
ela.

Uma política vem em duas peças:

- **uma definição**: uma condição sobre as propriedades de um recurso e um **efeito**, o que acontece
  quando a condição é verdadeira. "Se a localização não for uma destas, recuse";
- **uma atribuição**: essa definição aplicada num escopo, uma das caixas da lição 2, com valores para
  os seus parâmetros. "Recuse qualquer coisa fora do Brasil, debaixo de `mg-shop`".

A definição diz qual é a regra; a atribuição diz onde ela vale. Uma definição pode ser atribuída
muitas vezes, em escopos diferentes, com valores diferentes.

## Lendo uma definição nativa

A Microsoft entrega um catálogo grande de definições prontas para atribuir, as **nativas**
(*built-in*), e as publica num repositório público do GitHub, `Azure/azure-policy`. A que mantém os
recursos dentro de uma lista de regiões se chama *Allowed locations*. Crie o diretório da lição e
busque-a:

```sh
mkdir -p ~/azure/policy && cd ~/azure/policy
curl -sS -o allowed-locations.json https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/General/AllowedLocations_Deny.json
```

```
ana@laptop:~/azure/policy$ jq '{name, displayName: .properties.displayName, mode: .properties.mode, version: .properties.version, effects: .properties.parameters.effect.allowedValues}' allowed-locations.json
{
  "name": "e56962a6-4747-49cd-b67b-bf8b01975c4c",
  "displayName": "Allowed locations",
  "mode": "Indexed",
  "version": "1.1.0",
  "effects": [
    "Audit",
    "Deny",
    "Disabled"
  ]
}
```

**`name` é um GUID, e é o mesmo em todo tenant do Azure**: o id de uma definição nativa é
`/providers/Microsoft.Authorization/policyDefinitions/` seguido desse GUID, sem assinatura nenhuma, o
mesmo formato que a lição 2 encontrou para um grupo de gerenciamento. `version` é a versão da própria
definição, já que a Microsoft revisa as nativas. O `effect` é um **parâmetro**, escolhido na
atribuição, entre três valores, então a mesma regra pode recusar ou só reportar. Agora a regra em si:

```
ana@laptop:~/azure/policy$ jq '.properties.policyRule' allowed-locations.json
{
  "if": {
    "allOf": [
      {
        "field": "location",
        "notIn": "[parameters('listOfAllowedLocations')]"
      },
      {
        "field": "location",
        "notEquals": "global"
      },
      {
        "field": "type",
        "notEquals": "Microsoft.AzureActiveDirectory/b2cDirectories"
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

O `if` é uma condição sobre **campos** do recurso que está sendo criado ou mudado. `allOf` quer dizer
que todos os itens precisam valer: a localização não está na lista, a localização não é `global`, e o
recurso não é um diretório B2C do Entra. `[parameters('listOfAllowedLocations')]` é uma expressão,
preenchida a partir da atribuição. O `then` cita o efeito. Essa é a gramática inteira, tirando os
operadores: `field`, uma comparação (`equals`, `notIn`, `like`, `exists`, `contains`...), e `allOf`,
`anyOf` e `not` para combiná-las.

## O que o modo deixa de fora

**`"mode": "Indexed"` quer dizer que a definição olha só para tipos de recurso que têm tags e
localização**, e um grupo de recursos não é um deles. É por isso que a descrição de *Allowed
locations* diz que ela exclui grupos de recursos, e por isso a Microsoft entrega uma segunda definição
para eles:

```
ana@laptop:~/azure/policy$ curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/General/ResourceGroupAllowedLocations_Deny.json | jq -c '[.name, .properties.displayName, .properties.mode]'
["e765b5de-1225-4ba3-bd56-1ac6695af988","Allowed locations for resource groups","All"]
```

O modo `All` avalia tudo, grupos de recursos e assinaturas incluídos. Uma definição sobre a região dos
recursos quer `Indexed`, para que tipos sem localização não a disparem; uma definição sobre grupos de
recursos precisa ser `All`, senão nunca os vê. Errar o modo produz uma política que está atribuída,
reporta, e em silêncio não governa nada.

## A mesma definição, perguntada ao Azure

O Resource Manager guarda as mesmas nativas, e a CLI pode mostrar uma:

```
ana@laptop:~/azure/policy$ az policy definition show --name e56962a6-4747-49cd-b67b-bf8b01975c4c
ERROR: Please run 'az login' to setup account.
```

Essa precisa de login, como toda pergunta ao Resource Manager neste laboratório. A cópia do GitHub é a
que você consegue ler aqui, e **é a cópia que a Microsoft mantém às claras**, então o histórico de uma
definição, cada mudança na regra dela, está no log do repositório.
