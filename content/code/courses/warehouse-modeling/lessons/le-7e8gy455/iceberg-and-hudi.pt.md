---
title: Iceberg e Hudi
version: 1
---

O Delta Lake é um de três formatos de tabela abertos, e os outros dois são construídos sobre a mesma ideia: dados em
arquivos Parquet, mais metadados que dizem quais arquivos formam cada versão.

O **Apache Iceberg**, criado na Netflix, guarda seus metadados numa árvore em vez de um log plano. Um arquivo de
metadados para cada versão da tabela aponta para uma manifest list, que aponta para manifests, cada um listando
um conjunto de arquivos de dados com suas estatísticas. A árvore permite planejar tabelas muito grandes rapidamente. O
Iceberg também identifica colunas por id e não por nome, então renomear uma coluna ou mudar o esquema de partição não
regrava dados. E ele tem **particionamento oculto** (hidden partitioning): uma tabela particionada pelo mês de um
timestamp é consultada com um filtro comum no timestamp, e o Iceberg descobre quais partições servem.

O **Apache Hudi**, criado na Uber, foi feito primeiro para tabelas que recebem um fluxo constante de updates e deletes,
como uma cópia de um banco operacional mantida em dia por captura de mudanças (change data capture). Ele oferece
**merge on read** ao lado de copy on write: as mudanças são gravadas em pequenos arquivos de log ao lado dos dados, e
mescladas na hora da leitura até que uma compactação as incorpore, o que deixa baratos os updates pequenos e
frequentes.

O que decide entre eles é, em grande parte, o resto da pilha:

- **Quais motores leem e escrevem o formato.** Spark, Trino, Flink, DuckDB, Snowflake, BigQuery, Redshift e Databricks
  leem um ou mais dos três, e o suporte muda por motor e por versão.
- **Qual catálogo** guarda o ponteiro para os metadados atuais de cada tabela. O Iceberg em particular depende de um
  serviço de catálogo para seus commits atômicos, e a lição 12 volta aos catálogos.

Os três também vêm se aproximando. Alguns produtos já gravam os metadados de uma tabela em mais de um formato ao mesmo
tempo, então uma tabela Delta pode ser lida como tabela Iceberg, e a escolha pesa menos a cada ano. **Para a
modelagem, nada muda**: a estrela das lições 2 a 6 fica tão à vontade em qualquer dos três quanto no DuckDB.
