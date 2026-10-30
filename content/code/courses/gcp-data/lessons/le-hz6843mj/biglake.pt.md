---
title: BigLake, conexões e um cache de metadados
version: 1
---

**Uma tabela BigLake é uma tabela externa que o BigQuery lê com a identidade dele em vez da sua.** Numa
tabela externa simples, quem roda a consulta precisa de permissão para ler os arquivos no bucket, então
dar uma tabela a uma analista significa dar o bucket também, todo arquivo dele, por qualquer ferramenta.
Uma tabela BigLake passa por uma **conexão**: um recurso do BigQuery com uma service account própria, e é
essa service account que recebe acesso ao bucket. A analista recebe a tabela, e nunca toca no Cloud
Storage. Tudo nesta seção vem da documentação do Google sobre o BigLake e as conexões dele, e nada disso
rodou.

## Uma conexão, e a tabela sobre ela

A conexão é criada uma vez, por região. No Google Cloud, como você digitaria e não rodado aqui:

```sh
bq mk --connection --location=southamerica-east1 --project_id=planner-dev \
  --connection_type=CLOUD_RESOURCE quitanda-lake
bq show --connection planner-dev.southamerica-east1.quitanda-lake
```

**`CLOUD_RESOURCE` é o tipo de conexão que alcança o Cloud Storage**, e o `bq show` imprimiria a service
account que o Google criou para ela. Essa conta então recebe acesso de leitura em `quitanda-curated-prod`,
o passo de IAM que o `gcp-foundations` ensinou, e ela é a única identidade que lê os arquivos. A tabela
cita a conexão:

```sql
CREATE EXTERNAL TABLE quitanda.orders_lake
WITH PARTITION COLUMNS (dt DATE)
WITH CONNECTION `planner-dev.southamerica-east1.quitanda-lake`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://quitanda-curated-prod/orders/*'],
  hive_partition_uri_prefix = 'gs://quitanda-curated-prod/orders/',
  max_staleness = INTERVAL 4 HOUR,
  metadata_cache_mode = 'AUTOMATIC'
);
```

**`WITH CONNECTION` é toda a diferença no DDL**, e ela muda o que pode ser imposto. Como o BigQuery lê os
arquivos em nome do usuário, ele pode filtrar o que devolve: a documentação lista **segurança por linha**
e **segurança por coluna** com mascaramento de dados para tabelas BigLake, os mesmos controles que uma
tabela nativa tem. Uma analista pode receber os pedidos do próprio bairro, ou os pedidos sem
`customer_id`, e nenhuma ferramenta dela consegue contornar isso, porque ela não tem acesso aos arquivos
com que contornaria.

## O cache de metadados

**A parte mais lenta de consultar arquivos é descobrir o que há neles**, e a última seção mediu isso: o
rodapé de cada arquivo lido antes de um byte de dado, e cada objeto listado antes de qualquer arquivo
ser aberto. Uma tabela BigLake pode **guardar esses metadados em cache** no BigQuery: a lista de arquivos
e as estatísticas dos rodapés deles, incluindo o mínimo e o máximo de cada coluna que a aula 15 usou para
pular grupos de linhas.

**`max_staleness` diz quão velho o cache pode ser antes de uma consulta deixar de confiar nele**, e
`metadata_cache_mode` diz quem o atualiza. `AUTOMATIC` deixa o BigQuery atualizar na agenda dele;
`MANUAL` deixa para uma chamada do procedimento de sistema `BQ.REFRESH_EXTERNAL_METADATA_CACHE`, que um
job roda depois de escrever arquivos novos. Uma consulta rodada dentro da validade usa a lista e as
estatísticas em cache e pula a listagem e os rodapés; uma consulta rodada depois lê os arquivos como uma
tabela externa simples leria. A documentação fixa a faixa de validade que uma tabela pode declarar e os
detalhes da agenda automática.

**O preço do cache é que a tabela pode estar atrás do bucket.** Com quatro horas de validade, um arquivo
escrito às nove não é visto por uma consulta das nove e meia que usa o cache. Para a exportação noturna
da Quitanda, escrita uma vez às três da manhã e atualizada manualmente pelo job que a escreve, isso não
custa nada; para um bucket que recebe arquivos a cada minuto, é a primeira pergunta a responder.

## BigLake contra uma tabela nativa

**O BigLake fecha boa parte da distância para uma tabela nativa e mantém a única coisa que uma tabela
nativa não oferece**: o dado fica em arquivos abertos, num bucket que a empresa possui, legível por
outros motores. O que ele não fecha é o armazenamento: os arquivos continuam cobrados como objetos do
Cloud Storage, sem desconto de longo prazo do BigQuery, e o layout continua sendo o que quem escreveu
fez. Uma tabela que o warehouse consulta mil vezes por dia, de dado que nada mais lê, sai mais barata e
mais rápida como tabela nativa; uma tabela que vários motores dividem, governada num lugar só, é para o
que o BigLake existe.
