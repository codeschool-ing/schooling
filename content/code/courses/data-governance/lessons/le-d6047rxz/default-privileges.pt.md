---
title: Tabelas que ainda não existem
version: 1
---

Concessões são feitas sobre objetos que existem. Uma tabela criada amanhã começa como toda tabela
começou na primeira seção — aberta ao dono e a mais ninguém:

```sql
SET ROLE ipe_owner;
CREATE TABLE sales.returns (
  order_id    integer REFERENCES sales.orders,
  returned_on date    NOT NULL,
  reason      text    NOT NULL
);
```

```
ana@lab:~/gov$ psql -f new-table.sql
SET
CREATE TABLE
ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.returns"
ERROR:  permission denied for table returns
```

**Essa recusa é o padrão seguro, e também um chamado de defeito esperando para acontecer.** Um
pipeline cria uma tabela, o painel que a lê falha na segunda de manhã, alguém conserta às pressas
com a concessão mais larga que faz o erro sumir, e ninguém volta para revisar.

O PostgreSQL deixa o dono dizer antes o que os objetos novos devem levar:

```sql
-- Whatever ipe_owner creates in `sales` from now on, analysts may read.
-- It changes nothing that exists already: that is what GRANT is for.
SET ROLE ipe_owner;
ALTER DEFAULT PRIVILEGES IN SCHEMA sales GRANT SELECT ON TABLES TO analyst;
GRANT SELECT ON sales.returns TO analyst;
CREATE TABLE sales.deliveries (
  order_id     integer REFERENCES sales.orders,
  delivered_at timestamptz
);
```

```
ana@lab:~/gov$ psql -f defaults.sql
SET
ALTER DEFAULT PRIVILEGES
GRANT
CREATE TABLE
ana@lab:~/gov$ psql -c "\ddp"
            Default access privileges
   Owner   | Schema | Type  |  Access privileges  
-----------+--------+-------+---------------------
 ipe_owner | sales  | table | analyst=r/ipe_owner
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.returns" -c "SELECT count(*) FROM sales.deliveries"
 count 
-------
     0
(1 row)

 count 
-------
     0
(1 row)
```

`\ddp` mostra a regra: toda tabela que `ipe_owner` criar em `sales` é legível por `analyst`.
`deliveries`, criada depois da regra, ficou legível na hora; `returns`, criada antes, precisou do
`GRANT` comum no mesmo arquivo. **Um privilégio padrão muda o futuro e nunca o passado**, que é a
primeira coisa que surpreende todo mundo que usa um.

Dois detalhes decidem se funciona:

- **A regra pertence ao papel que cria os objetos.** Ela diz "para tabelas que `ipe_owner` cria".
  Uma tabela que a Ana criasse como ela mesma não seria coberta, o que é mais um motivo para o
  schema mudar sob `SET ROLE ipe_owner` e nunca como pessoa.
- **Padrões devem ser tão estreitos quanto as concessões que substituem.** Um padrão de `SELECT`
  para analistas em `sales` é uma decisão sobre `sales`. A mesma regra no schema `health` faria
  toda futura tabela de dado médico se abrir a todo analista no dia em que fosse criada — a
  decisão tomada uma vez, anos antes, por alguém pensando noutra tabela.
