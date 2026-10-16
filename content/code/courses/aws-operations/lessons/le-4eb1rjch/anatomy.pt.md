---
title: As partes de um alarme, e os três estados
version: 1
---

Um alarme vigia uma métrica e responde a uma pergunta a cada período: esta métrica está num estado de
que alguém deveria saber? A imagem comum é um limite: acima dele, alarme. **O limite é um de cinco
números, e os outros quatro decidem se o alarme acorda alguém à toa**, ou fica quieto durante uma
queda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um gráfico de barras de erros por minuto em onze minutos: 0, 1, 0, 12, 15, 0, 14, 16, e depois três minutos sem dado. Uma linha tracejada marca o limite de 10; as barras acima dele, 12, 15, 14 e 16, estão destacadas. Uma caixa tracejada em volta de cinco pontos seguidos, 0, 12, 15, 0 e 14, tem o rótulo últimos 5 pontos, 3 acima, ALARM.\"><defs><marker id=\"mn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M50 200 L665 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M50 130 L665 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"655\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">limite 10</text><text x=\"80.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M115 200 L115 193 L155 193 L155 200 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"135.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"190.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M225 200 L225 116 L265 116 L265 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"245.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><path d=\"M280 200 L280 95 L320 95 L320 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"300.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15</text><text x=\"355.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M390 200 L390 102 L430 102 L430 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"410.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><path d=\"M445 200 L445 88 L485 88 L485 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"465.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"520.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem dado</text><text x=\"520.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-</text><text x=\"575.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem dado</text><text x=\"575.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-</text><text x=\"630.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem dado</text><text x=\"630.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-</text><path d=\"M162 40 L438 40 L438 226 L162 226 Z\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></path><text x=\"168\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">últimos 5 pontos: 3 acima, ALARM</text><text x=\"50\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Erros por minuto. A janela anda um minuto por vez; no fim ela tem dois pontos ruins e três vazios.</text></svg>", "caption": "Três de cinco é a regra; o que os três minutos vazios do fim valem é a configuração de dado ausente."}
```

| parte | o valor da loja | o que ela decide |
|---|---|---|
| estatística e período | `Sum` a cada 60 segundos | o que é um ponto de dado |
| limite e comparação | `GreaterThanThreshold` 10 | o que conta como ponto ruim |
| períodos de avaliação, N | 5 | quantos pontos recentes são olhados |
| pontos para alarmar, M | 3 | quantos deles precisam ser ruins |
| dado ausente | `notBreaching` | o que um minuto sem dado vale |

**M de N** é a parte que torna um alarme utilizável. Um único minuto ruim é ruído: uma rajada de novas
tentativas, o reinício de um deploy. Três minutos ruins em cinco são um padrão, e o alarme dispara no
padrão e não no ruído. M igual a N, 5 de 5, espera uma sequência perfeita de minutos ruins e perde uma
queda que pisca; M de 1 dispara em toda piscada.

Um alarme está sempre num de três estados: **`OK`**, `ALARM` e `INSUFFICIENT_DATA`, que
significa que o alarme não consegue dizer, porque o dado de que precisa não está lá. Ele avisa numa
**mudança** de estado, não a cada período passado num deles, então um alarme em `ALARM` por uma hora
manda uma mensagem, mais uma quando volta a `OK`.

## No laboratório

```
ana@laptop:~/aws/alarms$ aws sns create-topic --name shop-oncall --query TopicArn --output text
arn:aws:sns:sa-east-1:123456789012:shop-oncall
ana@laptop:~/aws/alarms$ aws cloudwatch put-metric-alarm --alarm-name api-errors --namespace Shop --metric-name Errors5xx --dimensions Name=Service,Value=api --statistic Sum --period 60 --evaluation-periods 5 --datapoints-to-alarm 3 --threshold 10 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions arn:aws:sns:sa-east-1:123456789012:shop-oncall --ok-actions arn:aws:sns:sa-east-1:123456789012:shop-oncall
ana@laptop:~/aws/alarms$ aws cloudwatch describe-alarms --alarm-names api-errors --query 'MetricAlarms[0].[StateValue,StateReason,DatapointsToAlarm,EvaluationPeriods,TreatMissingData]' --output text
OK	Unchecked: Initial alarm creation	3	5	notBreaching
```

O alarme existe, com cada número acima, e o estado dele é `OK` com o motivo `Unchecked: Initial alarm
creation`. Esse motivo nunca muda no moto: **o moto guarda alarmes e nunca os avalia**. A próxima seção
publica dados que deveriam disparar este alarme, e depois faz a avaliação ela mesma.
