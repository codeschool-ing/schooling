---
title: O Athena lê os arquivos onde eles estão
version: 1
---

**O Athena é SQL sobre arquivos que ficam no S3.** Nada é carregado nele e nada é guardado nele:
não há disco do Athena para encher, instância para dimensionar nem cluster para deixar ligado. Uma
consulta nomeia uma tabela, a tabela nomeia um prefixo no S3 e um formato de arquivo, e o motor do
Athena lê os objetos sob esse prefixo no momento em que a consulta roda. Quando termina, os
arquivos estão exatamente como estavam, e a resposta é gravada como um arquivo próprio num prefixo
que você escolheu.

A imagem com que a maioria das pessoas chega é a oposta: um data warehouse em que você carrega os
dados, como o Redshift da lição 14. Essa imagem leva a dois erros. Um é procurar um lugar para pôr
os dados, quando eles já estão onde devem estar. O outro é o caro, e é o assunto desta lição: **o
Athena é cobrado pelos bytes que lê, não pelo tempo que roda nem pelas linhas que devolve.** Uma
consulta que lê um bucket inteiro para contar dez linhas paga pelo bucket.

## Uma tabela é uma descrição, não um recipiente

Uma tabela do Athena são algumas linhas no Glue Data Catalog, que a lição 16 abre: as colunas e
seus tipos, o formato dos arquivos, onde eles moram e as colunas que vêm da chave em vez do arquivo.
Para os pedidos que esta lição grava, a descrição é este arquivo:

`orders.sql`:

```sql
CREATE EXTERNAL TABLE quitanda.orders (
  order_id      string,
  customer_id   string,
  hour          tinyint,
  items         smallint,
  total_cents   bigint,
  payment       string,
  neighbourhood string
)
PARTITIONED BY (dt string)
STORED AS PARQUET
LOCATION 's3://quitanda-curated-prod/orders/'
```

**`EXTERNAL` quer dizer que os dados não são da tabela.** Apagar a tabela apaga a descrição e deixa
cada objeto do S3 onde está. `PARTITIONED BY (dt string)` diz que `dt` nem é uma coluna dentro dos
arquivos: ela é lida da chave, do `dt=2026-10-01/` que a lição 1 pôs em todo caminho exatamente por
isso. E `STORED AS PARQUET` nomeia o formato, que é a decisão cujo preço o resto desta lição calcula.

Uma partição precisa ser conhecida pelo catálogo antes de o Athena lê-la. O arquivo de um dia novo,
gravado hoje à noite, fica invisível para toda consulta até a partição dele ser adicionada. `MSCK REPAIR TABLE` percorre o prefixo e registra o que encontra, um `ALTER TABLE … ADD PARTITION` nomeia uma, um crawler faz isso numa agenda, e a projeção do fim desta lição torna isso desnecessário. É a surpresa
mais comum da primeira semana com o Athena: um arquivo que está claramente no bucket e uma consulta
que não o vê.

## O que o moto faz com ela

Enviado ao moto, o comando faz o que a consulta da lição 1 fez:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-athena-results-prod
make_bucket: quitanda-athena-results-prod
ana@laptop:~/aws$ aws athena start-query-execution --query-string file://orders.sql --result-configuration OutputLocation=s3://quitanda-athena-results-prod/
{
    "QueryExecutionId": "327552ed-b1e2-4267-9365-d8700b391a96"
}
ana@laptop:~/aws$ aws athena get-query-execution --query-execution-id 327552ed-b1e2-4267-9365-d8700b391a96 --query 'QueryExecution.[StatementType,Status.State]' --output text
DDL	SUCCEEDED
ana@laptop:~/aws$ aws glue get-databases
{
    "DatabaseList": []
}
```

**`DDL` e `SUCCEEDED`, e o catálogo está vazio.** O Athena teria recusado o comando, porque ainda
não existe um banco chamado `quitanda`, e com ele teria gravado uma tabela no catálogo. O moto não
fez nem uma coisa nem outra: leu o comando o bastante para chamá-lo de DDL, marcou como concluído e
não guardou nada. O mesmo vale para todo `SELECT` desta lição, então daqui em diante as perguntas vão
para o DuckDB, um motor que roda dentro de um programa Python, lendo no S3 do moto os mesmos objetos
que o Athena leria. **Toda resposta abaixo é do DuckDB, e toda contagem de bytes é o que o DuckDB
leu**; onde o Athena se comporta de outro jeito, a lição diz.

## O preço é uma linha

```
ana@laptop:~/aws$ python3 prices.py athena
AWS public price list, sa-east-1, USD, excluding tax

Athena, USD
  SQL queries, per TB scanned                           9.00000  TB
```

**Nove dólares por terabyte lido, em São Paulo**, e o resto da conta está nas regras em volta desse
número, tiradas da página de preços do Athena:

- os bytes são arredondados para cima até o megabyte inteiro, com **10 MB como o mínimo que
  qualquer consulta custa**;
- os bytes são os lidos do S3, comprimidos, então um arquivo comprimido custa o tamanho comprimido;
- comandos que só mudam o catálogo, como `CREATE TABLE` ou `ADD PARTITION`, não custam nada, e uma
  consulta que falha também não;
- uma consulta que você cancela custa o que ela tinha lido quando parou.

A resposta que o Athena grava no prefixo de resultados é um objeto comum, cobrado como armazenamento
do S3, e as leituras que ele faz são requisições GET comuns, cobradas pelo preço que o bloco S3 da
tabela imprime. O Athena também vende capacidade por hora, para equipes cujas consultas são
previsíveis o bastante para reservá-la; este curso calcula o jeito por terabyte, que é o padrão e o
que um primeiro lago paga.
