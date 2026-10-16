---
title: Prefixos, datas e particionamento dinâmico
version: 1
---

**O layout padrão, `2026/10/16/16/`, é uma data que nenhum motor de consulta reconhece como tal.** As
chaves do lago deste curso são no estilo Hive, `dt=2026-10-16/`, porque é essa a forma que o Athena
(lição 15) e o Glue Data Catalog leem como partição, para que uma consulta de um dia leia um dia. Um
delivery stream pode escrever esse layout sozinho. O `Prefix` dele pode ter **expressões** que o Firehose preenche para cada objeto. As duas que importam são `!{timestamp:…}`, um padrão de data
avaliado na hora de chegada do registro em UTC, e `!{partitionKeyFromQuery:…}`, um valor tirado do
próprio registro.

## Um prefixo datado

A configuração da primeira seção com uma data no estilo Hive no prefixo, e um prefixo de erro que
separa as falhas por tipo:

```
ana@laptop:~/aws$ jq '.Prefix = "raw/orders-dt/dt=!{timestamp:yyyy-MM-dd}/" | .ErrorOutputPrefix = "errors/orders-dt/!{firehose:error-output-type}/"' orders-to-s3.json > orders-dt.json
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-dt --extended-s3-destination-configuration file://orders-dt.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-dt"
}
ana@laptop:~/aws$ aws firehose put-record-batch --delivery-stream-name orders-dt --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount
0
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-dt/ --recursive
2026-10-16 13:10:50        131 raw/orders-dt/dt=!{timestamp:yyyy-MM-dd}/2026/10/16/16/orders-dt-1-2026-10-16-16-10-50-423b2c94-da7d-4041-8d81-df2aba15ae71
```

