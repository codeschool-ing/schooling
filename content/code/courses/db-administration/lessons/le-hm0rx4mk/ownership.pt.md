---
title: Posse, e apagar um papel que é dono de coisas
version: 1
---

Todo objeto tem exatamente um dono, e **um papel não pode ser apagado enquanto for dono de qualquer
coisa ou tiver qualquer privilégio**. O servidor recusa, em vez de deixar tabelas sem dono ou listas
de acesso citando um papel que não existe mais. Essa recusa é o motivo de remover alguém que saiu
ser um procedimento, e não um comando.

Um estagiário recebeu um canto do esquema `reports`, criou uma tabela nele, compartilhou com o
`reporting`, e também é dono de uma tabela no banco `ana`:

```
shop=# CREATE ROLE intern LOGIN;
CREATE ROLE

shop=# GRANT USAGE, CREATE ON SCHEMA reports TO intern;
GRANT

shop=# SET ROLE intern;
SET

shop=> CREATE TABLE reports.ideas (body text);
CREATE TABLE

shop=> GRANT SELECT ON reports.ideas TO reporting;
GRANT

shop=> RESET ROLE;
RESET

shop=# \c ana
You are now connected to database "ana" as user "ana".

ana=# CREATE TABLE notes (body text);
CREATE TABLE

ana=# ALTER TABLE notes OWNER TO intern;
ALTER TABLE

ana=# \c shop
You are now connected to database "shop" as user "ana".

shop=# DROP ROLE intern;
ERROR:  role "intern" cannot be dropped because some objects depend on it
DETAIL:  privileges for schema reports
owner of table reports.ideas
1 object in database ana
```

O `DETAIL` é um inventário: um privilégio no esquema, uma tabela de que ele é dono, e **`1 object in
database ana`**. A posse em outros bancos só é contada, nunca nomeada, porque uma sessão enxerga o
catálogo do banco em que está conectada e de nenhum outro.

## REASSIGN OWNED, depois DROP OWNED

Dois comandos limpam um papel, e a ordem importa:

- `REASSIGN OWNED BY intern TO shop_owner` passa tudo o que o estagiário possui para outro papel.
  A tabela sobrevive, com um dono novo.
- `DROP OWNED BY intern` apaga o que ele ainda possuir e revoga todo privilégio concedido a ele,
  junto com os privilégios padrão dele.

Rode o segundo primeiro e a tabela do estagiário é apagada em vez de mantida. Os dois agem **só no
banco atual**, como a primeira tentativa mostra:

```
shop=# REASSIGN OWNED BY intern TO shop_owner;
REASSIGN OWNED

shop=# DROP OWNED BY intern;
DROP OWNED

shop=# DROP ROLE intern;
ERROR:  role "intern" cannot be dropped because some objects depend on it
DETAIL:  1 object in database ana

shop=# \c ana
You are now connected to database "ana" as user "ana".

ana=# REASSIGN OWNED BY intern TO ana;
REASSIGN OWNED

ana=# DROP OWNED BY intern;
DROP OWNED

ana=# DROP ROLE intern;
DROP ROLE
```

O `DROP ROLE` ainda encontrou o objeto no `ana`. Conectado lá, os mesmos dois comandos o limparam,
passando aquela tabela para a `ana`, e o papel pôde sair. Num cluster com muitos bancos isso é um laço
por todos eles, e o `DETAIL` do `DROP ROLE` que falhou é a lista de quais visitar.

A tabela que o estagiário criou agora é do `shop_owner`, e o grant que ele fez nela sobreviveu,
reescrito com o novo dono como grantor:

```
shop=# \dp reports.ideas
                                   Access privileges
 Schema  | Name  | Type  |       Access privileges       | Column privileges | Policies 
---------+-------+-------+-------------------------------+-------------------+----------
 reports | ideas | table | shop_owner=arwdDxt/shop_owner+|                   | 
         |       |       | reporting=r/shop_owner        |                   | 
(1 row)
```

O `reporting` continua lendo. Se a tabela do estagiário devia ter ido embora com ele, o comando é o
`DROP OWNED` sem o `REASSIGN`; essa é uma decisão sobre dados e merece uma segunda olhada antes de
rodar.

## Um DROP ROLE que falha como inventário

Como a recusa lista tudo o que depende de um papel, ela também é a resposta mais rápida para "o que
esse papel tem aqui?". O comando não muda nada quando falha:

```
shop=# DROP ROLE reporting;
ERROR:  role "reporting" cannot be dropped because some objects depend on it
DETAIL:  privileges for database shop
privileges for column id of table customers
privileges for column name of table customers
privileges for column country of table customers
privileges for column created_at of table customers
privileges for table orders
privileges for schema reports
privileges for view reports.sales_by_month
privileges for table refunds
privileges for default privileges on new relations belonging to role shop_owner in schema public
privileges for table shipments
privileges for table coupons
privileges for table reports.ideas
```

Todas as portas que a lição 12 abriu para o `reporting` estão ali: o banco, quatro colunas de
`customers`, as tabelas e a visão, o esquema, o privilégio padrão desta lição e os grants que esse
padrão fez em `shipments` e `coupons`. Não faça isso com um papel que pode não ter mais nada, porque
aí o comando dá certo.
