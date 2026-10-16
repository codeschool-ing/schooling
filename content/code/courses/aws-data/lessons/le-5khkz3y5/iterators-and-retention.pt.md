---
title: Iteradores, e por quanto tempo um shard se lembra
version: 1
---

**Ler um registro não o remove.** Uma fila entrega uma mensagem a um leitor e a esquece; um shard
guarda todo registro pelo seu **período de retenção**, seja quem for que o tenha lido, e cada leitor
guarda a própria posição. É isso que deixa dois programas lerem o mesmo stream com propósitos
diferentes, e que deixa um programa lê-lo de novo depois de um bug. A posição é um **iterador de
shard** (*shard iterator*), e onde ele começa é a primeira escolha de todo consumidor.

## Cinco lugares para começar

O `consumer.py` pediu `TRIM_HORIZON`. A linha de comando pode pedir os outros. Cada comando abaixo pega
um iterador no shard 0, que guarda os cinco registros de `c-17` e `c-03` da seção anterior, e o passa
direto ao `get-records`. O primeiro mostra um registro inteiro, o segundo decodifica o dado dele, e do
terceiro em diante cada resposta é só os números de sequência que voltaram:

```
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --limit 1
{
    "Records": [
        {
            "SequenceNumber": "1",
            "ApproximateArrivalTimestamp": "2026-10-16T12:49:57.155000-03:00",
            "Data": "eyJvcmRlcl9pZCI6ICJvLTEwMSIsICJjdXN0b21lcl9pZCI6ICJjLTE3IiwgInN0YXR1cyI6ICJwbGFjZWQifQ==",
            "PartitionKey": "c-17"
        }
    ],
    "NextShardIterator": "b3JkZXJzOnNoYXJkSWQtMDAwMDAwMDAwMDAwOjE=\n",
    "MillisBehindLatest": 49
}
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --limit 1 --query 'Records[0].Data' --output text | base64 -d; echo
{"order_id": "o-101", "customer_id": "c-17", "status": "placed"}
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
1	2	3	4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type LATEST --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type AT_SEQUENCE_NUMBER --starting-sequence-number 3 --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
3	4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type AFTER_SEQUENCE_NUMBER --starting-sequence-number 3 --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type AT_TIMESTAMP --timestamp $(date -d '10 minutes ago' +%s) --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
1	2	3	4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type LATEST --query ShardIterator --output text) && aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-105", "customer_id": "c-17", "status": "placed"}' --query SequenceNumber --output text && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
6
6
```

| tipo | começa em | para |
|---|---|---|
| `TRIM_HORIZON` | o registro mais antigo que o shard ainda guarda | ler tudo, ou reprocessar |
| `LATEST` | logo depois do registro mais novo | um consumidor que só se importa com o que acontecer daqui para frente |
| `AT_SEQUENCE_NUMBER` | aquele registro | retomar num registro que você não terminou |
| `AFTER_SEQUENCE_NUMBER` | o registro seguinte àquele | retomar depois do último registro que você terminou |
| `AT_TIMESTAMP` | o primeiro registro que chegou naquele horário ou depois | "reprocessar tudo desde as 09:00" |

**O `LATEST` não devolveu nada, e esse é o significado dele**: o iterador aponta para depois do
registro mais novo, então só vê o que for escrito depois que ele existe. O último comando prova isso:
pegou um iterador, escreveu um registro, que o `put-record` numerou 6, e o iterador devolveu
exatamente esse registro. Um consumidor que começa com `LATEST` depois de reiniciar pula tudo o que foi
escrito enquanto ele estava parado, e é por isso que um consumidor que não pode perder registros guarda
o último número de sequência que terminou e retoma com `AFTER_SEQUENCE_NUMBER`. Essa posição guardada
é um **checkpoint**, e a lição 23 mostra o que acontece quando um consumidor cai entre fazer o
trabalho e anotar um.

O `Data` de um registro vem em base64 quando a linha de comando o imprime, e é por isso que o segundo
comando passa por `base64 -d`. E um iterador vive pouco: a AWS documenta que ele expira cinco minutos
depois de emitido se não for usado, e um consumidor que dorme mais que isso precisa pedir um novo a
partir do checkpoint. O moto guarda os iteradores enquanto estiver rodando, então essa expiração não
foi vista aqui.

## Retenção

**Um registro fica no shard pelo período de retenção e depois é apagado, lido ou não.** O padrão é 24
horas. Dá para subir para 7 dias, 168 horas, e além disso até 365 dias:

```
ana@laptop:~/aws$ aws kinesis increase-stream-retention-period --stream-name orders --retention-period-hours 168
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders --query StreamDescriptionSummary.RetentionPeriodHours
168
ana@laptop:~/aws$ aws kinesis increase-stream-retention-period --stream-name orders --retention-period-hours 9000

aws: [ERROR]: An error occurred (InvalidArgumentException) when calling the IncreaseStreamRetentionPeriod operation: Maximum allowed retention period is 8760 hours. Requested retention period (9000 hours) is too long.
ana@laptop:~/aws$ aws kinesis decrease-stream-retention-period --stream-name orders --retention-period-hours 12

aws: [ERROR]: An error occurred (InvalidArgumentException) when calling the DecreaseStreamRetentionPeriod operation: Minimum allowed retention period is 24 hours. Requested retention period (12 hours) is too short.
```

**8.760 horas são 365 dias, e o moto recusou 9.000 com o próprio limite da AWS na mensagem.** Também
recusou descer abaixo de 24. O que o moto não faz é apagar nada: os registros dele ficam até ele
parar, diga a retenção o que disser, então a exclusão em si não foi rodada aqui. Na AWS, um registro
mais velho que o período de retenção some, e um consumidor que fica mais atrasado que isso perde
registros sem erro nenhum. O próximo `GetRecords` dele simplesmente começa no registro mais antigo que
sobrou, e `TRIM_HORIZON` passa a significar, em silêncio, um ponto mais tardio do que ontem.

**A retenção é o tamanho da sua segunda chance.** Com 24 horas, um bug achado na segunda de manhã num
consumidor publicado na sexta não se corrige reprocessando, porque os registros que ele tratou mal não
existem mais. Com 7 dias, se corrige. A última seção desta lição põe preço nessa diferença, e a lição
21 mostra a resposta de costume para histórico mais velho que qualquer retenção: uma cópia do stream no
S3.
