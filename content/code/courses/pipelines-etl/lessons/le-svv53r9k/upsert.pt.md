---
title: O upsert: inserir o novo, sobrescrever o alterado
version: 1
---

Uma dimensão guarda uma linha por coisa — um livro, uma loja — e a carga precisa inserir as novas e
mudar as que mudaram, sem tocar no resto. O PostgreSQL faz as duas coisas num comando só:

```
-- marts.dim_book: one row per book, as it is now. A changed price overwrites
-- the old one (type 1); a new book is inserted.
CREATE TABLE IF NOT EXISTS marts.dim_book (
  book_id          integer PRIMARY KEY,
  isbn             text    NOT NULL,
  title            text    NOT NULL,
  category         text    NOT NULL,
  publisher        text    NOT NULL,
  list_price_cents integer NOT NULL);

INSERT INTO marts.dim_book AS d
SELECT book_id, isbn, title, category, publisher, list_price_cents
  FROM staging.books
    ON CONFLICT (book_id) DO UPDATE
   SET isbn = excluded.isbn, title = excluded.title, category = excluded.category,
       publisher = excluded.publisher, list_price_cents = excluded.list_price_cents
 WHERE (d.isbn, d.title, d.category, d.publisher, d.list_price_cents)
       IS DISTINCT FROM (excluded.isbn, excluded.title, excluded.category,
                         excluded.publisher, excluded.list_price_cents)
RETURNING (xmax = 0) AS inserted;
```

O `ON CONFLICT (book_id)` transforma uma inserção que colidiria com um livro existente numa
atualização desse livro. Três detalhes nele fazem trabalho de verdade:

- **o `WHERE` da atualização** compara a linha antiga com a nova, e pula os livros que não mudaram.
  Sem ele, cada um dos 1.200 livros seria reescrito toda noite — 1.200 versões novas de linha para o
  PostgreSQL limpar, e uma coluna como `updated_at`, se houvesse uma, dizendo que todo livro mudou
  hoje;
- **o `RETURNING (xmax = 0)`** informa, para cada linha escrita, se ela foi inserida (`t`) ou
  atualizada (`f`). Ele se apoia num detalhe do PostgreSQL — uma linha recém-inserida não tem
  transação de exclusão registrada — e é como o `nightly.sh` imprime a sua contagem;
- **o alvo do conflito é uma restrição de verdade.** O `ON CONFLICT (book_id)` só funciona porque
  `book_id` é a chave primária. Um upsert numa coluna sem índice único é um erro, o que é o resultado
  certo: sem ele, "a linha existente" não é uma coisa bem definida.

Em 3 de março uma editora mudou o preço de um livro:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-03
ana@vm:~/etl$ grep "^UPDATE books" /var/lib/etl-data/days/2026-03-03.sql
UPDATE books SET list_price_cents = 5990, updated_at = '2026-03-03 07:09:32-03:00' WHERE book_id = 136;
ana@vm:~/etl$ sh nightly.sh 2026-03-03
      1 updated
2026-03-03: 477 fact rows
```

**Um livro atualizado, os outros 1.199 intocados.** O preço antigo se foi: `dim_book` é uma dimensão
de *tipo 1*, que guarda só o presente. Para um preço de tabela, quase sempre é isso que um relatório
quer — o preço que o livro tem agora. Um relatório que precisa do preço que um livro tinha no dia em
que foi vendido não deve perguntar à dimensão: o preço pago está na linha do pedido, registrado no
momento da venda.

O `MERGE`, do padrão SQL e presente no PostgreSQL desde a versão 15, faz o mesmo trabalho com mais
ramos — atualizar quando casa, apagar quando casa e está marcado, inserir quando não casa. Para um
inserir-ou-atualizar, o `ON CONFLICT` é mais curto e é o que este curso usa.
