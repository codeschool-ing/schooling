---
title: Tabelas de objetos e Iceberg
version: 1
---

**Mais dois tipos de tabela leem o Cloud Storage, e cada um resolve um problema que a tabela Parquet das
duas últimas seções não tem.** Uma **tabela de objetos** é para arquivos que nem são linhas: recibos
fotografados pelos entregadores, fotos de produtos, PDFs de notas fiscais. Uma **tabela Iceberg** é para
linhas que precisam mudar: um update, um delete, um esquema que ganha uma coluna, feitos em arquivos que
vários motores leem. Os dois são ensinados aqui pela documentação do Google e nada disso rodou.

## Tabelas de objetos

**Uma tabela de objetos é uma tabela somente leitura com uma linha por objeto de um bucket, e as colunas
são os metadados do objeto.** Ela é criada sobre uma conexão, como uma tabela BigLake:

```sql
CREATE EXTERNAL TABLE quitanda.receipts
WITH CONNECTION `planner-dev.southamerica-east1.quitanda-lake`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://quitanda-raw-prod/receipts/*']
);
```

**Cada linha descreve um objeto**: a `uri`, a `generation`, o `content_type`, o `size`, quando foi
`updated`, e os metadados personalizados ligados a ele. O conteúdo não está na tabela. O que a tabela
torna possível é SQL sobre o inventário de um bucket, com a governança do BigQuery: quais recibos
chegaram ontem, quantos bytes de fotos cada loja mandou, quais objetos passam de um tamanho. O uso
principal que a documentação dá a ela é entregar os objetos a um modelo, pelo BigQuery ML ou por uma
função remota, com a tabela como a lista do que processar.

**É um inventário, e a aula 1 já tinha um de certa forma**: `gcloud storage ls` também lista objetos. A
diferença é que a tabela de objetos pode entrar num join com os pedidos, ser filtrada em SQL e ser dada a
alguém que não tem acesso ao bucket.

## Iceberg

**Apache Iceberg é um formato aberto de tabela**: um conjunto de arquivos Parquet mais arquivos de
metadados, também no bucket, que registram quais arquivos de dados formam a tabela em cada momento. Mudar
a tabela significa escrever arquivos de dados novos e um arquivo de metadados novo que aponta para o
conjunto novo, e todo motor que entende Iceberg lê a mesma tabela na mesma versão. É o que dá a arquivos
num bucket as coisas que uma tabela de warehouse dá por certas: updates e deletes, um esquema que evolui,
e ler a tabela como ela era numa versão anterior.

**O BigQuery encontra o Iceberg de dois jeitos**, na documentação do Google. **Ele lê uma tabela Iceberg que
outro motor gerencia**, pelos metadados dela, como tabela externa ou BigLake somente leitura. E **ele
gerencia uma sozinho**: uma tabela BigLake para Apache Iceberg no BigQuery, em que o BigQuery escreve o
Parquet e os metadados Iceberg num bucket seu e aceita DML sobre ela, enquanto o Spark e outros motores
leem os mesmos arquivos. A página de preços do BigQuery chama isso de "Lakehouse for Apache Iceberg
tables", com cargas e merges nelas cobrados pelo que ela chama de tarifas padrão do Lakehouse for Apache
Iceberg; o curso não as precifica além disso.

**Para a Quitanda, o Iceberg é a resposta a uma pergunta que ela ainda não tem.** Os pedidos são escritos
uma vez por noite e nunca mudam, então uma pasta de arquivos Parquet por dia os atende. No dia em que uma
correção precisar mudar os pedidos do mês passado num lago que o Spark e o BigQuery leem, reescrever
pastas à mão deixa de ser seguro, e um formato de tabela que registra cada mudança é a ferramenta. A aula
25 traz a captura de mudanças, que é o jeito comum de esse dia chegar.