**O moto escreveu a expressão na chave como texto, e depois acrescentou a parte datada dele.**
`dt=!{timestamp:yyyy-MM-dd}/` é um nome de pasta no bucket do moto, e é isso que o laboratório
consegue mostrar, nada além: o moto não avalia expressão nenhuma. Na AWS a expressão é avaliada. A regra documentada para a parte padrão é justamente a que o moto quebrou: **quando o prefixo usa
`!{timestamp:…}`, o Firehose não acrescenta nada depois dele; quando não usa nenhuma, o Firehose
acrescenta a parte `YYYY/MM/dd/HH/` sozinho.** Então na AWS este objeto ficaria direto em
`raw/orders-dt/dt=2026-10-16/`, com o mesmo tipo de nome de antes. Essa chave não foi produzida aqui,
porque o moto não consegue produzi-la.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Três chaves do S3 para o mesmo objeto, cortadas em partes. Com o prefixo padrão, raw/orders/ é seguido pela hora UTC 2026/10/16/16/ que o Firehose acrescenta, e depois pelo nome do objeto. Com uma expressão de timestamp na AWS, o prefixo vira raw/orders-dt/dt=2026-10-16/ e nada é acrescentado antes do nome do objeto. No moto, a expressão fica como texto, dt=!{timestamp:yyyy-MM-dd}/, e o moto acrescenta a hora UTC depois dela mesmo assim.\" data-fig=\"l21-keys\"><text x=\"20.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">prefixo padrão</text><rect x=\"150.0\" y=\"30.0\" width=\"76.9\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"188.4\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">raw/orders/</text><rect x=\"230.9\" y=\"30.0\" width=\"94.6\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"278.2\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2026/10/16/16/</text><rect x=\"329.5\" y=\"30.0\" width=\"177.2\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418.1\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders-to-s3-1-&lt;time&gt;-&lt;uuid&gt;</text><text x=\"20.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">expressão, na AWS</text><rect x=\"150.0\" y=\"90.0\" width=\"177.2\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238.6\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">raw/orders-dt/dt=2026-10-16/</text><rect x=\"331.2\" y=\"90.0\" width=\"159.5\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"411.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders-dt-1-&lt;time&gt;-&lt;uuid&gt;</text><text x=\"20.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">expressão, no moto</text><rect x=\"150.0\" y=\"150.0\" width=\"253.9\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.9\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">raw/orders-dt/dt=!{timestamp:yyyy-MM-dd}/</text><rect x=\"407.9\" y=\"150.0\" width=\"94.6\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455.2\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2026/10/16/16/</text><rect x=\"506.5\" y=\"150.0\" width=\"159.5\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586.2\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders-dt-1-&lt;time&gt;-&lt;uuid&gt;</text><rect x=\"150.0\" y=\"192.0\" width=\"12.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"168.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu Prefix</text><rect x=\"340.0\" y=\"192.0\" width=\"12.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a hora UTC que o Firehose acrescenta</text><rect x=\"530.0\" y=\"192.0\" width=\"12.0\" height=\"10.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o nome do objeto</text></svg>", "caption": "A chave do mesmo objeto de três jeitos: o layout padrão, uma expressão avaliada na AWS, e a mesma expressão guardada como texto pelo moto."}
```

**Um prefixo com expressão também precisa de um `ErrorOutputPrefix`**, diz a documentação da AWS. É
lá que o Firehose escreve os registros que não conseguiu entregar como configurado, e
`!{firehose:error-output-type}` põe o motivo na chave, como `processing-failed` ou
`format-conversion-failed`, para que uma falha seja uma pasta que alguém pode abrir em vez de um
silêncio.

## Particionamento dinâmico

**Uma data vem do relógio; uma loja vem do registro.** O particionamento dinâmico lê um campo de cada
registro JSON com uma consulta `jq` e usa o valor dele no prefixo, para que os pedidos da Quitanda
caiam numa pasta por loja sem programa nenhum no meio. Ele é ligado no destino, e a consulta é um
processador do tipo `MetadataExtraction`. Salve isto ao lado dos outros:

`orders-by-store.json`:

```json
{
  "RoleARN": "arn:aws:iam::123456789012:role/quitanda-firehose",
  "BucketARN": "arn:aws:s3:::quitanda-raw-prod",
  "Prefix": "raw/orders-by-store/store=!{partitionKeyFromQuery:store}/dt=!{timestamp:yyyy-MM-dd}/",
  "ErrorOutputPrefix": "errors/orders-by-store/!{firehose:error-output-type}/",
  "BufferingHints": {"SizeInMBs": 64, "IntervalInSeconds": 300},
  "DynamicPartitioningConfiguration": {"Enabled": true},
  "ProcessingConfiguration": {
    "Enabled": true,
    "Processors": [{
      "Type": "MetadataExtraction",
      "Parameters": [
        {"ParameterName": "MetadataExtractionQuery", "ParameterValue": "{store: .store}"},
        {"ParameterName": "JsonParsingEngine", "ParameterValue": "JQ-1.6"}
      ]
    }]
  }
}
```

```
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-by-store --extended-s3-destination-configuration file://orders-by-store.json
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-by-store"
}
ana@laptop:~/aws$ aws firehose put-record --delivery-stream-name orders-by-store --cli-binary-format raw-in-base64-out --record '{"Data": "{\"order_id\": \"o-205\", \"store\": \"pinheiros\"}\n"}'
{
    "RecordId": "efb638c8-7fb5-4c2b-a766-aa1478249a9a",
    "Encrypted": false
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-by-store/ --recursive
2026-10-16 13:10:52         44 raw/orders-by-store/store=!{partitionKeyFromQuery:store}/dt=!{timestamp:yyyy-MM-dd}/2026/10/16/16/orders-by-store-1-2026-10-16-16-10-52-93acbbcb-daa8-427e-afa2-adf5570573f7
```

**De novo a chave carrega as expressões como texto**: o moto não rodou `jq` nem leu campo nenhum, e o
`pinheiros` do registro não aparece em lugar nenhum da chave. Na AWS este registro cairia em
`raw/orders-by-store/store=pinheiros/dt=2026-10-16/`. A consulta `{store: .store}` dá à chave o nome
`store`, que é o nome que o prefixo pede, e um registro sem campo `store`, ou com algo que não é JSON,
iria para o prefixo de erro.

**O particionamento dinâmico é cobrado por gigabyte em cima da ingestão**, ao preço da última seção,
e multiplica os buffers, como a seção anterior disse: um por combinação distinta de chaves. Uma chave
de partição é uma coluna pela qual uma consulta vai filtrar e que tem dezenas de valores, não uma que
tem milhares. Particionado por cliente, o stream da Quitanda teria um buffer por cliente e escreveria
cada um pela metade a cada intervalo, e o lago ganharia dezenas de milhares de objetos minúsculos por
dia.
