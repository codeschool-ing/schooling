---
title: Autoscaling
version: 1
---

**O autoscaling do DynamoDB não faz parte do DynamoDB.** É o Application Auto Scaling, o mesmo serviço
que escala outros recursos da AWS, mexendo na capacidade provisionada da tabela com `update-table` por
você. Ele só vale para tabelas e índices provisionados, e é montado em dois passos: um **alvo
escalável** (*scalable target*), que diz o que pode mudar e entre quais limites, e uma **política de
escala**, que diz o que buscar. A política é um arquivo. `policy.json`:

```json
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {"PredefinedMetricType": "DynamoDBWriteCapacityUtilization"},
  "ScaleOutCooldown": 60,
  "ScaleInCooldown": 60
}
```

**Target tracking em 70%**: manter as unidades de escrita consumidas em cerca de 70% das provisionadas,
somando capacidade quando ficam acima disso e tirando quando ficam bem abaixo. Os cooldowns são os
segundos de espera depois de uma mudança antes de considerar a próxima.

```
ana@laptop:~/aws$ aws application-autoscaling register-scalable-target --service-namespace dynamodb --resource-id table/products --scalable-dimension dynamodb:table:WriteCapacityUnits --min-capacity 5 --max-capacity 500
{
    "ScalableTargetARN": "arn:aws:application-autoscaling:sa-east-1:123456789012:scalable-target/m5dloybd3ubrfiyla2pm9qo1gjve3osjqew6"
}
ana@laptop:~/aws$ aws application-autoscaling put-scaling-policy --service-namespace dynamodb --resource-id table/products --scalable-dimension dynamodb:table:WriteCapacityUnits --policy-name products-writes --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration file://policy.json --query "Alarms[].AlarmName"
[
    "TargetTracking-table/products-AlarmHigh-7383b42b-b07f-4480-b7f2-281ad286ed12",
    "TargetTracking-table/products-AlarmLow-1792338c-7a9a-4a3f-a0be-df8b0a5c97e8",
    "TargetTracking-table/products-ProvisionedCapacityHigh-f8e77f49-847a-4b6d-a4a5-55e4fc20092b",
    "TargetTracking-table/products-ProvisionedCapacityLow-d6a2a5d3-74a8-4572-a1a4-ff7bf74ff4df"
]
```

O alvo deixa a tabela products variar entre 5 e 500 unidades de escrita. A política respondeu com
quatro alarmes do CloudWatch, porque é assim que o target tracking funciona: ele não observa a tabela
diretamente, cria alarmes sobre as métricas dela e age quando um deles dispara.

```
ana@laptop:~/aws$ aws cloudwatch describe-alarms --query 'MetricAlarms[].[MetricName,ComparisonOperator,Threshold,Period,EvaluationPeriods]' --output text
ConsumedReadCapacityUnits	GreaterThanThreshold	42.0	60	2
ConsumedReadCapacityUnits	LessThanThreshold	30.0	60	15
ProvisionedReadCapacityUnits	GreaterThanThreshold	1.0	300	2
ProvisionedReadCapacityUnits	LessThanThreshold	1.0	300	3
ana@laptop:~/aws$ aws application-autoscaling describe-scaling-activities --service-namespace dynamodb --resource-id table/products 2>&1 | head -2

aws: [ERROR]: An error occurred (500) when calling the DescribeScalingActivities operation (reached max retries: 2): <!doctype html>
```

**Os alarmes têm a forma que a AWS cria, e o conteúdo errado.** Dois observam as unidades consumidas, um
minuto por vez: um dispara depois de 2 minutos acima do alvo, outro depois de 15 minutos bem abaixo, e
é por isso que subir é rápido e descer é lento de propósito. Outros dois observam a própria capacidade
provisionada. Mas esta é uma política de unidades de escrita, e todo alarme nomeia uma métrica de
leitura; e os limiares, 42 e 30, são 70% e 50% de 60 segundos de uma unidade só, não das 5 unidades que
esta tabela tem. Na AWS eles são calculados a partir da capacidade real da tabela e mudam toda vez que
ela muda. O moto registra uma política e desenha alarmes com a forma certa, e nada por trás deles é real.

**E nada escala.** O moto não publica métricas, então nenhum alarme dispara, a capacidade fica onde o
`update-table` a pôs, e o histórico de atividades de escala nem está implementado: o `500` é o servidor
do moto falhando, não uma resposta. O que a AWS faria não foi rodado aqui, e vale dizer com todas as
letras. Quando as escritas passam de 70% da capacidade por dois minutos, o Application Auto Scaling sobe
a capacidade para trazê-las de volta a 70%, dentro dos limites do alvo. Quando caem bem abaixo por
quinze, ele a baixa, respeitando a franquia de reduções do dia. Cada passo leva minutos desde a primeira
requisição cheia, e durante esses minutos a tabela atende com o que tem.
