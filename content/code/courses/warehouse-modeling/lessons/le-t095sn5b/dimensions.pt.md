---
title: Dimensões: quem, o quê, onde e quando
version: 2
---

Uma **tabela dimensão** guarda as coisas que descrevem um fato, uma linha por coisa, com todo
atributo pelo qual uma pessoa possa filtrar ou agrupar. Ela responde às perguntas de que um número
precisa antes de significar algo: *qual* livro, *qual* loja, *qual* dia.

A Ana constrói três para o processo de vendas, mais uma pequena para promoções, um arquivo SQL para
cada. `dim_book.sql` e `dim_shop.sql` estão nesta seção e `dim_promotion.sql` no fim dela;
`dim_date.sql` é o assunto da seção 06. Salve os quatro em `~/wh` e então:

```
ana@lab:~/wh$ for f in dim_date dim_shop dim_book dim_promotion; do duckdb wh.duckdb < $f.sql; done
```

Veja um livro como o warehouse o guarda:

```
ana@lab:~/wh$ duckdb -line wh.duckdb -c "SELECT * FROM dim_book WHERE book_id = 2395"
    book_key = 581
     book_id = 2395
        isbn = 9786519698044
       title = The Salt Season IV
     authors = Petra Dahl Torres
      format = hardcover
    category = Brazilian history
 subcategory = History
  department = Non-fiction
   publisher = Editora Litoral
published_on = 2007-12-21
```

**Larga, achatada e escrita para uma pessoa.** O banco operacional espalha este livro por cinco
tabelas: `books`, `book_authors`, `authors`, `categories` três vezes, e `publishers`. Aqui ele é uma
linha, e cada coluna é uma palavra que alguém poria num relatório: o departamento, o nome da editora,
os autores em ordem. Nada precisa ser ligado para descobrir o que um `category_id` significa, porque
não existe `category_id`.

É assim que a `dim_book` é construída:

```sql
-- The category tree has three levels where it branches and two where it does
-- not; every book gets all three, repeating the name where a level is missing.
CREATE TABLE dim_book AS
WITH writers AS (
    SELECT ba.book_id, string_agg(a.name, '; ' ORDER BY ba.position) AS authors
    FROM staging.book_authors ba JOIN staging.authors a USING (author_id)
    GROUP BY ba.book_id
)
SELECT row_number() OVER (ORDER BY b.isbn)                     AS book_key,
       b.book_id,
       b.isbn,
       b.title,
       w.authors,
       b.format,
       leaf.name                                               AS category,
       CASE WHEN up2.category_id IS NULL THEN leaf.name ELSE up1.name END AS subcategory,
       coalesce(up2.name, up1.name)                            AS department,
       p.name                                                  AS publisher,
       b.published_on
FROM staging.books b
JOIN staging.categories leaf ON leaf.category_id = b.category_id
JOIN staging.categories up1  ON up1.category_id = leaf.parent_id
LEFT JOIN staging.categories up2 ON up2.category_id = up1.parent_id
JOIN staging.publishers p    ON p.publisher_id = b.publisher_id
JOIN writers w               ON w.book_id = b.book_id;
```

O meio dela trata a árvore de categorias irregular da lição 1, **uma vez**. Um livro sob um ramo de
dois níveis, como *Manga*, recebe a própria categoria repetida como subcategoria, então toda linha tem
os três níveis e ninguém que escreve um relatório precisa saber quais ramos são rasos.

## Três propriedades que toda dimensão tem

- **Uma chave própria.** `book_key` é um número que o warehouse atribui, ao lado do `book_id` da
  rede. A lição 4 é sobre por que os dois ficam separados; por ora, note que são números diferentes,
  581 e 2395 para este livro.
- **Atributos descritivos, em texto.** `format` diz `hardcover`, não `2`. Um código que precisa de
  uma tabela de consulta para ser lido é uma junção que todo relatório precisa lembrar.
- **Poucas linhas, muitas colunas.** 3.000 livros, 7 lojas, 732 linhas de datas: tabelas pequenas
  para as quais toda linha fato aponta.

As lojas vêm de `dim_shop.sql`:

```sql
CREATE TABLE dim_shop AS
SELECT row_number() OVER (ORDER BY opened_on) AS shop_key,
       shop_id,
       name                                   AS shop_name,
       coalesce(city, 'Online')               AS city,
       coalesce(state, '--')                  AS state,
       CASE WHEN state IN ('SP', 'MG') THEN 'Southeast'
            WHEN state IN ('PR', 'RS') THEN 'South'
            ELSE 'Online' END                 AS region,
       channel,
       opened_on
FROM staging.shops;
```

Todas elas:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM dim_shop"
┌──────────┬─────────┬───────────┬────────────────┬─────────┬───────────┬─────────┬────────────┐
│ shop_key │ shop_id │ shop_name │      city      │  state  │  region   │ channel │ opened_on  │
│  int64   │  int64  │  varchar  │    varchar     │ varchar │  varchar  │ varchar │    date    │
├──────────┼─────────┼───────────┼────────────────┼─────────┼───────────┼─────────┼────────────┤
│        1 │       1 │ Paulista  │ São Paulo      │ SP      │ Southeast │ store   │ 2012-04-02 │
│        2 │       3 │ Cambuí    │ Campinas       │ SP      │ Southeast │ store   │ 2016-03-05 │
│        3 │       4 │ Savassi   │ Belo Horizonte │ MG      │ Southeast │ store   │ 2018-06-01 │
│        4 │       2 │ Pinheiros │ São Paulo      │ SP      │ Southeast │ store   │ 2019-09-14 │
│        5 │       7 │ Online    │ Online         │ --      │ Online    │ online  │ 2020-05-04 │
│        6 │       5 │ Batel     │ Curitiba       │ PR      │ South     │ store   │ 2021-11-20 │
│        7 │       6 │ Moinhos   │ Porto Alegre   │ RS      │ South     │ store   │ 2025-03-08 │
└──────────┴─────────┴───────────┴────────────────┴─────────┴───────────┴─────────┴────────────┘
```

`region` não existe em nenhuma tabela operacional. A Ana a acrescentou porque o gerente compara o Sul
com o Sudeste, e **uma dimensão é o lugar de um atributo assim**: escrito uma vez, a partir do estado,
e disponível para toda tabela fato que aponte para uma loja. A loja online não tem cidade, e recebe a
palavra `Online` em vez de uma célula vazia, para que um relatório agrupado por cidade tenha uma linha
que consiga rotular.

## As promoções

`dim_promotion.sql` copia as dez promoções e acrescenta uma linha que não é promoção nenhuma: a chave
0, *No promotion*, para onde aponta toda venda sem promoção. A lição 4 explica por que uma linha assim
é melhor que uma chave vazia.

```sql
CREATE TABLE dim_promotion AS
SELECT promotion_id AS promotion_key, promotion_id, code, name AS promotion_name,
       percent_off, starts_on, ends_on, coalesce(category, 'All departments') AS applies_to
FROM staging.promotions
UNION ALL
SELECT 0, NULL, '', 'No promotion', 0, NULL, NULL, ''
ORDER BY promotion_key;
```
