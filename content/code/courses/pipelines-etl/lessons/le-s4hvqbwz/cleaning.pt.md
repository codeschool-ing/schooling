---
title: Limpar: um jeito só de escrever cada coisa
version: 1
---

Os preços chegam de catorze editoras por uma API só, e a API repassa o que o sistema de cada editora
mandou. Antes de limpar qualquer coisa, **descubra o que está errado, e escreva a consulta que o
encontra**, porque a mesma consulta vai ser como você confere que a limpeza funcionou:

```
-- One example of each kind of trouble in the publishers' feed.
SELECT DISTINCT ON (problem)
       problem, doc->>'isbn' AS isbn, format('%L', doc->>'publisher') AS publisher,
       doc->'list_price_cents' AS price, doc->>'currency' AS currency
  FROM (SELECT doc,
               CASE WHEN doc->>'isbn' LIKE '%-%' THEN 'hyphens in the isbn'
                    WHEN jsonb_typeof(doc->'list_price_cents') = 'string' THEN 'price as text'
                    WHEN doc->>'publisher' <> trim(doc->>'publisher') THEN 'space in the name'
                    WHEN doc->'list_price_cents' = 'null' THEN 'no price'
               END AS problem
          FROM raw.prices) AS feed
 WHERE problem IS NOT NULL
 ORDER BY problem, doc->>'isbn';
ana@vm:~/etl$ psql -d wh -f find_problems.sql
       problem       |       isbn        | publisher  | price  | currency 
---------------------+-------------------+------------+--------+----------
 hyphens in the isbn | 978-65-00696-49-3 | 'Maré'     | 7990   | BRL
 no price            | 9786528944132     | 'Oásis'    | null   | BRL
 price as text       | 9786500697902     | 'Farol'    | "5990" | brl
 space in the name   | 9786501522548     | 'Granito ' | 9990   | BRL
(4 rows)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS prices, count(b.book_id) AS matching_a_book FROM raw.prices p LEFT JOIN raw.books b ON b.isbn = p.doc->>'isbn'"
 prices | matching_a_book 
--------+-----------------
    909 |             839
(1 row)
```

```

```

Quatro tipos de problema, cada um vindo dos hábitos de uma editora, e a última consulta mostra quanto
eles custam antes de alguém olhar um único preço: **70 dos 909 preços não batem com livro nenhum**,
porque os ISBNs da Maré têm hífens e os da loja não. Um relatório de preços de tabela por livro
estaria, em silêncio, sem o catálogo inteiro da Maré.

A tabela de staging escreve uma decisão por problema:

```
-- The publishers' prices, parsed out of JSON and made to agree with each other:
-- ISBNs without hyphens, names without stray spaces, one spelling of the
-- currency, a number where a number was sent as text. A price that is missing
-- is not a price, and is left out.
DROP TABLE IF EXISTS staging.prices CASCADE;
CREATE TABLE staging.prices AS
SELECT replace(trim(doc->>'isbn'), '-', '')     AS isbn,
       trim(doc->>'publisher')                  AS publisher,
       (doc->>'list_price_cents')::integer      AS list_price_cents,
       upper(doc->>'currency')                  AS currency,
       (doc->>'updated_at')::timestamptz        AS updated_at
  FROM raw.prices
 WHERE doc->>'list_price_cents' IS NOT NULL;
```

```
ana@vm:~/etl$ psql -q -d wh -f sql/staging/00_schema.sql -f sql/staging/prices.sql
psql:sql/staging/prices.sql:5: NOTICE:  table "prices" does not exist, skipping
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS prices, count(b.book_id) AS matching_a_book FROM staging.prices p LEFT JOIN raw.books b USING (isbn)"
 prices | matching_a_book 
--------+-----------------
    906 |             906
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT publisher, currency, count(*) FROM staging.prices WHERE publisher IN ('Maré', 'Farol', 'Granito') GROUP BY 1, 2 ORDER BY 1"
 publisher | currency | count 
-----------+----------+-------
 Farol     | BRL      |    72
 Granito   | BRL      |    76
 Maré      | BRL      |    69
(3 rows)
```

Cada preço agora bate com um livro, a Granito é uma editora em vez de uma editora com um espaço, e a
moeda da Farol está escrita como a de todo mundo.

## Três regras que o arquivo segue

- **Limpe no staging, uma vez.** Todo relatório que precisa de um preço lê `staging.prices`. Se a
  limpeza morasse em cada relatório, o próximo relatório esqueceria os hífens.
- **Diga o que foi descartado, e por quê.** Três preços não tinham valor e ficaram de fora, e o
  comentário diz isso. Uma etapa de limpeza que remove linhas em silêncio é um filtro que ninguém
  conhece. A lição 16 transforma "quantos foram descartados" num número que o pipeline confere.
- **Conserte a forma, nunca os fatos.** Tirar os hífens muda como um ISBN é escrito, não qual livro
  ele nomeia. Trocar um preço que falta por uma média inventaria um fato, e o warehouse o mostraria
  como se uma editora o tivesse dito.
