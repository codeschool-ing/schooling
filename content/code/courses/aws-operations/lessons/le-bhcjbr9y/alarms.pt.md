---
title: Alarmes sobre o que a trilha registra
version: 1
---

Um log lido depois do fato explica um incidente. O mesmo log, lido enquanto chega, pode **levantar** um. A
lição 18 prometeu o alarme para uma chave pendente de exclusão que algo ainda usa; é aqui que ele é
construído, de dois dos jeitos com que o CloudTrail alimenta alarmes.

## Um filtro de métrica no grupo de logs da trilha

Uma trilha também pode mandar seus eventos para um grupo do CloudWatch Logs, e dali os filtros de métrica
da lição 9 transformam eventos que casam numa métrica. A AWS documenta que o uso de uma chave pendente de
exclusão fica registrado com a mensagem de erro terminando em `is pending deletion.`, e um filtro na
sintaxe JSON dos padrões de filtro casa com ela:

```
ana@laptop:~/aws/trail$ aws logs create-log-group --log-group-name /shop/cloudtrail
ana@laptop:~/aws/trail$ aws logs put-metric-filter --log-group-name /shop/cloudtrail --filter-name kms-pending-use --filter-pattern '{ ($.eventSource = kms.amazonaws.com) && ($.errorMessage = "* is pending deletion.") }' --metric-transformations metricName=KmsPendingKeyUse,metricNamespace=Shop/Security,metricValue=1
ana@laptop:~/aws/trail$ aws logs describe-metric-filters --log-group-name /shop/cloudtrail --query 'metricFilters[].[filterName,metricTransformations[0].metricName]' --output text
kms-pending-use	KmsPendingKeyUse
ana@laptop:~/aws/trail$ aws cloudwatch put-metric-alarm --alarm-name kms-pending-key-used --namespace Shop/Security --metric-name KmsPendingKeyUse --statistic Sum --period 300 --evaluation-periods 1 --threshold 0 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions arn:aws:sns:sa-east-1:123456789012:shop-page
```

Na AWS, cada tentativa de usar a chave durante os sete dias soma agora 1 a `KmsPendingKeyUse`, e o alarme
chama alguém na primeira. **O moto guarda o filtro e o alarme e não aplica nenhum dos dois**: os filtros de
métrica dele ignoram padrões JSON, como a lição 9 descobriu, e ele não avalia alarme nenhum.

## Uma regra sobre o próprio evento

Para mudanças que importam no momento em que acontecem, uma regra do EventBridge sobre o evento é mais
rápida que uma métrica: o CloudTrail manda eventos de gerenciamento ao EventBridge como `AWS API Call via
CloudTrail`, e um padrão os escolhe. Este pega qualquer um que desative uma chave ou agende a exclusão
dela.

`key-events.json`:

```json
{
  "source": ["aws.kms"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["kms.amazonaws.com"],
    "eventName": ["DisableKey", "ScheduleKeyDeletion"]
  }
}
```

```
ana@laptop:~/aws/trail$ aws events put-rule --name key-changes --event-pattern file://key-events.json --query RuleArn --output text
arn:aws:events:sa-east-1:123456789012:rule/key-changes
```

Com `shop-page` como alvo, como na lição 19, quem está de plantão fica sabendo da exclusão agendada de uma
chave no minuto em que ela é agendada, com seis dias e vinte e três horas para perguntar por quê.

O mesmo padrão, com outros nomes de evento, cobre a lista curta pela qual a maioria das equipes chama
alguém: o usuário root entrando, uma trilha sendo parada ou apagada, um security group aberto para
`0.0.0.0/0`, uma política IAM anexada a um usuário. **Uma trilha que pode ser parada em silêncio não é um
log de auditoria**, então `StopLogging` e `DeleteTrail` entram primeiro nessa lista.
