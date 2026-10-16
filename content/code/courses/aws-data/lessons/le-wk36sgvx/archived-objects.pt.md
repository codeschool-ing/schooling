---
title: Lendo de volta um objeto arquivado
version: 1
---

**Um objeto em Glacier Flexible Retrieval ou Deep Archive não pode ser lido até ser restaurado.** Ele
aparece na listagem, tem tamanho e ETag, o `head-object` o descreve, e um `GET` dos bytes dele é
recusado. As pessoas esperam uma leitura lenta; o que recebem é leitura nenhuma, e uma requisição à
parte que pede ao S3 uma cópia temporária legível, que chega horas depois. O Glacier Instant Retrieval
é a única classe de arquivo sem esse passo, e é o que o nome dela diz.

O bucket da seção anterior ainda guarda as quatro cópias. Peça duas delas:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-archive-prod/orders/2026-09/deep.csv back.csv
warning: Skipping file s3://quitanda-archive-prod/orders/2026-09/deep.csv. Object is of storage class GLACIER. Unable to perform download operations on GLACIER objects. You must restore the object to be able to perform the operation. See aws s3 download help for additional parameter options to ignore or force these transfers.
                                                              
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv back.csv

aws: [ERROR]: An error occurred (InvalidObjectState) when calling the GetObject operation: The operation is not valid for the object's storage class

Additional error details:
StorageClass: DEEP_ARCHIVE
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/instant.csv back.csv --query "[ContentLength,StorageClass]" --output text
10295	GLACIER_IR
```

**Duas recusas e uma resposta.** O `aws s3 cp` recusou antes de baixar qualquer coisa: pediu os
metadados do objeto, viu uma classe de arquivo, e pulou o arquivo com um aviso que chama o Deep Archive
de `GLACIER` também, a palavra da linha de comando para os dois. O `get-object` mandou a requisição
mesmo assim, e o moto respondeu como o S3 responde, com `InvalidObjectState`. A cópia em Glacier
Instant Retrieval voltou na hora, todos os 10.295 bytes.

## A restauração

Uma restauração diz por quantos dias a cópia legível deve viver e com que pressa fazê-la, o tier:

```
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv --restore-request "Days=2,GlacierJobParameters={Tier=Bulk}"
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv --query "[StorageClass,Restore]"
[
    "DEEP_ARCHIVE",
    "ongoing-request=\"false\", expiry-date=\"Sun, 18 Oct 2026 15:54:18 GMT\""
]
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv back.csv --query "[ContentLength,StorageClass]" --output text
10295	DEEP_ARCHIVE
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/deep2.csv --storage-class DEEP_ARCHIVE
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/deep2.csv
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/deep2.csv --restore-request "Days=1,GlacierJobParameters={Tier=Expedited}"
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --restore-request Days=1

aws: [ERROR]: An error occurred (InvalidObjectState) when calling the RestoreObject operation: The operation is not valid for the object's storage class

Additional error details:
StorageClass: STANDARD
ana@laptop:~/aws$ aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/instant.csv --restore-request Days=1

aws: [ERROR]: An error occurred (InvalidObjectState) when calling the RestoreObject operation: The operation is not valid for the object's storage class

Additional error details:
StorageClass: GLACIER_IR
```

**No moto a restauração termina antes do comando seguinte**: `ongoing-request="false"` já, e o `GET`
que falhou há um instante dá certo. Essa é a maior diferença entre o moto e o S3 nesta lição. Na AWS o
mesmo `head-object` imprimiria `ongoing-request="true"` enquanto a restauração durasse, e todo `GET`
continuaria falhando com `InvalidObjectState` até ela terminar. A AWS documenta as velocidades assim:

| classe | tier | a cópia fica pronta em |
|---|---|---|
| Glacier Flexible Retrieval | Expedited | 1 a 5 minutos |
| Glacier Flexible Retrieval | Standard | 3 a 5 horas |
| Glacier Flexible Retrieval | Bulk | 5 a 12 horas |
| Deep Archive | Standard | até 12 horas |
| Deep Archive | Bulk | até 48 horas |

Nada disso foi rodado aqui; é o comportamento documentado. **O Deep Archive não tem o tier Expedited**,
e o moto aceitou o pedido Expedited acima sem reclamar. O S3 o recusa. Um programa que restaura do Deep
Archive e só foi testado contra o moto pode ir para produção com um tier que o S3 nunca vai aceitar.

A cópia restaurada é temporária. Quando os dias dela acabam o objeto volta a ser ilegível, e pelos
dias em que ela vive você paga pelo objeto arquivado e pela cópia restaurada. O objeto nunca sai da
classe dele: o `StorageClass` acima ainda diz `DEEP_ARCHIVE` depois da restauração. Para trazê-lo de
volta de vez, restaure-o e depois copie-o sobre si mesmo em outra classe, como fez a seção anterior.

**Pedir a restauração de algo que não está arquivado é recusado**, como mostram os dois últimos
comandos acima: a cópia em Standard e a cópia em Glacier Instant Retrieval não têm nada a restaurar.

## O que as horas querem dizer para um projeto

Uma restauração medida em horas decide o que pode ir para uma classe de arquivo: dados de que ninguém
precisa hoje à tarde. As exportações de auditoria da Quitanda servem, porque o pedido de um auditor
chega com semanas de antecedência. Os pedidos do mês passado não servem, porque o time financeiro roda
de novo um relatório sobre eles sempre que um número parece errado, e um relatório que espera doze
horas pela entrada é um relatório que ninguém espera.
