---
title: Um orçamento, e os dois alertas que ele carrega
version: 1
---

Os alarmes da lição 10 vigiam o que os clientes sentem. Alguns incidentes os clientes nunca sentem: uma
flag de debug esquecida ligada que grava quarenta gigabytes de logs por dia, um teste de carga esquecido,
uma credencial minerando criptomoeda em instâncias que outra pessoa lançou. O serviço funciona; **a conta
é a única coisa que se mexe**, e ela se mexe no fim do mês, a menos que algo a vigie todo dia. Esta lição
faz da conta um sinal como qualquer outro.

O primeiro instrumento é o **AWS Budgets**: um valor para um período, e notificações quando o gasto cruza
uma fração dele. Orçamentos são grátis para este uso; a AWS só cobra por orçamentos que executam **ações**,
além dos dois primeiros, o que esta lição não usa. Trabalhe em `~/aws/bill`
(`mkdir -p ~/aws/bill && cd ~/aws/bill`). O mês da loja fica em cerca de 1.500 USD, então o orçamento é de
1.600.

`budget.json`:

```json
{
  "BudgetName": "shop-monthly",
  "BudgetLimit": { "Amount": "1600", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

`notifications.json`:

```json
[
  {
    "Notification": { "NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN", "Threshold": 80, "ThresholdType": "PERCENTAGE" },
    "Subscribers": [{ "SubscriptionType": "SNS", "Address": "arn:aws:sns:us-east-1:123456789012:billing" }]
  },
  {
    "Notification": { "NotificationType": "FORECASTED", "ComparisonOperator": "GREATER_THAN", "Threshold": 100, "ThresholdType": "PERCENTAGE" },
    "Subscribers": [{ "SubscriptionType": "SNS", "Address": "arn:aws:sns:us-east-1:123456789012:billing" }]
  }
]
```

```
ana@laptop:~/aws/bill$ aws sns create-topic --name billing --region us-east-1 --query TopicArn --output text
arn:aws:sns:us-east-1:123456789012:billing
ana@laptop:~/aws/bill$ aws budgets create-budget --account-id 123456789012 --budget file://budget.json --notifications-with-subscribers file://notifications.json
ana@laptop:~/aws/bill$ aws budgets describe-budgets --account-id 123456789012 --query 'Budgets[].[BudgetName,BudgetLimit.Amount,TimeUnit,CalculatedSpend.ActualSpend.Amount]' --output text
shop-monthly	1600	MONTHLY	0
ana@laptop:~/aws/bill$ aws budgets describe-notifications-for-budget --account-id 123456789012 --budget-name shop-monthly --query 'Notifications[].[NotificationType,ComparisonOperator,Threshold]' --output text
ACTUAL	GREATER_THAN	80
FORECASTED	GREATER_THAN	100
```

As duas notificações são o ponto. **`ACTUAL` acima de 80%** diz que o dinheiro foi gasto: no dia 25 de um
mês normal é esperado, no dia 9 é notícia. **`FORECASTED` acima de 100%** diz que o mês está a caminho de
passar do orçamento, pela previsão da própria AWS para o resto do mês, e essa chega cedo o bastante para
agir. Um orçamento só com uma notificação real a 100% diz, no dia 30, o que todo mundo vai ver no dia 1º.

O moto guarda o orçamento e as duas notificações, e o gasto real dele é 0, porque não há gasto: nenhuma
notificação vai sair daqui. Na AWS o gasto é atualizado várias vezes ao dia, e uma notificação de
orçamento vai para endereços de e-mail ou para um tópico SNS, e do tópico para as rotas da lição 14: o
alerta de previsão para um ticket, e um orçamento da conta inteira passando o real de 100% no começo do
mês para um chamado.

O tópico fica em `us-east-1`, e isso não é descuido: a métrica de cobrança da próxima seção só existe lá,
e um alarme só notifica um tópico da própria região, então um tópico lá serve aos dois.
