---
title: Orçamentos e alertas, e o que eles não fazem
version: 1
---

Um orçamento é **um número para um período, com limiares que mandam uma mensagem quando o gasto os
cruza**. É só isso. A crença comum é que definir um orçamento de 400 dólares quer dizer que a conta não
consegue gastar 401. **Um alerta avisa; ele não para nada.** O gasto continua passando por todos os
limiares até que uma pessoa, ou algo que uma pessoa construiu, mude o que está rodando.

## Um orçamento, por escrito

Este é um orçamento para a aplicação estimada antes nesta aula, no formato que o AWS Budgets recebe: o
pedido da operação `CreateBudget`, como um arquivo JSON que a AWS CLI sabe ler. O limite é a estimativa,
298,64, arredondada para 400.

```schooling-example
{
  "language": "json",
  "file": "budget.json",
  "parts": [
    {
      "code": "{\n  \"AccountId\": \"111122223333\",\n  \"Budget\": {\n    \"BudgetName\": \"shop-monthly\",\n    \"BudgetLimit\": {\"Amount\": \"400\", \"Unit\": \"USD\"},\n    \"TimeUnit\": \"MONTHLY\",\n    \"BudgetType\": \"COST\"\n  },",
      "note": "O orçamento em si: um nome, um **limite** escrito como valor e unidade, um período e o que é medido. `COST` é dinheiro; um orçamento `USAGE` contaria horas ou gigabytes. O número da conta é o que a documentação da AWS usa nos exemplos."
    },
    {
      "code": "  \"NotificationsWithSubscribers\": [\n    {\"Notification\": {\"NotificationType\": \"ACTUAL\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 50, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]},",
      "note": "Uma notificação e quem a recebe. Ela dispara quando o gasto **real** passa de 50% do limite e manda um e-mail. Quem assina também pode ser um tópico SNS, que é como uma mensagem chega a um canal de chat ou a um programa."
    },
    {
      "code": "    {\"Notification\": {\"NotificationType\": \"ACTUAL\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 80, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]},\n    {\"Notification\": {\"NotificationType\": \"ACTUAL\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 100, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]},",
      "note": "O mesmo em 80% e em 100%. A mensagem de 100% chega depois que o limite já foi passado, e por isso não é a única."
    },
    {
      "code": "    {\"Notification\": {\"NotificationType\": \"FORECASTED\", \"ComparisonOperator\": \"GREATER_THAN\",\n                      \"Threshold\": 100, \"ThresholdType\": \"PERCENTAGE\"},\n     \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"cloud-costs@example.com\"}]}",
      "note": "A **previsão**: o provedor projeta o mês a partir do gasto até agora e avisa quando a projeção passa do limite, o que pode acontecer semanas antes de o gasto real passar."
    },
    {
      "code": "  ]\n}"
    }
  ]
}
```

Ele **não foi criado em lugar nenhum**: este curso não tem conta. O que a CLI faz antes de procurar
credenciais é conferir o arquivo contra a definição da operação, e isso dá para rodar num laptop. A
primeira tentativa chegou até pedir credenciais, o que quer dizer que o arquivo passou; a segunda tem
uma letra a menos e não passa:

```
ana@laptop:~/cloud$ aws budgets create-budget --cli-input-json file://budget.json

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
ana@laptop:~/cloud$ sed s/BudgetLimit/BudgetLimt/ budget.json > typo.json
ana@laptop:~/cloud$ aws budgets create-budget --cli-input-json file://typo.json

aws: [ERROR]: An error occurred (ParamValidation): Parameter validation failed:
Unknown parameter in Budget: "BudgetLimt", must be one of: BudgetName, BudgetLimit, PlannedBudgetLimits, CostFilters, CostTypes, TimeUnit, TimePeriod, CalculatedSpend, BudgetType, LastUpdatedTime, AutoAdjustData, FilterExpression, Metrics, BillingViewArn, HealthStatus
```

## Por que os limiares começam na metade

Os dados de cobrança não são ao vivo. O uso é medido, coletado e precificado antes de chegar ao sistema
de cobrança, e **os números que um orçamento compara estão horas atrás do uso que descrevem**. Um alerta
em 100% do gasto real, portanto, chega depois que o dinheiro já foi gasto, e depois que o que estava
gastando rodou mais algumas horas.

