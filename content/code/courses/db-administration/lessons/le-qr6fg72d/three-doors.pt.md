---
title: Três portas no caminho até uma linha
version: 1
---

Um papel que quer ler uma tabela precisa passar por **três portas, em ordem**: `CONNECT` no banco,
`USAGE` no esquema onde a tabela está, e o privilégio na própria tabela. Cada porta é verificada
separadamente, cada recusa tem a sua frase, e a chave da porta de dentro não vale nada enquanto uma
de fora estiver fechada. Quando uma aplicação diz "permission denied", as palavras depois dessas
duas dizem em qual porta ela bateu.

A imagem tentadora é que um `GRANT SELECT` numa tabela é acesso à tabela. É acesso à última porta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Três caixas aninhadas: o banco shop contém o esquema reports, que contém a visão sales_by_month. Uma seta de uma sessão como bruno atravessa três fronteiras a caminho da visão, e cada fronteira é uma porta marcada com o privilégio que ela pede: CONNECT no banco, verificado no login; USAGE no esquema, verificado quando um nome é procurado nele; SELECT na visão, verificado por objeto.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"140\" y=\"16\" width=\"566\" height=\"188\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"154\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">banco</text><text x=\"198\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop</text><rect x=\"300\" y=\"48\" width=\"396\" height=\"144\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">esquema</text><text x=\"370\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">reports</text><rect x=\"460\" y=\"80\" width=\"226\" height=\"100\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"474\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">visão</text><text x=\"474\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sales_by_month</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma sessão como</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">bruno</text><line x1=\"70\" y1=\"160\" x2=\"600\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#arr)\"></line><rect x=\"106\" y=\"148\" width=\"68\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CONNECT</text><rect x=\"266\" y=\"148\" width=\"68\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">USAGE</text><rect x=\"426\" y=\"148\" width=\"68\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">SELECT</text><text x=\"220\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">verificado no login</text><text x=\"380\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">verificado pelo nome</text><text x=\"573\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">verificado por objeto</text></svg>", "caption": "Três portas, cada uma com seu privilégio e sua recusa. Ter a mais interna não abre nada se uma de fora estiver fechada."}
```

## O banco: CONNECT

Um papel recém-criado consegue conectar a todos os bancos do cluster, porque **o PostgreSQL dá
`CONNECT` em todo banco ao `PUBLIC`**, o pseudopapel que significa todo mundo. O `bruno` não recebeu
nada, e entra no `shop` mesmo assim. Tire o privilégio do `PUBLIC` e a porta fecha:

```
ana@db:~$ psql -h localhost -U bruno shop -c "SELECT current_user;"
 current_user 
--------------
 bruno
(1 row)

shop=# REVOKE CONNECT ON DATABASE shop FROM PUBLIC;
REVOKE

shop=# \l shop
                                             List of databases
 Name | Owner | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules | Access privileges 
------+-------+----------+-----------------+---------+---------+------------+-----------+-------------------
 shop | ana   | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =T/ana           +
      |       |          |                 |         |         |            |           | ana=CTc/ana
(1 row)
ana@db:~$ psql -h localhost -U bruno shop -c "SELECT current_user;"
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  permission denied for database "shop"
DETAIL:  User does not have CONNECT privilege.
shop=# GRANT CONNECT ON DATABASE shop TO reporting, app;
GRANT
```

O `\l shop` imprimiu a lista de acesso do banco pela primeira vez, porque uma lista que nunca foi
mudada fica guardada vazia e significa "os padrões". Agora ela está escrita, uma entrada por linha
na forma `grantee=privilégios/grantor`. **Um grantee vazio é o `PUBLIC`**: `=T/ana` diz que todo
mundo mantém o `T`, o direito de criar tabelas temporárias, e perdeu o `c`, conectar. `ana=CTc/ana`
é o conjunto completo do dono, sendo `C` o direito de criar esquemas. A lição 13 usa as mesmas
letras para tabelas.

A recusa veio do servidor no login, antes de qualquer SQL rodar, com um `DETAIL` dizendo qual
privilégio falta. O `GRANT CONNECT ... TO reporting` deixou o `bruno` entrar de novo pelo grupo
dele, e o `app` ganhou o mesmo, porque vai precisar.

## O esquema: USAGE

Um esquema é um espaço de nomes dentro de um banco, e um papel precisa de **`USAGE` num esquema para
procurar qualquer nome nele**. Crie um para relatórios, ponha nele uma visão que soma os pedidos por
mês, e conceda ao `reporting` o direito de ler a visão, e nada mais:

```
shop=# CREATE SCHEMA reports;
CREATE SCHEMA

shop=# CREATE VIEW reports.sales_by_month AS
shop-# SELECT date_trunc('month', created_at)::date AS month, count(*) AS orders, sum(total_cents) AS total_cents
shop-# FROM orders GROUP BY 1 ORDER BY 1;
CREATE VIEW

shop=# GRANT SELECT ON reports.sales_by_month TO reporting;
GRANT
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT * FROM reports.sales_by_month;
ERROR:  permission denied for schema reports
LINE 1: SELECT * FROM reports.sales_by_month;
                      ^

shop=> SELECT count(*) FROM customers;
ERROR:  permission denied for table customers
```

Duas consultas, duas portas diferentes. A visão é recusada no esquema, `permission denied for schema
reports`, mesmo existindo o grant na própria visão. `customers` é recusada na tabela,
`permission denied for table customers`: a porta do esquema estava aberta, porque o `public` dá
`USAGE` a todo mundo, e a da tabela não. Abra o esquema:

```
shop=# GRANT USAGE ON SCHEMA reports TO reporting;
GRANT
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT * FROM reports.sales_by_month;
   month    | orders | total_cents 
------------+--------+-------------
 2026-01-01 | 129176 |  3293617315
 2026-02-01 | 116676 |  2975134074
 2026-03-01 | 129177 |  3293611206
 2026-04-01 | 125010 |  3187726565
 2026-05-01 | 129177 |  3294763695
 2026-06-01 | 124990 |  3186856365
 2026-07-01 | 129146 |  3293209392
 2026-08-01 | 116648 |  2974581388
(8 rows)
```

**O `bruno` agora lê uma soma sobre um milhão de pedidos sem privilégio nenhum em `orders`.** Uma
visão roda a consulta dela com os privilégios do dono da visão, aqui a `ana`, então a visão é uma
porta por si só: ela deixa passar exatamente as colunas e linhas que a consulta produz. É o jeito
comum de dar uma janela estreita para uma tabela larga. Uma visão criada com
`WITH (security_invoker = true)`, possível desde a versão 15, verifica no lugar disso os privilégios
do papel que consulta sobre as tabelas de baixo.

## Perguntando sem fazer login

Fazer login como o papel é o teste honesto, e ele precisa da senha do papel. O servidor também
responde à pergunta diretamente, para qualquer papel, da sessão de um superusuário:

```
shop=# SELECT has_database_privilege('bruno', 'shop', 'CONNECT') AS connect, has_schema_privilege('bruno', 'reports', 'USAGE') AS usage, has_table_privilege('bruno', 'customers', 'SELECT') AS select;
 connect | usage | select 
---------+-------+--------
 t       | t     | f
(1 row)
```

O `has_database_privilege`, o `has_schema_privilege` e o `has_table_privilege` seguem a participação
em grupos como uma sessão de verdade faria, então o `bruno` aparece como capaz de conectar pelo
`reporting`. São eles que um script que audita grants deve chamar, em vez de ler as listas de acesso
por conta própria.
