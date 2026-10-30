---
title: Um indicador, contado a partir do que o cliente vê
version: 1
---

**Um indicador de nível de serviço é uma razão: eventos bons sobre eventos válidos.** Não é CPU, nem memória, nem número de
pods: essas são causas, e o cliente não sente nenhuma delas diretamente. Os indicadores da loja são sobre o checkout, a rota
em que uma falha perde uma venda, e são dois:

- **disponibilidade**: de todas as requisições de checkout, a fração que deu certo;
- **velocidade**: de todas as requisições de checkout, a fração que deu certo em até um segundo.

Os dois são contados na `AppRequests`, o registro do que os clientes receberam de fato. Por dia, com o dia tomado no
calendário de São Paulo e não no de UTC, porque é o dia sobre o qual o negócio presta contas:

```kql
// sli.kql: two indicators for checkout, per day: availability and speed
AppRequests
| where Name == "POST /checkout"
| summarize valid = count(), available = countif(Success), fast = countif(Success and DurationMs <= 1000)
    by day = bin(datetime_utc_to_local(TimeGenerated, "America/Sao_Paulo"), 1d)
| extend availability = round(100.0 * available / valid, 2), speed = round(100.0 * fast / valid, 2)
| order by day asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < sli.kql
day                   valid  available  fast  availability  speed
2026-10-12T00:00:00Z  4269   4264       4243  99.88         99.39
2026-10-13T00:00:00Z  4256   4253       4233  99.93         99.46
2026-10-14T00:00:00Z  4265   4260       4249  99.88         99.62
2026-10-15T00:00:00Z  4193   4084       4009  97.4          95.61
2026-10-16T00:00:00Z  4229   4226       4201  99.93         99.34
2026-10-17T00:00:00Z  4427   4424       4407  99.93         99.55
2026-10-18T00:00:00Z  4224   4222       4207  99.95         99.6
```

`datetime_utc_to_local()` passa cada horário para o horário local antes de o `bin()` cortá-lo em dias, então a coluna `day`
é uma data local, mesmo impressa com um `Z`. Seis dias ficam perto de 99,9% de disponibilidade e 99,5% de velocidade. **A
quinta teve 97,4% e 95,6%.** Esses dois números são o incidente, visto pelo único juiz que importa.

Duas escolhas na consulta são decisões, e não detalhes. **O indicador de velocidade conta uma falha rápida como ruim**
(`Success and DurationMs <= 1000`): um erro em 20 ms não é um checkout rápido. E **válida** é toda requisição de checkout;
uma equipe que excluísse, digamos, requisições de robôs poria esse filtro aqui, uma vez, onde todo mundo vê.
