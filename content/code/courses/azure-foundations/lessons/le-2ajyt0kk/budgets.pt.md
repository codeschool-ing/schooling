---
title: Um orçamento, e o que os seus dois alertas querem dizer
version: 1
---

**Um orçamento no Azure é um valor e um conjunto de limites; o Cost Management compara a fatura com
eles e avisa alguém quando um limite é ultrapassado.** A imagem comum é a de um limite de gastos, um
teto que o Azure não deixa a assinatura atravessar. Não é isso. A própria documentação da Microsoft o
diz numa linha: quando um limite é atingido, *os recursos não são afetados, e o consumo não é
interrompido*. Um orçamento que chega a 100% manda um e-mail, e cada máquina por trás dele continua
ligada e continua cobrando. A lição 1 pôs o orçamento em segundo lugar na primeira hora de uma conta
de verdade, antes de qualquer coisa que custe dinheiro, exatamente por isso: um aviso só serve
enquanto o valor ainda é pequeno.

## O orçamento que a lição 1 prometeu

Um orçamento é um recurso como outro qualquer, do tipo `Microsoft.Consumption/budgets`, e pode ser
escrito em Bicep e compilado no laboratório. Ele pertence a um escopo: uma assinatura, um grupo de
recursos, um grupo de gerenciamento ou uma conta de cobrança. O primeiro da loja vigia a assinatura
`shop-prod` inteira, então o arquivo mira numa assinatura. Crie o diretório da lição:

```sh
mkdir -p ~/azure/cost && cd ~/azure/cost
```

e salve isto como `budget.bicep` nele:

```bicep
targetScope = 'subscription'

@description('The first day of the month the budget starts counting from.')
param startDate string = '2026-11-01'

resource monthly 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-shop-monthly'
  properties: {
    category: 'Cost'
    amount: 50
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [
          'billing@shop.example'
        ]
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [
          'billing@shop.example'
        ]
      }
    }
  }
}
```

Campo por campo:

| campo | o que diz |
|---|---|
| `category: 'Cost'` | o orçamento conta dinheiro, na moeda de cobrança da assinatura |
| `amount: 50` | cinquenta por mês, um número pequeno de propósito para uma assinatura onde se está aprendendo |
| `timeGrain: 'Monthly'` | a contagem volta a zero no dia primeiro de cada mês. `Quarterly` e `Annually` também existem, e dividem o valor igualmente pelos seus meses |
| `startDate` | o primeiro dia de um mês; um orçamento não pode começar no meio de um |
| `actual80` | **um alerta sobre o que já foi cobrado**: dispara quando o custo do mês passa de 80% de cinquenta, que é quarenta |
| `forecast100` | **um alerta sobre para onde o mês está indo**: dispara quando a previsão da Microsoft para o total do mês passa de cinquenta |
| `contactEmails` | uma caixa de correio compartilhada em vez de uma pessoa, pelo motivo que a lição 1 deu para a identidade que assina |

Os nomes `actual80` e `forecast100` são da própria loja; o Azure só pede que cada notificação tenha
um. Um orçamento leva pelo menos uma notificação e no máximo cinco, cada uma com o seu limite, que o
Azure aceita de 0,01% a 1000% do valor.

Compile e leia de volta o que o Resource Manager receberia:

```
ana@laptop:~/azure/cost$ az bicep build --file budget.bicep --stdout | jq -c '."$schema", (.resources[0] | {type, apiVersion, alerts: [.properties.notifications | to_entries[] | {(.key): "\(.value.thresholdType) > \(.value.threshold)%"}]})'
"https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
{"type":"Microsoft.Consumption/budgets","apiVersion":"2024-08-01","alerts":[{"actual80":"Actual > 80%"},{"forecast100":"Forecasted > 100%"}]}
```

Um template mirado numa assinatura, um recurso do tipo orçamento, e os dois alertas nas palavras em
que o Azure os guarda.

## Dois alertas, duas perguntas

Os dois limites respondem perguntas diferentes, e um orçamento com só um deles responde metade.

**O alerta real diz que o dinheiro foi gasto.** Em 80% do valor do mês, quarenta dos cinquenta já se
foram. Ele não pode estar errado e não pode chegar cedo: quando dispara, os quarenta já estão na
fatura. É o alerta a manter quando alguém pede uma prova.

