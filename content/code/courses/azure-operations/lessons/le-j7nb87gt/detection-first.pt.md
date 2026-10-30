---
title: Detecção primeiro, depois prevenção
version: 1
---

**Uma política de WAF nova começa no modo Detection, e fica nele até os logs dizerem que ela pode bloquear.** Em Detection, toda
regra é avaliada e toda correspondência é **registrada**, e nada é bloqueado. O motivo são os falsos positivos: uma regra
gerenciada escrita para pegar injeção de SQL também casa com um cliente procurando `O'Brien's 1/2 price`, e em Prevention esse
cliente recebe um 403 e vai embora.

Então o caminho da loja até Prevention são algumas semanas lendo o que Detection teria bloqueado. Os logs do WAF chegam ao
workspace por um diagnostic setting, o mecanismo da lição 8, numa tabela por produto, e a pergunta feita a eles é: **qual regra
casou com quais requisições legítimas?** Toda correspondência com um cliente real é um falso positivo a remover antes da troca.
Essa leitura não foi feita aqui, porque um log de WAF precisa de um WAF.

O remédio usual é uma **exclusão**: uma parte da requisição que um conjunto de regras ignora. A caixa de busca da loja manda
texto livre num argumento chamado `search`, que o conjunto padrão vivia casando, então a política regional o exclui:

```bicep
// appgw-waf.bicep
resource waf 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-05-01' = {
  name: 'waf-agw-shop'
  location: 'brazilsouth'
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: true
    }
    managedRules: {
      managedRuleSets: [
        { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1' }
      ]
      exclusions: [
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Equals'
          selector: 'search'
          exclusionManagedRuleSets: [
            { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1' }
          ]
        }
      ]
    }
  }
}
```

```
ana@laptop:~/azure/waf$ bicep build appgw-waf.bicep; echo "exit status $?"
exit status 0
```

Uma exclusão é um buraco cortado de propósito, e quanto mais estreito melhor: um nome de argumento, para um conjunto de regras,
em vez de desligar uma regra para o site inteiro. Ela também deve ficar escrita com o motivo, porque a próxima pessoa a ler a
política vai ver uma lacuna e estranhar.

Excluídos os falsos positivos, o modo muda para Prevention, que na política do Front Door da loja é um parâmetro. A troca é um
deploy como outro qualquer: pela esteira, com a aprovação da lição 3, e observada por um salto de 403 nos minutos seguintes, que é
a versão do canário para o WAF.
