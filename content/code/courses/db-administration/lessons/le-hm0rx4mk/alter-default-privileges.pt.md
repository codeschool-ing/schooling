---
title: ALTER DEFAULT PRIVILEGES, e de quais tabelas ele fala
version: 1
---

O `ALTER DEFAULT PRIVILEGES` guarda grants que o servidor **acrescenta a um objeto no momento em que
ele é criado**. Ele se escreve como um `GRANT`, com um tipo de objeto no plural no lugar do nome do
objeto, e duas cláusulas que decidem a quais objetos futuros ele se aplica:

- `FOR ROLE shop_owner` — objetos que esse papel criar. Sem ela, vale o papel que roda o comando.
- `IN SCHEMA public` — objetos criados nesse esquema. Sem ela, vale todo esquema do banco atual.

Defina os dois que o desenho da lição 12 pede:

```
shop=# ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner IN SCHEMA public
shop-#     GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app;
ALTER DEFAULT PRIVILEGES

shop=# ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner IN SCHEMA public
shop-#     GRANT SELECT ON TABLES TO reporting;
ALTER DEFAULT PRIVILEGES

shop=# \dp refunds
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | refunds | table |                   |                   | 
(1 row)
```

A `refunds` não mudou: os padrões valem para o que for criado daqui em diante. Dê os grants dela à
mão, uma vez:

```
shop=# GRANT SELECT, INSERT, UPDATE, DELETE ON refunds TO app;
GRANT

shop=# GRANT SELECT ON refunds TO reporting;
GRANT
```

E crie a próxima tabela como uma migração faria:

```
shop=# SET ROLE shop_owner;
SET

shop=> CREATE TABLE shipments (
shop(>     id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
shop(>     order_id   bigint NOT NULL REFERENCES orders (id),
shop(>     shipped_at timestamptz NOT NULL DEFAULT now()
shop(> );
CREATE TABLE

shop=> RESET ROLE;
RESET

shop=# \dp shipments
                                     Access privileges
 Schema |   Name    | Type  |       Access privileges       | Column privileges | Policies 
--------+-----------+-------+-------------------------------+-------------------+----------
 public | shipments | table | reporting=r/shop_owner       +|                   | 
        |           |       | app=arwd/shop_owner          +|                   | 
        |           |       | shop_owner=arwdDxt/shop_owner |                   | 
(1 row)
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM shipments;
 count 
-------
     0
(1 row)
```

A `shipments` chegou com os dois grants. Ninguém digitou um `GRANT` para ela, o `bruno` consegue
lê-la, e o grantor registrado é o `shop_owner`, o dono, como em qualquer grant.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma linha do tempo com cinco eventos. Primeiro, o GRANT ON ALL TABLES roda uma vez e cobre as tabelas que existem, customers e orders. Depois o shop_owner cria refunds, que não recebe grant. Depois o ALTER DEFAULT PRIVILEGES é executado para toda tabela que o shop_owner criar. Depois o shop_owner cria shipments, que recebe os grants sozinha. Por último, a ana cria coupons, que não recebe grant, porque a ana não é o shop_owner.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><line x1=\"20\" y1=\"104\" x2=\"700\" y2=\"104\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"700\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><text x=\"80\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GRANT ... ON ALL</text><text x=\"80\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TABLES</text><line x1=\"80\" y1=\"72\" x2=\"80\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"80\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"215\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop_owner cria</text><text x=\"215\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refunds</text><line x1=\"215\" y1=\"72\" x2=\"215\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"215\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"350\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ALTER DEFAULT</text><text x=\"350\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">PRIVILEGES</text><line x1=\"350\" y1=\"72\" x2=\"350\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"350\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"485\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop_owner cria</text><text x=\"485\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shipments</text><line x1=\"485\" y1=\"72\" x2=\"485\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"485\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"620\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana cria</text><text x=\"620\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">coupons</text><line x1=\"620\" y1=\"72\" x2=\"620\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"620\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><rect x=\"30\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">customers</text><rect x=\"30\" y=\"156\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><rect x=\"165\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"215\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refunds</text><rect x=\"435\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shipments</text><rect x=\"570\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"620\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">coupons</text><text x=\"80\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">com grant</text><text x=\"215\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem grant</text><text x=\"350\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para toda tabela que</text><text x=\"350\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_owner criar</text><text x=\"485\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">com grant</text><text x=\"620\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem grant: não é shop_owner</text></svg>", "caption": "Um GRANT alcança as tabelas que existem quando ele roda. Um privilégio padrão alcança as tabelas que um papel nomeado criar depois, e nada mais."}
```

## A armadilha do criador

Olhe de novo a primeira cláusula: `FOR ROLE shop_owner`. **Um privilégio padrão pertence ao papel que
cria o objeto, não ao esquema onde ele cai**, e esse é o erro pelo qual o recurso é conhecido. Uma
administradora com pressa cria uma tabela como ela mesma:

```
shop=# CREATE TABLE coupons (code text PRIMARY KEY, percent integer NOT NULL);
CREATE TABLE

