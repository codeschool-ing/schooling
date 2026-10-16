---
title: Conferir a cópia
version: 1
---

## O que chegou

Antes de conferir os valores, olhe o que o pgloader construiu:

```
ana@db:~$ psql legacy
legacy=# \dt legacy.*
         List of relations
 Schema |   Name    | Type  | Owner 
--------+-----------+-------+-------
 legacy | customers | table | ana
 legacy | orders    | table | ana
(2 rows)

legacy=# \d customers
                                           Table "legacy.customers"
   Column   |           Type           | Collation | Nullable |                    Default                    
------------+--------------------------+-----------+----------+-----------------------------------------------
 customerid | bigint                   |           | not null | nextval('customers_customerid_seq'::regclass)
 email      | character varying(255)   |           | not null | 
 fullname   | character varying(100)   |           | not null | 
 isactive   | boolean                  |           | not null | true
 birthdate  | date                     |           |          | 
 createdat  | timestamp with time zone |           | not null | 
Indexes:
    "idx_16470_primary" PRIMARY KEY, btree (customerid)
    "idx_16470_customers_email" UNIQUE, btree (email)
Referenced by:
    TABLE "orders" CONSTRAINT "orders_customer_fk" FOREIGN KEY (customerid) REFERENCES customers(customerid)

legacy=# \d orders
                                         Table "legacy.orders"
   Column   |           Type           | Collation | Nullable |                 Default                 
------------+--------------------------+-----------+----------+-----------------------------------------
 orderid    | bigint                   |           | not null | nextval('orders_orderid_seq'::regclass)
 customerid | bigint                   |           | not null | 
 status     | orders_status            |           | not null | 'new'::orders_status
 totalcents | bigint                   |           | not null | 
 shippedat  | timestamp with time zone |           |          | 
 note       | character varying(200)   |           | not null | ''::character varying
Indexes:
    "idx_16476_primary" PRIMARY KEY, btree (orderid)
    "idx_16476_orders_customer" btree (customerid)
Foreign-key constraints:
    "orders_customer_fk" FOREIGN KEY (customerid) REFERENCES customers(customerid)

legacy=# SHOW search_path;
  search_path   
----------------
 public, legacy
(1 row)

legacy=# SELECT customerid, fullname, birthdate, createdat FROM customers ORDER BY customerid LIMIT 3;
 customerid |     fullname     | birthdate  |       createdat        
------------+------------------+------------+------------------------
          1 | Zoë Customer 1   | 1960-02-07 | 2024-01-01 12:00:00-03
          2 | Ana Customer 2   | 1960-03-15 | 2024-01-01 15:00:00-03
          3 | Mário Customer 3 | 1960-04-21 | 2024-01-01 18:00:00-03
(3 rows)
```

Boa parte da lista da primeira seção aparece nessas duas descrições:

- **As tabelas estão num esquema chamado `legacy`**, com o nome do banco MySQL, e o pgloader ajustou
  o `search_path` do banco para `public, legacy`, para que nomes sem qualificação ainda as
  encontrem. Um papel que se conecta com um `search_path` próprio, ou um código que escreve
  `public.customers`, não vai encontrá-las.
- `INT UNSIGNED` virou `bigint`, o único tipo com sinal largo o bastante para todo valor que ele
  permitia.
- `TINYINT(1)` virou `boolean`, o `ENUM` virou um tipo próprio, `orders_status`, e o
  `AUTO_INCREMENT` virou uma sequence por trás de um default.
- `birthdate` agora aceita NULL, e `shippedat` também: as datas zeradas precisavam ir para algum
  lugar.
- Os índices se chamam `idx_`, um número tirado do id interno da tabela e o nome do MySQL, então
  recebem nomes diferentes a cada execução da migração. Renomeie-os num script se alguma coisa se
  refere a um índice pelo nome.
