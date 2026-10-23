---
title: O arquivo que roda a cada partida
version: 1
---

Desde a aula 9, as tabelas da livraria vêm do `schema.sql` e as linhas vêm do `data.sql`, e o
`spring.sql.init.mode=always` manda o Spring Boot rodar os dois **a cada partida**. Por isso todo comando
neles tem de ser inofensivo na segunda vez. É por isso que a aula 10 escreveu `CREATE TABLE IF NOT EXISTS`
e terminou cada `INSERT` com `ON CONFLICT ... DO NOTHING`: sem essas guardas, a segunda partida falharia
numa tabela que já existe ou num nome que já está lá.

A imagem que a maioria das pessoas tem é que o `schema.sql` descreve o esquema, então mudar o arquivo muda
o esquema. **Ele descreve o esquema de um banco vazio, e de nenhum outro.** Uma mudança de verdade mostra
isso. Suponha que a loja queira uma contagem de estoque em cada livro. Abra
`src/main/resources/schema.sql` e acrescente uma coluna a `book`, para que o arquivo fique assim:

```sql
CREATE TABLE IF NOT EXISTS author (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author_id   bigint    NOT NULL REFERENCES author (id),
    price_cents integer   NOT NULL CHECK (price_cents >= 0),
    stock       integer   NOT NULL DEFAULT 0
);
```

Compile, inicie a aplicação no segundo terminal como nas aulas anteriores e pergunte ao PostgreSQL como a
tabela está. O `psql` aceita a conexão inteira como uma URL; a senha está nela só porque é a senha de
desenvolvimento deste curso:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'Started|Catalogue'
2026-10-22T19:29:14.030-03:00  INFO 13638 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 7.627 seconds (process running for 8.277)
2026-10-22T19:29:14.169-03:00  INFO 13638 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c '\d book'
                                  Table "public.book"
   Column    |     Type      | Collation | Nullable |             Default              
-------------+---------------+-----------+----------+----------------------------------
 id          | bigint        |           | not null | nextval('book_id_seq'::regclass)
 isbn        | character(13) |           | not null | 
 title       | text          |           | not null | 
 author_id   | bigint        |           | not null | 
 price_cents | integer       |           | not null | 
Indexes:
    "book_pkey" PRIMARY KEY, btree (id)
    "book_isbn_key" UNIQUE CONSTRAINT, btree (isbn)
Check constraints:
    "book_price_cents_check" CHECK (price_cents >= 0)
Foreign-key constraints:
    "book_author_id_fkey" FOREIGN KEY (author_id) REFERENCES author(id)
```

A aplicação iniciou sem uma palavra de reclamação, e a tabela não tem coluna `stock`. O `IF NOT EXISTS`
achou uma tabela chamada `book` e pulou o comando inteiro, coluna nova incluída. Nada falhou, então nada
avisou: o arquivo agora descreve uma tabela que não existe em lugar nenhum, a não ser num banco novinho.

O problema não é a guarda; qualquer versão desse arquivo tem as mesmas três lacunas.

- **Ele não consegue mudar o que existe.** Um `ALTER TABLE book ADD COLUMN stock ...` funcionaria uma vez
  e falharia em toda partida seguinte, então cada mudança precisaria de uma guarda própria, escrita à mão,
  para sempre.
- **Ele não guarda registro.** O banco não faz ideia de qual versão do arquivo viu por último, e portanto
  você também não.
- **Cada cópia do banco deriva por conta própria.** O seu notebook, o de um colega e o servidor de
  produção partiram cada um de uma versão diferente do arquivo, e nada consegue dizer qual.

O que um esquema precisa, em vez disso, é de **uma sequência de mudanças**, cada uma aplicada uma vez, em
ordem, com o próprio banco registrando quais já recebeu. Isso é uma **ferramenta de migração**, e o Spring
Boot dá suporte a duas: o **Flyway**, que a livraria usa daqui em diante, e o **Liquibase**, que a última
seção desta aula roda para comparar. A coluna `stock` é da aula 14, que a acrescenta do jeito certo; a
edição que você acabou de fazer some na próxima seção, junto com o arquivo em que foi feita.
