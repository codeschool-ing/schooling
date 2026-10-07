---
title: dbt build, e o que uma falha para
version: 1
---

O `dbt run` constrói modelos e o `dbt test` os testa; **o `dbt build` faz as duas coisas, na ordem do
grafo**, testando cada modelo logo depois de construí-lo e antes de construir qualquer coisa que o
leia. Na saída da seção anterior, duas linhas perto do fim dizem `SKIP relation
dbt_marts.daily_sales` e `SKIP relation dbt_marts.fact_sales`, cada uma `due to ephemeral model
status 'skipped'`.

Um teste no `stg_orders` falhou, então nada abaixo do `stg_orders` foi construído: nem o
`int_sales`, e portanto nem os dois marts. **Os marts ficaram com as linhas de ontem**, que é
exatamente o que deve acontecer quando os dados a partir dos quais eles seriam construídos estão sob
suspeita. Um relatório com um dia de atraso que diz isso é melhor que um atual e errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l12-build\" aria-label=\"O dbt build na ordem do grafo. O stg_orders é construído e depois testado; o teste de cliente dele falha. Tudo abaixo dele é pulado: o int_sales, e portanto o daily_sales e o fact_sales, que ficam com as linhas que tinham. O stg_books, que não depende do stg_orders, é construído e testado normalmente.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"40.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_orders</text><text x=\"100.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">teste falhou</text><rect x=\"30.0\" y=\"150.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_books</text><text x=\"100.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">construído · testado</text><rect x=\"270.0\" y=\"40.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int_sales</text><text x=\"340.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pulado</text><rect x=\"510.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><text x=\"580.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pulado</text><rect x=\"510.0\" y=\"110.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daily_sales</text><text x=\"580.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pulado</text><path d=\"M170.0 62.0 L268.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M410.0 56.0 L508.0 42.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M410.0 70.0 L508.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M170.0 172.0 L508.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"580.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ficaram com as linhas de ontem</text></svg>", "caption": "Um teste que falha para o que lê o modelo, e mais nada."}
```

Esse é o comportamento certo para uma regra cuja falha quer dizer que os dados estão ruins. Para os
sete clientes apagados é o errado: nada neles torna os marts pouco confiáveis. A **severidade** de um
teste diz de que tipo ele é. `error`, o padrão, para o que vem depois; `warn` avisa e segue:

```
ana@vm:~/etl/shop$ grep -n -A4 "not_null:" models/staging/schema.yml
10:          - not_null:
11-              config:
12-                where: "shop_id = 7"            # the website: a till may sell to nobody
13-                severity: warn                  # 7 erased customers: known, and lawful
14-      - name: status
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "WARN|FAIL|SKIP|ERROR|Done"
06:31:16  5 of 11 WARN 7 not_null_stg_orders_customer_id ................................. [WARN 7 in 0.10s]
06:31:16  [WARNING]: in test not_null_stg_orders_customer_id (models/staging/schema.yml)
06:31:16  [WARNING]: Got 7 results, configured to warn if != 0
06:31:16  Done. PASS=10 WARN=1 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=11
```

`WARN 7`, tudo construído, `ERROR=0`. O aviso continua na saída de todo build, e vale a pena vigiar
o número dele: sete hoje, e se forem setenta semana que vem, alguma outra coisa além do direito de ser
esquecido está tirando clientes de pedidos do site.

A severidade também pode ser decidida pela contagem, com `warn_if` e `error_if` — avisar acima de
dez, falhar acima de cem — para regras em que umas poucas exceções são normais e muitas são um
incidente.
