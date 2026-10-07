---
title: A primeira execução, e para onde ela foi
version: 1
---

```
ana@vm:~/etl/shop$ dbt run
06:26:58  Running with dbt=1.12.5
06:26:59  Registered adapter: postgres=1.11.0
06:26:59  Unable to do partial parsing because saved manifest not found. Starting full parse.
06:27:00  Found 4 models, 3 sources, 477 macros
06:27:00  
06:27:00  Concurrency: 4 threads (target='dev')
06:27:00  
06:27:00  2 of 4 START sql view model dbt_staging.stg_order_lines ........................ [RUN]
06:27:00  3 of 4 START sql view model dbt_staging.stg_orders ............................. [RUN]
06:27:00  1 of 4 START sql view model dbt_staging.stg_books .............................. [RUN]
06:27:00  1 of 4 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.16s]
06:27:00  2 of 4 OK created sql view model dbt_staging.stg_order_lines ................... [CREATE VIEW in 0.17s]
06:27:00  3 of 4 OK created sql view model dbt_staging.stg_orders ........................ [CREATE VIEW in 0.18s]
06:27:00  4 of 4 START sql table model dbt_marts.daily_sales ............................. [RUN]
06:27:00  4 of 4 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6195 in 0.09s]
06:27:00  
06:27:00  Finished running 1 table model, 3 view models in 0 hours 0 minutes and 0.38 seconds (0.38s).
06:27:00  
06:27:00  Completed successfully
06:27:00  
06:27:00  Done. PASS=4 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=4
```

Quatro modelos, e a ordem é a que os `ref`s implicam: as três views primeiro, ao mesmo tempo — o
projeto permite quatro threads, e nenhuma delas depende de outra — e o `daily_sales` só quando as
três terminaram. O `SELECT 6195` é o número de linhas com que a tabela foi construída.

Mas olhe os schemas: `dbt_staging` e `dbt_marts`, não `staging` e `marts`.

```
ana@vm:~/etl$ psql -d wh -c "\dn"
         List of schemas
    Name     |       Owner       
-------------+-------------------
 dbt_marts   | ana
 dbt_staging | ana
 marts       | ana
 public      | pg_database_owner
 raw         | ana
 staging     | ana
(6 rows)
```

**Esse é o padrão do dbt, e é de propósito.** Um `+schema` próprio é *somado* ao schema do target,
não posto no lugar dele: `dbt` do profile, depois `_staging`. O motivo é uma equipe. O profile de
cada pessoa nomeia o próprio schema de target — `dbt_ana`, `dbt_rui` — e todo mundo pode construir
o projeto inteiro ao mesmo tempo sem sobrescrever o de ninguém, nem o de produção. A lição 18 usa
exatamente isso para manter um warehouse de desenvolvimento separado do real. O comportamento mora
numa macro chamada `generate_schema_name`, e um projeto pode trocá-la; a Ana não troca, porque aqui
ela lhe dá algo que ela quer.

O pipeline antigo dela construía `staging` e `marts`, e ele continua lá. Então, por enquanto, os dois
rodam lado a lado, e **a primeira coisa que a Ana faz com o novo é conferi-lo contra o antigo**:

```
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM (TABLE marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS old_only" -c "SELECT count(*) FROM (TABLE dbt_marts.daily_sales EXCEPT TABLE marts.daily_sales) AS new_only"
 count 
-------
     0
(1 row)

 count 
-------
     0
(1 row)
```

`EXCEPT` nas duas direções, e nada de nenhum lado: as mesmas linhas, os mesmos números. Uma
reescrita que não foi comparada com o que substitui não foi testada, por mais limpa que pareça.
