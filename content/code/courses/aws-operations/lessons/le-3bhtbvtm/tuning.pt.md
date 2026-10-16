---
title: Ajustando, um alarme por vez
version: 1
---

A tabela do mês nomeia os alarmes a mudar. Cada um recebe um de quatro movimentos, e a ordem é a ordem
em que tentá-los:

1. **Corrigir a causa.** `disk-80` dispara toda noite porque o backup escreve seus arquivos temporários no
   disco de dados. Levá-los para outro lugar acaba com os chamados e com o risco juntos.
2. **Fazê-lo esperar.** Um alarme que dispara num único período ruim de cinco minutos chama a cada pico.
   Doze períodos de doze, uma hora acima da linha, chamam só para um disco que está enchendo de verdade.
3. **Torná-lo um ticket.** `db-cpu` e `queue-depth` são causas. Quando importam, `api-errors` ou
   `api-latency` chamam de qualquer jeito; até lá, são trabalho para a manhã.
4. **Apagá-lo.** Um alarme em que ninguém agiu em três meses, e que não teria mudado decisão nenhuma, é
   ruído com nome. A métrica dele continua no painel.

O primeiro movimento é trabalho da equipe, não um comando da AWS. Os outros três são uma mudança no
alarme.

## Mudar um alarme sem perdê-lo

Os cinco alarmes da loja chamam todos, por `shop-page`:

```
ana@laptop:~/aws/oncall$ aws cloudwatch describe-alarms --query 'MetricAlarms[].[AlarmName,AlarmActions[0]]' --output text
api-errors	arn:aws:sns:sa-east-1:123456789012:shop-page
api-latency	arn:aws:sns:sa-east-1:123456789012:shop-page
db-cpu	arn:aws:sns:sa-east-1:123456789012:shop-page
queue-depth	arn:aws:sns:sa-east-1:123456789012:shop-page
disk-80	arn:aws:sns:sa-east-1:123456789012:shop-page
ana@laptop:~/aws/oncall$ TICKET=$(aws sns create-topic --name shop-ticket --query TopicArn --output text); echo $TICKET
arn:aws:sns:sa-east-1:123456789012:shop-ticket
```

**`put-metric-alarm` substitui o alarme inteiro.** Não existe comando para mudar só as ações. Uma chamada
que nomeia `db-cpu` e o tópico novo e mais nada é recusada, já que os períodos e a comparação são
obrigatórios; uma que informa esses e esquece as dimensões cria outro alarme com o mesmo nome, olhando
uma métrica que ninguém publica. O jeito seguro é ler o alarme, mudar os campos e escrever tudo de volta.
`describe-alarms` devolve mais do que `put-metric-alarm` aceita, o estado e os horários entre outras
coisas, então um pequeno filtro `jq`, `to-ticket.jq`, guarda só as configurações, troca o tópico e tira
os campos que o alarme deixa vazios, que a linha de comando recusaria como `null`:

```
# to-ticket.jq: an alarm's settings, routed to the topic in $t
{AlarmName, AlarmDescription, Namespace, MetricName, Dimensions, Statistic,
 Period, EvaluationPeriods, DatapointsToAlarm, Threshold, ComparisonOperator,
 TreatMissingData, AlarmActions: [$t], OKActions: [$t]}
| with_entries(select(.value != null))
```

```
ana@laptop:~/aws/oncall$ jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names db-cpu --query MetricAlarms[0]) > db-cpu.json
ana@laptop:~/aws/oncall$ aws cloudwatch put-metric-alarm --cli-input-json file://db-cpu.json
ana@laptop:~/aws/oncall$ jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names queue-depth --query MetricAlarms[0]) > queue-depth.json
ana@laptop:~/aws/oncall$ aws cloudwatch put-metric-alarm --cli-input-json file://queue-depth.json
```

`disk-80` recebe o segundo movimento além do terceiro, uma hora de períodos antes de dizer qualquer coisa:

```
ana@laptop:~/aws/oncall$ jq --arg t "$TICKET" -f to-ticket.jq <(aws cloudwatch describe-alarms --alarm-names disk-80 --query MetricAlarms[0]) | jq ".EvaluationPeriods = 12 | .DatapointsToAlarm = 12" > disk-80.json
ana@laptop:~/aws/oncall$ aws cloudwatch put-metric-alarm --cli-input-json file://disk-80.json
```

```
ana@laptop:~/aws/oncall$ aws cloudwatch describe-alarms --query 'MetricAlarms[].[AlarmName,AlarmActions[0],EvaluationPeriods]' --output text
api-errors	arn:aws:sns:sa-east-1:123456789012:shop-page	5
api-latency	arn:aws:sns:sa-east-1:123456789012:shop-page	5
db-cpu	arn:aws:sns:sa-east-1:123456789012:shop-ticket	1
queue-depth	arn:aws:sns:sa-east-1:123456789012:shop-ticket	1
disk-80	arn:aws:sns:sa-east-1:123456789012:shop-ticket	12
```

Dois alarmes chamam, três abrem tickets, e `disk-80` espera doze períodos. No mês que acabou de ser
medido, isso dá os 30 chamados da seção anterior em vez de 121. Guarde os arquivos JSON: são os alarmes
como estão agora, e a diferença entre dois deles é a mudança que a próxima revisão lê. Melhor ainda, os
alarmes moram no CloudFormation ou no Terraform das lições 4 a 7, onde uma mudança como esta é um pull
request.

## Mantendo ajustado

A fadiga de alertas volta, porque os sistemas mudam e os alarmes não. Três hábitos a mantêm longe:

- **a passagem conta os chamados**, alarme por alarme, e um alarme com ação em menos da metade das vezes
  num mês recebe um dos quatro movimentos;
- **todo alarme novo diz quem age e o que faz** na descrição, então um alarme de descrição vazia é o
  primeiro candidato ao quarto movimento;
- **um alarme que nunca dispara é testado**, com `set-alarm-state` como na lição 10, porque o silêncio de
  uma rota quebrada parece igual ao silêncio de um serviço saudável.
