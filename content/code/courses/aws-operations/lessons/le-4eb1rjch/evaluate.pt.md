---
title: Avaliando um alarme você mesmo, porque o moto não avalia
version: 1
---

Dez minutos na vida da API da loja: calma, depois erros acima de 10 na maioria dos minutos, depois nada.
O laço publica um ponto por minuto, no passado, de onze minutos atrás até quatro minutos atrás; nos
últimos três minutos não publica nada, como uma API que caiu não publica nada:

```sh
now=$(date -u +%s)
for pair in 11:0 10:1 9:0 8:12 7:15 6:0 5:14 4:16; do
  m=${pair%:*} v=${pair#*:}
  aws cloudwatch put-metric-data --namespace Shop --metric-name Errors5xx \
    --dimensions Service=api --unit Count --value "$v" \
    --timestamp "$(date -u -d "@$((now - m * 60))" +%Y-%m-%dT%H:%M:%SZ)"
done
```

```
ana@laptop:~/aws/alarms$ aws cloudwatch describe-alarms --alarm-names api-errors --query 'MetricAlarms[0].[StateValue,StateReason]' --output text
OK	Unchecked: Initial alarm creation
```

Os dados estão lá e o alarme continua `OK`, sem avaliação. O que o CloudWatch teria decidido é uma
pergunta com resposta precisa, e um programa curto consegue dá-la. É um **modelo da avaliação que a
AWS documenta**, não o código do CloudWatch: ele lê os pontos de volta com o `boto3`, a biblioteca
Python sobre a qual a linha de comando da AWS é feita (o moto a instalou), e aplica M de N minuto a
minuto, com cada um dos quatro jeitos de tratar dado ausente:

```python
# alarm.py: what CloudWatch would decide, minute by minute, for one alarm
import datetime as dt
import sys

import boto3

THRESHOLD, M, N = 10, 3, 5            # 3 of the last 5 minutes above 10
TREAT = sys.argv[1] if len(sys.argv) > 1 else "missing"

now = dt.datetime.now(dt.timezone.utc).replace(second=0, microsecond=0)
minutes = [now - dt.timedelta(minutes=k) for k in range(12, 0, -1)]
points = boto3.client("cloudwatch").get_metric_statistics(
    Namespace="Shop", MetricName="Errors5xx",
    Dimensions=[{"Name": "Service", "Value": "api"}],
    StartTime=minutes[0], EndTime=now, Period=60, Statistics=["Sum"],
)["Datapoints"]
value = {p["Timestamp"].replace(second=0, microsecond=0): p["Sum"] for p in points}

state = "INSUFFICIENT_DATA"
for i, minute in enumerate(minutes):
    window = [value.get(m) for m in minutes[max(0, i - N + 1):i + 1]]
    if TREAT == "breaching":
        window = [THRESHOLD + 1 if v is None else v for v in window]
    elif TREAT == "notBreaching":
        window = [0 if v is None else v for v in window]
    present = [v for v in window if v is not None]
    if not present:
        state = state if TREAT == "ignore" else "INSUFFICIENT_DATA"
    elif sum(v > THRESHOLD for v in present) >= M:
        state = "ALARM"
    elif TREAT != "ignore" or len(present) == len(window):
        state = "OK"
    shown = "-" if value.get(minute) is None else int(value[minute])
    print(f"{minute:%H:%M}  {shown:>3}  {state}")
```

Os quatro tratamentos só diferem no que um minuto sem dado vale: **`notBreaching`** o conta como bom,
`breaching` como ruim, `missing` o deixa de fora (e sem nada sobrando, o estado é
`INSUFFICIENT_DATA`), `ignore` mantém o alarme no estado em que estava. As horas impressas são UTC.

## O alarme que ficou quieto quando o serviço morreu

O alarme da loja trata dado ausente como bom:

```
ana@laptop:~/aws/alarms$ python3 alarm.py notBreaching
16:29    -  OK
16:30    0  OK
16:31    1  OK
16:32    0  OK
16:33   12  OK
16:34   15  OK
16:35    0  OK
16:36   14  ALARM
16:37   16  ALARM
16:38    -  ALARM
16:39    -  OK
16:40    -  OK
```

Leia a coluna da direita de cima para baixo. Os erros começam às 16:33; às 16:36, três dos últimos
cinco minutos estão acima de 10, e o alarme dispara. Aí **a API para de publicar de vez**, e dois
minutos depois o alarme volta a `OK`. Os três últimos minutos não têm dado, `notBreaching` os conta
como bons, e só sobram dois minutos ruins na janela. **A pior queda da hora, um serviço fora do ar, é
lida como recuperação.**

Os mesmos dados nos outros tratamentos:

```
ana@laptop:~/aws/alarms$ python3 alarm.py breaching | tail -4
16:37   16  ALARM
16:38    -  ALARM
16:39    -  ALARM
16:40    -  ALARM
ana@laptop:~/aws/alarms$ python3 alarm.py ignore | tail -4
16:37   16  ALARM
16:38    -  ALARM
16:39    -  ALARM
16:40    -  ALARM
```

`breaching` e `ignore` mantêm o alarme em `ALARM` durante o silêncio. Qual está certo depende do que o
silêncio significa para a métrica:

| a métrica | o silêncio significa | tratar dado ausente como |
|---|---|---|
| erros contados por um filtro de métrica com `defaultValue=0` | nada a contar | `notBreaching`: o zero é publicado, silêncio de verdade é raro |
| erros publicados pela própria aplicação | a aplicação pode ter caído | `breaching`, ou um segundo alarme na pulsação |
| o sucesso de um job noturno, uma vez por noite | o job não rodou | `breaching` |
| latência de um serviço sem tráfego à noite | nenhuma requisição, nada de errado | `notBreaching` ou `ignore` |

O primeiro alarme da loja foi configurado para a primeira linha e alimentado pela segunda. Esse
desencontro é a lição; a correção é `breaching`, ou **um alarme separado no próprio tráfego**, que
dispara quando as requisições por minuto caem a zero. Na AWS, a avaliação teria acontecido a cada
minuto sem ninguém rodar nada, e as decisões da coluna da direita são as que o CloudWatch documenta
para esta configuração; elas foram calculadas aqui, não observadas.