- **`createdat` virou `timestamp with time zone`**, e `12:00:00` virou `12:00:00-03`. Um `DATETIME`
  do MySQL não tem fuso, então foi lido no `TimeZone` deste servidor, que é o de São Paulo. Se a
  aplicação tivesse gravado esses valores em UTC, cada um deles estaria agora três horas errado, e
  nada jamais diria isso. Em que fuso os valores antigos foram gravados é uma pergunta para os donos
  da aplicação, feita antes da migração.

## Contar e resumir

O resumo de uma ferramenta diz o que a ferramenta fez. **Uma conferência diz o que o destino
guarda**, e ela é escrita por você, nos dois engines, para não compartilhar os erros da ferramenta.
Dois números por tabela fazem quase todo o trabalho: quantas linhas, e um checksum sobre todas elas.

O checksum é um `md5` de cada linha transformada numa linha de texto, com as linhas juntadas em ordem
de id. **A parte difícil é o texto.** Uma linha do MySQL e a sua cópia no PostgreSQL saem impressas
de forma diferente mesmo quando significam a mesma coisa: `1` contra `t` numa flag, uma data zerada
contra NULL, `2024-01-01 12:00:00` contra `2024-01-01 12:00:00-03`. Então a consulta de cada lado
escreve cada coluna numa forma combinada, e cada uma dessas grafias é uma decisão sobre o que a
migração deveria fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"O mesmo cliente como o MySQL guarda e como o PostgreSQL guarda, cada um transformado pela sua própria consulta numa linha de texto idêntica, e as linhas de uma tabela resumidas num checksum.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"320\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">no MySQL</text><text x=\"34\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">IsActive</text><text x=\"130\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"34\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BirthDate</text><text x=\"130\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">0000-00-00</text><text x=\"34\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CreatedAt</text><text x=\"130\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2024-01-02 06:00:00</text><line x1=\"180\" y1=\"120\" x2=\"270.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"380\" y=\"16\" width=\"320\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">no PostgreSQL</text><text x=\"394\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">isactive</text><text x=\"490\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">t</text><text x=\"394\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">birthdate</text><text x=\"490\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">NULL</text><text x=\"394\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">createdat</text><text x=\"490\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2024-01-02 06:00:00-03</text><line x1=\"540\" y1=\"120\" x2=\"450.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"20\" y=\"166\" width=\"680\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a grafia combinada: uma linha por registro, igual dos dois lados</text><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">7|customer7@example.com|Mário Customer 7|1|\\N|2024-01-02 06:00:00</text><line x1=\"360\" y1=\"226\" x2=\"360\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">md5 de todas as linhas, juntadas em ordem de id: um checksum por tabela</text></svg>", "caption": "Dois engines, duas representações do registro 7, uma linha de texto. O checksum compara as linhas, então cada lado tem de escrever o registro do mesmo jeito."}
```

Salve isto como `check-mysql.sql`:

```sql
-- check-mysql.sql: a count and a checksum per table, on the MySQL side.
-- Run it with: sudo mysql -t legacy < check-mysql.sql
SET SESSION group_concat_max_len = 1024 * 1024 * 64;

SELECT 'customers' AS tbl, COUNT(*) AS n_rows,
       MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive,
                                  IF(BirthDate = 0, '\\N', BirthDate),
                                  CreatedAt)
                        ORDER BY CustomerID SEPARATOR '\n')) AS checksum
FROM Customers
UNION ALL
SELECT 'orders', COUNT(*),
       MD5(GROUP_CONCAT(CONCAT_WS('|', OrderID, CustomerID, Status, TotalCents,
                                  IF(ShippedAt = 0, '\\N', ShippedAt), Note)
                        ORDER BY OrderID SEPARATOR '\n'))
FROM Orders;
```

e isto como `check-pg.sql`:

```sql
-- check-pg.sql: the same count and checksum, on the PostgreSQL side.
-- Run it with: psql legacy -f check-pg.sql
SELECT 'customers' AS tbl, count(*) AS n_rows,
       md5(string_agg(concat_ws('|', customerid, email, fullname, isactive::int,
                                coalesce(birthdate::text, '\N'),
                                to_char(createdat, 'YYYY-MM-DD HH24:MI:SS')),
                      E'\n' ORDER BY customerid)) AS checksum
