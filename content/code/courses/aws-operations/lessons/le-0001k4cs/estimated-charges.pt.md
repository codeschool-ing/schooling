---
title: EstimatedCharges, a conta como métrica do CloudWatch
version: 1
---

Orçamentos olham o mês. O segundo instrumento é uma métrica: **`EstimatedCharges`**, no namespace
`AWS/Billing`, a estimativa da conta no mês até agora em dólares americanos, atualizada várias vezes ao
dia. Ela só é publicada em **`us-east-1`**, qualquer que seja a região que a conta usa, e só depois que os
alertas de cobrança são ligados uma vez nas preferências de cobrança. Um alarme sobre ela é um alarme
como os da lição 10:

```
ana@laptop:~/aws/bill$ aws cloudwatch put-metric-alarm --region us-east-1 --alarm-name bill-over-1600 --namespace AWS/Billing --metric-name EstimatedCharges --dimensions Name=Currency,Value=USD --statistic Maximum --period 21600 --evaluation-periods 1 --threshold 1600 --comparison-operator GreaterThanThreshold --alarm-actions arn:aws:sns:us-east-1:123456789012:billing
ana@laptop:~/aws/bill$ aws cloudwatch describe-alarms --region us-east-1 --query 'MetricAlarms[].[AlarmName,Namespace,MetricName,StateValue]' --output text
bill-over-1600	AWS/Billing	EstimatedCharges	OK
ana@laptop:~/aws/bill$ aws cloudwatch list-metrics --region us-east-1 --namespace AWS/Billing
{
    "Metrics": []
}
```

O alarme tem os mesmos 1.600 USD do orçamento, sobre o máximo de um período de seis horas, já que a métrica
muda poucas vezes por dia e um período menor quase sempre não veria dados. O último comando é o honesto:
**não existe métrica `AWS/Billing` no moto**, então este alarme vai vigiar nada para sempre. O moto também
o informa como `OK`, onde a AWS começa um alarme em `INSUFFICIENT_DATA` até a métrica chegar.

## O que a métrica é, e o que não é

`EstimatedCharges` é **cumulativa no mês**: sobe a partir do dia 1º e cai para perto de zero quando o mês
seguinte começa. Essa forma deixa um limite fixo certo para uma pergunta, *o mês passou de 1.600?*, e
errado para a maioria das outras: um alarme a 800 dispara no dia 16 de um mês normal e no dia 5 de um
ruim, e diz a mesma coisa nas duas vezes. Dois hábitos a tornam útil:

- **um alarme por serviço**, com a dimensão `ServiceName`, `AmazonCloudWatch` ou `AmazonEC2`, para o
  chamado nomear o que se mexeu;
- **a taxa, não o nível**: a matemática de métricas da lição 12 se aplica, e `RATE(m1)` sobre a métrica são
  dólares por segundo, a coisa que um pico muda. Um alarme sobre a taxa dispara no dia em que o gasto muda
  de ritmo, qualquer que seja o dia do mês.

A próxima seção faz o segundo com os dados que um relatório diário de custo daria, já que o moto não tem
nenhum.
