---
title: Um stream do Kinesis como origem, e quanto custa
version: 1
---

**Um delivery stream pode ler um data stream do Kinesis em vez de receber escrita direta**, e esse é o
jeito de costume de os dois se encontrarem. O stream da lição 20 serve os programas que precisam de
cada evento em segundos; o Firehose vira mais um consumidor dele, e o trabalho inteiro dele é guardar
uma cópia de tudo no S3, muito depois de a retenção do stream ter apagado. A lição 20 terminou nisso: a
resposta a "reprocessar o mês passado" não é uma retenção maior, é o lago.

A origem é dada na criação, com o ARN do stream e um papel com que o Firehose pode lê-lo:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders --shard-count 1
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-from-stream --delivery-stream-type KinesisStreamAsSource --kinesis-stream-source-configuration KinesisStreamARN=arn:aws:kinesis:sa-east-1:123456789012:stream/orders,RoleARN=arn:aws:iam::123456789012:role/quitanda-firehose --extended-s3-destination-configuration RoleARN=arn:aws:iam::123456789012:role/quitanda-firehose,BucketARN=arn:aws:s3:::quitanda-raw-prod,Prefix=raw/orders-from-stream/
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-from-stream"
}
ana@laptop:~/aws$ aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-206"}'
{
    "ShardId": "shardId-000000000000",
    "SequenceNumber": "1"
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-from-stream/ --recursive
ana@laptop:~/aws$ aws firehose put-record --delivery-stream-name orders-from-stream --cli-binary-format raw-in-base64-out --record '{"Data": "{\"order_id\": \"o-207\"}"}'
{
    "RecordId": "f383c9d0-1712-4940-97a2-e4fb97647365",
    "Encrypted": false
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-from-stream/ --recursive
2026-10-16 13:11:02         21 raw/orders-from-stream/2026/10/16/16/orders-from-stream-1-2026-10-16-16-11-02-a9dd7281-348b-4cab-b031-0bc8fd1b7f28
```

**O moto não ligou nada.** O registro posto no stream do Kinesis nunca chegou ao bucket, cuja listagem
voltou vazia; o moto guarda a origem na configuração e não lê dela. Depois aceitou um `put-record`
mandado direto ao delivery stream e entregou esse. A AWS faz o contrário nos dois pontos, pela
documentação dela: um delivery stream com origem no Kinesis lê o stream continuamente, e recusa
`PutRecord` e `PutRecordBatch`, porque os registros dele só podem vir do stream. Então o par pode ser
configurado no laboratório e não observado.

Na AWS o delivery stream lê o stream como qualquer outro consumidor, então divide com os outros
consumidores comuns da lição 20 os 2 MB por segundo de leitura dos shards, e lê cada shard em ordem. A
ordem dentro de um objeto é, portanto, a ordem de um shard, e registros de shards diferentes se
intercalam, como no consumidor da lição 20.

## A conta

```
ana@laptop:~/aws$ python3 prices.py kinesis
AWS public price list, sa-east-1, USD, excluding tax

Kinesis Data Streams, USD
  provisioned, per shard-hour                           0.03000  hour
  provisioned, per million PUT payload units            0.02800  million
  provisioned, extended retention, per shard-hour       0.04000  hour
  on demand, per stream-hour                            0.08000  hour
  on demand, data written                               0.16000  GB
  on demand, data read                                  0.08000  GB

Data Firehose, USD per GB
  ingested, first 500 TB                                0.05800  GB
  format conversion                                     0.03500  GB
  dynamic partitioning                                  0.03100  GB
```

**A ingestão é cobrada por gigabyte, mas não por gigabyte enviado.** A página de preços da AWS, de
onde esta tabela lê o preço mas não a regra, diz que cada registro é arredondado para cima até os
próximos 5 KB antes de ser contado. Para os eventos de pedido da Quitanda, 20 milhões de registros por
dia de cerca de 1 KB cada, essa regra é a conta inteira:

| ingestão, um evento por registro | conta | USD por mês |
|---|---|---|
| tamanho cobrado | 20 milhões × 5 KB = 100 GB por dia, × 30 dias = 3.000 GB | |
| ingestão | 3.000 × 0,05800 | 174,00 |

**Cinco vezes os dados que foram enviados**, porque cada registro de 1 KB conta como 5 KB. Juntar cinco
eventos num registro de 5 KB, o que o produtor faz unindo cinco linhas de JSON com as quebras de linha
delas, manda os mesmos bytes como 4 milhões de registros por dia:

| ingestão, cinco eventos por registro | conta | USD por mês |
|---|---|---|
| tamanho cobrado | 4 milhões × 5 KB = 20 GB por dia, × 30 dias = 600 GB | |
| ingestão | 600 × 0,05800 | 34,80 |
| conversão para Parquet | 600 × 0,03500 | 21,00 |
| particionamento dinâmico por loja | 600 × 0,03100 | 18,60 |
| **total** | | **74,40** |

**Juntar custa uma linha no produtor e poupa 139,20 por mês**, e é invisível no laboratório, onde o
moto não conta nada. As duas linhas opcionais são cobradas sobre os mesmos gigabytes; o particionamento
dinâmico também tem cobranças por objeto escrito e por hora de processamento `jq` que a tabela não
imprime, então a linha real dele é um pouco maior que 18,60. E o S3 em que os objetos caem é cobrado à
parte, aos preços de armazenamento da lição 2.

Ao lado da lição 20, o desenho fica claro: um stream do Kinesis provisionado para os mesmos eventos
custou 82,50 por mês, e não entrega nada em lugar nenhum sozinho. O Firehose custa mais ou menos o
mesmo de novo e escreve o lago, já particionado e em Parquet, sem programa seu rodando. Quando o único
consumidor seria um programa que copia o stream para o S3, o delivery stream é esse programa, já
escrito, e um produtor pode pôr registros nele diretamente, sem stream do Kinesis nenhum.
