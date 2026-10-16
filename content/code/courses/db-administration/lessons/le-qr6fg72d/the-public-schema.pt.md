---
title: O esquema public, e o que o PUBLIC recebe
version: 1
---

Todo banco é criado com um esquema chamado `public`, e todas as tabelas do `shop` estão nele. **O que
o `PUBLIC` pode fazer nesse esquema mudou no PostgreSQL 15**, e a mudança é uma das poucas dos
últimos anos que tornou um padrão mais seguro quebrando scripts que dependiam do antigo.

## O que a versão 16 dá

```
shop=# \dn+ public
                                       List of schemas
  Name  |       Owner       |           Access privileges            |      Description       
--------+-------------------+----------------------------------------+------------------------
 public | pg_database_owner | pg_database_owner=UC/pg_database_owner+| standard public schema
        |                   | =U/pg_database_owner                   | 
(1 row)
ana@db:~$ psql -h localhost -U bruno shop
shop=> CREATE TABLE notes (body text);
ERROR:  permission denied for schema public
LINE 1: CREATE TABLE notes (body text);
                     ^

shop=> CREATE TEMP TABLE notes (body text);
CREATE TABLE
```

Duas entradas. O dono do esquema é o **`pg_database_owner`**, um papel predefinido cujo único membro
é, a cada momento, quem for dono do banco atual; aqui é a `ana`, e ela recebe `U`, uso, e `C`,
criar. Todos os outros, o grantee vazio, recebem só o `U`. Então qualquer papel que consegue
conectar pode usar as tabelas do `public` em que tem privilégios, e **não pode criar nada ali**. O
`CREATE TABLE` do `bruno` foi recusado no esquema.

A tabela temporária dele funcionou, porque tabelas temporárias moram num esquema próprio de cada
sessão, e o `PUBLIC` ainda tem o `T` no banco, como o `\l shop` mostrou na seção anterior. Uma
tabela temporária some com a sessão e não toca nos dados de ninguém. Se até isso for demais,
`REVOKE TEMPORARY ON DATABASE shop FROM PUBLIC` tira esse direito.

## O que as versões antes da 15 davam

**Até a versão 14, o `PUBLIC` tinha `CREATE` no `public`, e o esquema pertencia ao superusuário de
bootstrap**, então a lista de acesso dizia `=UC/postgres`. Todo papel que conseguia conectar podia
criar tabelas, visões e funções no esquema que todos os outros papéis procuram primeiro. Essa
segunda metade é a perigosa: uma função criada no `public` com o nome de uma que um administrador
chama, e tipos de argumento que se encaixam melhor na chamada, é escolhida no lugar da verdadeira e
roda com os direitos do administrador. O projeto publicou isso como problema de segurança em 2018
(CVE-2018-1058) e passou quatro anos recomendando o `REVOKE` antes de torná-lo o padrão.

**O novo padrão só vale para bancos criados pela versão 15 ou posterior.** Um banco que veio de um
servidor mais antigo pelo `pg_upgrade`, ou por um dump e restore do esquema, mantém a lista de acesso
que tinha, com `=UC/postgres` e tudo. Depois de qualquer upgrade a partir da 14 ou anterior, olhe o
`\dn+ public` em todos os bancos e, onde o `C` ainda estiver ao lado do grantee vazio, rode:

```sql
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
```

A lição 20 faz um upgrade de versão maior e põe isso entre as verificações que vêm depois de um.

## As outras coisas que o PUBLIC tem

O `PUBLIC` recebe uma lista curta por padrão, e vale saber de cor, porque cada item é uma porta já
aberta quando um papel é criado:

| objeto | o que o `PUBLIC` recebe | o que um banco cuidadoso faz |
|---|---|---|
| um banco | `CONNECT`, `TEMPORARY` | revoga o `CONNECT` e o concede por papel, como a seção anterior fez |
| o esquema `public` | `USAGE` (e `CREATE` antes da 15) | revoga o `CREATE` onde um servidor antigo o deixou |
| uma função ou procedure | `EXECUTE` | revoga nas funções que não devem ser chamáveis por todo mundo |
| uma linguagem, um tipo | `USAGE` | deixa como está |

**Uma tabela, uma visão, uma sequência e um esquema que você mesmo cria não dão nada ao `PUBLIC`.**
Tudo neles precisa ser concedido, que é o que o resto desta lição faz.
