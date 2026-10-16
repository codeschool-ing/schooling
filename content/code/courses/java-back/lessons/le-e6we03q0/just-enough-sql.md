---
title: Just enough SQL
version: 1
---

JDBC carries SQL; it does not replace it. So before any Java, the four statements this lesson
needs, typed straight into `psql`. They are a working minimum. `sql-databases` is the course that
teaches the language properly, starting from why tables are shaped the way they are.

A **table** is a set of rows that all have the same columns, and each column has a type. The
bookshop's catalogue is one table, `book`, and its definition says as much about what is refused as
about what is stored. Connect as in the last section and type it:

```
ana@vm:~$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

bookshop=> CREATE TABLE book (
bookshop(>     id          bigserial PRIMARY KEY,
bookshop(>     isbn        char(13)  NOT NULL UNIQUE,
bookshop(>     title       text      NOT NULL,
bookshop(>     author      text      NOT NULL,
bookshop(>     price_cents integer   NOT NULL CHECK (price_cents >= 0)
bookshop(> );
CREATE TABLE

bookshop=> INSERT INTO book (isbn, title, author, price_cents) VALUES
bookshop->     ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
bookshop->     ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
bookshop->     ('9786500000047', 'The War of the Worlds', 'H. G. Wells', 3200),
bookshop->     ('9786500000054', 'Wise Blood', 'Flannery O''Connor', 4100);
INSERT 0 4

bookshop=> SELECT * FROM book;
 id |     isbn      |         title         |      author       | price_cents 
----+---------------+-----------------------+-------------------+-------------
  1 | 9786500000016 | Dom Casmurro          | Machado de Assis  |        3990
  2 | 9786500000023 | The Time Machine      | H. G. Wells       |        2950
  3 | 9786500000047 | The War of the Worlds | H. G. Wells       |        3200
  4 | 9786500000054 | Wise Blood            | Flannery O'Connor |        4100
(4 rows)

bookshop=> SELECT title, price_cents FROM book WHERE author = 'H. G. Wells';
         title         | price_cents 
-----------------------+-------------
 The Time Machine      |        2950
 The War of the Worlds |        3200
(2 rows)

bookshop=> INSERT INTO book (isbn, title, author, price_cents) VALUES ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950);
ERROR:  duplicate key value violates unique constraint "book_isbn_key"
DETAIL:  Key (isbn)=(9786500000023) already exists.

bookshop=> INSERT INTO book (isbn, title, author, price_cents) VALUES ('9786500000030', 'Frankenstein', 'Mary Shelley', -1);
ERROR:  new row for relation "book" violates check constraint "book_price_cents_check"
DETAIL:  Failing row contains (6, 9786500000030, Frankenstein, Mary Shelley, -1).
```

While a statement is unfinished, the prompt turns into `bookshop(>` inside a bracket and
`bookshop->` outside one: `psql` is still listening, and nothing runs until the semicolon.

## What the table says

Each column is a name, a type and its rules, and the rules are where the work is.

- `bigserial PRIMARY KEY` makes `id` a 64-bit number that PostgreSQL fills in itself, from a
  counter called a **sequence**. The `INSERT` never names `id`, and the rows came back numbered from
  one to four. A **primary key** is the column that identifies a row: never null, never repeated.
- `char(13)` holds exactly thirteen characters, the length of an ISBN-13, and `UNIQUE` means
  no two rows share one.
- `text` is a string of any length. `NOT NULL` refuses a row with no value there.
- `integer` with `CHECK (price_cents >= 0)` holds the price in whole cents, as lesson 6's
  `BookRequest` already did, so the money stays exact, and refuses a negative one.

`SELECT *` reads every column of every row; naming the columns and adding a `WHERE` reads the ones
you asked for. Strings in SQL go between single quotes, so the apostrophe in Flannery O'Connor's
name is written twice inside one, `'Flannery O''Connor'`, and stored once. That detail comes back
two sections from now.

## The two refusals

The last two statements are the table defending itself. A second The Time Machine with the same
ISBN breaks the `UNIQUE` rule, and the error names the constraint PostgreSQL made for it,
`book_isbn_key`, and the key that already exists. A price of -1 breaks the `CHECK`.

**These rules hold whatever program does the writing.** Lesson 7 made `BookService` refuse a
duplicate ISBN with a 409; the table refuses it too, for `psql`, for a script somebody runs next
year, and for two requests that arrive at the same moment and both pass the service's check, which
is lesson 14's subject.

One number in the last line is worth a second look. Frankenstein's failed row would have been
**6**, not 5. The duplicate took 5 from the sequence before the `UNIQUE` rule refused it, and a
sequence never hands a number back. Gaps in `id` are normal, and nothing should depend on there
being none.

The table and its four rows stay in the database for the next two sections, where Java reads them.
