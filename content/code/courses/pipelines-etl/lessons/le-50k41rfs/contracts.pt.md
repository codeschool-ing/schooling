---
title: Um contrato para o que outros leem
version: 1
---

O relatório da manhã lê o `daily_sales`, e confia em mais do que as linhas: em que as colunas estejam
lá, com esses nomes, e em que o `revenue_cents` seja um número inteiro de centavos. Nada disso está
escrito em lugar algum que o pipeline confira. Qualquer mudança no modelo — uma refatoração, uma
"correçãozinha" — pode alterar isso, e o relatório descobre ficando errado.

Um **contrato** escreve isso onde o dbt o faz valer. No YAML do modelo, o contrato é ligado e cada
coluna ganha o seu tipo:

```
version: 2

models:
  - name: daily_sales
    description: >
      Books and revenue by day, shop and category, counting completed sales only.
      One row per combination that sold anything. Read by the morning report.
    config:
      contract:
        enforced: true            # these columns, with these types, or the build fails
    columns:
      - name: order_date
        data_type: date
        description: The day of the sale in São Paulo, not in UTC.
        constraints:
          - type: not_null
      - name: shop_id
        data_type: integer
      - name: category
        data_type: text
      - name: books
        data_type: integer
      - name: revenue_cents
        data_type: bigint
        description: Sum of quantity times unit price, in cents of a real.
  - name: fact_sales
    description: >
      One row per order line sold. Incremental: each run replaces the last thirty
      days it has, so changes older than that need a full refresh.
    columns:
      - name: customer_id
        description: Null for a sale at a till to nobody, and for a customer erased on request.
```

Com o contrato valendo, o dbt compara as colunas que o `select` do modelo produz com as declaradas,
**antes** de construir a tabela. O primeiro build bate e roda. Então alguém decide que o relatório
ficaria melhor em reais:

```
ana@vm:~/etl/shop$ dbt build -s daily_sales 2>&1 | grep -E " OK | PASS |ERROR|Done"
07:03:43  1 of 1 OK created sql table model dbt_marts.daily_sales ........................ [INSERT 0 7202 in 0.21s]
07:03:43  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ sed -i 's/sum(s.line_cents)::bigint as revenue_cents/sum(s.line_cents) \/ 100.0 as revenue_cents/' shop/models/marts/daily_sales.sql
ana@vm:~/etl$ grep -n revenue_cents shop/models/marts/daily_sales.sql
6:       sum(s.line_cents) / 100.0 as revenue_cents
ana@vm:~/etl/shop$ dbt build -s daily_sales 2>&1 | grep -vE "^[0-9:]{8}  (Running|Registered|Found|Concurrency|Finished|$)" | grep -v "^$"
07:03:46  1 of 1 START sql table model dbt_marts.daily_sales ............................. [RUN]
07:03:46  1 of 1 ERROR creating sql table model dbt_marts.daily_sales .................... [ERROR in 0.10s]
07:03:46  Completed with 1 error, 0 partial successes, and 0 warnings:
07:03:46  [ERROR]: in model daily_sales (models/marts/daily_sales.sql)
07:03:46    Compilation Error in model daily_sales (models/marts/daily_sales.sql)
  This model has an enforced contract that failed.
  Please ensure the name, data_type, and number of columns in your contract match the columns in your model's definition.
  
  | column_name   | definition_type | contract_type | mismatch_reason    |
  | ------------- | --------------- | ------------- | ------------------ |
  | revenue_cents | DECIMAL         | LONGINTEGER   | data type mismatch |
  
  
  > in macro assert_columns_equivalent (macros/relations/column/columns_spec_ddl.sql)
  > called by macro default__get_assert_columns_equivalent (macros/relations/column/columns_spec_ddl.sql)
  > called by macro get_assert_columns_equivalent (macros/relations/column/columns_spec_ddl.sql)
  > called by macro postgres__create_table_as (macros/adapters.sql)
  > called by macro create_table_as (macros/relations/table/create.sql)
  > called by macro default__get_create_table_as_sql (macros/relations/table/create.sql)
  > called by macro get_create_table_as_sql (macros/relations/table/create.sql)
  > called by macro statement (macros/etc/statement.sql)
  > called by macro materialization_table_default (macros/materializations/models/table.sql)
  > called by model daily_sales (models/marts/daily_sales.sql)
07:03:46    compiled code at target/compiled/shop/models/marts/daily_sales.sql
07:03:46  Done. PASS=0 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
ana@vm:~/etl$ sed -i 's/sum(s.line_cents) \/ 100.0 as revenue_cents/sum(s.line_cents)::bigint as revenue_cents/' shop/models/marts/daily_sales.sql
```

A tabela não foi construída. O dbt nomeia a coluna, o tipo que o modelo agora produz — `DECIMAL` — e o
tipo que o contrato prometeu — `LONGINTEGER`, a palavra dele para `bigint` — e para. O relatório
continua lendo a tabela de ontem com o significado de ontem, e a pessoa que fez a mudança descobre
pelo build, e não por um gerente. A Ana põe a linha de volta como estava.

Duas coisas que um contrato não é. Não é um teste das linhas: uma coluna `bigint` ainda pode guardar
números errados, que é para o que servem os testes. E não é permanente: um contrato pode mudar, mas aí
muda **de propósito**, no YAML, onde um revisor vê — e o dono do relatório pode ser avisado antes. A
lição 18 trata de como uma mudança assim chega à produção.

O `not_null` sob o `order_date` é uma **restrição** (*constraint*): o dbt a acrescenta à tabela que
cria, então o próprio PostgreSQL recusa um nulo ali, venha de quem vier.
