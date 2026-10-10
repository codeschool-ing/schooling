---
title: Privilégios em colunas
version: 1
---

`SELECT`, `INSERT`, `UPDATE` e `REFERENCES` podem ser concedidos sobre **uma lista de colunas em vez
da tabela inteira**. É assim que um analista lê os clientes sem ler os endereços de e-mail deles: a
tabela continua sendo uma tabela só, e a coluna de que o analista não precisa simplesmente não está
no grant dele.

```
shop=# GRANT SELECT (id, name, country, created_at) ON customers TO reporting;
GRANT
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT * FROM customers LIMIT 1;
ERROR:  permission denied for table customers

shop=> SELECT id, name, country FROM customers ORDER BY id LIMIT 3;
 id |    name    | country 
----+------------+---------
  1 | Customer 1 | PT
  2 | Customer 2 | AR
  3 | Customer 3 | MX
(3 rows)
shop=# \dp customers
                               Access privileges
 Schema |   Name    | Type  | Access privileges | Column privileges | Policies 
--------+-----------+-------+-------------------+-------------------+----------
 public | customers | table |                   | id:              +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | name:            +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | country:         +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | created_at:      +| 
        |           |       |                   |   reporting=r/ana | 
(1 row)
```

O `SELECT *` pede todas as colunas, `email` entre elas, e é recusado por inteiro; **o erro cita a
tabela e não a coluna**, o que manda as pessoas procurarem um grant de tabela que falta. Listar as
colunas concedidas funciona. O `\dp` guarda os grants de coluna numa coluna própria, uma entrada por
coluna, com `r` para leitura.

## Um REVOKE de coluna não desfaz um GRANT de tabela

Os dois tipos de grant ficam guardados separadamente, e um papel tem a união deles. Então o jeito
óbvio de esconder uma coluna de alguém que consegue ler a tabela não faz nada:

```
shop=# GRANT SELECT ON customers TO app;
GRANT

shop=# REVOKE SELECT (email) ON customers FROM app;
REVOKE
ana@db:~$ psql -h localhost -U app shop
shop=> SELECT email FROM customers ORDER BY id LIMIT 1;
         email         
-----------------------
 customer1@example.com
(1 row)
shop=# REVOKE SELECT ON customers FROM app;
REVOKE
```

O `REVOKE` deu certo porque não havia nada para revogar: o `app` não tinha grant de coluna em
`email`, tinha a tabela. **Para esconder uma coluna, revogue o privilégio da tabela e conceda as
colunas que quer manter**, como o `reporting` recebeu acima.

## UPDATE numa coluna, e o WHERE que precisa de SELECT

Um grant de coluna para `UPDATE` deixa um papel mudar algumas colunas e outras não: uma aplicação que
marca pedidos como enviados não tem nada que mudar quanto eles custam. Conceda ao `app` só a coluna
`status` e experimente, dentro de transações desfeitas com rollback:

```
shop=# GRANT UPDATE (status) ON orders TO app;
GRANT
ana@db:~$ psql -h localhost -U app shop
shop=> BEGIN;
BEGIN

shop=*> UPDATE orders SET status = 'shipped' WHERE id = 1;
ERROR:  permission denied for table orders

shop=!> ROLLBACK;
ROLLBACK

shop=> BEGIN;
BEGIN

shop=*> UPDATE orders SET status = 'shipped';
UPDATE 1000000

shop=*> ROLLBACK;
ROLLBACK
shop=# REVOKE UPDATE (status) ON orders FROM app;
REVOKE
```

O comando cuidadoso foi recusado e o catastrófico passou. **`WHERE id = 1` lê a coluna `id`, e ler
precisa de `SELECT` nela**, que o `app` não tem; o comando sem `WHERE` não lê nada e mudou o milhão
de linhas. O mesmo vale para o `RETURNING` e para qualquer coluna usada do lado direito do `SET`. Um
grant de `UPDATE` quase sempre anda junto com um grant de `SELECT` nas colunas que encontram a linha,
e um grant que parece funcionar só "sem o `WHERE`" é isto, não um bug.
