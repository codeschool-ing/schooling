---
title: ELT: carregar primeiro, transformar onde os dados caem
version: 1
---

A versão ELT divide o trabalho em dois, e a primeira metade não faz ideia de qual é a pergunta. Ela
copia os pedidos da semana, as suas linhas e os livros para um schema do warehouse chamado `raw`,
exatamente como a loja os tem:

```schooling-example
{
  "language": "python",
  "file": "extract_load.py",
  "parts": [
    {
      "code": "\"\"\"ELT, first half: copy the shop's rows for a range of days into the\nwarehouse's raw schema, exactly as they are.\"\"\"\nimport datetime as dt\nimport sys\n\nimport psycopg\nfrom psycopg import sql\n\n"
    },
    {
      "code": "first, last = (dt.date.fromisoformat(a) for a in sys.argv[1:3])\nwindow = sql.SQL(\"ordered_at >= {} AND ordered_at < {}\").format(\n    sql.Literal(first), sql.Literal(last + dt.timedelta(days=1)))\n",
      "note": "O período vira um pedaço de SQL, montado com `psycopg.sql` para que as datas sejam citadas pela biblioteca em vez de coladas numa string."
    },
    {
      "code": "QUERIES = {\n    \"orders\": sql.SQL(\"SELECT * FROM orders WHERE {}\").format(window),\n    \"order_lines\": sql.SQL(\"SELECT l.* FROM order_lines l JOIN orders o USING (order_id)\"\n                           \" WHERE {}\").format(window),\n    \"books\": sql.SQL(\"SELECT * FROM books\"),\n}\n\n",
      "note": "Três consultas, uma por tabela, e **nenhuma transforma nada**. As linhas são escolhidas pela data do pedido, e os livros vêm inteiros, porque uma linha pode citar qualquer livro."
    },
    {
      "code": "with psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    wh.execute(\"CREATE SCHEMA IF NOT EXISTS raw\")\n    wh.execute(open(\"raw.sql\").read())\n",
      "note": "As tabelas cruas são criadas se faltarem, a partir de `raw.sql`."
    },
    {
      "code": "    wh.execute(\"DELETE FROM raw.order_lines WHERE order_id IN (SELECT order_id FROM raw.orders\"\n               \" WHERE {})\".format(window.as_string(wh)))\n    wh.execute(\"DELETE FROM raw.orders WHERE {}\".format(window.as_string(wh)))\n    wh.execute(\"TRUNCATE raw.books\")\n",
      "note": "O que uma execução anterior carregou para o mesmo período é removido antes, para que o período seja substituído em vez de somado de novo."
    },
    {
      "code": "    for table, query in QUERIES.items():\n        src, dst = shop.cursor(), wh.cursor()\n        with src.copy(sql.SQL(\"COPY ({}) TO STDOUT\").format(query)) as out, \\\n             dst.copy(sql.SQL(\"COPY raw.{} FROM STDIN\").format(sql.Identifier(table))) as into:\n",
      "note": "**`COPY ... TO STDOUT` de um lado, `COPY ... FROM STDIN` do outro.** As linhas fluem de um banco para o outro no formato do próprio PostgreSQL, sem nunca virar objetos Python. A lição 19 mede quanto isso vale."
    },
    {
      "code": "            for chunk in out:\n                into.write(chunk)\n        print(f\"raw.{table}: {src.rowcount} rows\")"
    }
  ]
}
```

As tabelas que ela enche são declaradas uma vez, em `raw.sql`, com as colunas da loja e nenhuma das
suas regras — nenhuma chave primária, nenhuma chave estrangeira, nenhum check:

```
-- The raw layer: the shop's tables as the shop has them, no keys enforced and
-- nothing cleaned. Created once; extract_load.py fills it.
CREATE TABLE IF NOT EXISTS raw.orders (
  order_id integer, shop_id integer, customer_id integer,
  ordered_at timestamptz, status text, updated_at timestamptz);
CREATE TABLE IF NOT EXISTS raw.order_lines (
  order_id integer, line_no integer, book_id integer,
  quantity integer, unit_price_cents integer);
CREATE TABLE IF NOT EXISTS raw.books (
  book_id integer, isbn text, title text, category text, publisher text,
  list_price_cents integer, updated_at timestamptz);
```

**Não ter regras é uma decisão, não um esquecimento.** O trabalho da camada crua é guardar o que a
origem disse, inclusive o que a origem errou. Uma chave estrangeira aqui recusaria uma linha cujo
livro a loja apagou depois, e então o warehouse discordaria da origem sobre o que aconteceu sem
avisar. Conferir é tarefa dos passos depois deste, onde uma recusa pode ser relatada.

```
ana@vm:~/etl$ time python extract_load.py 2026-03-01 2026-03-07
raw.orders: 1933 rows
raw.order_lines: 3048 rows
raw.books: 1200 rows

real	0m0.225s
user	0m0.186s
sys	0m0.016s
```

A segunda metade é a pergunta, escrita em SQL e rodada dentro do warehouse:

```
-- ELT, second half: the same question, answered inside the warehouse.
DROP TABLE IF EXISTS elt_sales_by_category;
CREATE TABLE elt_sales_by_category AS
SELECT (o.ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS day,
       b.category,
       sum(l.quantity)::integer AS books,
       sum(l.quantity * l.unit_price_cents)::bigint AS revenue_cents
  FROM raw.orders o
  JOIN raw.order_lines l USING (order_id)
  JOIN raw.books b USING (book_id)
 WHERE o.status = 'completed'
 GROUP BY 1, 2;
```

```
ana@vm:~/etl$ time psql -d wh -f sales_by_category.sql
psql:sales_by_category.sql:2: NOTICE:  table "elt_sales_by_category" does not exist, skipping
DROP TABLE
SELECT 98

real	0m0.016s
user	0m0.000s
sys	0m0.005s
```

## A mesma resposta?

**Dois programas que deveriam concordar devem ser obrigados a provar isso**, e o SQL tem o operador
para tanto. O `EXCEPT` devolve as linhas da primeira consulta que não estão na segunda; rode-o nas
duas direções, e duas respostas vazias significam que as tabelas têm as mesmas linhas:

```
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM (SELECT * FROM etl_sales_by_category EXCEPT SELECT * FROM elt_sales_by_category) AS only_etl"
 count 
-------
     0
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM (SELECT * FROM elt_sales_by_category EXCEPT SELECT * FROM etl_sales_by_category) AS only_elt"
 count 
-------
     0
(1 row)
```

Nada numa tabela que não esteja na outra: a resposta ETL e a ELT concordam nas noventa e oito
linhas, até o centavo. **Essa conferência é barata e vale a pena manter**: um pipeline que
substitui outro é o momento mais comum de uma diferença silenciosa, e a lição 17 transforma a
comparação num teste.

Um detalhe é diferente e é fácil não ver. No `etl.py`, o `.date()` transformou cada horário numa
data de São Paulo porque o psycopg o entregou no fuso da sessão. Em SQL a mesma coisa é `AT TIME
ZONE 'America/Sao_Paulo'`, escrito por extenso. **Um dia é uma opinião de um fuso horário**, e os
dois programas concordam porque os dois perguntaram a São Paulo; a lição 6 mostra o que acontece
quando um deles não pergunta.
