---
title: Avisando alguém, por um tópico
version: 1
---

O estado de um alarme muda em silêncio a menos que ele tenha **ações**. A ação comum é publicar num
**tópico** do SNS, e o tópico entrega a cada **assinatura** que tem: um e-mail, um número de SMS, um
endpoint HTTPS de um serviço de plantão, uma fila, uma função Lambda. O alarme da loja já nomeia o
tópico `shop-oncall` para `ALARM` e para `OK`, então quem é chamado também fica sabendo quando acabou.

Um tópico separa o alarme das pessoas. **Alarmes nomeiam um tópico por público, nunca uma pessoa**:
quando o plantão muda na segunda-feira, as assinaturas mudam e nenhum dos quarenta alarmes muda. A
lição 14 é sobre esse plantão.

## Seguindo o caminho no laboratório

Uma assinatura de e-mail precisa de alguém clicando num link de confirmação, o que um laboratório não
faz, então o laboratório assina uma fila e lê a fila como caixa de entrada. Depois força o alarme para
`ALARM` à mão, que é também como uma equipe testa o caminho na AWS:

```
ana@laptop:~/aws/alarms$ QUEUE=$(aws sqs create-queue --queue-name oncall-inbox --query QueueUrl --output text)
ana@laptop:~/aws/alarms$ aws sns subscribe --topic-arn arn:aws:sns:sa-east-1:123456789012:shop-oncall --protocol sqs --notification-endpoint arn:aws:sqs:sa-east-1:123456789012:oncall-inbox --query SubscriptionArn --output text
arn:aws:sns:sa-east-1:123456789012:shop-oncall:4621fb4c-a6f6-41d6-878f-4eb73b672643
ana@laptop:~/aws/alarms$ aws cloudwatch set-alarm-state --alarm-name api-errors --state-value ALARM --state-reason 'set by hand to test the route'
ana@laptop:~/aws/alarms$ aws sqs receive-message --queue-url $QUEUE --wait-time-seconds 2 --query 'length(Messages || `[]`)'
0
ana@laptop:~/aws/alarms$ aws sns publish --topic-arn arn:aws:sns:sa-east-1:123456789012:shop-oncall --subject 'ALARM: api-errors' --message file://notification.json --query MessageId --output text
8b6c26aa-61d0-4648-8fc1-6a859a764da8
ana@laptop:~/aws/alarms$ aws sqs receive-message --queue-url $QUEUE --wait-time-seconds 2 --query 'Messages[0].Body' --output text | jq -r .Message | jq '{AlarmName, NewStateValue, NewStateReason}'
{
  "AlarmName": "api-errors",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 3 out of the last 5 datapoints were greater than the threshold (10.0)."
}
```

Leia em ordem. A assinatura é feita. `set-alarm-state` passa o alarme para `ALARM`, e **a fila não
recebe nada**: o moto muda o estado e não roda ação nenhuma. Na AWS, esse único comando é o teste padrão
de que um chamado chega ao telefone certo, e rodá-lo uma vez depois de cada mudança no caminho é
barato.

O laboratório então publica à mão o que o CloudWatch teria publicado, `notification.json`, escrito por
esta lição no formato documentado da mensagem de um alarme:

```json
{
  "AlarmName": "api-errors",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 3 out of the last 5 datapoints were greater than the threshold (10.0).",
  "OldStateValue": "OK",
  "Region": "South America (Sao Paulo)",
  "Trigger": {
    "MetricName": "Errors5xx",
    "Namespace": "Shop",
    "Statistic": "SUM",
    "Period": 60,
    "EvaluationPeriods": 5,
    "DatapointsToAlarm": 3,
    "ComparisonOperator": "GreaterThanThreshold",
    "Threshold": 10.0,
    "TreatMissingData": "notBreaching"
  }
}
```

A fila a recebe, embrulhada no envelope do próprio SNS, e o `jq` desembrulha a `Message` até os três
campos que uma pessoa lê primeiro. **Toda mensagem de alarme diz qual alarme, que estado, e por quê**:
`NewStateReason` é a frase do CloudWatch sobre os pontos, e o bloco `Trigger` repete a regra do alarme,
então quem é chamado não precisa do console para saber o que cruzou o quê.

## Para que serve cada assinatura

| assinatura | use para |
|---|---|
| um serviço de plantão (HTTPS) | acordar uma pessoa: reconhecimento, escalonamento, um telefone que toca |
| e-mail | um registro, e para alarmes que podem esperar a manhã |
| um canal de chat, pela integração de chat da AWS | a equipe vendo junto durante um incidente |
| uma fila ou uma função Lambda | automação: abrir um chamado, escalar, um passo de runbook |

E-mail sozinho não é plantão: o telefone de ninguém toca por um e-mail às três da manhã, o que é a
resposta certa para aquele alarme ou o motivo de uma queda ter sido descoberta por um cliente.
