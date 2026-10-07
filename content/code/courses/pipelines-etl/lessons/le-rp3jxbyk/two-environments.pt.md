---
title: Dois ambientes a partir de um projeto
version: 1
---

Um **ambiente** é um lugar completo para o pipeline rodar: o código, a configuração e os dados que ele
escreve. A Ana precisa de dois. **Produção** é o que os relatórios leem, construído pela carga noturna
a partir de uma versão do código que foi terminada e testada. **Desenvolvimento** é onde ela muda
coisas, construído quando ela quiser a partir do que estiver fazendo. Nada feito em desenvolvimento
pode mudar o que a produção diz.

Para o warehouse, a separação é um segundo target do dbt. A lição 11 mostrou que um schema próprio é
somado ao schema do target; essa regra agora faz o trabalho:

```
ana@vm:~/etl$ cat ~/.dbt/profiles.yml
ponto_final:
  target: dev                   # what dbt builds when nobody says otherwise
  outputs:
    dev:                        # Ana's own schemas, beside production's
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt_ana
      threads: 4
    prod:                       # what the reports read; built only by the nightly
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt
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

O `dev` escreve em `dbt_ana_staging` e `dbt_ana_marts`, o `prod` em `dbt_staging` e `dbt_marts`, no
mesmo warehouse, lendo o mesmo `raw`. E o `dev` é o padrão, então um `dbt build` digitado com pressa
constrói os schemas da Ana, nunca os dos relatórios. O target `test` da lição 17 é o terceiro
ambiente, com um warehouse próprio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l18-environments\" aria-label=\"Um repositório, dois ambientes. No repositório, a main tem dois commits com tag, v1.0.0 e v1.1.0, e uma branch onde a mudança foi feita. A Ana trabalha em ~/etl, na main, e constrói com o target dev nos schemas dbt_ana. A produção é o ~/etl-prod, num checkout de uma tag, construído com o target prod nos schemas dbt que os relatórios leem. Os dois leem o mesmo schema raw.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o repositório</text><path d=\"M30.0 90.0 L200.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"60.0\" cy=\"90.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"60.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.0.0</text><circle cx=\"170.0\" cy=\"90.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"170.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.0</text><path d=\"M60 90 C 90 58, 140 58, 170 90\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"115.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">branch</text><rect x=\"250.0\" y=\"30.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~/etl · main · target dev</text><rect x=\"250.0\" y=\"150.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~/etl-prod · uma tag · target prod</text><path d=\"M200.0 90.0 L248.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M176.0 98.0 L248.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"510.0\" y=\"30.0\" width=\"190.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dbt_ana_staging · dbt_ana_marts</text><rect x=\"510.0\" y=\"150.0\" width=\"190.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dbt_staging · dbt_marts</text><path d=\"M470.0 55.0 L508.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M470.0 175.0 L508.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"605.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os relatórios</text><text x=\"605.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">raw, compartilhado, só leitura</text></svg>", "caption": "A produção é uma tag e um target; o desenvolvimento é todo o resto.", "same": ["branch"]}
```

Para o código, a separação é um segundo checkout. Uma **tag** nomeia um commit para sempre: `v1.0.0`
é *a carga noturna como roda hoje*, aconteça o que acontecer com a `main` depois. O `git worktree`
põe esse commit num diretório próprio, a partir do qual a produção é construída:

```
ana@vm:~/etl$ git tag -a v1.0.0 -m "The nightly as it runs today" && git worktree add -q ~/etl-prod v1.0.0 && git worktree list
/home/ana/etl       cdef2c0 [main]
/home/ana/etl-prod  cdef2c0 (detached HEAD)
ana@vm:~/etl-prod$ dbt build --project-dir shop --target prod --quiet && dbt ls --project-dir shop --target prod --resource-type model -q --output name
daily_sales
fact_sales
int_sales
stg_books
stg_events
stg_order_lines
stg_orders
ana@vm:~/etl$ psql -d wh -c "\dn dbt*"
   List of schemas
    Name     | Owner 
-------------+-------
 dbt_marts   | ana
 dbt_staging | ana
(2 rows)
```

Dois diretórios de um repositório: `~/etl` na `main`, onde a Ana trabalha, e `~/etl-prod` fixo em
`v1.0.0`, que é o que a carga noturna roda. Editar um arquivo em `~/etl` não muda nada em
`~/etl-prod`. Os schemas de produção agora existem, construídos a partir do código com tag; os da Ana
ainda não.
