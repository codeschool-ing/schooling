---
title: A linha do tempo, montada a partir do que os sistemas registraram
version: 1
---

**Uma linha do tempo montada de memória é uma história; montada a partir de registros, é evidência.** Três fontes cobrem a
quinta. As requisições são as da lição 9. As outras duas são escritas aqui, pelo curso, que diz isso.

O **activity log** registra toda mudança feita pelo Resource Manager, numa tabela chamada `AzureActivity`: qual operação,
por quem, de onde, e se deu certo. Onze das mudanças da semana, no formato dela (a lição 21 lê esta tabela de verdade):

```kql
// activity.kql: the subscription's week of changes, in the shape of the AzureActivity table
.set-or-replace AzureActivity <|
datatable(TimeGenerated: datetime, OperationNameValue: string, ActivityStatusValue: string, Caller: string,
          CallerIpAddress: string, ResourceGroup: string, Resource: string, Properties: dynamic) [
    datetime(2026-10-12 13:14), "MICROSOFT.RESOURCES/DEPLOYMENTS/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "shop-main-41", dynamic({}),
    datetime(2026-10-12 13:21), "MICROSOFT.WEB/SITES/SLOTS/SLOTSSWAP/ACTION", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "app-shop-api/staging", dynamic({}),
    datetime(2026-10-13 18:40), "MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE", "Success", "ana@example.com", "203.0.113.24", "rg-shop", "rg-shop", dynamic({"role": "Monitoring Reader", "principal": "carla@example.com"}),
    datetime(2026-10-14 12:05), "MICROSOFT.RESOURCES/DEPLOYMENTS/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "shop-main-42", dynamic({}),
    datetime(2026-10-14 12:11), "MICROSOFT.WEB/SITES/SLOTS/SLOTSSWAP/ACTION", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "app-shop-api/staging", dynamic({}),
    datetime(2026-10-15 16:58), "MICROSOFT.SQL/SERVERS/DATABASES/WRITE", "Failure", "bruno@example.com", "198.51.100.7", "rg-shop", "sql-shop/shop", dynamic({"sku": "S1", "error": "AuthorizationFailed"}),
    datetime(2026-10-15 17:02), "MICROSOFT.SQL/SERVERS/DATABASES/WRITE", "Success", "bruno@example.com", "198.51.100.7", "rg-shop", "sql-shop/shop", dynamic({"sku": "S1", "previousSku": "S3"}),
    datetime(2026-10-15 17:44), "MICROSOFT.SQL/SERVERS/DATABASES/WRITE", "Success", "carla@example.com", "203.0.113.51", "rg-shop", "sql-shop/shop", dynamic({"sku": "S3", "previousSku": "S1"}),
    datetime(2026-10-16 14:30), "MICROSOFT.INSIGHTS/SCHEDULEDQUERYRULES/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "checkout-failing", dynamic({}),
    datetime(2026-10-17 21:12), "MICROSOFT.STORAGE/STORAGEACCOUNTS/DELETE", "Success", "ana@example.com", "203.0.113.24", "rg-test-ana", "sttestana01", dynamic({}),
    datetime(2026-10-18 10:03), "MICROSOFT.KEYVAULT/VAULTS/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "kv-shop-prod", dynamic({})
]
```

O **canal do incidente**, como tabela: o que as pessoas fizeram e quando, anotado enquanto faziam:

```kql
// incident-log.kql: what people did during Thursday's incident, as the incident channel recorded it
.set-or-replace IncidentLog <|
datatable(TimeGenerated: datetime, Who: string, What: string) [
    datetime(2026-10-15 17:15), "pager", "checkout burn-rate alert pages carla (on call)",
    datetime(2026-10-15 17:18), "carla@example.com", "acknowledged; checkout failing, SQL timeouts in AppDependencies",
    datetime(2026-10-15 17:22), "carla@example.com", "declared SEV2, carla incident commander, dani communications",
    datetime(2026-10-15 17:29), "dani@example.com", "status page: checkout failing for some customers, investigating",
    datetime(2026-10-15 17:38), "carla@example.com", "activity log: sql-shop/shop scaled S3 to S1 at 17:02 by bruno",
    datetime(2026-10-15 17:44), "carla@example.com", "scaled sql-shop/shop back to S3",
    datetime(2026-10-15 17:52), "carla@example.com", "checkout healthy for 5 minutes; mitigated",
    datetime(2026-10-15 18:05), "dani@example.com", "status page: resolved, postmortem to follow"
]
```

