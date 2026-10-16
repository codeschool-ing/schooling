---
title: O SQL da aplicação
version: 1
---

Os dados atravessaram e foram conferidos. **A aplicação continua falando MySQL**, e cada consulta que
ela manda foi escrita por gente que testava contra as respostas do MySQL. Algumas dessas consultas
agora falham alto, que é o caso bom. As outras rodam e devolvem outra coisa, que é o caso que chega
aos clientes.

## As mesmas perguntas, duas respostas

```
ana@db:~$ sudo mysql legacy
mysql> SELECT 5 / 2, 'abc' = 'ABC', IFNULL(NULL, 'none'), CONCAT('a', NULL);
+--------+---------------+----------------------+-------------------+
| 5 / 2  | 'abc' = 'ABC' | IFNULL(NULL, 'none') | CONCAT('a', NULL) |
+--------+---------------+----------------------+-------------------+
| 2.5000 |             1 | none                 | NULL              |
+--------+---------------+----------------------+-------------------+
1 row in set (0.00 sec)

mysql> SELECT CustomerID FROM Customers WHERE Email = 'CUSTOMER1@EXAMPLE.COM';
+------------+
| CustomerID |
+------------+
|          1 |
+------------+
1 row in set (0.00 sec)

mysql> SELECT `Email` FROM Customers ORDER BY CustomerID LIMIT 2, 1;
+-----------------------+
| Email                 |
+-----------------------+
| customer3@example.com |
+-----------------------+
1 row in set (0.00 sec)
```

```
ana@db:~$ psql legacy
legacy=# SELECT 5 / 2, 'abc' = 'ABC', coalesce(NULL, 'none'), concat('a', NULL), 'a' || NULL;
 ?column? | ?column? | coalesce | concat | ?column? 
----------+----------+----------+--------+----------
        2 | f        | none     | a      | 
(1 row)

legacy=# SELECT IFNULL(NULL, 'none');
ERROR:  function ifnull(unknown, unknown) does not exist
LINE 1: SELECT IFNULL(NULL, 'none');
               ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

legacy=# SELECT customerid FROM customers WHERE email = 'CUSTOMER1@EXAMPLE.COM';
 customerid 
------------
(0 rows)

legacy=# SELECT `email` FROM customers;
ERROR:  syntax error at or near "FROM"
LINE 1: SELECT `email` FROM customers;
                       ^

legacy=# SELECT email FROM customers ORDER BY customerid LIMIT 2, 1;
ERROR:  LIMIT #,# syntax is not supported
LINE 1: SELECT email FROM customers ORDER BY customerid LIMIT 2, 1;
                                                        ^
HINT:  Use separate LIMIT and OFFSET clauses.

legacy=# SELECT email FROM customers ORDER BY customerid LIMIT 1 OFFSET 2;
         email         
-----------------------
 customer3@example.com
(1 row)

legacy=# SELECT "CustomerID" FROM customers LIMIT 1;
ERROR:  column "CustomerID" does not exist
LINE 1: SELECT "CustomerID" FROM customers LIMIT 1;
               ^
HINT:  Perhaps you meant to reference the column "customers.customerid".

legacy=# SELECT CustomerID FROM Customers LIMIT 1;
 customerid 
------------
          1
(1 row)

legacy=# \q
```

Passe por elas em ordem, porque **as silenciosas estão no topo**:

- `5 / 2` é `2.5000` no MySQL e `2` no PostgreSQL, que divide inteiros como inteiros. Uma média
  calculada assim perde a parte fracionária sem erro em lugar nenhum.
- `'abc' = 'ABC'` é `1` e `f`: a collation da primeira seção. A busca por e-mail achou o cliente 1 no
  MySQL e não acha ninguém no PostgreSQL.
- `CONCAT('a', NULL)` é NULL no MySQL. O `concat` do PostgreSQL pula o NULL e devolve `a`, e o `||`
  dele devolve NULL. Mesmo nome, outra função.
- `IFNULL` não existe no PostgreSQL; `coalesce` existe nos dois e é o que se deve escrever.
- A crase é a aspa do MySQL para nomes. O PostgreSQL usa aspas duplas para nomes, e uma crase é erro
  de sintaxe.
