---
title: Compressão, Parquet, e uma Lambda no meio
version: 1
---

**O Firehose pode mudar os registros a caminho do S3, de três jeitos de ambição crescente**:
comprimir cada objeto, converter os registros de JSON para Parquet, ou entregar cada lote a uma função
Lambda que o reescreve. Os três são configurados e nenhum é rodado pelo moto, que guarda os bytes que
recebeu exatamente como os recebeu. Esta seção mostra isso, e depois diz o que a AWS faz no lugar.

## Compressão

`CompressionFormat` aceita `GZIP`, `ZIP`, `Snappy` ou `HADOOP_SNAPPY`, e comprime cada objeto inteiro.
Uma cópia do primeiro arquivo com `GZIP`, e os primeiros bytes do que o moto escreveu:

```
ana@laptop:~/aws$ jq '.CompressionFormat = "GZIP" | .Prefix = "raw/orders-gz/"' orders-to-s3.json > orders-gz.json
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-gz --extended-s3-destination-configuration file://orders-gz.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-gz"
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-gz --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ K=$(aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/orders-gz/ --query 'Contents[0].Key' --output text) && echo "$K" && aws s3 cp s3://quitanda-raw-prod/$K - | head -c 16 | od -c
raw/orders-gz/2026/10/16/16/orders-gz-1-2026-10-16-16-10-54-030752a7-a4e4-45cf-a9aa-cc5f43c9ada9
0000000   {   "   o   r   d   e   r   _   i   d   "   :       "   o   -
0000020
```

**Um arquivo gzip começa com os dois bytes `037 213`, e este começa com `{"order_id"`.** O moto
guardou JSON puro sob uma configuração que pedia gzip. Na AWS o objeto seria comprimido, linhas de JSON
costumam encolher a uma fração do tamanho, e o Athena e o DuckDB leem gzip do jeito que está. Nada foi
rodado que mostre a proporção, então nenhuma proporção é citada aqui.

## Conversão de formato de registro

**Converter para Parquet é onde o Firehose poupa um job ao lago.** A lição 19 defendeu o Parquet: uma
consulta lê só as colunas que nomeia, e a conta é dos bytes lidos. O Firehose pode escrever Parquet ou
ORC diretamente, se souber o esquema, e o esquema vem de uma tabela do Glue Data Catalog da lição 16.
Salve isto em `~/aws` também:

`orders-parquet.json`:

```json
{
  "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
  "BucketARN": "arn:aws:s3:::quitanda-curated-prod",
  "Prefix": "curated/orders/dt=!{timestamp:yyyy-MM-dd}/",
  "ErrorOutputPrefix": "errors/orders/!{firehose:error-output-type}/",
  "BufferingHints": {"SizeInMBs": 128, "IntervalInSeconds": 900},
  "CompressionFormat": "UNCOMPRESSED",
  "DataFormatConversionConfiguration": {
    "Enabled": true,
    "InputFormatConfiguration": {"Deserializer": {"OpenXJsonSerDe": {}}},
    "OutputFormatConfiguration": {"Serializer": {"ParquetSerDe": {"Compression": "SNAPPY"}}},
    "SchemaConfiguration": {
      "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
      "DatabaseName": "quitanda", "TableName": "orders", "Region": "sa-east-1"
    }
  }
}
```

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name orders

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetTable operation: Database quitanda not found.
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-parquet --extended-s3-destination-configuration file://orders-parquet.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-parquet"
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-parquet --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ for k in $(aws s3api list-objects-v2 --bucket quitanda-curated-prod --prefix curated/ --query 'Contents[].Key' --output text); do echo "$k"; aws s3 cp s3://quitanda-curated-prod/$k - | cat -A; echo; done
curated/orders/dt=!{timestamp:yyyy-MM-dd}/2026/10/16/16/orders-parquet-1-2026-10-16-16-10-57-eb178df6-4e22-454d-94d6-1e0378cd1df6
{"order_id": "o-203", "customer_id": "c-05", "total_cents": 990}$
{"order_id": "o-204", "customer_id": "c-03", "total_cents": 2350}$
```

**Três coisas passaram sem conferência, uma depois da outra.** O banco `quitanda` do Glue não existe,
e o `get-table` disse isso; o moto criou o delivery stream mesmo assim, sem procurá-lo. Depois aceitou
os registros, e os escreveu como as linhas de JSON que eram, sob uma chave com a expressão como texto.

O que a AWS faz no lugar não foi rodado e vem da documentação dela. O stream lê as colunas e os tipos
da tabela do Glue, interpreta cada registro com o desserializador JSON nomeado em
`InputFormatConfiguration`, e escreve arquivos Parquet, comprimidos por dentro com `SNAPPY`; é por isso
que o `CompressionFormat` do objeto inteiro fica `UNCOMPRESSED`. A entrada tem de ser JSON. Um registro
que não bate com o esquema vai para o prefixo de erro em `format-conversion-failed`, e um stream cuja
tabela não existe falha todo registro desse jeito. O buffer é maior de propósito, 128 MB e 900
segundos, porque um arquivo Parquet merece as estatísticas de coluna por ser grande; a AWS fixa 64 MB
como tamanho mínimo quando a conversão está ligada.

## Uma Lambda no meio

**Quando um registro precisa de mais que uma troca de formato, o Firehose pode chamar uma função
Lambda em cada lote.** É assim que um delivery stream descarta pedidos de teste, mascara o endereço de
um cliente, ou transforma uma linha de log em JSON antes da conversão. A função recebe uma lista de
registros, cada um com um `recordId` e o `data` em base64, e tem de devolver a mesma lista com todo
`recordId` de volta, cada um com um `result`, que é `Ok`, `Dropped` ou `ProcessingFailed`, e o `data`
novo. Um registro devolvido como `ProcessingFailed`, ou um que a função deixou de devolver, vai para o
prefixo de erro em `processing-failed`.

Este curso não roda uma transformação. A Lambda do moto precisa de um motor de contêineres para
executar funções, e o delivery stream no moto não chama nenhuma; o contrato acima é o da AWS, da
documentação dela. **A transformação também é por onde os duplicados entram em silêncio**: o Firehose
tenta de novo um lote cuja chamada falhou ou estourou o tempo, então uma função com efeito colateral,
como escrever num banco, pode executá-lo duas vezes para um registro. A lição 23 é exatamente sobre
isso.