**O alerta de previsão diz que o dinheiro vai ser gasto.** O Cost Management projeta o total do mês a
partir do custo até ali, e o alerta dispara quando essa projeção passa de cinquenta. No terceiro dia
de um mês, uma máquina esquecida que custa dois por dia projeta uns sessenta, e a previsão diz isso
enquanto só seis foram cobrados. **É o alerta que chega a tempo de fazer alguma coisa.** Ele também
pode errar, nos dois sentidos: uma cobrança avulsa no começo do mês infla a projeção, e um custo que
só começa no dia vinte fica invisível para ela até lá.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-two-alerts\" aria-label=\"Um mês inventado para um orçamento de 50: uma máquina esquecida soma 2 por dia desde o dia primeiro. O custo real sobe em linha reta e cruza 40, o limite de 80%, no dia 20, quando o alerta real dispara. A previsão do mês, desenhada tracejada, fica em cerca de 60 desde o início, acima do orçamento de 50, então o alerta de previsão dispara no dia 3, dezessete dias antes.\"><path d=\"M80.0 270.0 L660.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 270.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"70.0\" y=\"204.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"70.0\" y=\"138.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"70.0\" y=\"105.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><text x=\"70.0\" y=\"72.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><text x=\"80.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"260.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"460.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"660.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><text x=\"370.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia do mês</text><path d=\"M80.0 105.7 L660.0 105.7\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"660.0\" y=\"95.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">orçamento: 50</text><path d=\"M80.0 138.6 L660.0 138.6\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"660.0\" y=\"150.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80% do orçamento</text><path d=\"M80.0 263.4 L660.0 72.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M120.0 72.9 L660.0 72.9\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"300.0\" y=\"60.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">previsão do mês</text><circle cx=\"120.0\" cy=\"72.9\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"130.0\" y=\"90.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alerta de previsão, dia 3</text><circle cx=\"460.0\" cy=\"138.6\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"470.0\" y=\"160.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">alerta real, dia 20</text><text x=\"320.0\" y=\"237.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">custo real</text></svg>", "caption": "Um mês inventado: o alerta de previsão chega dezessete dias antes do real."}
```

É por isso que a loja mantém os dois, com a previsão em 100% e o real abaixo dela: um diz *este mês
vai passar*, o outro *este mês já foi quase todo*.

## Com que atraso chega um alerta

**Um orçamento não vigia em tempo real, e o atraso faz parte do desenho.** A documentação da Microsoft
dá a cadeia. Os dados de custo e uso chegam ao Cost Management entre 8 e 24 horas depois de
acontecerem. Os orçamentos são avaliados contra eles uma vez a cada 24 horas, e o e-mail sai até uma
hora depois da avaliação:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l13-delay\" aria-label=\"A cadeia entre um custo e o e-mail sobre ele, segundo a documentação da Microsoft: o custo acontece; os dados chegam ao Cost Management de 8 a 24 horas depois; os orçamentos são avaliados uma vez a cada 24 horas; o e-mail sai até uma hora depois da avaliação.\"><defs><marker id=\"l13-delay-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um custo</text><text x=\"90.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">acontece</text><path d=\"M163.0 78.0 L197.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-delay-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 a 24 horas</text><rect x=\"200.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os dados chegam</text><text x=\"270.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ao Cost Management</text><path d=\"M343.0 78.0 L377.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-delay-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">até 24 horas</text><rect x=\"380.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o orçamento</text><text x=\"450.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">é avaliado</text><path d=\"M523.0 78.0 L557.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-delay-af-ah-paper-dim)\"></path><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">até uma hora</text><rect x=\"560.0\" y=\"50.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o e-mail</text><text x=\"630.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">é enviado</text></svg>", "caption": "Mais de um dia pode passar entre o custo e o alerta sobre ele."}
```

Então o alerta de um custo da manhã de segunda-feira pode chegar na noite de terça. **Um recurso
descontrolado tem mais de um dia de vantagem sobre qualquer orçamento**, e esse é o argumento para
manter o valor pequeno e o alerta de previsão ligado: o limite mais cedo é a única coisa que recupera
um pouco desse dia.

Mais dois atrasos pegam as pessoas de surpresa. Uma assinatura recém-criada pode levar até 48 horas
para o Cost Management, orçamentos incluídos, funcionar nela. E um orçamento compara com o custo como
foi cobrado, não distribuído: uma reserva paga de uma vez cai no orçamento no dia da compra, que é o
assunto da lição 14.
