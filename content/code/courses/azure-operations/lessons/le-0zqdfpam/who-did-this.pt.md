---
title: Respondendo "quem fez isso?"
version: 1
---

**Três perguntas chegam toda semana, e cada uma é uma consulta.** A primeira: *quem apagou alguma coisa?*

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where OperationNameValue endswith "/DELETE" | project TimeGenerated, Caller, CallerIpAddress, ResourceGroup, Resource'
TimeGenerated         Caller           CallerIpAddress  ResourceGroup  Resource
2026-10-17T21:12:00Z  ana@example.com  203.0.113.24     rg-test-ana    sttestana01
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where Resource startswith "sql-shop" | project TimeGenerated, Caller, ActivityStatusValue, sku = tostring(Properties.sku), before = tostring(Properties.previousSku)'
TimeGenerated         Caller             ActivityStatusValue  sku  before
2026-10-15T16:58:00Z  bruno@example.com  Failure              S1
2026-10-15T17:02:00Z  bruno@example.com  Success              S1   S3
2026-10-15T17:44:00Z  carla@example.com  Success              S3   S1
```

Uma deleção, uma conta de armazenamento de teste em `rg-test-ana`, por `ana`, no sábado à noite. A segunda consulta responde a
pergunta de que a lição 15 precisou: tudo o que aconteceu com o banco, em ordem, com o SKU antes e depois, lido das `Properties`
com `tostring()`. Um valor dinâmico precisa ganhar um tipo antes de ser comparado ou exibido como texto.

A segunda pergunta: *o que cada identidade anda fazendo?*

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | summarize changes = count(), failed = countif(ActivityStatusValue == "Failure"), operations = make_set(tostring(split(OperationNameValue, "/")[-1])) by Caller | order by changes desc'
Caller                                changes  failed  operations
3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11  6        0       ['WRITE', 'ACTION']
ana@example.com                       3        0       ['WRITE', 'DELETE']
bruno@example.com                     2        1       ['WRITE']
carla@example.com                     1        0       ['WRITE']
```

`make_set()` junta os valores distintos de uma expressão num array, e `split(...)[-1]` pega a última parte do nome da operação. A
identidade da esteira fez seis mudanças, todas escritas e ações, que é o que uma esteira deve fazer. **Uma pessoa perto do topo
desta lista merece um olhar**, não porque pessoas não devam mudar coisas, mas porque toda mudança que uma pessoa faz no portal é
uma mudança que nenhum pull request revisou.

A terceira: *quem mudou quem tem acesso?*

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where OperationNameValue startswith "MICROSOFT.AUTHORIZATION/" | project TimeGenerated, Caller, OperationNameValue, Properties'
TimeGenerated         Caller           OperationNameValue                             Properties
2026-10-13T18:40:00Z  ana@example.com  MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE  {'role': 'Monitoring Reader', 'principal': 'carla@example.com'}
2026-10-15T16:59:00Z  ana@example.com  MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE  {'role': 'SQL DB Contributor', 'principal': 'bruno@example.com'}
```

Duas atribuições de papel, as duas por `ana`. A segunda é a que o postmortem da lição 15 achou: às 13:59 de quinta, um minuto
depois de Bruno ser recusado, `ana` deu a ele *SQL DB Contributor* em `rg-shop`, e o banco pôde ser redimensionado pelo portal.
Ninguém fez nada errado de um jeito que uma regra proíba, e é exatamente por isso que a ação do postmortem foi pôr o tamanho do
banco em Bicep, e por isso que atribuições de papel ganham um alerta na próxima seção.
