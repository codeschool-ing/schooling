---
title: Uma instância, um banco e um schema, no emulador
version: 1
---

**Um banco do Spanner mora dentro de uma instância, e a instância é onde está o dinheiro.** A
instância é a capacidade de computação, medida em nós ou processing units, e uma configuração que diz
onde ficam as cópias dos dados: uma região, duas ou várias. Os bancos são criados dentro dela e
dividem a capacidade dela, e as tabelas são criadas dentro de um banco pelo schema. São três camadas
onde o Cloud SQL e o AlloyDB tinham um servidor e seus bancos, e o motivo é o assunto desta aula: a
instância não é uma máquina, é uma fatia de uma frota, que cresce acrescentando mais fatias.

**Esta seção e as três seguintes são praticadas no emulador do Spanner**, o que o Google entrega com a
linha de comando e que a aula 1 instalou como `cloud-spanner-emulator`. É um programa que fala a API
do Spanner no seu laptop e guarda tudo em memória. Ele roda o seu schema, o seu SQL e as suas
transações, e não roda o Spanner: há um processo, nenhuma réplica, nenhum split e nada para medir. A
última seção desta aula lista o que isso deixa de fora, com as transcrições que mostram. **O emulador
é publicado só para Linux x86-64**, como a aula 1 disse, então numa máquina Arm esta aula é lida em
vez de praticada.

## O emulador, num terminal só dele

```sh
cd ~/gcp && export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud emulators spanner start
```

**Ele responde em duas portas**: 9010 para gRPC, que o cliente Python usa por `SPANNER_EMULATOR_HOST`,
e 9020 para REST, que o `gcloud` usa por `CLOUDSDK_API_ENDPOINT_OVERRIDES_SPANNER`. As duas variáveis
são definidas pelo "Toda vez que você abre um terminal" da aula 1. Deixe-o rodando e digite o resto no
outro terminal.

## Uma instância

**Uma instância precisa de uma configuração, e o emulador tem exatamente uma:**

```
ana@laptop:~/gcp$ gcloud spanner instance-configs list
NAME             DISPLAY_NAME              FREE_INSTANCE_AVAILABILITY
emulator-config  Emulator Instance Config
```

**No Google Cloud a lista é longa**: `regional-southamerica-east1` para São Paulo, nomes dual-region e
multirregionais como `nam-eur-asia1`, cada um um posicionamento de réplicas com um preço. Aqui toda
instância é criada com `--config=emulator-config`, e a capacidade é dada em processing units:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda --config=emulator-config --description="Quitanda shop" --processing-units=100
Creating instance...
.....done.
ana@laptop:~/gcp$ gcloud spanner instances list
NAME      DISPLAY_NAME   CONFIG           NODE_COUNT  PROCESSING_UNITS  STATE  INSTANCE_TYPE
quitanda  Quitanda shop  emulator-config              100               READY
```

**100 processing units é a menor instância que o Spanner vende**, um décimo de nó, e a coluna
`PROCESSING_UNITS` diz isso. `--processing-units` e `--nodes` são dois nomes para uma configuração:
1.000 processing units são 1 nó. Abaixo de 1.000 os passos são de 100, e acima são nós inteiros, e o
emulador impõe essa regra com a frase do próprio Spanner:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda-test --config=emulator-config --description="A test" --processing-units=150
ERROR: (gcloud.spanner.instances.create) HTTPError 400: {"code":3,"message":"Invalid CreateInstance request. Processing units should be multiple of 100 for values below 1000 and multiples of 1000 for values above 1000."}
```

## Um schema

**Um schema do Spanner é DDL**, bem parecido com o `CREATE TABLE` de `sql-databases`, com três coisas
que são do Spanner: toda tabela nomeia a sua `PRIMARY KEY` depois da lista de colunas, uma tabela pode
ser intercalada (`INTERLEAVE`) em outra, e uma sequência pode ser bit-reversed. As três próximas
seções tratam dessas três, e este arquivo é o banco da loja da Quitanda inteiro para esta aula.

`schema.sql`:

