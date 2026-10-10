---
title: A tabela que chega amanhã
version: 1
---

A lição 12 terminou com cada papel tendo exatamente o que precisa, e esse estado dura **até a
próxima migração**. O `GRANT ... ON ALL TABLES IN SCHEMA public` parece uma regra sobre o esquema. É
um laço que rodou uma vez: encontrou as tabelas que existiam naquele momento, concedeu em cada uma e
não guardou lembrança nenhuma de ter feito isso.

A próxima tabela mostra. Uma migração acrescenta reembolsos, rodada como o dono, do jeito que a
lição 12 organizou:

```
shop=# SET ROLE shop_owner;
SET

shop=> CREATE TABLE refunds (
shop(>     id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
shop(>     order_id     bigint NOT NULL REFERENCES orders (id),
shop(>     amount_cents integer NOT NULL,
shop(>     created_at   timestamptz NOT NULL DEFAULT now()
shop(> );
CREATE TABLE

shop=> RESET ROLE;
RESET

shop=# \dp refunds
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | refunds | table |                   |                   | 
(1 row)
ana@db:~$ psql -h localhost -U app shop
shop=> INSERT INTO refunds (order_id, amount_cents) VALUES (1, 500);
ERROR:  permission denied for table refunds
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM refunds;
ERROR:  permission denied for table refunds
```

O `\dp refunds` mostra uma lista de acesso vazia, o que numa tabela significa **o dono e mais
ninguém**. A aplicação que está para gravar reembolsos é recusada, e o analista a quem vão pedir
relatórios sobre eles também. Nada falhou durante a migração, e nada vai falhar até a primeira
requisição que tocar a tabela nova, que acontece em produção, depois do deploy, na frente de um
cliente.

Há três jeitos de responder a isso, e só o terceiro continua funcionando:

1. **Rodar o `GRANT ... ON ALL TABLES` de novo depois de cada migração.** Funciona até o dia em que
   alguém esquece, e concede em tudo a cada vez, inclusive na tabela que foi deixada de fora de
   propósito no mês passado.
2. **Pôr os grants em cada migração**, ao lado do `CREATE TABLE`. Melhor: a decisão fica escrita
   onde a tabela está. Ainda depende de todo autor lembrar, toda vez.
3. **Dizer ao servidor o que uma tabela nova deve receber**, uma vez, antes de as tabelas
   existirem. Isso é um privilégio padrão, e a próxima seção define dois.

Seja qual for a escolha, a própria `refunds` precisa dos grants à mão, porque um privilégio padrão é
aplicado quando uma tabela é criada e nunca depois.
