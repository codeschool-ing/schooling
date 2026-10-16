---
title: Taxa de queima, e chamar pelo orçamento
version: 1
---

Um alarme na taxa de erro (lição 10) chama quando 2% das requisições falham, seja lá o que isso
signifique para o mês. Um alarme no **orçamento** chama quando o mês está em perigo. A grandeza que ele
vigia é a **taxa de queima**: quão rápido o orçamento está sendo gasto, comparado a gastá-lo por igual.

> taxa de queima = taxa de erro / (1 − SLO)

Com taxa de queima 1, o orçamento dura exatamente os 30 dias. Com 14,4 ele dura umas 50 horas, então uma
hora nesse ritmo gasta 2% do orçamento do mês; com 36 ele acaba em 20 horas. Os limites mais usados, do
*Site Reliability Workbook* do Google, chamam quando a taxa passa de **14,4 na última hora** (2% do
orçamento em uma hora) ou de **6 nas últimas seis horas** (5%), e abrem um chamado para queimas mais
lentas.

## Duas janelas, e por quê

Uma janela longa sozinha chama tarde e continua chamando depois de o problema ser resolvido, porque
uma hora de histórico continua ruim por uma hora. Então cada limite é conferido em **duas janelas**, uma
longa e uma doze vezes mais curta, e só chama quando as duas queimam: a longa diz que o problema é
grande o bastante para importar, a curta diz que ele ainda está acontecendo.

Dois programas mostram isso. O primeiro publica uma hora de tráfego da loja, mil requisições por
minuto, com 50 erros por minuto durante 25 minutos, terminando agora (`ongoing`) ou terminando vinte
minutos atrás (`recovered`), cada um com a própria dimensão `Service`:

```python
# hour.py SCENARIO: an hour of the shop's traffic, as two metrics per minute
import datetime as dt
import sys

import boto3

scenario = sys.argv[1]                        # "ongoing" or "recovered"
bad = range(1, 26) if scenario == "ongoing" else range(21, 46)

now = dt.datetime.now(dt.timezone.utc).replace(second=0, microsecond=0)
data = []
for k in range(60, 0, -1):                    # k minutes ago
    errors = 50 if k in bad else 1
    for name, value in (("Requests", 1000), ("Errors", errors)):
        data.append({"MetricName": name, "Value": value, "Unit": "Count",
                     "Dimensions": [{"Name": "Service", "Value": scenario}],
                     "Timestamp": now - dt.timedelta(minutes=k)})

cw = boto3.client("cloudwatch")
for i in range(0, len(data), 20):
    cw.put_metric_data(Namespace="Shop", MetricData=data[i:i + 20])
print(f"{scenario}: {len(data)} data points published")
```

O segundo lê de volta a última hora e os últimos cinco minutos e calcula as duas taxas de queima,
chamando só quando as duas passam de 14,4:

```python
# burn.py SERVICE: how fast the error budget is burning, over two windows
import datetime as dt
import sys

import boto3

SLO = 0.999                       # 99.9% of requests succeed, over 30 days
BUDGET = 1 - SLO
PAGE_ABOVE = 14.4                 # 2% of a 30-day budget in one hour

cw = boto3.client("cloudwatch")
now = dt.datetime.now(dt.timezone.utc).replace(second=0, microsecond=0)


def total(name, minutes):
    points = cw.get_metric_statistics(
        Namespace="Shop", MetricName=name,
        Dimensions=[{"Name": "Service", "Value": sys.argv[1]}],
        StartTime=now - dt.timedelta(minutes=minutes), EndTime=now,
        Period=60, Statistics=["Sum"])["Datapoints"]
    return sum(p["Sum"] for p in points)


burning = []
for label, minutes in (("1 hour", 60), ("5 min", 5)):
    errors, requests = total("Errors", minutes), total("Requests", minutes)
    burn = errors / requests / BUDGET
    burning.append(burn > PAGE_ABOVE)
    print(f"{label:>6}: {int(errors):>5} errors in {int(requests):>6} requests, burn rate {burn:5.1f}")
print("page" if all(burning) else "no page")
```

```
ana@laptop:~/aws/slo$ python3 hour.py ongoing
ongoing: 120 data points published
ana@laptop:~/aws/slo$ python3 burn.py ongoing
1 hour:  1285 errors in  60000 requests, burn rate  21.4
 5 min:   250 errors in   5000 requests, burn rate  50.0
page
```

A hora queimou a 21,4 e os últimos cinco minutos a 50: as duas acima de 14,4, então chama, e deve
chamar. A mesma hora de erros, terminada vinte minutos antes:

```
ana@laptop:~/aws/slo$ python3 hour.py recovered
recovered: 120 data points published
ana@laptop:~/aws/slo$ python3 burn.py recovered
1 hour:  1285 errors in  60000 requests, burn rate  21.4
 5 min:     5 errors in   5000 requests, burn rate   1.0
no page
```

A hora é idêntica, 1.285 erros e queima de 21,4. Os últimos cinco minutos queimaram a 1,0, a taxa de um
erro por minuto que o serviço sempre tem. **Nenhum chamado**, porque não há nada a fazer: o incidente
acabou, e o orçamento que ele gastou agora é um número para a revisão. Uma única janela de uma hora
teria chamado aqui, vinte minutos depois da recuperação.

Os dados são sintéticos e as janelas são calculadas pelo programa a partir das somas do moto; o
CloudWatch faria o mesmo a partir das mesmas métricas com matemática de métricas, que a próxima seção
mostra, e que o moto não avalia.
