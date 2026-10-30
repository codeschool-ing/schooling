---
title: Requisições, dependências e o id que as junta
version: 1
---

**O Application Insights é a parte do Azure Monitor que observa uma aplicação por dentro.** Um SDK ou uma distribuição
OpenTelemetry na aplicação, assunto da lição 13, registra o que o código faz e envia a um recurso do Application
Insights, que guarda num workspace do Log Analytics, em tabelas próprias:

| tabela | uma linha para |
|---|---|
| `AppRequests` | cada requisição que a aplicação atendeu |
| `AppDependencies` | cada chamada que ela fez ao atender uma: SQL, HTTP, uma fila, um cache |
| `AppExceptions` | cada exceção que ela registrou |
| `AppTraces` | cada linha de log que a aplicação escreveu |
| `AppMetrics`, `AppPerformanceCounters` | números que o SDK coletou |

O que faz delas mais que cinco listas é o **`OperationId`**: toda linha produzida ao atender uma requisição leva o mesmo
valor, então uma requisição e tudo o que ela fez podem ser remontados. (Na visão de consulta clássica do Application
Insights o mesmo campo se chama `operation_Id`; as tabelas do workspace o escrevem `OperationId`.)

A lição 9 carregou a `AppRequests`. Esta lição acrescenta a `AppDependencies`, gerada a partir dela do mesmo jeito e
dizendo isso: toda requisição de escrita faz uma chamada SQL, todo checkout também chama o provedor de pagamentos, e os
checkouts do incidente de quinta fizeram chamadas SQL que levaram três segundos, falhando com `-2`, que é o código que o
cliente SQL do .NET informa para um timeout. Salve como `dependencies.kql` ao lado dos outros arquivos:

```kql
// dependencies.kql: the calls each write request made, in the shape of AppDependencies
.set-or-replace AppDependencies <|
AppRequests
| where Name in ("POST /cart", "POST /checkout")
| extend slow = DurationMs > 2000
| project TimeGenerated, OperationId, Name = iff(Name == "POST /cart", "INSERT basket_items", "INSERT orders"),
    Target = "sql-shop.database.windows.net | shop", DependencyType = "SQL",
    ResultCode = iff(slow and not(Success), "-2", "0"), Success = not(slow and not(Success)),
    DurationMs = iff(slow, iff(Success, 2900.0, 3000.0), round(DurationMs * 0.4, 1)), AppRoleName, ItemCount
| union (
    AppRequests
    | where Name == "POST /checkout" and not(DurationMs > 2000 and not(Success))
    | project TimeGenerated, OperationId, Name = "POST /v1/charges", Target = "api.payments.example",
        DependencyType = "HTTP", ResultCode = "201", Success = true, DurationMs = round(DurationMs * 0.3, 1),
        AppRoleName, ItemCount)
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < dependencies.kql | cut -c1-80
ExtentId                              OriginalSize  ExtentSize  CompressedSize  
b7ff82e8-7784-49f0-a4de-b31f92a1ba02  11208972.0    1442364.0   1045705.0       
ana@laptop:~/azure/kusto$ python3 kql.py 'AppDependencies | summarize calls = count(), failed = countif(not(Success)) by DependencyType, Target'
DependencyType  Target                                calls  failed
HTTP            api.payments.example                  29760  0
SQL             sql-shop.database.windows.net | shop  62446  103
```

A resposta está cortada em 80 colunas aqui; a tabela que ela cria tem umas 62.000 chamadas SQL e 30.000 chamadas ao
provedor de pagamentos, e as 103 falhas são todas SQL. Como a `AppRequests`, a tabela real tem muito mais colunas, entre
elas `Data` com o texto do SQL, e o curso fica com as que usa.