Salve os dois ao lado dos outros e carregue com `python3 kql.py < activity.kql` e `python3 kql.py < incident-log.kql`.
Depois ponha as três fontes num relógio só, no horário de São Paulo, porque é o horário de que as pessoas envolvidas se
lembram:

```kql
// timeline.kql: three sources, one clock, in São Paulo time
let since = datetime(2026-10-15 16:30);
let until = datetime(2026-10-15 18:30);
union
    (AzureActivity | where TimeGenerated between (since .. until)
        | project TimeGenerated, Source = "activity", Event = strcat(Caller, " ", OperationNameValue, " ", ActivityStatusValue, " ", tostring(Properties.sku))),
    (AppRequests | where Name == "POST /checkout" and TimeGenerated between (since .. until)
        | summarize failed = countif(not(Success)) by TimeGenerated = bin(TimeGenerated, 10m)
        | where failed > 0
        | project TimeGenerated, Source = "requests", Event = strcat(failed, " checkouts failed in 10 minutes")),
    (IncidentLog | project TimeGenerated, Source = "channel", Event = strcat(Who, ": ", What))
| project Local = format_datetime(datetime_utc_to_local(TimeGenerated, "America/Sao_Paulo"), "HH:mm"), Source, Event
| order by Local asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < timeline.kql
Local  Source    Event
13:58  activity  bruno@example.com MICROSOFT.SQL/SERVERS/DATABASES/WRITE Failure S1
14:00  requests  9 checkouts failed in 10 minutes
14:02  activity  bruno@example.com MICROSOFT.SQL/SERVERS/DATABASES/WRITE Success S1
14:10  requests  32 checkouts failed in 10 minutes
14:15  channel   pager: checkout burn-rate alert pages carla (on call)
14:18  channel   carla@example.com: acknowledged; checkout failing, SQL timeouts in AppDependencies
14:20  requests  20 checkouts failed in 10 minutes
14:22  channel   carla@example.com: declared SEV2, carla incident commander, dani communications
14:29  channel   dani@example.com: status page: checkout failing for some customers, investigating
14:30  requests  28 checkouts failed in 10 minutes
14:38  channel   carla@example.com: activity log: sql-shop/shop scaled S3 to S1 at 17:02 by bruno
14:40  requests  14 checkouts failed in 10 minutes
14:44  channel   carla@example.com: scaled sql-shop/shop back to S3
14:44  activity  carla@example.com MICROSOFT.SQL/SERVERS/DATABASES/WRITE Success S3
14:52  channel   carla@example.com: checkout healthy for 5 minutes; mitigated
15:05  channel   dani@example.com: status page: resolved, postmortem to follow
```

Leia de cima para baixo e o incidente se conta sozinho. Uma linha de `requests` leva o rótulo do começo do seu bin de
dez minutos, então a linha das 14:00 guarda as falhas a partir das 14:05. Às 13:58 `bruno` tentou mudar o tamanho do banco e foi recusado; às
14:02 conseguiu, **S1**, abaixo do S3. Três minutos depois os checkouts começaram a falhar. A chamada veio às 14:15, a
declaração às 14:22. Às 14:38 Carla achou a mudança no activity log, às 14:44 a desfez, e as falhas pararam dentro daquele bin de
dez minutos. A nota de Carla diz 17:02 porque ela copiou do log, em UTC, e é assim que dois relógios entram num canal só;
uma linha do tempo num fuso só resolve isso.

**A causa esteve no activity log o tempo todo.** Vinte e três minutos se passaram entre a chamada e olhar ali, e essa é a
conclusão que mais importa: a primeira pergunta de qualquer incidente é *o que mudou?*, e o activity log é onde o Azure
responde. O runbook da loja agora começa com esta consulta.
