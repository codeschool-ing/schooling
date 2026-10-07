---
title: Ninguém, até uma permissão dizer o contrário
version: 1
---

Bruno consegue logar. O primeiro portão disse sim. O que ele pode fazer?

```
ana@lab:~/gov$ psql -c "\l ipe"
                                               List of databases
 Name |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules | Access privileges 
------+----------+----------+-----------------+---------+---------+------------+-----------+-------------------
 ipe  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
(1 row)

ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "SELECT count(*) FROM sales.customers"
ERROR:  permission denied for schema sales
LINE 1: SELECT count(*) FROM sales.customers
                             ^
ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "\dn"
       List of schemas
  Name   |       Owner       
---------+-------------------
 health  | ipe_owner
 public  | pg_database_owner
 sales   | ipe_owner
 support | ipe_owner
(4 rows)
```

**Ele não lê nada, e enxerga a forma de tudo.** As tabelas são recusadas no schema, porque
ninguém concedeu a ele `USAGE` em `sales`; esse é o segundo portão, e ele segurou. Mas ele lista
os schemas, e toda outra visão do catálogo: os nomes das tabelas, as colunas, os nomes dos outros
papéis. O catálogo é legível por todo papel que conecta, e isso é de propósito — um cliente
precisa dele para funcionar. É também por isso que um nome de tabela como
`customers_with_hiv_status` é um vazamento por si só, digam o que disserem as permissões.

## O papel em que todo mundo está

O `\l` acima mostra a coluna **Access privileges** vazia para o `ipe`. Vazia não quer dizer nada:
quer dizer **os padrões**, e o padrão de um banco é que o pseudo-papel `PUBLIC` — todo papel,
inclusive os criados no ano que vem — pode conectar a ele e criar tabelas temporárias nele.

**Um padrão que concede é uma política que ninguém escreveu.** Ele faz com que todo papel novo
consiga abrir sessão no `ipe` no momento em que ganha senha, quer alguém tenha decidido isso, quer
não. Ana inverte o padrão: ninguém conecta a menos que seja nomeado.

```sql
-- Who may open a session on `ipe` at all: nobody, until a grant says so.
REVOKE CONNECT, TEMPORARY ON DATABASE ipe FROM PUBLIC;
GRANT CONNECT ON DATABASE ipe TO bruno, carla, davi, site_app, etl_loader;
```

```
ana@lab:~/gov$ sudo -u postgres psql -d ipe < connect.sql
REVOKE
GRANT
ana@lab:~/gov$ psql -c "\l ipe"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  permission denied for database "ipe"
DETAIL:  User does not have CONNECT privilege.
ana@lab:~/gov$ sudo -u postgres psql -c "GRANT CONNECT ON DATABASE ipe TO ana"
GRANT
ana@lab:~/gov$ psql -c "\l ipe"
                                                 List of databases
 Name |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 ipe  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | postgres=CTc/postgres+
      |          |          |                 |         |         |            |           | bruno=c/postgres     +
      |          |          |                 |         |         |            |           | carla=c/postgres     +
      |          |          |                 |         |         |            |           | davi=c/postgres      +
      |          |          |                 |         |         |            |           | site_app=c/postgres  +
      |          |          |                 |         |         |            |           | etl_loader=c/postgres+
      |          |          |                 |         |         |            |           | ana=c/postgres
(1 row)
```

O primeiro `\l` é a Ana se trancando do lado de fora. Ela dependia de `PUBLIC` como todo mundo, e a
lista de nomes a que concedeu não incluía o dela — exatamente o erro que o padrão esconde. **O erro
diz o que falta**, `User does not have CONNECT privilege`, e o superusuário corrige com uma
concessão. O segundo `\l` é a política escrita: uma linha por papel que pode entrar, cada uma
concedida por `postgres`, e nada para `PUBLIC`.

Lia, cuja senha expirou, não está na lista. Se alguém prorrogasse a senha dela por engano, ela
ainda não conseguiria abrir sessão no `ipe`. **Dois controles que falham de forma independente são
o que "defesa em profundidade" quer dizer no tamanho de um banco**: uma data de expiração que
ninguém precisa lembrar, e uma permissão que ninguém deu.

## Onde isso deixa o laboratório

Toda pessoa e todo programa têm login próprio, todo login tem um método que o prova, a porta
registra quem passou, e entrar não dá a ninguém dado nenhum. Essa última parte é o ponto de
partida da aula 2, que decide — tabela por tabela, coluna por coluna e linha por linha — o que cada
um pode ler.
