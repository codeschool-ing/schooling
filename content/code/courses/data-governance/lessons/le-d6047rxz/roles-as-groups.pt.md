---
title: Conceda ao cargo, não à pessoa
version: 1
---

A concessão do Bruno respondeu a uma pergunta: o que o Bruno pode ler? A pergunta que sobrevive a
um ano de contratações e saídas é outra — **o que um analista pode ler?** — e a resposta dela
deve ser escrita uma vez, num lugar só, e valer para quem for analista hoje.

Isso é **controle de acesso baseado em papéis** (RBAC): os privilégios são concedidos a papéis
que representam cargos, e as pessoas viram membros dos cargos que exercem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l2-rbac\" aria-label=\"Controle de acesso baseado em papéis no banco da Ipê. À esquerda, os logins: bruno, carla, site_app e etl_loader. No meio, os cargos de que são membros: analyst, support_agent, app_web e pipeline. À direita, o que cada cargo pode fazer. Os privilégios são concedidos só aos cargos; nenhuma seta vai de uma pessoa a uma tabela.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"80.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">logins</text><text x=\"300.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">cargos</text><text x=\"560.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">privilégios</text><rect x=\"20.0\" y=\"44.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bruno</text><rect x=\"225.0\" y=\"44.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">analyst</text><rect x=\"440.0\" y=\"40.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT orders, items, products</text><text x=\"570.0\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT 6 columns of customers</text><path d=\"M140.0 66.0 L223.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 66.0 L438.0 66.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"20.0\" y=\"108.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">carla</text><rect x=\"225.0\" y=\"108.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">support_agent</text><rect x=\"440.0\" y=\"104.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"121.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT customers, orders</text><text x=\"570.0\" y=\"138.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE (status) tickets</text><path d=\"M140.0 130.0 L223.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 130.0 L438.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"20.0\" y=\"172.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">site_app</text><rect x=\"225.0\" y=\"172.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app_web</text><rect x=\"440.0\" y=\"168.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT products</text><text x=\"570.0\" y=\"202.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT orders, items, payments</text><path d=\"M140.0 194.0 L223.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 194.0 L438.0 194.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"20.0\" y=\"236.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">etl_loader</text><rect x=\"225.0\" y=\"236.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pipeline</text><rect x=\"440.0\" y=\"232.0\" width=\"260.0\" height=\"52.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"249.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SELECT customers, orders, items,</text><text x=\"570.0\" y=\"266.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">payments, products</text><path d=\"M140.0 258.0 L223.0 258.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M375.0 258.0 L438.0 258.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path></svg>", "caption": "Pessoas são membros de cargos; cargos têm privilégios. Um analista novo é uma associação, não quarenta concessões.", "same": ["logins"]}
```

No PostgreSQL um cargo é só um papel que não pode logar:

```sql
-- One role per job, none of which can log in. People are made members.
CREATE ROLE analyst       NOLOGIN;
CREATE ROLE support_agent NOLOGIN;
CREATE ROLE app_web       NOLOGIN;
CREATE ROLE pipeline      NOLOGIN;

GRANT analyst       TO bruno, lia;
GRANT support_agent TO carla;
GRANT app_web       TO site_app;
GRANT pipeline      TO etl_loader;

-- What each job may do, granted to the job and never to the person.
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales TO analyst, support_agent, app_web, pipeline;
GRANT USAGE ON SCHEMA support TO support_agent;

GRANT SELECT ON sales.orders, sales.order_items, sales.products TO analyst;
GRANT SELECT ON sales.orders, sales.order_items, sales.products,
                sales.customers, sales.payments TO pipeline;
GRANT SELECT ON sales.products TO app_web;
GRANT INSERT ON sales.orders, sales.order_items, sales.payments TO app_web;
GRANT SELECT ON sales.customers, sales.orders TO support_agent;
GRANT SELECT, UPDATE (status) ON support.tickets TO support_agent;

