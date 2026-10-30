---
title: A política da loja, na borda
version: 1
---

**A política do Front Door da loja tem dois conjuntos de regras gerenciados e duas regras próprias.**

```bicep
// frontdoor-waf.bicep
@allowed([ 'Detection', 'Prevention' ])
param mode string = 'Detection'

resource waf 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2024-02-01' = {
  name: 'wafshopprod'
  location: 'Global'
  sku: { name: 'Premium_AzureFrontDoor' }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: mode
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1', ruleSetAction: 'Block' }
        { ruleSetType: 'Microsoft_BotManagerRuleSet', ruleSetVersion: '1.1' }
      ]
    }
    customRules: {
      rules: [
        {
          name: 'checkoutRateLimit'
          priority: 10
          ruleType: 'RateLimitRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 30
          matchConditions: [
            { matchVariable: 'RequestUri', operator: 'Contains', matchValue: [ '/checkout' ] }
          ]
          action: 'Block'
        }
        {
          name: 'onlyBrazilForAdmin'
          priority: 20
          ruleType: 'MatchRule'
          matchConditions: [
            { matchVariable: 'RequestUri', operator: 'BeginsWith', matchValue: [ '/admin' ] }
            { matchVariable: 'RemoteAddr', operator: 'GeoMatch', negateCondition: true, matchValue: [ 'BR' ] }
          ]
          action: 'Block'
        }
      ]
    }
  }
}
```

```
ana@laptop:~/azure/waf$ bicep build frontdoor-waf.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/waf$ jq -r '.resources[0].properties.customRules.rules[] | [.priority, .name, .ruleType, .action] | @tsv' frontdoor-waf.json
10	checkoutRateLimit	RateLimitRule	Block
20	onlyBrazilForAdmin	MatchRule	Block
```

**`Microsoft_DefaultRuleSet` 2.1** é o conjunto principal da Microsoft, cobrindo as categorias do OWASP: injeção, cross-site
scripting, violações de protocolo, inclusão de arquivo local. As regras dele pontuam uma requisição, e uma requisição acima do
limite recebe a ação do conjunto, aqui `Block`. **`Microsoft_BotManagerRuleSet`** separa o tráfego em robôs bons, como
buscadores, robôs ruins conhecidos e desconhecidos, e age em cada classe.

As regras personalizadas são avaliadas antes das gerenciadas, por ordem de **prioridade**, a menor primeiro:

- **`checkoutRateLimit`**: mais de 30 requisições a `/checkout` num minuto vindas de um endereço de cliente não é um cliente; é
  alguém testando números de cartão roubados, e a regra o bloqueia pelo resto do minuto. O limite veio dos próprios dados da
  loja: a semana da lição 10 nunca mostra um cliente perto disso;
- **`onlyBrazilForAdmin`**: o caminho de administração, que só a equipe da loja usa, recusa requisições de fora do Brasil. Duas
  condições numa regra se combinam com *e*, e o `negateCondition` transforma a checagem de país em *não Brasil*.

Geografia é um controle fraco, e a loja sabe disso: um endereço pode estar em qualquer país que o dono alugue. A regra está ali
para cortar o barulho de scanners de fora, não para autenticar ninguém; o caminho de administração ainda exige login com segundo
fator, que é o que de fato o protege.
