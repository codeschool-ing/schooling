---
title: Summarize, e a média que mente
version: 1
---

**O `summarize` transforma muitas linhas em poucas: uma por grupo, com as agregações que você pedir.** É o operador em
que a maioria das perguntas termina. Uma consulta longa o bastante para querer ser lida duas vezes vai num arquivo,
enviado com `python3 kql.py < arquivo.kql`:

```kql
// thursday.kql: how each route did on Thursday, in São Paulo's day
AppRequests
| where TimeGenerated between (datetime(2026-10-15 03:00) .. 1d)
| summarize requests = count(), failed = countif(not(Success)) by Name
| extend failed_pct = round(100.0 * failed / requests, 2)
| order by failed desc
```

```

```

`count()` e `countif()` agregam por `Name`; `extend` acrescenta uma coluna calculada a partir das outras, e `100.0` em
vez de `100` faz a divisão ser real em vez de inteira. Leia a resposta como um operador leria. Três rotas falharam em
torno de uma requisição em mil ou menos, que é o ruído de fundo que todo serviço tem. **O checkout falhou 2,6% das
vezes, no dia inteiro.** Diluída em 24 horas, uma queda de 42 minutos em que dois checkouts em três falharam parece um
dia ruim, e não um incidente; a lição 14 transforma isso na diferença entre uma taxa de erro e um orçamento de erro.

## Percentis

A lição 8 avisou que a média esconde as requisições lentas. Aqui está a semana, dos dois jeitos:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | summarize avg = round(avg(DurationMs), 1), p50 = round(percentile(DurationMs, 50)), p95 = round(percentile(DurationMs, 95)), p99 = round(percentile(DurationMs, 99)) by Name'
Name            avg    p50   p95    p99
GET /cart       103.3  95.0  150.0  756.0
GET /products   103.2  95.0  150.0  154.0
POST /cart      104.1  95.0  150.0  940.0
POST /checkout  118.7  96.0  150.0  997.0
```

A média de toda rota fica em cerca de 103 ms e a mediana em cerca de 95. O percentil 95 é 150 para as quatro: 95
requisições em 100 terminaram em até 150 ms. **O 99 é onde as rotas se separam.** Uma requisição em cem em `GET /cart`,
`POST /cart` e no checkout levou perto de um segundo, enquanto `GET /products` ficou em 154 ms. Nada nas médias diz isso.
O `percentile()` calcula uma estimativa, muito próxima para tantas linhas, e o objetivo de latência da loja na lição 14
é escrito como percentil exatamente por isso: o cliente sente a cauda lenta, não a média.
