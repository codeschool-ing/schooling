---
title: Dimensionando um compromisso pelo piso
version: 1
---

**Um compromisso deve cobrir o uso que está sempre lá, e nada acima disso.** As exportações de pedidos da loja rodam num scale set
de workers `Standard_D4s_v5` que cresce no horário comercial. Um mês da contagem de instâncias, uma linha por hora, gerado no
formato que as métricas do scale set dariam e dizendo isso, vai em `usage.kql`:

```kql
// usage.kql: thirty days of the export workers' scale set, one row per hour, in instances running
.set-or-replace WorkerHours <|
range TimeGenerated from datetime(2026-09-19 03:00) to datetime(2026-10-19 02:00) step 1h
| extend hour = hourofday(TimeGenerated - 3h), weekday = dayofweek(TimeGenerated - 3h) / 1d
| extend busy = hour between (8 .. 19) and weekday between (1 .. 5)
| extend Instances = iff(busy, 4, 2) + iff(busy and abs(hash(TimeGenerated, 10)) < 3, 2, 0)
| project TimeGenerated, Instances, VmSize = "Standard_D4s_v5"
```

Duas instâncias rodam o tempo todo; em dias úteis das 08:00 às 19:00 em São Paulo ele roda quatro, e em algumas dessas horas,
seis. Carregue e olhe a forma antes de qualquer conta:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'WorkerHours | summarize hours = count(), min = min(Instances), p10 = percentile(Instances, 10), median = percentile(Instances, 50), max = max(Instances), avg = round(avg(Instances), 2)'
hours  min  p10  median  max  avg
720    2    2    2       6    2.87
ana@laptop:~/azure/kusto$ python3 kql.py 'WorkerHours | summarize hours = count() by Instances | order by Instances asc'
Instances  hours
2          480
4          166
6          74
```

**O piso é 2**: o mínimo e o percentil 10 concordam, e dois terços das 720 horas do mês rodaram exatamente duas. A média, 2,87, é
o número que as pessoas pegam, e é o errado: um compromisso de três ficaria parcialmente sem uso em 480 horas do mês. A mediana diz
o mesmo que o piso aqui; num uso com mais picos, o percentil 10 é medida mais segura que o mínimo, que uma única hora calma fora do
comum consegue puxar para baixo.

Os dados que esta lição gera são um mês. Uma decisão real usa mais tempo, três meses pelo menos, para uma baixa sazonal entrar, e
pergunta se a carga vai existir pelo prazo inteiro: um compromisso de três anos em algo que vai ser substituído na próxima
primavera é uma conta por algo desligado.
