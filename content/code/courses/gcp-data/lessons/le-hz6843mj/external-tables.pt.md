---
title: Tabelas externas, e consultar arquivos onde eles estão
version: 1
---

**Uma tabela externa é uma tabela cujos dados o BigQuery não guarda.** A definição dela cita arquivos no
Cloud Storage e um formato, e uma consulta sobre ela lê esses arquivos no momento em que roda. Nada é
carregado e nada é copiado: apague um arquivo do bucket e a próxima consulta não vê as linhas dele,
escreva um novo e a próxima consulta vê. A aula 13 carregou os pedidos da Quitanda numa tabela, e a
carga foi gratuita enquanto os mesmos pedidos passaram a ser guardados duas vezes. Uma tabela externa é
a outra escolha: os pedidos ficam em `quitanda-curated-prod`, cobrados como objetos, e o BigQuery vai até
eles.

Tudo sobre o BigQuery nesta seção vem da documentação do Google, "Introduction to external data sources"
e "Query Cloud Storage data", e da página de preços. Nada disso rodou. A próxima seção lê os mesmos
arquivos de volta do emulador do Cloud Storage com um programa, que é a parte que um laptop consegue
fazer.

## Definir uma

O DDL dos pedidos como tabela externa, mostrado como seria rodado e não rodado:

```sql
CREATE EXTERNAL TABLE quitanda.orders_ext
WITH PARTITION COLUMNS (dt DATE)
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://quitanda-curated-prod/orders/*'],
  hive_partition_uri_prefix = 'gs://quitanda-curated-prod/orders/'
);
```

**`uris` é onde estão os arquivos**, com um curinga, e `format` diz como lê-los: Parquet aqui, e a
documentação lista CSV, JSON, Avro e ORC entre os outros. **`WITH PARTITION COLUMNS` e
`hive_partition_uri_prefix` são a convenção Hive da aula 13, lida pelo BigQuery**: tudo depois do
prefixo que se pareça com `dt=2026-09-29/` vira um valor da coluna `dt`. Uma consulta que filtra por `dt`
então pula as pastas que descarta, pelo nome, antes de abrir um arquivo, que é a poda que a aula 15 mediu
no DuckDB. A opção `require_hive_partition_filter = true` é a versão da tabela externa do
`require_partition_filter`.

## Do que ela abre mão

**Uma tabela externa é mais lenta e mais limitada que uma nativa**, e a documentação é direta sobre o
porquê. O BigQuery tem de listar os objetos e ler os metadados de cada arquivo na hora da consulta, onde
uma tabela nativa já tem os metadados prontos; ele lê Parquet, não o próprio formato de armazenamento; e
não pode usar as estatísticas que mantém das próprias tabelas. **Clustering não está disponível**, já que o
BigQuery não arruma os arquivos. Os resultados de uma consulta numa tabela externa não vão para o cache
como os resultados nativos. E quem escreve os arquivos decide o layout: um job que escreve mil arquivos
pequenos por dia faz toda consulta abrir mil arquivos, e o BigQuery não consegue consertar isso do lado
dele.

**O que ela ganha é que o dado tem uma casa só.** Os arquivos que a exportação noturna escreve são a
tabela, sem passo de carga entre eles que possa falhar, atrasar ou dobrar o armazenamento. Outros motores
podem ler os mesmos arquivos: Spark no Dataproc na aula 23, DuckDB num laptop nesta. Esse é o argumento a
favor do lago que as aulas 1 a 5 construíram, e uma tabela externa é como o warehouse entra nele sem ser
dono dele.

## Como ela é cobrada

**Sob demanda, uma consulta numa tabela externa é cobrada por TiB como qualquer outra**, aos mesmos 11,25
USD em `southamerica-east1`, pelos bytes que a consulta lê dos arquivos. Num formato colunar como o
Parquet, isso quer dizer as colunas que a consulta cita, nos arquivos que o filtro de partição mantém;
em CSV ou JSON, em que uma coluna não pode ser lida sem a sua linha, quer dizer arquivos inteiros. A
documentação do Google sobre fontes de dados externas diz como os bytes são contados em cada formato, e o
hábito da aula 16 vale sem mudança: cite as colunas, filtre as partições.

**O armazenamento é do Cloud Storage, pelos preços do Cloud Storage.** Os arquivos são cobrados como
objetos na classe deles, 0,035 USD por GiB-mês para Standard em São Paulo, em
`cloud.google.com/storage/pricing`, lido em 2026-10-30. E a página de preços do BigQuery acrescenta a
regra que mais importa ao longo dos anos: "Long-term storage pricing applies only to BigQuery storage,
not to data stored in external data sources such as Bigtable, Cloud Storage, and Google Drive." Um
arquivo que ninguém tocou há um ano é mais barato no BigQuery do que num bucket Standard, a menos que uma
regra de ciclo de vida da aula 3 o mova para uma classe mais fria. A última seção desta aula põe os dois
lado a lado.
