---
title: Um privilégio é um verbo sobre um objeto
version: 1
---

A aula 1 deixou todo papel capaz de conectar e nenhum capaz de ler. Esta aula preenche a
lacuna, e começa pelo que é um privilégio: **um verbo, sobre um objeto, concedido a um papel.**
`SELECT` numa tabela, `USAGE` num schema, `EXECUTE` numa função, `CONNECT` num banco. Nada é
concedido em geral; todo privilégio nomeia a coisa de que trata.

Ana vai testar como outras pessoas a aula inteira, então anota como chegar a cada uma. Um
**arquivo de serviço** poupa digitar host, porta, banco e usuário toda vez:

```ini
# One entry per role Ana tests as. `psql service=bruno` reads the host,
# the port, the database and the user from here, and the password from
# ~/.pgpass as before.
[bruno]
host=db.ipe.example
port=5433
dbname=ipe
user=bruno

[carla]
host=db.ipe.example
port=5433
dbname=ipe
user=carla

[site_app]
host=db.ipe.example
port=5433
dbname=ipe
user=site_app
```

A senha continua vindo do `~/.pgpass`. `psql service=bruno` agora equivale ao comando comprido
da aula 1.

## Partindo do nada

```
ana@lab:~/gov$ psql -c "\dp sales.*"
                                Access privileges
 Schema |    Name     | Type  | Access privileges | Column privileges | Policies 
--------+-------------+-------+-------------------+-------------------+----------
 sales  | customers   | table |                   |                   | 
 sales  | order_items | table |                   |                   | 
 sales  | orders      | table |                   |                   | 
 sales  | payments    | table |                   |                   | 
 sales  | products    | table |                   |                   | 
(5 rows)
```

`\dp` lista privilégios de acesso. Toda tabela de `sales` mostra a coluna vazia, o que, como no
banco da aula 1, quer dizer os padrões — e para uma tabela o padrão é que **só o dono pode fazer
qualquer coisa**. Ninguém mais recebeu verbo nenhum.

A primeira tentativa da Ana é a natural: dar ao Bruno o que ele pede.

```sql
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales TO bruno;
GRANT SELECT ON sales.orders TO bruno;
```

```
ana@lab:~/gov$ psql -f first-grant.sql
SET
GRANT
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.orders"
 count 
-------
 36424
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.order_items"
ERROR:  permission denied for table order_items
ana@lab:~/gov$ psql -c "\dp sales.orders"
                                  Access privileges
 Schema |  Name  | Type  |      Access privileges      | Column privileges | Policies 
--------+--------+-------+-----------------------------+-------------------+----------
 sales  | orders | table | ipe_owner=arwdDxt/ipe_owner+|                   | 
        |        |       | bruno=r/ipe_owner           |                   | 
(1 row)
```

Foram precisas duas concessões para uma tabela. **`USAGE` no schema deixa um papel olhar dentro
dele**, e **`SELECT` na tabela deixa ler as linhas**; uma sem a outra é recusada. E o Bruno
recebeu exatamente o que foi concedido: `order_items` continua fechada, porque ninguém a nomeou.

A coluna de privilégios agora diz `bruno=r/ipe_owner`: *bruno* pode ler (*r*, de *read*),
concedido por *ipe_owner*. A linha do próprio dono, `arwdDxt`, é todo verbo que uma tabela tem:

| letra | privilégio | letra | privilégio |
|---|---|---|---|
| `a` | INSERT (*append*) | `D` | TRUNCATE |
| `r` | SELECT (*read*) | `x` | REFERENCES |
| `w` | UPDATE (*write*) | `t` | TRIGGER |
| `d` | DELETE | | |

## Só o dono entrega as chaves

Ana tenta conceder a tabela seguinte sem virar a dona antes:

```
ana@lab:~/gov$ psql -c "GRANT SELECT ON sales.order_items TO bruno"
ERROR:  permission denied for schema sales
ana@lab:~/gov$ psql -c "SELECT tableowner FROM pg_tables WHERE tablename = 'order_items'"
 tableowner 
------------
 ipe_owner
(1 row)
```

Ela é recusada no schema, antes mesmo de a tabela ser considerada. **A própria Ana não tem
privilégio nenhum sobre o dado da Ipê.** Ela pode virar `ipe_owner` quando quiser, que é o que o
`SET ROLE` fez no arquivo acima; sem isso ela é um papel como outro qualquer. Esse é o arranjo
que a aula 1 montou de propósito, e aqui ele aparece pela primeira vez: quem administra o acesso
não lê, por padrão, o dado.

Conceder pessoa a pessoa funciona para um analista e uma tabela. Não sobrevive a um time de
analistas e quarenta tabelas, e a próxima seção o substitui.