FROM customers
UNION ALL
SELECT 'orders', count(*),
       md5(string_agg(concat_ws('|', orderid, customerid, status, totalcents,
                                coalesce(to_char(shippedat, 'YYYY-MM-DD HH24:MI:SS'), '\N'),
                                note),
                      E'\n' ORDER BY orderid))
FROM orders;
```

Leia os dois lado a lado. `IF(BirthDate = 0, '\\N', BirthDate)` e `coalesce(birthdate::text, '\N')`
dizem os dois que uma data ausente se escreve `\N`. `to_char(createdat, …)` tira o fuso que o
PostgreSQL acrescentou, porque o valor do MySQL nunca teve um. `isactive::int` escreve o booleano
como `1` ou `0`, do jeito que o MySQL guarda.

```
ana@db:~$ sudo mysql -t legacy < check-mysql.sql
+-----------+--------+----------------------------------+
| tbl       | n_rows | checksum                         |
+-----------+--------+----------------------------------+
| customers |   2001 | c370102af0b5fcd7c3901ba45dbe9440 |
| orders    |  10000 | fa25ee5b819306900b7daf3738251f51 |
+-----------+--------+----------------------------------+
ana@db:~$ psql legacy -f check-pg.sql
    tbl    | n_rows |             checksum             
-----------+--------+----------------------------------
 customers |   2001 | e5a659f63d17dfbe7278d837079c7365
 orders    |  10000 | fa25ee5b819306900b7daf3738251f51
(2 rows)
```

**As contagens batem, e isso prova menos do que parece.** Todas as linhas chegaram. `orders` bate
também no checksum, então cada valor dela diz a mesma coisa dos dois lados, datas zeradas incluídas.
`customers` não bate.

## Achar a linha

Um checksum sobre a tabela inteira diz que alguma coisa difere, e não onde. **Estreite por faixas**:
o mesmo checksum, agrupado em blocos de 500 ids, rodado dos dois lados. A primeira tentativa disso
do lado do MySQL deu errado de um jeito que vale ver, então ela ficou aqui junto com o conserto:

```
ana@db:~$ sudo mysql legacy
mysql> SELECT CustomerID DIV 500 AS block, MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive, IF(BirthDate = 0, '\\N', BirthDate), CreatedAt) ORDER BY CustomerID SEPARATOR '\n')) AS checksum FROM Customers GROUP BY block;
+-------+----------------------------------+
| block | checksum                         |
+-------+----------------------------------+
|     0 | da7f23b476ff2c082819017f7bfa4d6f |
|     1 | a414f7848affb5e5a5dc240197790cec |
|     2 | e4394d5a5cb083c89321d012c064dfb6 |
|     3 | de1d8f8d3a371aeb0dbbd86a2075706c |
|     4 | 42620e66e87e7bdae51f19cf6ea938b4 |
+-------+----------------------------------+
5 rows in set, 4 warnings (0.00 sec)

mysql> SHOW WARNINGS;
+---------+------+----------------------------------+
| Level   | Code | Message                          |
+---------+------+----------------------------------+
| Warning | 1260 | Row 14 was cut by GROUP_CONCAT() |
| Warning | 1260 | Row 28 was cut by GROUP_CONCAT() |
| Warning | 1260 | Row 41 was cut by GROUP_CONCAT() |
| Warning | 1260 | Row 54 was cut by GROUP_CONCAT() |
+---------+------+----------------------------------+
4 rows in set (0.00 sec)

