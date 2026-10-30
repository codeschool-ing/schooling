---
title: Fechando o caminho público, e mantendo fechado
version: 1
---

**Um private endpoint acrescenta um caminho privado; ele não remove o público.** Isso pede mais uma propriedade no serviço,
`publicNetworkAccess: 'Disabled'`, que o cofre da lição 17 já definiu. Até ela estar definida, o banco é alcançável pelos dois
caminhos, e o private endpoint não protege nada que o firewall público já não protegesse.

Definir uma vez é fácil. Manter definido é o problema, porque a próxima pessoa que precisar de acesso do notebook vai religar,
com a intenção de desligar depois. **O Azure Policy faz a decisão durar**: uma política com efeito `deny` recusa, no Resource
Manager, qualquer requisição que crie ou mude um servidor SQL de modo que o acesso público seja outra coisa que não desligado:

```bicep
// no-public.bicep
targetScope = 'subscription'

resource denyPublicSql 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'deny-public-sql'
  properties: {
    displayName: 'SQL servers must not allow public network access'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          { field: 'type', equals: 'Microsoft.Sql/servers' }
          { field: 'Microsoft.Sql/servers/publicNetworkAccess', notEquals: 'Disabled' }
        ]
      }
      then: { effect: 'deny' }
    }
  }
}

resource assign 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'deny-public-sql'
  properties: {
    policyDefinitionId: denyPublicSql.id
    displayName: 'SQL servers must not allow public network access'
  }
}
```

```
ana@laptop:~/azure/private$ bicep build no-public.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/private$ jq -r '.resources[0].properties.policyRule.then.effect' no-public.json
deny
```

A política é definida e atribuída na assinatura, então cobre todo grupo de recursos, inclusive os criados no ano que vem. Ela
recusa o portal, a linha de comando, o Bicep e o Terraform igualmente, porque todos passam pelo Resource Manager, que é o ponto
da lição 4 sobre no que o Bicep compila. O Azure também traz políticas internas para a mesma regra em muitos serviços; uma
personalizada é escrita aqui porque mostra a forma, e a lição 24 escreve outra.

Uma política `deny` atribuída a uma assinatura com violações existentes não as muda: ela impede as novas. Os recursos existentes
aparecem como **não conformes**, que é a visão de postura da lição 16. A ordem que a loja segue é a segura: conserte os servidores
existentes primeiro, depois atribua a política, e a partir daí ninguém desfaz sem mudar a política, que é uma mudança revisada
num arquivo.
