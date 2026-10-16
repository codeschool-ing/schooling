---
title: SQL suficiente
version: 1
---

O JDBC carrega SQL; ele não o substitui. Então, antes de qualquer Java, os quatro comandos de que
esta aula precisa, digitados direto no `psql`. Eles são um mínimo que funciona. O `sql-databases` é
o curso que ensina a linguagem de verdade, a começar por por que as tabelas têm o formato que têm.

Uma **tabela** é um conjunto de linhas que têm todas as mesmas colunas, e cada coluna tem um tipo. O
catálogo da livraria é uma tabela, `book`, e a definição dela diz tanto sobre o que é recusado quanto
sobre o que é guardado. Conecte como na seção anterior e digite:

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

Enquanto um comando está incompleto, o prompt vira `bookshop(>` dentro de um parêntese e
`bookshop->` fora dele: o `psql` continua ouvindo, e nada roda até o ponto e vírgula.

## O que a tabela diz

Cada coluna é um nome, um tipo e as regras dela, e as regras são onde está o trabalho.

- `bigserial PRIMARY KEY` faz de `id` um número de 64 bits que o próprio PostgreSQL preenche, a
  partir de um contador chamado **sequência**. O `INSERT` nunca nomeia `id`, e as linhas voltaram
  numeradas de um a quatro. Uma **chave primária** é a coluna que identifica uma linha: nunca nula,
  nunca repetida.
- `char(13)` guarda exatamente treze caracteres, o tamanho de um ISBN-13, e `UNIQUE` quer dizer que
  duas linhas nunca dividem um.
- `text` é uma string de qualquer tamanho. `NOT NULL` recusa uma linha sem valor ali.
- `integer` com `CHECK (price_cents >= 0)` guarda o preço em centavos inteiros, como o
  `BookRequest` da aula 6 já fazia, para que o dinheiro continue exato, e recusa um negativo.

`SELECT *` lê todas as colunas de todas as linhas; nomear as colunas e acrescentar um `WHERE` lê as
que você pediu. Strings em SQL vão entre aspas simples, então o apóstrofo do nome de Flannery
O'Connor é escrito duas vezes dentro de uma, `'Flannery O''Connor'`, e guardado uma vez. Esse detalhe
volta daqui a duas seções.

## As duas recusas

Os dois últimos comandos são a tabela se defendendo. Um segundo The Time Machine com o mesmo ISBN
viola a regra `UNIQUE`, e o erro nomeia a restrição que o PostgreSQL criou para ela,
`book_isbn_key`, e a chave que já existe. Um preço de -1 viola o `CHECK`.

**Essas regras valem seja qual for o programa que escreve.** A aula 7 fez o `BookService` recusar um
ISBN repetido com um 409; a tabela também o recusa, para o `psql`, para um script que alguém rode no
ano que vem, e para duas requisições que chegam no mesmo instante e passam as duas pela verificação
do serviço, que é o assunto da aula 14.

Um número na última linha merece uma segunda olhada. A linha de Frankenstein que falhou teria sido a
**6**, não a 5. O duplicado pegou o 5 da sequência antes de a regra `UNIQUE` recusá-lo, e uma
sequência nunca devolve um número. Buracos em `id` são normais, e nada deve depender de não haver
nenhum.

A tabela e as quatro linhas ficam no banco para as próximas duas seções, onde o Java as lê.
