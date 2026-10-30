---
title: O que um registro guarda
version: 1
---

**O activity log registra operações do plano de controle: requisições ao Resource Manager que criam, mudam ou apagam algo, e
algumas ações sobre recursos.** Ele não registra operações do plano de dados: ler um blob, consultar um banco ou buscar um
segredo não estão nele; isso está nos logs de recurso de cada serviço, os diagnostic settings da lição 8. Essa fronteira decide o
que esta lição consegue responder: *quem apagou a conta de armazenamento* está no activity log; *quem leu o arquivo dentro dela*
não está.

A lição 15 carregou doze registros da semana, escritos pelo curso no formato da tabela `AzureActivity`, com uma linha por operação
concluída. Carregue o `activity.kql` de novo se o emulador reiniciou. Um deles, inteiro:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where Resource == "sttestana01"'
TimeGenerated         OperationNameValue                        ActivityStatusValue  Caller           CallerIpAddress  ResourceGroup  Resource     Properties
2026-10-17T21:12:00Z  MICROSOFT.STORAGE/STORAGEACCOUNTS/DELETE  Success              ana@example.com  203.0.113.24     rg-test-ana    sttestana01  {}
```

As colunas que respondem perguntas:

- **`OperationNameValue`**: a operação, como o provedor de recursos a nomeia, terminando em `WRITE`, `DELETE` ou `ACTION`;
- **`ActivityStatusValue`**: na tabela real uma operação escreve várias linhas, `Start`, `Accepted`, depois `Success` ou
  `Failure`; o curso fica com a última;
- **`Caller`**: o nome de usuário para uma pessoa, ou um id de objeto ou de aplicação para um service principal ou identidade
  gerenciada, e por isso a esteira aparece como um GUID;
- **`CallerIpAddress`**: de onde uma pessoa chamou; vazio para os próprios serviços do Azure;
- **`Properties`**: o que mais o provedor escreveu, uma coluna dinâmica, como o SKU novo.

A tabela real tem mais, inclusive `CorrelationId`, que amarra as linhas de uma operação, e `Authorization`, com o papel que a
permitiu.
