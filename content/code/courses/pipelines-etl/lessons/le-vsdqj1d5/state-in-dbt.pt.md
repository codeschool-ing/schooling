---
title: dbt, comparando duas versões do projeto
version: 1
---

O dbt tem o seu próprio jeito de refazer só o que mudou, e compara algo melhor que horários: ele
compara **o próprio projeto** com uma cópia guardada dele. Toda execução deixa um `manifest.json` em
`target/`, com o SQL e a configuração de cada modelo. Guarde um de um estado conhecido — o que está
rodando em produção, por exemplo — e o dbt consegue dizer quais modelos são diferentes dele.

A Ana guarda o manifest do último build bom, e então muda o `stg_books` de verdade desta vez: as
categorias passam pelo `initcap`, para que uma editora que mande `poetry` não abra uma categoria nova
ao lado de `Poetry`.

```
ana@vm:~/etl$ rm -rf prod-state && cp -r shop/target prod-state
ana@vm:~/etl$ sed -i 's/select book_id, isbn, title, category, publisher, list_price_cents/select book_id, isbn, title, initcap(category) as category, publisher, list_price_cents/' shop/models/staging/stg_books.sql
ana@vm:~/etl/shop$ dbt ls -s state:modified --state ../prod-state
06:49:16  Running with dbt=1.12.5
06:49:16  Registered adapter: postgres=1.11.0
06:49:17  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
shop.staging.stg_books
ana@vm:~/etl/shop$ dbt ls -s state:modified+ --state ../prod-state --resource-type model --resource-type exposure
06:49:19  Running with dbt=1.12.5
06:49:19  Registered adapter: postgres=1.11.0
06:49:20  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
exposure:shop.morning_report
shop.marts.daily_sales
shop.staging.stg_books
ana@vm:~/etl/shop$ dbt build -s state:modified+ --state ../prod-state 2>&1 | grep -E " OK | PASS | FAIL | WARN |Done"
06:49:23  1 of 4 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.10s]
06:49:23  2 of 4 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6837 in 0.11s]
06:49:23  4 of 4 PASS not_null_daily_sales_order_date .................................... [PASS in 0.05s]
06:49:23  Done. PASS=3 WARN=0 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=4
done
```

O `state:modified` são os modelos cuja definição difere do manifest guardado: só o `stg_books`. Com
um `+`, tudo o que vem depois também: o `daily_sales`, que lê os livros, e o relatório da manhã que lê
o `daily_sales`. O `fact_sales` não está na lista, porque nada do que ele lê mudou. O build que vem a
seguir faz exatamente isso: a view, a tabela e o teste nela.

É uma declaração levada um passo adiante. O projeto diz o que cada tabela deve ser; o manifest
guardado diz como cada tabela **foi construída**; a diferença é o trabalho. Uma mudança só de
comentário também contaria como modificação aqui, já que o texto do SQL mudou, mas um reembolso na
loja continuaria não contando — nenhuma comparação de código enxerga uma mudança nos dados. Numa
equipe, o manifest guardado costuma ser o de produção, e *construir o que este pull request
modificou, e tudo depois dele* é como uma mudança é testada sem refazer o warehouse; a lição 18 volta
a isso.
