---
title: O catálogo, e do que uma tabela é feita
version: 1
---

**O Glue Data Catalog é o índice do lago, e não guarda dado nenhum.** O `orders.sql` da lição 15
descreveu uma tabela em uma dúzia de linhas; essas linhas são o que o catálogo guarda, e tudo o que
lê o lago pelo nome lê essas linhas primeiro. O Athena lê, o Redshift Spectrum lê, um cluster EMR lê
quando mandam usar o catálogo como metastore, um job do Glue lê, e o Lake Formation, na lição 18,
escreve as permissões dele contra os mesmos nomes. Há um catálogo por conta e região, então uma
tabela definida uma vez é a mesma tabela para todos eles.

A imagem errada aqui é um motor de banco de dados com disco próprio. O catálogo está mais perto de
um serviço de diretório: bancos que agrupam tabelas, tabelas que descrevem onde os arquivos estão e
como lê-los, e partições que dizem qual prefixo guarda qual fatia. **Apague todo objeto do S3 e o
catálogo não muda; apague o catálogo e todo objeto continua lá**, ilegível pelo nome até alguém
descrevê-lo de novo.

## As partes de uma tabela

O terminal é o da lição 1: o moto rodando no terminal dele e as quatro linhas de "O seu
laboratório, em resumo" da lição 1 digitadas neste. Uma tabela mora num banco, então o banco vem
primeiro:

```
ana@laptop:~/aws$ aws glue create-database --database-input '{"Name": "quitanda", "Description": "Quitanda lake, curated layer"}'
ana@laptop:~/aws$ aws glue get-databases
{
    "DatabaseList": [
        {
            "Name": "quitanda",
            "Description": "Quitanda lake, curated layer",
            "CreateTime": "2026-10-16T13:22:50.863000-03:00",
            "CatalogId": "123456789012"
        }
    ]
}
```

`CatalogId` é a conta, a `123456789012` do moto. Depois a tabela, escrita no JSON que a API recebe,
que é a mesma descrição que o `orders.sql` deu ao Athena, sem nada implícito:

`orders-table.json`:

```json
{
  "Name": "orders",
  "TableType": "EXTERNAL_TABLE",
  "Parameters": {"classification": "parquet"},
  "PartitionKeys": [{"Name": "dt", "Type": "string"}],
  "StorageDescriptor": {
    "Columns": [
      {"Name": "order_id", "Type": "string"},
      {"Name": "customer_id", "Type": "string"},
      {"Name": "hour", "Type": "tinyint"},
      {"Name": "items", "Type": "smallint"},
      {"Name": "total_cents", "Type": "bigint"},
      {"Name": "payment", "Type": "string"},
      {"Name": "neighbourhood", "Type": "string"}
    ],
    "Location": "s3://quitanda-curated-prod/orders/",
    "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}
```

Quatro partes, e cada uma responde a uma pergunta que um leitor faz antes de ler um byte:

| parte | a pergunta que ela responde |
|---|---|
| `Columns` | o que há em cada arquivo, em que ordem, com qual tipo |
| `Location` | qual prefixo do S3 guarda os arquivos |
| `InputFormat`, `OutputFormat`, `SerdeInfo` | como transformar os bytes em linhas e de volta: aqui, Parquet |
| `PartitionKeys` | quais colunas vêm da chave em vez do arquivo |

**O `StorageDescriptor` é a parte sem a qual um leitor não anda**, e o nome é do Hive: o catálogo é
compatível com o metastore do Hive, e é por isso que o Spark e o Trino o leem sem adaptador. Os três
nomes de classe são como um motor compatível com o Hive fica sabendo o formato. `classification` é o
rótulo do próprio Glue para o mesmo fato, que os crawlers gravam e o console do Glue mostra.

```
ana@laptop:~/aws$ aws glue create-table --database-name quitanda --table-input file://orders-table.json
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name orders --query 'Table.[Name,TableType,VersionId,StorageDescriptor.Location,length(StorageDescriptor.Columns),PartitionKeys[0].Name]' --output text
orders	EXTERNAL_TABLE	1	s3://quitanda-curated-prod/orders/	7	dt
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name nope

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetTable operation: Table nope not found.
```

**Versão 1, sete colunas, uma chave de partição e uma recusa clara para um nome que não existe.**
Esta parte da AWS é uma estrutura de dados, e o moto a guarda fielmente: a tabela acima é o que o
Athena encontraria se o mesmo JSON fosse enviado a uma conta real. O que o moto continua sem fazer é
ler os arquivos, então nada conferiu se as sete colunas são as sete do Parquet. O catálogo de verdade
também não confere: **uma tabela é uma afirmação sobre os arquivos, e nada compara a afirmação com
eles** até uma consulta ler os dois e um deles estar errado.
