---
title: O grafo que o dbt monta para você
version: 1
---

Na lição 8 a Ana escreveu a ordem do pipeline à mão: `extract >> transform >> [dim_customer,
dim_book]`. Dentro do `transform`, a ordem dos arquivos SQL era a do alfabeto. No projeto dbt
ninguém escreveu ordem nenhuma, e o dbt tem uma mesmo assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-graph\" aria-label=\"O grafo que o dbt monta a partir do projeto shop. Três fontes no schema raw alimentam três views de staging: pedidos, linhas de pedido e livros. Pedidos e linhas de pedido alimentam o int_sales, um modelo efêmero desenhado tracejado porque nunca é construído. O int_sales alimenta os dois marts, o daily_sales, que também lê os livros, e o fact_sales.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.orders</text><text x=\"86.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fonte</text><rect x=\"192.0\" y=\"30.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_orders</text><text x=\"258.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text><path d=\"M152.0 52.0 L190.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"110.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.order_lines</text><text x=\"86.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fonte</text><rect x=\"192.0\" y=\"110.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_order_lines</text><text x=\"258.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text><path d=\"M152.0 132.0 L190.0 132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"190.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw.books</text><text x=\"86.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fonte</text><rect x=\"192.0\" y=\"190.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"258.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stg_books</text><text x=\"258.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text><path d=\"M152.0 212.0 L190.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"364.0\" y=\"70.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"430.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int_sales</text><text x=\"430.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">efêmero</text><path d=\"M324.0 52.0 L362.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M324.0 132.0 L362.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"150.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daily_sales</text><text x=\"626.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabela</text><rect x=\"560.0\" y=\"40.0\" width=\"132.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><text x=\"626.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">incremental</text><path d=\"M496.0 92.0 L558.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M496.0 92.0 L558.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M324.0 212.0 L558.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Ninguém escreveu estas setas. Cada uma é um ref() ou um source() dentro de um modelo.", "same": ["incremental", "view"]}
```

Cada seta é um `ref` ou um `source` dentro de um modelo. Acrescente um modelo que se refira ao
`stg_books`, e o grafo ganha uma seta nova antes de o modelo rodar uma vez; tire um `ref`, e a seta
some. **As dependências não podem se afastar do código, porque elas são o código.**

O grafo também é o jeito de escolher o que rodar. Um `+` antes do nome de um modelo quer dizer *tudo
de que ele depende*; depois, *tudo o que depende dele*:

```
ana@vm:~/etl/shop$ dbt ls -s +daily_sales
08:48:33  Running with dbt=1.12.5
08:48:34  Registered adapter: postgres=1.11.0
08:48:34  Found 6 models, 3 sources, 477 macros
shop.marts.daily_sales
shop.staging.int_sales
shop.staging.stg_books
shop.staging.stg_order_lines
shop.staging.stg_orders
source:shop.raw.books
source:shop.raw.order_lines
source:shop.raw.orders
ana@vm:~/etl/shop$ dbt ls -s stg_orders+ --resource-type model
08:48:36  Running with dbt=1.12.5
08:48:36  Registered adapter: postgres=1.11.0
08:48:36  Found 6 models, 3 sources, 477 macros
shop.marts.daily_sales
shop.marts.fact_sales
shop.staging.int_sales
shop.staging.stg_orders
ana@vm:~/etl/shop$ dbt run -s stg_books+ 2>&1 | grep -E " OK |ERROR"
08:48:39  1 of 2 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.11s]
08:48:39  2 of 2 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6285 in 0.10s]
08:48:39  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

O `+daily_sales` é o que o `daily_sales` precisa, fontes incluídas: a lista a refazer quando os
números dele parecem errados. O `stg_orders+` é o que uma mudança no `stg_orders` pode afetar: a
lista a refazer depois de mudá-lo, e a olhar antes de mudá-lo. E o `dbt run -s stg_books+` rodou
exatamente os dois modelos que leem os livros, mais nada.

## Onde o Airflow entra agora

O dbt ordena os modelos e os roda, e para aí. Ele não espera a carga terminar, não tenta de novo às
três da manhã nem avisa ninguém — as coisas que as lições 9 e 10 deram ao Airflow. **O arranjo comum
é ter os dois**: uma tarefa do Airflow que roda `dbt run` (ou `dbt build`, na próxima lição) depois
que o `load_raw.py` terminou, de modo que o Airflow cuida do *quando* e o dbt do *em que ordem*.
Existem pacotes que transformam cada modelo do dbt numa tarefa própria do Airflow, para que o grafo
acima apareça também na interface do Airflow; nenhum está instalado no laboratório, e a lição não
roda nenhum.
