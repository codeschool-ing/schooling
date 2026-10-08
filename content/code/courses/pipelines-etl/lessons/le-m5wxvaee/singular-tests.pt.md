---
title: Um teste seu
version: 1
---

Os quatro testes genéricos conferem as colunas de um modelo. A falha que abriu esta lição tinha
outra forma: o `fact_sales` incremental e os dados de onde ele foi construído tinham se afastado, o
que nenhuma coluna de nenhum dos dois diz sozinha. **Um teste singular é um `select` em `tests/`** que
devolve as linhas que estão erradas, com os joins que precisar. O `drift.sql` da lição 11, com `ref`s
no lugar dos nomes de schema, é um:

```
-- Days on which the incremental fact table and a rebuild from staging disagree:
-- lesson 11's drift.sql, made into a test. Every row it returns is a failure.
select order_date, t.lines as in_table, s.lines as in_source
  from (select order_date, count(*) as lines from {{ ref('fact_sales') }} group by 1) as t
  full join (select order_date, count(*) as lines from {{ ref('int_sales') }} group by 1) as s
       using (order_date)
 where t.lines is distinct from s.lines
```

Como ele nomeia o `fact_sales` por `ref`, o dbt sabe que ele vem depois do `fact_sales`, e o `dbt
build` o roda ali. Hoje ele passa. Então chegam mais quatro dias da loja:

```
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "drift|Done"
08:49:03  12 of 12 START test fact_sales_has_not_drifted ................................. [RUN]
08:49:03  12 of 12 PASS fact_sales_has_not_drifted ....................................... [PASS in 0.05s]
08:49:03  Done. PASS=11 WARN=1 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=12
ana@vm:~/etl$ sudo shop until 2026-03-14
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "fact_sales|drift|Done"
08:49:08  11 of 12 START sql incremental model dbt_marts.fact_sales ...................... [RUN]
08:49:08  11 of 12 OK created sql incremental model dbt_marts.fact_sales ................. [INSERT 0 2238 in 0.20s]
08:49:08  12 of 12 START test fact_sales_has_not_drifted ................................. [RUN]
08:49:08  12 of 12 FAIL 11 fact_sales_has_not_drifted .................................... [FAIL 11 in 0.07s]
08:49:09  [ERROR]: in test fact_sales_has_not_drifted (tests/fact_sales_has_not_drifted.sql)
08:49:09    compiled code at target/compiled/shop/tests/fact_sales_has_not_drifted.sql
08:49:09  Done. PASS=10 WARN=1 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=12
ana@vm:~/etl/shop$ dbt build -s fact_sales+ --full-refresh 2>&1 | grep -E "fact_sales|drift|Done"
08:49:12  1 of 2 START sql incremental model dbt_marts.fact_sales ........................ [RUN]
08:49:12  1 of 2 OK created sql incremental model dbt_marts.fact_sales ................... [SELECT 32139 in 0.21s]
08:49:12  2 of 2 START test fact_sales_has_not_drifted ................................... [RUN]
08:49:12  2 of 2 PASS fact_sales_has_not_drifted ......................................... [PASS in 0.09s]
08:49:12  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

O build noturno acrescentou quatro dias ao `fact_sales` e depois **falhou, porque onze dias mais
antigos não batiam mais com a fonte** — pedidos cancelados e reembolsados depois de o dia deles ser
carregado, as mesmas mudanças atrasadas que a lição 11 achou à mão. Nada mais no warehouse teria
dito isso. A recarga completa do `fact_sales` e de tudo o que vem depois dele acerta a tabela, e o
teste volta a passar.

Na lição 11 isso era uma consulta que a Ana lembrava de rodar. Agora faz parte de todo build, e o
build fica vermelho na manhã em que a tabela erra, e não no dia em que alguém por acaso olha.

O teste também sugere a própria correção. Se uma recarga completa é necessária a cada poucos dias,
a janela de volta que a lição 11 descreveu sai mais barata; quão longe voltar é uma pergunta que o
histórico do teste responde, mostrando quão antigos os dias que derivam costumam ser.