- `LIMIT 2, 1` é a forma própria do MySQL para "pule duas, pegue uma". `LIMIT 1 OFFSET 2` funciona
  nos dois.
- `"CustomerID"` entre aspas duplas pede uma coluna com maiúsculas, e não há nenhuma: o pgloader
  converteu todos os nomes. **O `CustomerID` sem aspas funciona**, porque o PostgreSQL o converte
  para `customerid` antes de procurar. Uma aplicação que nunca pôs os nomes entre aspas sobrevive à
  conversão; um ORM que põe aspas em todo nome que gera não sobrevive, e o mapeamento dele precisa
  mudar.

## A chave única que ficou mais fraca

No MySQL, a chave `UNIQUE` em `Email` recusou `CUSTOMER1@example.com`, porque a collation o tornava
igual a `customer1@example.com`. O pgloader copiou a chave, e o PostgreSQL compara exatamente:

```
ana@db:~$ psql legacy
legacy=# INSERT INTO customers (email, fullname, createdat) VALUES ('CUSTOMER1@example.com', 'Ana Again', now()) RETURNING customerid;
 customerid 
------------
       2049
(1 row)

INSERT 0 1

legacy=# DELETE FROM customers WHERE email = 'CUSTOMER1@example.com';
DELETE 1

legacy=# CREATE UNIQUE INDEX customers_email_lower ON customers (lower(email));
CREATE INDEX

legacy=# INSERT INTO customers (email, fullname, createdat) VALUES ('CUSTOMER1@example.com', 'Ana Again', now());
ERROR:  duplicate key value violates unique constraint "customers_email_lower"
DETAIL:  Key (lower(email::text))=(customer1@example.com) already exists.

legacy=# \q
```

**A chave tinha o mesmo nome e um significado mais fraco**, e o primeiro insert provou isso dando
certo. O índice em `lower(email)` devolve a regra antiga, e as buscas da aplicação precisam pedir
`lower(email) = lower($1)` para usá-lo. A extensão `citext`, um tipo de texto que ignora maiúsculas,
é o outro jeito de ter a mesma regra. Qualquer um dos dois é uma decisão que alguém toma durante a
migração, ou é uma conta duplicada que alguém descobre um mês depois.

O id que o insert recebeu também é uma conferência. É 2049: não 2002, um depois da contagem de
linhas, mas um depois do maior id da tabela, 2048, a linha estranha que o MySQL numerou depois de um
buraco. O `reset sequences` do pgloader fez o seu trabalho. Uma sequence deixada em 1 teria falhado
na chave primária.

## O que o resto da aplicação precisa

Nada disto aparece até a aplicação rodar contra o servidor novo:

| MySQL | PostgreSQL |
| --- | --- |
| `INSERT … ON DUPLICATE KEY UPDATE` | `INSERT … ON CONFLICT (…) DO UPDATE` |
| `GROUP_CONCAT(x)` | `string_agg(x, ',')` |
| `DATE_FORMAT(d, '%Y-%m')` | `to_char(d, 'YYYY-MM')` |
| `LAST_INSERT_ID()` | `INSERT … RETURNING id` |
| um `TINYINT(1)` comparado com `= 1` | um `boolean`, comparado com `= true` ou usado sozinho |

**Então a aplicação também é ensaiada, contra uma cópia migrada.** Rode a suíte de testes dela
ali, depois reproduza um dia das consultas reais dela se conseguir capturá-las,
e conserte o que falhar antes da noite. O PL/SQL do Oracle e o T-SQL do SQL Server aumentam essa
parte: stored procedures são um programa na linguagem do engine de origem, e o ora2pg converte parte
dele e deixa o resto marcado para uma pessoa.

## Arrumar a casa

O banco `legacy` pode ficar; nada mais adiante no curso o lê. O MySQL é um segundo servidor usando
memória numa máquina que as lições seguintes medem, então pare-o e impeça que ele suba no boot:

```
ana@db:~$ sudo systemctl disable --now mysql
Synchronizing state of mysql.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable mysql
Removed "/etc/systemd/system/multi-user.target.wants/mysql.service".
```

`sudo systemctl enable --now mysql` o traz de volta se você quiser repetir alguma coisa disto.
