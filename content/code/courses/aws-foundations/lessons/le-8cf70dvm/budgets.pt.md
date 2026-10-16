---
title: Um orçamento, e o que os seus dois alertas querem dizer
version: 1
---

**Um orçamento (*budget*) é um número e um conjunto de limiares; ele vigia a fatura e avisa alguém
quando um limiar é ultrapassado.** A imagem comum é a de um teto de gastos, um limite que a AWS não
deixa a conta atravessar. Não é isso. Um orçamento que chega a 100% manda um e-mail, e cada máquina
por trás dele continua rodando e continua cobrando. A lição 1 pôs um orçamento em terceiro lugar na
primeira hora de uma conta real, antes de qualquer coisa que custe dinheiro, exatamente por isso. É
um aviso, e um aviso só serve enquanto o valor ainda é pequeno.

## O orçamento que a lição 1 prometeu

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. O orçamento é descrito em dois arquivos: o orçamento em si, e as suas
notificações com as pessoas e os tópicos que cada uma avisa. Escreva os dois em `~/aws`:

```sh
cat > budget.json <<'EOF'
{
  "BudgetName": "shop-monthly",
  "BudgetType": "COST",
  "TimeUnit": "MONTHLY",
  "BudgetLimit": {"Amount": "50", "Unit": "USD"}
}
EOF
cat > notifications.json <<'EOF'
[
  {
    "Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN",
                     "Threshold": 80, "ThresholdType": "PERCENTAGE"},
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "aws+billing@example.com"}]
  },
  {
    "Notification": {"NotificationType": "FORECASTED", "ComparisonOperator": "GREATER_THAN",
                     "Threshold": 100, "ThresholdType": "PERCENTAGE"},
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "aws+billing@example.com"},
                    {"SubscriptionType": "SNS",
                     "Address": "arn:aws:sns:sa-east-1:123456789012:budget-alerts"}]
  }
]
EOF
```

O **orçamento** é um orçamento de custo de 50 dólares por mês. A primeira **notificação** dispara
quando o custo real do mês passa de 80% disso, 40 dólares. Ela manda e-mail para uma caixa
compartilhada em vez de uma pessoa, pelo motivo que a lição 1 deu para o endereço do usuário root. A
segunda dispara quando a previsão da AWS para o mês passa de 100%, e avisa um tópico SNS além da
caixa. Um tópico é como um alerta chega a um canal de chat ou a um pager em vez de uma caixa de
entrada. Crie o tópico, depois o orçamento, e leia-o de volta. Orçamentos pertencem a uma conta e
não a uma região, então os comandos citam a conta, a `123456789012` padrão do moto:

```
ana@laptop:~/aws$ aws sns create-topic --name budget-alerts
{
    "TopicArn": "arn:aws:sns:sa-east-1:123456789012:budget-alerts"
}
ana@laptop:~/aws$ aws budgets create-budget --account-id 123456789012 --budget file://budget.json --notifications-with-subscribers file://notifications.json
ana@laptop:~/aws$ aws budgets describe-budgets --account-id 123456789012
{
    "Budgets": [
        {
            "BudgetName": "shop-monthly",
            "BudgetLimit": {
                "Amount": "50",
                "Unit": "USD"
            },
            "CostTypes": {
                "IncludeTax": true,
                "IncludeSubscription": true,
                "UseBlended": false,
                "IncludeRefund": true,
                "IncludeCredit": true,
                "IncludeUpfront": true,
                "IncludeRecurring": true,
                "IncludeOtherSubscription": true,
                "IncludeSupport": true,
                "IncludeDiscount": true,
                "UseAmortized": false
            },
            "TimeUnit": "MONTHLY",
            "TimePeriod": {
                "Start": "2026-09-30T21:00:00-03:00",
                "End": "2087-06-14T21:00:00-03:00"
            },
            "CalculatedSpend": {
                "ActualSpend": {
                    "Amount": "0",
                    "Unit": "USD"
                },
                "ForecastedSpend": {
                    "Amount": "0",
                    "Unit": "USD"
                }
            },
            "BudgetType": "COST",
            "LastUpdatedTime": "2026-10-16T12:59:51.960789-03:00"
        }
    ]
}
```

