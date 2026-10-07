---
title: Uma mudança, feita onde não pode machucar
version: 1
---

A lição 14 mudou o `stg_books` para passar toda categoria pelo `initcap`, para que uma editora que
escrevesse `poetry` não abrisse uma categoria nova ao lado de `Poetry`. Essa mudança foi feita no
lugar, na única cópia que havia. Agora ela passa pelos ambientes. Primeiro uma **branch**, para que a
`main` continue sendo aquilo a partir do qual a produção pode ser construída:

```
ana@vm:~/etl$ git switch -q -c initcap-categories && git branch
* initcap-categories
  main
ana@vm:~/etl$ git diff
diff --git a/shop/models/staging/stg_books.sql b/shop/models/staging/stg_books.sql
index fc9095c..27999d9 100644
--- a/shop/models/staging/stg_books.sql
+++ b/shop/models/staging/stg_books.sql
@@ -1,3 +1,3 @@
 -- One row per book.
-select book_id, isbn, title, category, publisher, list_price_cents
+select book_id, isbn, title, initcap(category) as category, publisher, list_price_cents
   from {{ source('raw', 'books') }}
```

Depois um build do projeto inteiro nos schemas da Ana — `dbt build` sem target é `dev`:

```
ana@vm:~/etl/shop$ dbt build --quiet; echo "exit status $?"
exit status 0
ana@vm:~/etl$ psql -d wh -c "\dn dbt*"
     List of schemas
      Name       | Owner 
-----------------+-------
 dbt_ana_marts   | ana
 dbt_ana_staging | ana
 dbt_marts       | ana
 dbt_staging     | ana
(4 rows)
```

Quatro schemas agora: os dois da produção, intocados, e os dois da Ana ao lado. Ela pode consultar,
quebrar e refazer os dela quantas vezes quiser.

Construir o projeto inteiro em desenvolvimento toda vez é desperdício quando um modelo mudou, e num
warehouse grande nem é possível. O `state:modified` da lição 14 escolhe o que mudou; o **`--defer`** do
dbt fornece o resto. Com o manifest da produção como estado, todo modelo que *não* foi escolhido é lido
**da produção**: o `daily_sales` da Ana é construído a partir do `stg_books` novo dela e das views de
pedidos da produção. E uma consulta que compara as versões do mart nos dois ambientes diz se a mudança
fez o que devia:

```
-- Rows of daily_sales that only one of the two environments has.
SELECT 'only in dev'  AS where_, count(*) FROM (TABLE dbt_ana_marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS d
UNION ALL
SELECT 'only in prod' AS where_, count(*) FROM (TABLE dbt_marts.daily_sales EXCEPT TABLE dbt_ana_marts.daily_sales) AS p;
```

```
ana@vm:~/etl$ cp -r ~/etl-prod/shop/target prod-manifest
ana@vm:~/etl/shop$ dbt build -s state:modified+ --state ../prod-manifest --defer 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:37:14  1 of 3 OK created sql view model dbt_ana_staging.stg_books ..................... [CREATE VIEW in 0.10s]
07:37:14  2 of 3 OK created sql table model dbt_ana_marts.daily_sales .................... [INSERT 0 7298 in 0.17s]
07:37:14  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=3
ana@vm:~/etl$ psql -d wh -f compare.sql
    where_    | count 
--------------+-------
 only in dev  |  2711
 only in prod |  2711
(2 rows)
```

Três nós — a view, o mart e o teste dele — e depois uma surpresa. **2.711 linhas diferem**, nas duas
direções. Uma mudança feita para afetar categorias que ainda não existem mudou linhas que existem hoje.
