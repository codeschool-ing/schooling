---
title: Uma view se agarra à sua tabela
version: 1
---

Chega o próximo dia de vendas, e a Ana carrega o `raw` como faz todo dia desde a lição 6:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-10
ana@vm:~/etl$ python load_raw.py
raw.shops: 7 rows
Traceback (most recent call last):
  File "/home/ana/etl/load_raw.py", line 18, in <module>
    wh.execute(f"DROP TABLE IF EXISTS raw.{table}")
    ~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/etl/py/lib/python3.13/site-packages/psycopg/connection.py", line 304, in execute
    raise ex.with_traceback(None)
psycopg.errors.DependentObjectsStillExist: cannot drop table raw.books because other objects depend on it
DETAIL:  view dbt_staging.stg_books depends on table raw.books
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
```

**O carregador que funcionou ontem falha hoje, e nada nele mudou.** O que mudou é que o `raw.books`
agora tem uma view construída sobre ele. No PostgreSQL uma view fica presa à tabela que lê, não ao
nome dela: a tabela não pode ser apagada enquanto a view existir, porque a view ficaria apontando
para o nada. Um `DROP … CASCADE` apagaria a view junto — e o staging do dbt sumiria em silêncio até
o próximo `dbt run`.

A falha não custou nada, porém. O carregador escreve no warehouse numa única transação, com commit
quando o bloco `with` termina, então o `raw.shops`, já recriado, foi desfeito junto com todo o resto,
e o `raw` está exatamente como estava antes do comando.

A correção é no carregador, não no dbt. **Uma tabela sobre a qual outras coisas são construídas é
esvaziada e preenchida de novo, nunca apagada**:

```
ana@vm:~/etl$ diff /tmp/load_raw.before.py load_raw.py
18,19c18,20
<         wh.execute(f"DROP TABLE IF EXISTS raw.{table}")
<         wh.execute(f"CREATE TABLE raw.{table} ({columns})")
---
>         # Emptied and refilled, never dropped: dbt's views are built on these tables.
>         wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{table} ({columns})")
>         wh.execute(f"TRUNCATE raw.{table}")
29,30c30,31
<         wh.execute(f"DROP TABLE IF EXISTS raw.{name}")
<         wh.execute(f"CREATE TABLE raw.{name} (doc jsonb NOT NULL, file text NOT NULL)")
---
>         wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{name} (doc jsonb NOT NULL, file text NOT NULL)")
>         wh.execute(f"TRUNCATE raw.{name}")
ana@vm:~/etl$ python load_raw.py
raw.shops: 7 rows
raw.books: 1200 rows
raw.customers: 5271 rows
raw.orders: 19700 rows
raw.order_lines: 30850 rows
raw.payments: 19700 rows
raw.prices: 0 documents
raw.events: 26334 documents
```

O `CREATE TABLE IF NOT EXISTS` cria a tabela da primeira vez e não faz nada depois, e o `TRUNCATE` a
esvazia. Duas consequências vêm junto. O `TRUNCATE` pega o mesmo lock exclusivo que a lição 7
descreveu, então uma consulta numa view de staging espera o carregador fazer commit em vez de ver uma
tabela vazia. E as colunas agora ficam fixadas pela primeira carga: **se a loja acrescentar uma
coluna, o `raw` não vai ganhá-la sozinho**, e o `COPY` falha com um número de colunas que não bate.
Essa falha é barulhenta, que é o tipo certo; a lição 16 trata de fazer de mudanças assim um contrato
em vez de uma surpresa.
