---
title: Costuras: por onde um teste consegue entrar
version: 1
---

Um teste de integração não pode rodar contra a loja de verdade e o warehouse de verdade: carregaria
dados reais em tabelas de produção, e as respostas dele mudariam toda noite. Ele precisa de bancos
próprios, e o pipeline tem de ser avisado para usá-los. O código da Ana tinha os nomes escritos dentro
— `dbname=shop`, `dbname=wh` —, então não havia por onde um teste entrar.

Um lugar onde o comportamento pode ser mudado sem mudar o código se chama **costura** (*seam*). A Ana
acrescenta duas: uma variável de ambiente para cada banco, com os bancos de verdade como padrão, e um
segundo target do dbt:

```
ana@vm:~/etl$ diff /tmp/load_raw.before.py load_raw.py
3a4
> import os
13c14,17
< with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
---
> SHOP_DB = os.environ.get("SHOP_DB", "shop")   # the tests point these at their own databases
> WH_DB = os.environ.get("WH_DB", "wh")
> 
> with psycopg.connect(dbname=SHOP_DB) as shop, psycopg.connect(dbname=WH_DB) as wh:
ana@vm:~/etl$ tail -n 10 ~/.dbt/profiles.yml
      threads: 4
    test:                       # the integration tests' own warehouse
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh_test
      schema: dbt
      threads: 4
```

A carga noturna roda exatamente como antes, porque nada define as variáveis e `dev` continua sendo o
target padrão. Os testes definem `SHOP_DB=shop_test WH_DB=wh_test` e passam `--target test`. **Nada
no pipeline sabe que está sendo testado**, que é o objetivo: o que o teste roda é o código que roda de
noite, não uma cópia feita testável.

As mesmas duas costuras são o que a lição 18 precisa para rodar o pipeline num ambiente de
desenvolvimento e em produção a partir do mesmo código. Um ambiente de teste é simplesmente o primeiro
ambiente.