```sql
CREATE SEQUENCE OrderSeq OPTIONS (sequence_kind = 'bit_reversed_positive');

CREATE TABLE Customers (
  CustomerId STRING(36) NOT NULL,
  Name       STRING(MAX) NOT NULL,
  District   STRING(MAX),
) PRIMARY KEY (CustomerId);

CREATE TABLE Orders (
  CustomerId STRING(36) NOT NULL,
  OrderId    INT64 NOT NULL DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderSeq)),
  Day        DATE NOT NULL,
  TotalCents INT64 NOT NULL,
) PRIMARY KEY (CustomerId, OrderId),
  INTERLEAVE IN PARENT Customers ON DELETE CASCADE;

CREATE TABLE Stock (
  Product STRING(MAX) NOT NULL,
  Units   INT64 NOT NULL,
) PRIMARY KEY (Product);

CREATE TABLE ByCounter (Id INT64 NOT NULL) PRIMARY KEY (Id);
CREATE TABLE ByUuid (Id STRING(36) NOT NULL DEFAULT (GENERATE_UUID())) PRIMARY KEY (Id);
CREATE TABLE BySequence (Id INT64 NOT NULL DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderSeq))) PRIMARY KEY (Id);
```

**`Customers`, `Orders` e `Stock` são a loja.** `ByCounter`, `ByUuid` e `BySequence` são três
tabelas com nada além de uma chave, uma de cada tipo que a próxima seção compara. `STRING(36)` é o
comprimento de um UUID por extenso, e `STRING(MAX)` é uma string sem limite declarado. Dinheiro é
`INT64` em centavos, como em todo o curso.

```
ana@laptop:~/gcp$ gcloud spanner databases create shop --instance=quitanda --ddl-file=schema.sql
Creating database...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases ddl describe shop --instance=quitanda | grep -c 'CREATE TABLE'
6
```

**O banco existe e tem seis tabelas e uma sequência**, criadas numa só mudança de schema. No Google
Cloud uma mudança de schema é uma operação longa, e acrescentar um índice a uma tabela grande leva um
tempo de que o emulador nunca precisa.

## Linhas, com a linha de comando

Três linhas para trabalhar, um cliente e dois produtos:

```
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Customers --data=CustomerId=c-17,Name=Ana,District=Lapa
commitTimestamp: '2026-10-30T18:46:45.832858Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Stock --data=Product=banana,Units=10
commitTimestamp: '2026-10-30T18:46:46.625355Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Stock --data=Product=rice-5kg,Units=30
commitTimestamp: '2026-10-30T18:46:47.294626Z'
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT Product, Units FROM Stock ORDER BY Product'
Product   Units
banana    10
rice-5kg  30
```

**`rows insert` devolve o timestamp do commit** e mais nada. Toda escrita no Spanner é confirmada num
timestamp, e a quinta seção desta aula lê o banco como ele estava num deles. O `execute-sql` que vem
depois é uma consulta em GoogleSQL, o dialeto padrão do Spanner, e responde como qualquer banco SQL
responderia.

## O outro dialeto

**Um banco é criado num de dois dialetos, e fica nele.** O GoogleSQL é o padrão, e é o que esta aula
usa. O outro é o do PostgreSQL, escolhido com `--database-dialect=POSTGRESQL`, que deixa uma aplicação
manter a grafia do PostgreSQL para DDL, tipos e SQL:

```
ana@laptop:~/gcp$ gcloud spanner databases create shop-pg --instance=quitanda --database-dialect=POSTGRESQL
Creating database...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop-pg --instance=quitanda --ddl='CREATE TABLE customers (customer_id varchar(36) NOT NULL PRIMARY KEY, name text NOT NULL)'
Schema updating...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql="INSERT INTO customers (customer_id, name) VALUES ('c-17', 'Ana')"
Statement modified 1 row
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql='SELECT customer_id, name FROM customers'
customer_id  name
c-17         Ana
```

**`varchar`, `text` e uma `PRIMARY KEY` escrita dentro da lista de colunas** são a grafia do
PostgreSQL, e o banco os aceitou. O que ele é por baixo continua sendo o Spanner, que é o aviso da aula
8 numa transcrição própria:

```
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql='SELECT version()'
ERROR: (gcloud.spanner.databases.execute-sql) HTTPError 501: {"code":12,"message":"Postgres function version() is not supported"}
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop-pg --instance=quitanda --ddl='CREATE EXTENSION pg_trgm'
ERROR: (gcloud.spanner.databases.ddl.update) HTTPError 400: {"code":9,"message":"Statement is not supported."}
```

**`version()` não é suportada, e `CREATE EXTENSION` também não.** O dialeto PostgreSQL é um dialeto, a
gramática, os tipos e muitas das funções; não é um servidor PostgreSQL, e o catálogo de extensões em
que uma aplicação pode se apoiar não está lá. Um programa escrito para o Cloud SQL ou o AlloyDB que
vai para ele é revisado consulta por consulta, e as chaves e a intercalação das duas próximas seções
valem nos dois dialetos. As duas recusas vêm do emulador, que segue a lista do Spanner do que cada
dialeto suporta; o que a lista tem num dado dia é a documentação do Spanner, "PostgreSQL interface",
que diz.
