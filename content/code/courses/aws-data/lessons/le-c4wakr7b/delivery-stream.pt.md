---
title: Um delivery stream, e os objetos que ele escreve
version: 1
---

**O Firehose é a parte de um pipeline de streaming que você não escreve.** Um data stream do Kinesis,
na lição 20, guarda registros e espera um programa lê-los; um **delivery stream** lê o que recebe,
junta em arquivos e escreve os arquivos em algum lugar, quase sempre o S3, sem código consumidor
nenhum. A AWS mudou o nome dele de Kinesis Data Firehose para Amazon Data Firehose em 2024, e a linha
de comando ainda o chama de `aws firehose`. A imagem errada a largar primeiro é a de que ele escreve um
objeto por registro. Ele escreve um objeto por **buffer**: os registros ficam guardados até se juntarem
bytes ou segundos suficientes, e então são escritos juntos.

O terminal é o da lição 1: o moto rodando no terminal dele e as quatro linhas de "O seu laboratório, em resumo" da lição 1 digitadas neste, com o moto ligado vazio. Um delivery stream precisa de um
destino, e o destino é descrito num arquivo. Salve este em `~/aws`:

`orders-to-s3.json`:

```json
{
  "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
  "BucketARN": "arn:aws:s3:::quitanda-raw-prod",
  "Prefix": "raw/orders/",
  "ErrorOutputPrefix": "errors/orders/",
  "BufferingHints": {"SizeInMBs": 64, "IntervalInSeconds": 300},
  "CompressionFormat": "UNCOMPRESSED"
}
```

**Quatro dessas linhas são a ideia inteira.** `BucketARN` e `Prefix` dizem para onde vão os objetos,
`BufferingHints` diz quando um buffer é escrito, e `ErrorOutputPrefix` diz para onde vão os registros
que não puderam ser entregues como pedido. `RoleARN` nomeia o papel do IAM que o Firehose assume para
escrever no bucket; o moto nunca confere se o papel existe, e na AWS ele precisa existir e confiar em
`firehose.amazonaws.com`, o padrão da lição 9 de `aws-foundations`.

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-to-s3 --delivery-stream-type DirectPut --extended-s3-destination-configuration file://orders-to-s3.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-to-s3"
}
ana@laptop:~/aws$ aws firehose describe-delivery-stream --delivery-stream-name orders-to-s3 --query 'DeliveryStreamDescription.[DeliveryStreamStatus,DeliveryStreamType,Destinations[0].ExtendedS3DestinationDescription.BufferingHints]'
[
    "ACTIVE",
    "DirectPut",
    {
        "SizeInMBs": 64,
        "IntervalInSeconds": 300
    }
]
```

## Três chamadas, três objetos

`put-record` manda um registro e `put-record-batch` manda até 500 numa requisição. Mais dois arquivos
de registros, o segundo com uma quebra de linha no fim de cada um, salvos ao lado do primeiro:

`batch.json`:

```json
[
  {"Data": "{\"order_id\": \"o-201\", \"customer_id\": \"c-17\", \"total_cents\": 4590}"},
  {"Data": "{\"order_id\": \"o-202\", \"customer_id\": \"c-02\", \"total_cents\": 12800}"}
]
```

`batch-nl.json`:

```json
[
  {"Data": "{\"order_id\": \"o-203\", \"customer_id\": \"c-05\", \"total_cents\": 990}\n"},
  {"Data": "{\"order_id\": \"o-204\", \"customer_id\": \"c-03\", \"total_cents\": 2350}\n"}
]
```

```
ana@laptop:~/aws$ aws firehose put-record --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --record '{"Data": "{\"order_id\": \"o-200\", \"customer_id\": \"c-17\", \"total_cents\": 1500}\n"}'
{
    "RecordId": "c3977c46-4b6a-41ad-bc33-7699a7628e6c",
    "Encrypted": false
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --records file://batch.json --query FailedPutCount
0
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod --recursive
2026-10-16 13:10:44         66 raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-44-34791ed3-64ca-4c6f-ada0-553848f853bd
2026-10-16 13:10:45        131 raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-4d0ced18-b2a1-4b8f-b677-79d2ca19ce5c
2026-10-16 13:10:45        131 raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-87813042-af20-40bb-a2f0-bcc3e2856c47
ana@laptop:~/aws$ for k in $(aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/orders/ --query 'Contents[].Key' --output text); do echo "$k"; aws s3 cp s3://quitanda-raw-prod/$k - | cat -A; echo; done
raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-44-34791ed3-64ca-4c6f-ada0-553848f853bd
{"order_id": "o-200", "customer_id": "c-17", "total_cents": 1500}$

raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-4d0ced18-b2a1-4b8f-b677-79d2ca19ce5c
{"order_id": "o-201", "customer_id": "c-17", "total_cents": 4590}{"order_id": "o-202", "customer_id": "c-02", "total_cents": 12800}
raw/orders/2026/10/16/16/orders-to-s3-1-2026-10-16-16-10-45-87813042-af20-40bb-a2f0-bcc3e2856c47
{"order_id": "o-203", "customer_id": "c-05", "total_cents": 990}$
{"order_id": "o-204", "customer_id": "c-03", "total_cents": 2350}$
```

**Toda chave começa com o prefixo e depois `2026/10/16/16/`, que é a hora em UTC**, não a de São
Paulo: o `ls` imprimiu a hora como 13:10 local e a chave diz 16. Essa parte datada é o que o Firehose
acrescenta por padrão depois do prefixo, e o nome do objeto depois dela é o nome do stream, um número
de versão, a hora de novo até o segundo, e um sufixo aleatório, para que dois objetos nunca colidam. A
seção depois da próxima muda esse layout.

**O moto escreveu um objeto por chamada, no instante em que cada chamada chegou.** A AWS não faria
isso: com as dicas do `orders-to-s3.json`, os quatro registros teriam esperado num buffer só por até
300 segundos e depois sido escritos como um objeto. Então o número de objetos acima é do moto, e nada
nele prevê o número na AWS; a próxima seção é sobre esse número.

**O que os objetos contêm é fiel, e é o que as pessoas erram.** O `cat -A` marca o fim de cada linha
com `$`. O objeto escrito a partir do `batch.json` é uma linha só com dois documentos JSON colados,
`}{`, porque **por padrão o Firehose não acrescenta delimitador entre registros**: ele concatena os
bytes que recebeu. Athena, Glue e DuckDB leem JSON como um documento por linha, e não conseguem ler
esse objeto como dois pedidos. Os registros do `batch-nl.json` terminam com `\n`, e o objeto deles tem
duas linhas, que todos esses leitores conseguem ler. Um processador chamado `AppendDelimiterToRecord`
pode fazer o Firehose acrescentar a quebra de linha sozinho; sem ele, a quebra de linha é tarefa do
produtor, e o primeiro registro desta seção, o que foi mandado com `put-record`, trazia a sua.