É por isso que um orçamento útil tem limiares abaixo do limite. Em 50% e 80% a mensagem é novidade, e
cedo o bastante para agir. O alerta de previsão é o mais cedo de todos: o provedor projeta o mês a partir
do gasto até agora e avisa quando a projeção passa do limite. Um processo descontrolado no dia cinco pode
disparar a previsão bem antes de o gasto real chegar à metade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um mês inventado contra o orçamento de 400 USD. O gasto cresce cerca de 10 dólares por dia até o dia 12, quando um processo descontrolado faz ele crescer 25 por dia. Linhas tracejadas marcam 200, 320 e 400 dólares, os limiares de 50, 80 e 100 por cento. O alerta de previsão dispara no dia 13, o de 50 por cento no dia 15, o de 80 no dia 20 e o de 100 no dia 23. Uma previsão tracejada a partir do dia 24 termina o mês muito acima do limite.\"><defs><marker id=\"bdg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 192.6 L560 192.6\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"62\" y=\"192.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"568\" y=\"192.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70 146.1 L560 146.1\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"62\" y=\"146.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">320</text><text x=\"568\" y=\"146.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M70 115.2 L560 115.2\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"62\" y=\"115.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><text x=\"568\" y=\"115.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">100%</text><path d=\"M70.0 266.1 L86.9 262.3 L103.8 258.4 L120.7 254.5 L137.6 250.6 L154.5 246.8 L171.4 242.9 L188.3 239.0 L205.2 235.2 L222.1 231.3 L239.0 227.4 L255.9 223.5 L272.8 213.9 L289.7 204.2 L306.6 194.5 L323.4 184.8 L340.3 175.2 L357.2 165.5 L374.1 155.8 L391.0 146.1 L407.9 136.5 L424.8 126.8 L441.7 117.1 L458.6 107.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M458.6 107.4 L560.0 49.4\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"488.4\" y=\"53.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">previsão</text><circle cx=\"281.2\" cy=\"209.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"309.9\" cy=\"192.6\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"391.0\" cy=\"146.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"445.1\" cy=\"115.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"289.2\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a previsão passa de 400</text><text x=\"301.9\" y=\"180.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50%</text><text x=\"383.0\" y=\"134.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">80%</text><text x=\"437.1\" y=\"103.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">100%</text><text x=\"255.9\" y=\"249.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um processo sai do controle</text><path d=\"M255.9 239.5 L255.9 227.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 270 L560 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 270 L70 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"10\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD gastos neste mês</text><text x=\"70.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"222.1\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"391.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"560.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"560\" y=\"306\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia do mês</text></svg>", "caption": "Um mês inventado, não uma conta. O alerta de previsão é o primeiro a disparar, no dia seguinte ao descontrole; o de 100% vem mais de uma semana depois. E cada mensagem chega horas depois do gasto que relata."}
```

Os provedores oferecem, sim, maneiras de agir além de avisar, e cada uma precisa ser construída de
propósito. O AWS Budgets pode executar ações, como aplicar uma política restritiva ou parar instâncias
escolhidas, quando um limiar é cruzado. A documentação do Google Cloud mostra como ligar as mensagens de
um orçamento a uma função que desliga a cobrança de um projeto. As duas agem sobre os mesmos dados
atrasados, e as duas podem parar algo que não devia parar, então nenhuma substitui uma pessoa lendo a
mensagem.

## Quando ele dispara

Uma mensagem de limiar é o começo de uma rotina curta, e vale escrevê-la antes que a primeira chegue:

1. Abra a visão de custos agrupada por serviço, depois por tag, no mês atual, e compare com a
   estimativa. A linha que mudou em geral salta aos olhos.
2. Descubra de quem é. As tags da próxima seção são o que faz disso uma consulta, e não uma
   investigação.
3. Decida se era esperado. Um lançamento, um cliente novo, uma migração: então aumente o orçamento e
   anote por quê. Um loop, um teste esquecido, um endereço que ninguém liberou: então pare hoje.
4. Mude alguma coisa para que não aconteça do mesmo jeito duas vezes: uma regra de retenção, uma tag, um
   padrão menor, um orçamento na conta que surpreendeu você.

Um orçamento que dispara todo mês e é ignorado todo mês é pior do que nenhum, porque ensina a todo mundo
que a mensagem dele não quer dizer nada. Quando o alerta de verdade chegar, vai ser lido do mesmo jeito.
