---
title: Rotação: chaves giram sozinhas, segredos precisam de ajuda
version: 1
---

**Rotação troca uma chave ou um segredo por uma versão nova, num calendário, para um vazado parar de funcionar sozinho.** Todo
objeto num cofre tem versões: girar acrescenta uma versão e deixa as antigas legíveis até expirarem ou serem desativadas, e é
isso que deixa os consumidores migrarem sem buraco.

**Chaves conseguem girar sozinhas.** A **política de rotação** de uma chave diz quando, e o cofre faz o resto. A loja assina
recibos de pedido com uma chave de curva elíptica que gira todo ano:

```bicep
// signing-key.bicep
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-shop-prod'
}

resource receipts 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: vault
  name: 'receipt-signing'
  properties: {
    kty: 'EC'
    curveName: 'P-256'
    keyOps: [ 'sign', 'verify' ]
    rotationPolicy: {
      attributes: { expiryTime: 'P1Y' }
      lifetimeActions: [
        { trigger: { timeBeforeExpiry: 'P30D' }, action: { type: 'rotate' } }
        { trigger: { timeBeforeExpiry: 'P45D' }, action: { type: 'notify' } }
      ]
    }
  }
}
```

```
ana@laptop:~/azure/vault$ bicep build signing-key.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/vault$ jq '.resources[0].properties.rotationPolicy.lifetimeActions' signing-key.json
[
  {
    "trigger": {
      "timeBeforeExpiry": "P30D"
    },
    "action": {
      "type": "rotate"
    }
  },
  {
    "trigger": {
      "timeBeforeExpiry": "P45D"
    },
    "action": {
      "type": "notify"
    }
  }
]
```

A chave expira um ano depois de cada versão ser criada; trinta dias antes disso, o cofre cria uma versão nova, e quinze dias
antes ainda, uma ação *notify* levanta um evento, para quem verifica recibos buscar a chave pública nova. Nada que a loja roda
participa.

**Segredos não conseguem girar sozinhos**, porque o cofre não consegue mudar a senha do banco: só o banco consegue. Então a
rotação de segredos é um pedaço pequeno de automação que a loja escreve. O cofre publica um **evento de expiração próxima** no
Event Grid um tempo antes da data de expiração de um segredo; uma função o recebe, gera uma senha nova, a define **primeiro no
banco**, e depois a grava no cofre como versão nova. A ordem importa: gravada primeiro no cofre, a senha nova seria buscada
pelo app antes de o banco aceitá-la. Muitos serviços oferecem um caminho melhor: **uma identidade gerenciada também para o
banco**, com autenticação do Entra, que tira a senha de vez, e com ela a rotação. Onde isso é possível, é a resposta que a loja
prefere.

Nada desta rotação foi executado aqui; o Bicep foi compilado.
