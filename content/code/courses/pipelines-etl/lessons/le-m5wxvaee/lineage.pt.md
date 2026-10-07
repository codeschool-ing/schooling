---
title: Linhagem: de onde vem, e o que alimenta
version: 1
---

**Linhagem** (*lineage*) é o grafo lido com um propósito: tudo de onde um número veio, ou tudo o
que uma mudança vai alcançar. O grafo do dbt já guarda quase tudo. O que falta é a ponta de lá: o
`daily_sales` é lido por um relatório toda manhã, e nada no projeto dizia isso. Uma **exposure** diz:

```
version: 2

exposures:
  - name: morning_report
    type: dashboard
    description: The sales report the shops' managers read at 08:00.
    owner:
      name: Ana
    depends_on:
      - ref('daily_sales')
```

Uma exposure não constrói nada nem roda nada. Ela é um nó no grafo com um dono e uma descrição, para
que o grafo vá até as pessoas que usam os dados:

```
ana@vm:~/etl/shop$ dbt ls -s +exposure:morning_report --resource-type model --resource-type source --resource-type exposure
08:49:18  Running with dbt=1.12.5
08:49:18  Registered adapter: postgres=1.11.0
08:49:18  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
exposure:shop.morning_report
shop.marts.daily_sales
shop.staging.int_sales
shop.staging.stg_books
shop.staging.stg_order_lines
shop.staging.stg_orders
source:shop.raw.books
source:shop.raw.order_lines
source:shop.raw.orders
ana@vm:~/etl/shop$ dbt ls -s source:raw.orders+ --resource-type model --resource-type exposure
08:49:20  Running with dbt=1.12.5
08:49:21  Registered adapter: postgres=1.11.0
08:49:21  Found 6 models, 8 data tests, 3 sources, 1 exposure, 477 macros
exposure:shop.morning_report
shop.marts.daily_sales
shop.marts.fact_sales
shop.staging.int_sales
shop.staging.stg_orders
```

O primeiro comando lê o grafo para cima a partir do relatório: todo modelo e toda fonte em que o
relatório da manhã se apoia. Quando um gerente diz que um número ali parece errado, essa é a lista de
lugares de onde ele pode ter vindo, e mais nenhum.

O segundo o lê para baixo a partir de uma fonte: tudo o que o `raw.orders` alcança, terminando no
relatório. **Antes de mudar o jeito de carregar os pedidos, essa é a lista do que pode quebrar**, e a
exposure põe um nome na última linha: o da Ana, e os gerentes que o leem às oito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l12-lineage\" aria-label=\"A linhagem de uma fonte até um relatório. O raw.orders alimenta o stg_orders, que alimenta o int_sales, que alimenta o daily_sales e o fact_sales; o daily_sales alimenta o relatório da manhã, uma exposure da Ana. Ler para a esquerda responde de onde um número veio; ler para a direita responde o que uma mudança vai alcançar.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"14.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.orders</text><path d=\"M126.0 120.0 L152.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"154.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_orders</text><path d=\"M266.0 120.0 L292.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"294.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int_sales</text><path d=\"M406.0 120.0 L432.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"434.0\" y=\"100.0\" width=\"112.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daily_sales</text><path d=\"M546.0 120.0 L578.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"100.0\" width=\"126.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">morning_report</text><text x=\"643.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exposure · Ana</text><rect x=\"434.0\" y=\"180.0\" width=\"112.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><path d=\"M406 134 C 420 150, 400 196, 432 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M690.0 40.0 L30.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de onde veio este número?</text><path d=\"M30.0 70.0 L690.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"360.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que esta mudança vai alcançar?</text></svg>", "caption": "Um grafo, lido em duas direções para duas perguntas.", "same": ["exposure · Ana"]}
```

A linhagem do dbt para nas bordas do projeto: ela começa nas fontes e termina nas exposures. Antes
das fontes está o `load_raw.py`, rodado pelo Airflow; os assets do Airflow da lição 9 descrevem essa
parte. Existem ferramentas que juntam as duas numa figura só, entre sistemas. Numa equipe de uma
pessoa, os dois comandos acima e o hábito de rodá-los antes de uma mudança cobrem quase tudo o que
elas fazem.