shop=# \dt coupons
        List of relations
 Schema |  Name   | Type  | Owner 
--------+---------+-------+-------
 public | coupons | table | ana
(1 row)

shop=# \dp coupons
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | coupons | table |                   |                   | 
(1 row)

shop=# ALTER TABLE coupons OWNER TO shop_owner;
ALTER TABLE

shop=# \dp coupons
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | coupons | table |                   |                   | 
(1 row)
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM coupons;
ERROR:  permission denied for table coupons
```

A `coupons` foi criada pela `ana`, então os padrões do `shop_owner` nem olharam para ela. Mudar o
dono depois não ajudou: **o `ALTER ... OWNER TO` muda a posse e não aplica privilégio padrão
nenhum**, porque eles são aplicados uma vez, na criação, e a tabela já tinha sido criada. O `bruno` é
recusado, e a lista de acesso fica vazia com qualquer um dos dois donos.

O conserto é dar os grants à mão ou, enquanto ela ainda está vazia, criá-la de novo como o papel
certo:

```
shop=# DROP TABLE coupons;
DROP TABLE

shop=# SET ROLE shop_owner;
SET

shop=> CREATE TABLE coupons (code text PRIMARY KEY, percent integer NOT NULL);
CREATE TABLE

shop=> RESET ROLE;
RESET

shop=# \dp coupons
                                    Access privileges
 Schema |  Name   | Type  |       Access privileges       | Column privileges | Policies 
--------+---------+-------+-------------------------------+-------------------+----------
 public | coupons | table | reporting=r/shop_owner       +|                   | 
        |         |       | app=arwd/shop_owner          +|                   | 
        |         |       | shop_owner=arwdDxt/shop_owner |                   | 
(1 row)
```

A mesma armadilha pega equipes que rodam o `ALTER DEFAULT PRIVILEGES` sem `FOR ROLE`. A
administradora roda como ela mesma, isso registra padrões para as tabelas da própria
administradora, e a ferramenta de deploy, que faz login com o próprio papel, cria tabelas às quais
nada disso se aplica. **O papel citado no `FOR ROLE` precisa ser o papel que roda as migrações**, e
esse é o motivo mais forte para toda migração rodar como um papel dono só, e não como quem estiver
fazendo o deploy.

## O que mais ele cobre

Os tipos de objeto no plural são `TABLES` (que inclui visões), `SEQUENCES`, `FUNCTIONS` (que inclui
procedures), `TYPES` e `SCHEMAS`. Uma tabela com coluna `serial` precisa de `GRANT USAGE ON
SEQUENCES` ao lado do grant da tabela; colunas identity, como a lição 12 mostrou, não precisam. Um
privilégio padrão fica guardado num banco e só vale nele, como qualquer outro grant.
