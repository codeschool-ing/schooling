---
title: A quem a segurança de linha não se aplica
version: 1
---

Uma política é uma regra para papéis, e três tipos de papel não estão presos a ela. Cada um é
razoável por si, e cada um é um caminho ao redor da regra que alguém precisa conhecer.

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) FROM sales.customers"
SET
 count 
-------
  6012
(1 row)

ana@lab:~/gov$ psql -c "SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname = 'customers'"
  relname  | relrowsecurity | relforcerowsecurity 
-----------+----------------+---------------------
 customers | t              | f
(1 row)

ana@lab:~/gov$ psql -c "\du postgres"
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
```

**O dono da tabela vê toda linha.** `ipe_owner` contou 6.012. As políticas só se aplicam ao dono
quando a tabela está em modo `FORCE ROW LEVEL SECURITY`, e o catálogo diz que `customers` não
está: `relforcerowsecurity` é `f`. Isso é de propósito — o dono é quem mantém a tabela e as
políticas — e é por isso que ninguém deveria ler dado como o dono.

**Um superusuário vê toda linha**, e também qualquer papel com o atributo `BYPASSRLS`, que o
`\du` imprime para `postgres`. Backups são feitos por um papel assim, porque um backup que
obedecesse às políticas seria um backup do que a pessoa que o roda consegue ver.

## Uma view roda como o dono, e a segurança de linha dela também

O terceiro é o sutil, e decorre da última seção. A view dos analistas lê a tabela como
`ipe_owner`. Ana concede a mesma view ao cargo de suporte, para ver o que um atendente
receberia:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "GRANT SELECT ON sales.customer_profile TO support_agent"
SET
GRANT
ana@lab:~/gov$ psql service=carla -c "SELECT count(*) FROM sales.customer_profile"
 count 
-------
  6012
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER VIEW sales.customer_profile SET (security_invoker = true)"
SET
ALTER VIEW
ana@lab:~/gov$ psql service=carla -c "SELECT count(*) FROM sales.customer_profile"
 count 
-------
  3386
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.customer_profile"
ERROR:  permission denied for table customers
```

Pela view, **a Carla vê todos os 6.012 clientes**. A política da tabela foi avaliada para o dono
da view, que é isento dela. Nada na política mudou; a porta estava em outra parede.

`security_invoker = true`, disponível desde o PostgreSQL 15, faz uma view conferir privilégios e
políticas como **a pessoa que a lê**, e não como o dono. Ligado nesta view, ele dá à Carla os
3.386 dela — e recusa o Bruno de vez, porque agora *ele* precisa de `birth_date` e não tem. Então
os dois tipos de view fazem trabalhos diferentes:

| | roda como | bom para |
|---|---|---|
| uma view padrão | o dono | expor colunas derivadas de linhas que todo o cargo pode ver — o perfil dos analistas |
| uma view `security_invoker` | quem lê | uma conveniência sobre uma tabela cuja segurança de linha precisa continuar valendo |

Ana devolve a view ao que era e a revoga do suporte:

```sh
psql -c "SET ROLE ipe_owner" -c "ALTER VIEW sales.customer_profile SET (security_invoker = false)" -c "REVOKE SELECT ON sales.customer_profile FROM support_agent"
```

A lição que ela anota é a que vale guardar:
**a segurança de linha protege uma tabela, não o dado que está nela.** Tudo o que lê a tabela em
nome de outro — uma view, uma função, uma view materializada, uma cópia noturna para outra
tabela, uma exportação — carrega o que o dono dele conseguia ver.
