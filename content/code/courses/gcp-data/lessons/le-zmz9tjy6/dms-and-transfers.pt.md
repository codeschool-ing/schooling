---
title: Database Migration Service, e o Data Transfer Service
version: 1
---

**O Datastream acompanha um banco até um warehouse; o Database Migration Service muda o próprio
banco de lugar.** Os dois usam a mesma maquinaria por baixo, um backfill e depois CDC a partir do log
da origem, e terminam em lugares diferentes. Um stream do Datastream termina no BigQuery ou no Cloud
Storage, e a loja continua rodando no PostgreSQL dela. Um migration job termina no Cloud SQL ou no
AlloyDB, das aulas 6 a 8, e o último passo dele é a loja se mudar para lá. Nenhum dos dois tem
emulador, então esta seção é lida, e os comandos dela estão marcados como não rodados.

## Um migration job

**Um job do Database Migration Service é um profile de origem, um destino e um tipo.** O tipo é a
primeira decisão, e são dois:

| tipo | o que faz | quando é a resposta |
|---|---|---|
| `ONE_TIME` | faz um dump da origem e o carrega no destino, uma vez | a origem pode parar de escrever durante a cópia |
| `CONTINUOUS` | carrega a origem e depois replica cada mudança até você promover o destino | um banco vivo se mudando quase sem tempo parado |

A loja da Quitanda saindo do rack para o Cloud SQL for PostgreSQL é do segundo tipo. A origem é um
connection profile como o do Datastream, e o destino é uma instância Cloud SQL que o job cria ou que
já existe. **Não rodado aqui:**

```sh
gcloud database-migration migration-jobs create shop-to-cloudsql \
  --region=southamerica-east1 --type=CONTINUOUS \
  --source=legacy-shop-dms --destination=shop-cloudsql
gcloud database-migration migration-jobs start shop-to-cloudsql --region=southamerica-east1
```

**De PostgreSQL para PostgreSQL a cópia anda sobre a replicação lógica**, as publicações e os slots da
seção anterior a esta: por padrão pela extensão `pglogical`, que a origem precisa ter instalada, e,
com `--use-postgres-native`, uma opção que esta versão da linha de comando oferece, pelas publicações
e assinaturas do próprio PostgreSQL. Os mesmos requisitos decorrem disso: `wal_level=logical` na
origem, um usuário com permissão de replicar e uma chave primária, ou uma replica identity, em cada
tabela cujos updates precisam atravessar. Uma origem sem isso reprova nas checagens do próprio job
antes de qualquer cópia, e o `gcloud database-migration migration-jobs verify` as roda quando você
pede.

**O cutover tem nome aqui: promote.** O `gcloud database-migration migration-jobs promote` para a
replicação e torna o destino um primário independente que aceita escritas. Depois dele, as
aplicações são apontadas para a instância nova, e o job acabou. A próxima seção é sobre a ordem em
volta desse único comando, que é onde as migrações perdem dados.

## Quanto custa

Segundo `cloud.google.com/database-migration/pricing`, lida em 2026-10-30: **uma migração homogênea,
de MySQL para Cloud SQL for MySQL ou de PostgreSQL para Cloud SQL for PostgreSQL ou AlloyDB, é
oferecida sem cobrança adicional.** O que se cobra é o próprio destino, pelos preços do Cloud SQL ou
do AlloyDB, e qualquer rede que a migração atravesse. Uma migração **heterogênea**, de Oracle ou SQL
Server para PostgreSQL, é cobrada por GiB processado, nas mesmas faixas de São Paulo do Datastream,
$3.176 por GiB nos primeiros 2.500 GiB de mudanças do mês. A página se contradiz num ponto: o texto
dela diz que os primeiros 50 GiB de backfill de cada mês são grátis, e a tabela e o exemplo dizem
500. A tabela é a base do cálculo do exemplo, e é o número com que este curso planejaria, perguntando
ao Google antes de contar com ele.

## BigQuery Data Transfer Service

**O Data Transfer Service é para cargas que acontecem num horário, não para cada mudança.** Uma
*transfer configuration* nomeia uma origem, um dataset de destino, um agendamento e os parâmetros da
origem, e o BigQuery a roda, guarda o histórico de cada execução e consegue refazer uma data passada
quando pedido, que é o backfill da aula anterior noutro produto. As origens incluem o Cloud Storage, o
Amazon S3 e o Azure Blob Storage, outros warehouses em migração, como Amazon Redshift e Teradata, os
próprios produtos de publicidade e análise do Google e uma lista crescente de bancos e aplicações
SaaS. As consultas agendadas da aula 18 também são transfer configurations.

Para a Quitanda a óbvia é a exportação noturna da aula 1: um objeto em
`gs://quitanda-raw-prod/raw/orders/` carregado numa tabela do BigQuery toda noite. **Não rodado
aqui, porque o `bq` não tem para onde ir neste laboratório:**

```sh
bq mk --transfer_config --data_source=google_cloud_storage \
  --target_dataset=shop --display_name='nightly orders' \
  --params='{"data_path_template": "gs://quitanda-raw-prod/raw/orders/*", "destination_table_name_template": "orders", "file_format": "CSV", "skip_leading_rows": "1"}'
```

**O preço depende do conector.** A página de preços do BigQuery, lida em 2026-10-30, lista os
conectores de Cloud Storage, Amazon S3, Azure Blob Storage, Redshift e Teradata, entre outros, sem
cobrança pela orquestração da transferência, e a carga em si usa o pool compartilhado e grátis do
BigQuery para cargas em lote. Os conectores de bancos e produtos SaaS, PostgreSQL e MySQL entre eles,
são cobrados pelas slot-horas que consomem, e a página sugere planejar até 20 slot-horas por hora em
que uma transferência roda. A taxa de São Paulo para essas slot-horas não é uma que este curso
conseguiu separar dos outros preços de slot da página, então nenhum número é dado para ela aqui.

## Qual dos três

**Datastream quando o warehouse deve acompanhar o banco em minutos, DMS quando o banco está se
mudando, e Data Transfer Service quando uma vez por noite basta.** Para a Quitanda a resposta é os
três, em momentos diferentes: a transferência da exportação noturna é aquilo com que os relatórios
rodam hoje; o Datastream para o BigQuery é o que os deixa parar de esperar a noite; e o dia em que a
loja for para o Cloud SQL é um job do DMS, com o mesmo backfill, o mesmo slot e o mesmo cutover que a
próxima seção põe em ordem.