-- Bruno's own grants were the first draft. The group replaces them.
REVOKE SELECT ON sales.orders FROM bruno;
REVOKE USAGE ON SCHEMA sales FROM bruno;
```

```
ana@lab:~/gov$ psql -f groups.sql
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
GRANT ROLE
GRANT ROLE
GRANT ROLE
GRANT ROLE
SET
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
REVOKE
REVOKE
ana@lab:~/gov$ psql -c "\drg"
                 List of role grants
 Role name  |   Member of   |   Options    | Grantor  
------------+---------------+--------------+----------
 ana        | analyst       | ADMIN        | postgres
 ana        | app_web       | ADMIN        | postgres
 ana        | bruno         | ADMIN        | postgres
 ana        | carla         | ADMIN        | postgres
 ana        | davi          | ADMIN        | postgres
 ana        | etl_loader    | ADMIN        | postgres
 ana        | ipe_owner     | SET          | postgres
 ana        | lia           | ADMIN        | postgres
 ana        | pipeline      | ADMIN        | postgres
 ana        | site_app      | ADMIN        | postgres
 ana        | support_agent | ADMIN        | postgres
 bruno      | analyst       | INHERIT, SET | ana
 carla      | support_agent | INHERIT, SET | ana
 etl_loader | pipeline      | INHERIT, SET | ana
 lia        | analyst       | INHERIT, SET | ana
 site_app   | app_web       | INHERIT, SET | ana
(16 rows)

ana@lab:~/gov$ psql -c "\dp sales.orders"
                                  Access privileges
 Schema |  Name  | Type  |      Access privileges      | Column privileges | Policies 
--------+--------+-------+-----------------------------+-------------------+----------
 sales  | orders | table | ipe_owner=arwdDxt/ipe_owner+|                   | 
        |        |       | analyst=r/ipe_owner        +|                   | 
        |        |       | pipeline=r/ipe_owner       +|                   | 
        |        |       | app_web=a/ipe_owner        +|                   | 
        |        |       | support_agent=r/ipe_owner   |                   | 
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.order_items"
 count 
-------
 63472
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM health.prescriptions"
ERROR:  permission denied for schema health
LINE 1: SELECT count(*) FROM health.prescriptions
                             ^
```

`\drg` lista quem é membro de quê. Ana aparece com `ADMIN` em todo papel que criou — ela pode
pôr e tirar membros — e só com `SET` em `ipe_owner`, o arranjo da aula 1. Cada pessoa é membro de
um cargo com `INHERIT, SET`: os privilégios do cargo chegam a ela sem que precise pedir.

Os privilégios da tabela não mencionam mais pessoa nenhuma. `\dp sales.orders` lista quatro
cargos, e `app_web=a` diz que o site pode inserir pedidos e mais nada com eles. O Bruno lê
`order_items` agora, via `analyst`, e `health.prescriptions` continua fechada no schema: ninguém
concedeu `USAGE` em `health` a cargo nenhum.

## O que isso compra

**Um analista novo é um comando**, `GRANT analyst TO …`, e recebe exatamente o que os outros têm.
**Uma saída também é um comando**, e as concessões em quarenta tabelas não precisam ser
caçadas. **Uma revisão de acesso lê quatro cargos**, não cada pessoa: "o que um analista pode
ler" se responde com `\dp`, e "quem é analista" com `\drg`.

E as concessões viram **uma descrição do negócio** que alguém além da Ana consegue ler.
`support_agent` pode atualizar uma coluna da tabela de chamados, `status`, e nenhuma outra:
escrito assim, a pergunta "o suporte pode fechar um chamado?" tem resposta, e a pergunta "o
suporte pode reescrever o que o cliente disse?" também.

## Onde deixa de bastar

Papéis são grossos de propósito. Todo analista recebe as mesmas linhas e as mesmas colunas, e
isso está certo até a regra depender de **algo da linha**, ou de **algo da pessoa** que um cargo
não carrega: a Carla atende São Paulo e Rio, outra atendente atende o Sul. Mais duas ferramentas
seguem daí — privilégios em colunas e políticas em linhas — e uma regra baseada em atributos é
uma política que lê um atributo. O resto desta aula constrói cada uma.
