---
title: O que a comparação pegou
version: 1
---

Que categorias estão no mart da Ana e não no da produção:

```
ana@vm:~/etl$ psql -d wh -c "SELECT DISTINCT category FROM dbt_ana_marts.daily_sales EXCEPT SELECT DISTINCT category FROM dbt_marts.daily_sales ORDER BY 1"
     category     
------------------
 Graphic Novels
 Literary Fiction
 Picture Books
 Science Fiction
 Young Adult
(5 rows)
```

O `initcap` põe em maiúscula **cada palavra**, não só a primeira. *Graphic novels* virou *Graphic
Novels*, e mais quatro também. As categorias do relatório teriam mudado de nome de um dia para o
outro, todo gráfico que filtra *Science fiction* teria ficado vazio, e ninguém teria pedido nada
disso. Na lição 14 essa mudança entrou na única cópia que havia e ninguém percebeu; aqui ela foi pega
em desenvolvimento, por uma comparação que levou um segundo.

O que a Ana queria era mais estreito: a primeira letra maiúscula e o resto como a editora escreveu.
Ela diz exatamente isso, e constrói de novo:

```
ana@vm:~/etl$ git diff
diff --git a/shop/models/staging/stg_books.sql b/shop/models/staging/stg_books.sql
index fc9095c..4cbcec1 100644
--- a/shop/models/staging/stg_books.sql
+++ b/shop/models/staging/stg_books.sql
@@ -1,3 +1,3 @@
 -- One row per book.
-select book_id, isbn, title, category, publisher, list_price_cents
+select book_id, isbn, title, upper(left(category, 1)) || substr(category, 2) as category, publisher, list_price_cents
   from {{ source('raw', 'books') }}
ana@vm:~/etl/shop$ dbt build -s state:modified+ --state ../prod-manifest --defer 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:37:17  1 of 3 OK created sql view model dbt_ana_staging.stg_books ..................... [CREATE VIEW in 0.10s]
07:37:18  2 of 3 OK created sql table model dbt_ana_marts.daily_sales .................... [INSERT 0 7298 in 0.17s]
07:37:18  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=3
ana@vm:~/etl$ psql -d wh -f compare.sql
    where_    | count 
--------------+-------
 only in dev  |     0
 only in prod |     0
(2 rows)
```

Zero linhas nas duas direções. **A mudança não faz nada com os dados de hoje**, o que é exatamente o
certo para uma mudança cujo propósito é proteger os de amanhã. É o resultado a querer de uma
refatoração, e a comparação é como saber que ele foi obtido, e não só esperado.

É esse o hábito que a lição ensina. Uma mudança num pipeline é uma mudança em números que
outras pessoas leem, e o único jeito de saber o que ela faz com eles é construí-la ao lado da produção
e comparar. **Os testes dizem que o código continua funcionando; a comparação diz o que ele agora
diz.** Os dois são necessários, porque uma mudança pode passar em todo teste e ainda renomear cinco
categorias.
