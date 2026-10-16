---
title: Um desenho de privilégio mínimo para o shop
version: 1
---

As seções até aqui abriram uma porta de cada vez. Um banco de verdade recebe suas portas todas de
uma vez, por um arquivo que alguém lê, e **três papéis cobrem a maioria das aplicações**:

| papel | faz login | o que pode fazer |
|---|---|---|
| `shop_owner` | nunca | é dono de todos os objetos; as migrações rodam como ele |
| `app` | sim, a aplicação | ler e gravar linhas; nunca mudar o formato de uma tabela |
| `reporting` | não, é um grupo; o `bruno` faz login | ler, menos dados pessoais |

A ideia que faz o trabalho é a primeira linha. **Quem é dono de uma tabela pode fazer qualquer coisa
com ela**: alterá-la, apagá-la, conceder grants nela, pular a segurança por linha dela. A posse não
pode ser limitada por um grant. Então o dono é um papel com o qual ninguém faz login, e o papel da
aplicação não é dono de nada. Um bug ou um comando injetado na aplicação pode então perder linhas,
que um backup traz de volta. Ele não consegue apagar uma tabela nem mudar quem pode lê-la.

Escreva o arquivo com um editor como `layout.sql` na sua pasta pessoal:

```schooling-example
{"language": "sql", "file": "layout.sql", "parts": [{"code": "-- layout.sql: who owns shop, who writes to it, who reads it\nCREATE ROLE shop_owner NOLOGIN;", "note": "O dono é um papel com o qual ninguém faz login. As migrações rodam como ele, por `SET ROLE shop_owner` a partir da sessão de um administrador, então não existe senha capaz de apagar uma tabela."}, {"code": "ALTER DATABASE shop OWNER TO shop_owner;\nALTER TABLE customers OWNER TO shop_owner;\nALTER TABLE orders OWNER TO shop_owner;\nALTER SCHEMA reports OWNER TO shop_owner;\nALTER VIEW reports.sales_by_month OWNER TO shop_owner;", "note": "Ser dono do banco faz do `shop_owner` o `pg_database_owner` do `shop`, então ele pode criar tabelas no `public`. A sequência de uma coluna identity muda de dono junto com a tabela."}, {"code": "REVOKE CONNECT ON DATABASE shop FROM PUBLIC;\nGRANT CONNECT ON DATABASE shop TO app, reporting;", "note": "A primeira porta, fechada para todo mundo e aberta para os dois papéis que precisam dela. As duas linhas já rodaram antes nesta lição; um grant que já existe não é erro, então o arquivo pode rodar de novo."}, {"code": "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;", "note": "A aplicação lê e grava linhas. Ela não recebe `TRUNCATE`, nem `REFERENCES`, nem `TRIGGER`, e não é dona de nada, então não consegue mudar o formato de uma tabela nem apagar uma."}, {"code": "GRANT SELECT ON orders TO reporting;\nGRANT SELECT (id, name, country, created_at) ON customers TO reporting;\nGRANT USAGE ON SCHEMA reports TO reporting;\nGRANT SELECT ON reports.sales_by_month TO reporting;", "note": "O reporting lê todos os pedidos, todas as colunas de clientes menos `email`, e a visão. O endereço de uma pessoa é a única coluna de que um analista não precisa."}]}
```

Rode-o como `ana`:

