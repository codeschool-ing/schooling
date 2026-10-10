---
title: InfluxDB, vendas por hora
version: 1
---

O InfluxDB guarda séries temporais: **medidas** com **tags**, **campos** e uma hora, escritas no line
protocol da aula 4. A versão 2 agrupa os dados em **buckets**, cada um com um **período de retenção**
depois do qual os dados dele são descartados.

A primeira subida consegue configurar tudo a partir de variáveis de ambiente: um usuário, uma
organização, um bucket chamado `sales` que guarda 30 dias, e um token de acesso, que o comando
`influx` dentro do contêiner passa a usar sozinho.

## Gerando os pontos

Três horas de vendas do show 1, um ponto por minuto para cada um de dois canais, a web e o aplicativo,
escritos em line protocol por um programinha salvo como `points.py`:

```python
# points.py
"""Three hours of ticket sales, one line per minute per channel, in line protocol."""
START = 1794776400  # 2026-11-15 18:00 in São Paulo, in seconds since 1970

for minute in range(180):
    for channel, share in (("web", 3), ("app", 2)):
        tickets = (minute * 7 + share * 11) % 9 + share
        print(f"sales,show=1,channel={channel} tickets={tickets}i {START + minute * 60}")
```

O número de ingressos por minuto vem de uma conta sobre o minuto, então toda rodada produz as mesmas
360 linhas. As horas estão em segundos, e é por isso que a escrita abaixo diz `-p s`, precisão em
segundos.

```
ana@lab:~/tickets$ docker run -d --name influx --memory 1g -e DOCKER_INFLUXDB_INIT_MODE=setup -e DOCKER_INFLUXDB_INIT_USERNAME=ana -e DOCKER_INFLUXDB_INIT_PASSWORD=lab-password -e DOCKER_INFLUXDB_INIT_ORG=sabia -e DOCKER_INFLUXDB_INIT_BUCKET=sales -e DOCKER_INFLUXDB_INIT_RETENTION=30d -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=lab-token influxdb:2.9.1
a6df716145711c625627aac4261ecd9b39a3826f718dc82f99e33e8d3c8c0f54
ana@lab:~/tickets$ python3 points.py > sales.lp
ana@lab:~/tickets$ head -3 sales.lp
sales,show=1,channel=web tickets=9i 1794776400
sales,show=1,channel=app tickets=6i 1794776400
sales,show=1,channel=web tickets=7i 1794776460
ana@lab:~/tickets$ docker cp sales.lp influx:/tmp/sales.lp
ana@lab:~/tickets$ docker exec influx influx write -b sales -p s -f /tmp/sales.lp
```

## Perguntando por hora

Uma consulta, salva como `hourly.flux`, na linguagem Flux do InfluxDB: ler o bucket nas três horas,
ficar com a medida `sales`, agrupar por canal, somar cada hora e manter três colunas:

```
// hourly.flux
from(bucket: "sales")
  |> range(start: 2026-11-15T21:00:00Z, stop: 2026-11-16T00:00:00Z)
  |> filter(fn: (r) => r._measurement == "sales")
  |> group(columns: ["channel"])
  |> aggregateWindow(every: 1h, fn: sum)
  |> keep(columns: ["_time", "channel", "_value"])
```

```
ana@lab:~/tickets$ docker cp hourly.flux influx:/tmp/hourly.flux
ana@lab:~/tickets$ docker exec influx influx query -f /tmp/hourly.flux
Result: _result
Table: keys: [channel]
        channel:string                      _time:time                  _value:int
----------------------  ------------------------------  --------------------------
                   app  2026-11-15T22:00:00.000000000Z                         357
                   app  2026-11-15T23:00:00.000000000Z                         357
                   app  2026-11-16T00:00:00.000000000Z                         366
Table: keys: [channel]
        channel:string                      _time:time                  _value:int
----------------------  ------------------------------  --------------------------
                   web  2026-11-15T22:00:00.000000000Z                         420
                   web  2026-11-15T23:00:00.000000000Z                         420
                   web  2026-11-16T00:00:00.000000000Z                         420
ana@lab:~/tickets$ docker exec influx influx bucket list --name sales
ID			Name	Retention	Shard group duration	Organization ID		Schema Type
d2ac90aec3114e1c	sales	720h0m0s	24h0m0s			512f1b194a989be8	implicit
ana@lab:~/tickets$ docker rm -f influx
influx
```

Duas tabelas, uma por canal, três horas cada: **420 ingressos por hora na web, 357 a 366 no
aplicativo**. As horas estão em UTC e cada linha leva o **fim** da sua hora, então `22:00Z` é a hora
das 18:00 às 19:00 em São Paulo. O `aggregateWindow` é a redução de amostragem da aula 4 feita na
hora da consulta; o InfluxDB também consegue rodá-la como tarefa agendada que grava as somas por hora
num segundo bucket com retenção maior, e deixa os pontos brutos expirarem.

O `bucket list` mostra a retenção, **720 horas**, trinta dias, definida quando o bucket foi criado. Um
ponto mais velho que isso é removido pelo InfluxDB sem ninguém apagar nada. Remova o contêiner quando
terminar.