Quatro coisas nessa resposta merecem leitura. **`CostTypes` é o que o orçamento conta**, e por
padrão ele conta quase tudo: imposto, suporte, pagamentos adiantados e reembolsos, e também
**créditos**. Uma conta nova vivendo de créditos (lição 1) mostra por isso um orçamento perto de
zero enquanto gasta. O primeiro mês depois que os créditos acabam chega em tamanho cheio, então crie
um orçamento feito para vigiar o uso com `IncludeCredit` em `false`. `UseBlended` e `UseAmortized`
estão os dois em `false`, então o orçamento conta o custo **não combinado** (*unblended*), a tarifa
cobrada no momento. A seção sobre o Cost Explorer diz o que os outros dois mudariam. O moto
preencheu `TimePeriod` do jeito que a documentação da AWS diz que a AWS preenche. Ele vai do
primeiro dia do mês corrente, em UTC, até 15 de junho de 2087, o substituto da AWS para "até ser
apagado". O fuso do prompt, o de São Paulo, é o motivo de aparecer como 21:00 do dia anterior. E
**`CalculatedSpend` é zero, porque o moto não tem gasto.** Contra a AWS esse bloco traz o custo real
do mês até agora e a previsão para o fim dele. São esses os dois números com que as notificações
comparam.

```
ana@laptop:~/aws$ aws budgets describe-notifications-for-budget --account-id 123456789012 --budget-name shop-monthly --output text
NOTIFICATIONS	GREATER_THAN	ACTUAL	80	PERCENTAGE
NOTIFICATIONS	GREATER_THAN	FORECASTED	100	PERCENTAGE
ana@laptop:~/aws$ aws budgets describe-subscribers-for-notification --account-id 123456789012 --budget-name shop-monthly --notification NotificationType=FORECASTED,ComparisonOperator=GREATER_THAN,Threshold=100,ThresholdType=PERCENTAGE 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeSubscribersForNotification operation (reached max retries: 2): <!doctype html>
```

O moto guardou as duas notificações e aceitou o tópico SNS como assinante. Mas **não consegue listar
os assinantes de volta**: a operação que os lê responde com um erro de servidor. Então este
laboratório não consegue mostrar se o moto guardou o tópico e a caixa. Contra a AWS, o tópico também
precisa de uma política de acesso que deixe `budgets.amazonaws.com` publicar nele, ou o tópico
descarta o alerta. O moto não julga políticas de recurso, então essa parte também não foi rodada.

## Real e previsto são duas perguntas diferentes

**Um alerta real (*actual*) pergunta "quanto já foi?". Um alerta de previsão (*forecasted*)
pergunta "onde este mês vai terminar?".** Eles disparam em dias diferentes para a mesma conta, e
cada um pede uma resposta diferente.

- **Real, em 80%**, dispara quando o dinheiro já foi gasto. Quer dizer: olhe agora, porque o que
  resta do mês são os outros 20%. É o alerta que não erra, e o que chega tarde.
- **Previsto, em 100%**, dispara quando a AWS projeta que o mês vai terminar acima do orçamento.
  Isso pode acontecer no quinto dia do mês com quase nada gasto. Quer dizer: algo mudou no ritmo do
  gasto. É o aviso antecipado, e a documentação da AWS diz que ele precisa de cerca de **cinco
  semanas de histórico** antes de conseguir prever qualquer coisa. Numa conta nova só o alerta real
  funciona no começo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l13-alerts\" aria-label=\"Uma ilustração de um mês contra um orçamento, não uma captura. O eixo horizontal é o dia do mês, de 1 a 30; o eixo vertical é o gasto como porcentagem do orçamento, com linhas em 80% e 100%. O gasto real sobe devagar até o dia 8, quando uma máquina nova começa, e depois mais rápido. No dia 10 a previsão, desenhada tracejada a partir desse dia, já termina o mês acima de 100%, então o alerta de previsão dispara no dia 10. O gasto real passa de 80% no dia 21, e o alerta real dispara aí.\"><path d=\"M90.0 280.0 L670.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 280.0 L90.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"270.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"470.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"670.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"380.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia do mês</text><text x=\"82.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><text x=\"90.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gasto, como fração do orçamento</text><path d=\"M90.0 157.3 L670.0 157.3\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"82.0\" y=\"157.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">80%</text><path d=\"M90.0 126.7 L670.0 126.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"82.0\" y=\"126.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100%</text><path d=\"M90.0 277.7 L110.0 275.4 L130.0 273.1 L150.0 270.8 L170.0 268.5 L190.0 266.2 L210.0 263.9 L230.0 261.6 L250.0 253.6 L270.0 245.6 L290.0 237.5 L310.0 229.5 L330.0 221.5 L350.0 213.5 L370.0 205.5 L390.0 197.4 L410.0 189.4 L430.0 181.4 L450.0 173.4 L470.0 165.4 L490.0 157.3 L510.0 149.3 L530.0 141.3 L550.0 133.3 L570.0 125.3 L590.0 117.2 L610.0 109.2 L630.0 101.2 L650.0 93.2 L670.0 85.1\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"666.0\" y=\"103.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">real</text><path d=\"M270.0 245.6 L670.0 57.7\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"666.0\" y=\"45.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">previsão, feita no dia 10</text><circle cx=\"270.0\" cy=\"245.6\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"280.0\" y=\"267.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">dia 10: alerta de previsão</text><circle cx=\"490.0\" cy=\"157.3\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"500.0\" y=\"177.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">dia 21: alerta real</text><text x=\"230.0\" y=\"235.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma máquina nova</text><path d=\"M230.0 243.6 L230.0 255.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"334.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma ilustração, não uma captura</text></svg>", "caption": "A previsão avisa quando o ritmo muda; o alerta real, quando o dinheiro já foi."}
