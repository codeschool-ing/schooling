---
title: Uma semana de requisições da loja
version: 1
---

**Os dados deste curso são gerados, por uma consulta, e o curso diz isso.** Nenhum log de loja real está aqui. Um comando
monta uma semana de requisições no formato da tabela `AppRequests` do Application Insights, a tabela que a lição 11
explica, e toda lição que precisa dela a carrega do mesmo jeito. Salve como `requests.kql` ao lado do `kql.py`:

```kql
// requests.kql: one week of the shop's requests, in the shape of Application Insights' AppRequests table
.set-or-replace AppRequests <|
range i from 0 to 302399 step 1
| extend TimeGenerated = datetime(2026-10-12 03:00) + i * 2s
| extend hour = hourofday(TimeGenerated - 3h)
| where abs(hash(i, 1000)) < iff(hour between (1 .. 6), 300, 1000)
| extend h = abs(hash(i * 3, 1000))
| extend Name = case(h < 500, "GET /products", h < 750, "GET /cart", h < 880, "POST /cart", "POST /checkout")
| extend broken = Name == "POST /checkout" and TimeGenerated between (datetime(2026-10-15 17:05) .. datetime(2026-10-15 17:47))
| extend ResultCode = case(broken and h % 3 != 0, "500", abs(hash(i * 5, 1000)) == 0, "500", "200")
| extend DurationMs = round(35.0 + abs(hash(i * 7, 120)) + iff(abs(hash(i * 11, 100)) == 0, 900.0, 0.0) + iff(broken, 3000.0, 0.0), 1)
| project TimeGenerated, OperationId = strcat("op-", tostring(i)), Name, ResultCode, Success = ResultCode == "200",
    DurationMs, AppRoleName = "shop-api", ItemCount = 1
```

Ela se lê numa passada, de cima para baixo, que é como todo KQL se lê. `range` faz uma linha a cada dois segundos a
partir da meia-noite em São Paulo da segunda-feira, 12 de outubro de 2026, que é 03:00 em UTC, o fuso em que todo
workspace guarda. `hash()` dá a cada linha um número pseudoaleatório fixo, então a semana é a mesma no seu computador e
no computador em que o curso foi gravado. Entre 01:00 e 07:00 no horário local, sete linhas em dez são descartadas,
porque uma loja é mais calma de madrugada. Cada requisição ganha uma rota, um resultado e uma duração, e na quinta, das
14:05 às 14:47 no horário local, dois em cada três checkouts falham e levam três segundos a mais. **Essa janela é o
incidente** que as lições 10, 11, 14 e 15 investigam; por enquanto, são só linhas.

`.set-or-replace` roda a consulta e guarda o resultado como a tabela, substituindo qualquer tabela com esse nome, então
carregar duas vezes não faz mal:

```
ana@laptop:~/azure/kusto$ python3 kql.py < requests.kql
ExtentId                              OriginalSize  ExtentSize  CompressedSize  IndexSize  RowCount
3b700688-db65-47e5-8021-6a4c8850c5f7  21074527.0    2562450.0   1719652.0       842798.0   249717
```

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | count'
Count
249717
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | take 3'
TimeGenerated         OperationId  Name           ResultCode  Success  DurationMs  AppRoleName  ItemCount
2026-10-12T03:00:00Z  op-0         GET /cart      200         True     94.0        shop-api     1
2026-10-12T03:00:02Z  op-1         GET /products  200         True     112.0       shop-api     1
2026-10-12T03:00:04Z  op-2         GET /products  200         True     93.0        shop-api     1
```

249.717 linhas. A resposta do comando é a primeira coisa que vale ler: **`OriginalSize` é o tamanho dos dados como
chegaram, cerca de 21 MB**, e `ExtentSize`, cerca de 2,6 MB, é o que o motor guarda de fato depois de comprimir e
indexar. A ingestão é cobrada pelo primeiro número, não pelo segundo. A próxima seção transforma isso em dinheiro.
