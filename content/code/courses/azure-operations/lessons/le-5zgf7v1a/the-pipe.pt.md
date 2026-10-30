---
title: Uma tabela entra, uma fila de operadores, uma resposta sai
version: 1
---

**Uma consulta KQL começa com uma tabela e a passa por operadores, da esquerda para a direita, separados por uma
barra vertical, `|`.** Cada operador recebe uma tabela e entrega uma tabela ao próximo. Não há uma ordem `SELECT …
FROM … WHERE` para decorar: você escreve os passos na ordem em que acontecem.

Toda consulta desta lição roda no emulador da lição 9, sobre a semana em `AppRequests`. Se o emulador reiniciou desde
então, recrie o banco e carregue o `requests.kql` de novo primeiro; a lição 9, seção 02, tem os dois comandos. Depois,
de `~/azure/kusto`:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where Success == false | take 3'
TimeGenerated         OperationId  Name           ResultCode  Success  DurationMs  AppRoleName  ItemCount
2026-10-12T11:36:16Z  op-15488     GET /products  500         False    125.0       shop-api     1
2026-10-12T11:39:30Z  op-15585     GET /products  500         False    75.0        shop-api     1
2026-10-12T13:14:26Z  op-18433     GET /products  500         False    125.0       shop-api     1
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where Sucess == false | take 3'
400 BadRequest: General_BadRequest: Request is invalid and cannot be executed.
Error details:
ClientRequestId='unspecified;72a22276-ec08-48ad-8a0e-afae39576c9d', ActivityId='f5b58c1e-33c9-4883-a470-4853bde9c1eb', Timestamp='2026-10-30T18:43:59.0190847Z'.
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | getschema | project ColumnName, ColumnType'
ColumnName     ColumnType
TimeGenerated  datetime
OperationId    string
Name           string
ResultCode     string
Success        bool
DurationMs     real
AppRoleName    string
ItemCount      long
```

A primeira consulta fica com as requisições que falharam e **pega**, com `take`, três delas, quaisquer três: o `take`
não promete ordem, o que o torna o jeito mais rápido de ver como uma tabela é e o jeito errado de responder qualquer
coisa.

A segunda tem um erro de digitação, `Sucess`, e mostra algo deste laboratório que vale saber cedo: **o emulador recusa a
consulta e não diz por quê.** O editor de consultas de um workspace do Log Analytics nomeia a coluna que não consegue
resolver e a sublinha; o emulador responde `General_BadRequest` para todo erro. Então, quando uma consulta for recusada
aqui, confira os nomes primeiro, e o `getschema`, a terceira consulta, lista toda coluna de uma tabela com o tipo.
Strings também são comparadas diferenciando maiúsculas com `==`: `Name == "post /checkout"` não acha nada, e `=~` é a
comparação que ignora maiúsculas.

## Filtrando, e o tempo

`where` fica com as linhas para as quais uma condição é verdadeira. Condições se combinam com `and`, `or` e `not()`, e
o tempo tem as suas conveniências: `between (início .. fim)`, em que o fim pode ser uma duração somada ao início.

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where TimeGenerated between (datetime(2026-10-15 17:00) .. 1h) and Name == "POST /checkout" and not(Success) | top 4 by TimeGenerated asc | project TimeGenerated, ResultCode, DurationMs'
TimeGenerated         ResultCode  DurationMs
2026-10-15T17:05:12Z  500         3130.0
2026-10-15T17:05:44Z  500         3151.0
2026-10-15T17:06:00Z  500         3139.0
2026-10-15T17:06:24Z  500         3089.0
```

**`top 4 by TimeGenerated asc`** ordena e fica com as quatro primeiras, o que o `take` não teria feito, e **`project`**
fica só com as colunas nomeadas, nessa ordem. A resposta é o primeiro momento do incidente que a lição 9 plantou:
quinta, 17:05:12, três segundos por checkout que falhou.

**Todo horário num workspace é UTC**, e 17:05 não é o que alguém em São Paulo lembra. Converta para quem lê, nunca para
o filtro:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize started = min(TimeGenerated), ended = max(TimeGenerated), failures = count() | extend started_local = datetime_utc_to_local(started, "America/Sao_Paulo")'
started               ended                 failures  started_local
2026-10-15T17:05:12Z  2026-10-15T17:46:28Z  103       2026-10-15T14:05:12Z
```

Esta consulta também antecipa a próxima seção: o `summarize` transformou 103 checkouts lentos que falharam numa linha só,
com o primeiro e o último deles. 14:05 em São Paulo, até 14:46.