```

**Os dois chegam atrás do gasto.** A documentação da AWS diz que a AWS atualiza os dados de
orçamento até três vezes por dia. Um alerta em 80% sai na primeira atualização depois de o gasto
cruzar a linha, o que pode ser bem depois dela. Uma máquina ligada por engano na sexta à noite
aparece na próxima atualização, não no minuto em que começou, e a fatura não espera pelo e-mail.

## Um orçamento que age, e o que ele ainda não faz

Um alerta informa; uma **ação de orçamento** (*budget action*) faz algo quando um limiar é
ultrapassado. A documentação da AWS lista três tipos:

- **aplicar uma política do IAM** a um usuário, grupo ou role, como uma política que nega iniciar
  instâncias novas, o assunto das lições 7 e 8;
- **aplicar uma service control policy** a uma conta ou a uma unidade organizacional, o que só a
  conta de gerenciamento pode fazer, porque só ela anexa SCPs (lição 4);
- **parar instâncias específicas do EC2 ou do RDS**, o que a AWS faz pelo Systems Manager.

Cada ação roda na hora ou espera alguém aprovar. Ela roda como uma role do IAM que você entrega ao
orçamento. **Nada disso existe no moto**: pedir as ações de um orçamento é um erro de servidor.

```
ana@laptop:~/aws$ aws budgets describe-budget-actions-for-budget --account-id 123456789012 --budget-name shop-monthly 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeBudgetActionsForBudget operation (reached max retries: 2): <!doctype html>
```

**Nem uma ação para o gasto, só uma parte dele.** Uma política que nega instâncias novas deixa as que
estão rodando rodando. Uma instância parada deixa de cobrar as horas, e os discos dela continuam
cobrando cada gigabyte que guardam. Nada que um orçamento faz apaga um recurso, que é a única coisa
que encerra o custo dele. O que os próprios orçamentos custam está na lista de preços:

```
ana@laptop:~/aws$ python3 price.py AWSBudgets 20260911124529 aws-other BudgetsUsage ActionEnabledBudgetsUsage
AWSBudgets 20260911124529, published 2026-09-11, USD
BudgetsUsage
          0 to       Inf Budget-days 0.0000
ActionEnabledBudgetsUsage
          0 to        62 Budget-days 0.0000
         62 to       Inf Budget-days 0.1000
```

Na lista que a AWS publicou em **11 de setembro de 2026**, um orçamento só com alertas não custa
nada. A AWS cobra um orçamento com ação por orçamento por dia, e os primeiros 62 desses
orçamentos-dia de um mês são grátis. Isso dá dois orçamentos assim por um mês inteiro. Depois disso,
cada um custa 0,10 dólar por dia. A região é `aws-other` porque o Budgets não pertence a região
nenhuma.

**Onde o orçamento mora decide o que ele vê.** Um orçamento criado numa conta-membro vigia essa
conta. Um orçamento criado na conta de gerenciamento vigia a organização inteira, porque o
faturamento consolidado (lição 3) põe as cobranças de toda conta na fatura dessa conta. Filtros
podem estreitá-lo para uma conta, um serviço ou uma tag. Filtrar por tag só funciona para tags que o
faturamento conhece, que é a próxima seção.