```
ana@db:~$ psql shop -f layout.sql
CREATE ROLE
ALTER DATABASE
ALTER TABLE
ALTER TABLE
ALTER SCHEMA
ALTER VIEW
REVOKE
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
shop=# \l shop
                                                    List of databases
 Name |   Owner    | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |     Access privileges     
------+------------+----------+-----------------+---------+---------+------------+-----------+---------------------------
 shop | shop_owner | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =T/shop_owner            +
      |            |          |                 |         |         |            |           | shop_owner=CTc/shop_owner+
      |            |          |                 |         |         |            |           | reporting=c/shop_owner   +
      |            |          |                 |         |         |            |           | app=c/shop_owner
(1 row)

shop=# \dp
                                             Access privileges
 Schema |       Name       |   Type   |       Access privileges       |    Column privileges     | Policies 
--------+------------------+----------+-------------------------------+--------------------------+----------
 public | customers        | table    | shop_owner=arwdDxt/shop_owner+| id:                     +| 
        |                  |          | app=arwd/shop_owner           |   reporting=r/shop_owner+| 
        |                  |          |                               | name:                   +| 
        |                  |          |                               |   reporting=r/shop_owner+| 
        |                  |          |                               | country:                +| 
        |                  |          |                               |   reporting=r/shop_owner+| 
        |                  |          |                               | created_at:             +| 
        |                  |          |                               |   reporting=r/shop_owner | 
 public | customers_id_seq | sequence |                               |                          | 
 public | orders           | table    | shop_owner=arwdDxt/shop_owner+|                          | 
        |                  |          | app=arwd/shop_owner          +|                          | 
        |                  |          | reporting=r/shop_owner        |                          | 
 public | orders_id_seq    | sequence |                               |                          | 
(4 rows)

shop=# \dp reports.*
                                       Access privileges
 Schema  |      Name      | Type |       Access privileges       | Column privileges | Policies 
---------+----------------+------+-------------------------------+-------------------+----------
 reports | sales_by_month | view | shop_owner=arwdDxt/shop_owner+|                   | 
         |                |      | reporting=r/shop_owner        |                   | 
(1 row)
```

O dono do banco agora é o `shop_owner`, e os grants feitos antes pela `ana` foram reescritos com o
novo dono como grantor, porque **um grant sobre um objeto é sempre registrado como feito pelo dono**
quando é um superusuário que o faz. O `\dp` se lê do mesmo jeito que se leu para o banco: `app=arwd`
é `a`ppend (insert), `r`ead (select), `w`rite (update) e `d`elete; o `arwdDxt` do dono acrescenta
`D` para truncate, `x` para references e `t` para trigger. As duas sequências não mostram entrada
nenhuma, e o próximo teste mostra por que isso está certo.

## Testando o desenho

Faça login como cada papel e tente o que ele deve e o que não deve fazer:

```
ana@db:~$ psql -h localhost -U app shop
shop=> BEGIN;
BEGIN

shop=*> INSERT INTO orders (customer_id, status, total_cents, created_at) VALUES (1, 'paid', 990, now());
INSERT 0 1

shop=*> ROLLBACK;
ROLLBACK

shop=> DROP TABLE orders;
ERROR:  must be owner of table orders

shop=> CREATE TABLE notes (body text);
ERROR:  permission denied for schema public
LINE 1: CREATE TABLE notes (body text);
                     ^
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT email FROM customers LIMIT 1;
ERROR:  permission denied for table customers

shop=> SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)
```

O `app` inseriu um pedido sem grant nenhum em `orders_id_seq`. **Uma coluna identity pega o próximo
valor sem verificar privilégios na sequência dela**; uma coluna declarada `serial`, o jeito mais
antigo, precisaria também de `GRANT USAGE ON SEQUENCE orders_id_seq TO app`. Ele não conseguiu apagar
a tabela, porque só o dono consegue, nem criar uma, porque o `public` dá `CREATE` só ao dono do
banco. O `bruno` foi recusado nos endereços de e-mail e lê todos os pedidos.

## Trabalhando como o dono

As migrações, os scripts que criam e mudam tabelas, rodam como `shop_owner`. Da sessão de um
administrador, isso é um comando:

```sql
SET ROLE shop_owner;
-- CREATE TABLE, ALTER TABLE ...
RESET ROLE;
```

A `ana` é superusuária e pode dar `SET ROLE` para qualquer um. Uma ferramenta de deploy que não é
faria login com o próprio papel, membro do `shop_owner` com `INHERIT FALSE`, e trocaria só enquanto
migra; a lição 11 explicou por que essa opção existe. Uma tabela criada entre as duas linhas pertence
ao `shop_owner`, como o resto.

**O que ela não vai ter é grant nenhum para o `app` ou o `reporting`.** O `GRANT ... ON ALL TABLES
IN SCHEMA` alcançou as tabelas que existiam quando rodou, e nenhuma outra. Esse é o assunto da
lição 13.