mysql> SET SESSION group_concat_max_len = 1024 * 1024 * 64;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT CustomerID DIV 500 AS block, MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive, IF(BirthDate = 0, '\\N', BirthDate), CreatedAt) ORDER BY CustomerID SEPARATOR '\n')) AS checksum FROM Customers GROUP BY block;
+-------+----------------------------------+
| block | checksum                         |
+-------+----------------------------------+
|     0 | a8621aa8a5b2fec81b7569b3a5f93aee |
|     1 | 81e2673ee6df88cb7e782d1ebd407c22 |
|     2 | 5a0f84a30fd20aae3d7edb4268332fa8 |
|     3 | 3ec854b312efbc543e7fdd5767e095c1 |
|     4 | 42620e66e87e7bdae51f19cf6ea938b4 |
+-------+----------------------------------+
5 rows in set (0.00 sec)
```

**O `GROUP_CONCAT` cortou o resultado em 1.024 bytes e só avisou num warning.** Quatro dos cinco
blocos receberam o checksum de uma string truncada, e nada na tela parecia errado, a não ser
`4 warnings` na linha debaixo da tabela. É para isso que serve a linha `SET SESSION
group_concat_max_len` no topo do `check-mysql.sql`. Depois dela, a mesma consulta dá hashes
diferentes para os blocos 0 a 3, e são esses que se comparam com os do PostgreSQL:

```
ana@db:~$ psql legacy
legacy=# SELECT customerid / 500 AS block, md5(string_agg(concat_ws('|', customerid, email, fullname, isactive::int, coalesce(birthdate::text, '\N'), to_char(createdat, 'YYYY-MM-DD HH24:MI:SS')), E'\n' ORDER BY customerid)) AS checksum FROM customers GROUP BY block ORDER BY block;
 block |             checksum             
-------+----------------------------------
     0 | a8621aa8a5b2fec81b7569b3a5f93aee
     1 | 81e2673ee6df88cb7e782d1ebd407c22
     2 | 5a0f84a30fd20aae3d7edb4268332fa8
     3 | 3ec854b312efbc543e7fdd5767e095c1
     4 | aa1ae73d2b751f85f0153771e2b38ba0
(5 rows)
```

Os blocos 0 a 3 batem. O bloco 4, ids de 2000 em diante, não bate, e ele tem só duas linhas. Procure
o que a coluna do PostgreSQL não consegue guardar:

```
ana@db:~$ sudo mysql legacy
mysql> SELECT CustomerID, Email, IsActive FROM Customers WHERE CustomerID >= 2000 AND IsActive NOT IN (0, 1);
+------------+------------------+----------+
| CustomerID | Email            | IsActive |
+------------+------------------+----------+
|       2048 | flag@example.com |        2 |
+------------+------------------+----------+
1 row in set (0.00 sec)
```

**A flag com 2.** A aplicação guardou um 2 numa coluna que tratava como sim ou não, o pgloader o
transformou em `true`, e `true` é `1`. Nada que a aplicação pudesse ver se perdeu, porque para ela
qualquer valor diferente de zero significava ativo. Então a cópia está certa, a conferência estava
errada, e o conserto é escrever essa decisão do lado do MySQL: comparar `IsActive <> 0`, que dá 1 ou
0, em vez do número cru.

```
ana@db:~$ sed -i 's/FullName, IsActive,/FullName, IsActive <> 0,/' check-mysql.sql
ana@db:~$ sudo mysql -t legacy < check-mysql.sql
+-----------+--------+----------------------------------+
| tbl       | n_rows | checksum                         |
+-----------+--------+----------------------------------+
| customers |   2001 | e5a659f63d17dfbe7278d837079c7365 |
| orders    |  10000 | fa25ee5b819306900b7daf3738251f51 |
+-----------+--------+----------------------------------+
```

Os dois checksums agora batem com os do PostgreSQL. O emoji dessa mesma linha atravessou byte a
byte, ou o hash ainda seria diferente.

**Esse é o formato de toda conferência numa migração de verdade.** Uma diferença ou é estrago, que
você conserta na migração, ou é uma decisão que você não tinha escrito, e que você escreve na
conferência. Rode os dois arquivos de novo depois de cada ensaio; na noite da migração, eles são a
prova de que a cópia está completa.
