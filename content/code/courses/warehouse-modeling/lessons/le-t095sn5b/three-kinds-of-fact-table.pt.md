---
title: Três tipos de tabela fato
version: 1
---

`fact_sales` e `fact_inventory` são construídas de jeitos diferentes, e não por acaso. Kimball nomeia
três tipos de tabela fato, e todo processo de negócio cabe num deles. Qual é decorre de como o
processo acontece no tempo.

| tipo | uma linha por | gravada | exemplo aqui |
|---|---|---|---|
| **transação** | evento | uma vez, quando acontece | `fact_sales` |
| **snapshot periódico** | coisa, por período | uma vez por período | `fact_inventory` |
| **snapshot acumulado** | coisa com um ciclo de vida | quando começa, e atualizada a cada etapa | `fact_fulfilment`, abaixo |

As duas primeiras já estão construídas. Uma tabela de transação cresce com a atividade: um dezembro
movimentado acrescenta mais linhas que um fevereiro calmo. Um snapshot periódico cresce com o
calendário: as prateleiras de toda loja são contadas no fim de todo mês, tenha vendido algo ou não, e
um mês sem movimento também ganha suas linhas.

## O snapshot acumulado

Os pedidos da loja online passam por etapas: pedido, pago, enviado, entregue. O gerente quer saber
quanto cada etapa leva, e que pacotes ainda estão na estrada. É um processo com **um começo, uma lista
conhecida de marcos e um fim**, e ganha uma linha por pedido, com uma data para cada marco:

```sql
-- Grain: one row per online order, updated as it moves. A milestone not
-- reached yet points at the 'Not yet' date, key 0.
CREATE TABLE fact_fulfilment AS
SELECT o.order_id,
       CAST(strftime(o.ordered_at, '%Y%m%d') AS INTEGER)                  AS ordered_date_key,
       coalesce(CAST(strftime(o.paid_at, '%Y%m%d') AS INTEGER), 0)        AS paid_date_key,
       coalesce(CAST(strftime(o.shipped_at, '%Y%m%d') AS INTEGER), 0)     AS shipped_date_key,
       coalesce(CAST(strftime(o.delivered_at, '%Y%m%d') AS INTEGER), 0)   AS delivered_date_key,
       o.status,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.shipped_at AS DATE))   AS days_to_ship,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.delivered_at AS DATE)) AS days_to_deliver
FROM staging.orders o
JOIN staging.shops sh USING (shop_id)
WHERE sh.channel = 'online' AND o.status <> 'cancelled';
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fact_fulfilment.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM fact_fulfilment WHERE order_id IN (100001, 676352)"
┌──────────┬──────────────────┬───────────────┬──────────────────┬────────────────────┬───────────┬──────────────┬─────────────────┐
│ order_id │ ordered_date_key │ paid_date_key │ shipped_date_key │ delivered_date_key │  status   │ days_to_ship │ days_to_deliver │
│  int64   │      int32       │     int32     │      int32       │       int32        │  varchar  │    int64     │      int64      │
├──────────┼──────────────────┼───────────────┼──────────────────┼────────────────────┼───────────┼──────────────┼─────────────────┤
│   100001 │         20240101 │      20240101 │         20240102 │           20240104 │ delivered │            1 │               3 │
│   676352 │         20251230 │      20251230 │         20251231 │                  0 │ shipped   │            1 │            NULL │
└──────────┴──────────────────┴───────────────┴──────────────────┴────────────────────┴───────────┴──────────────┴─────────────────┘
```

O pedido 100001 passou por todas as etapas em três dias. O pedido 676352 foi feito em 30 de dezembro
de 2025, enviado no dia seguinte, e não tinha sido entregue quando os dados terminam: o
`delivered_date_key` dele é 0, a linha *Not yet* de `dim_date`. **Quando ele chegar, a carga atualiza
esta linha**: a data de entrega ganha sua chave e `days_to_deliver` seu número. É o único tipo de
linha fato que se atualiza, e só para preencher um marco.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma linha de fact_fulfilment para o pedido 676352, mostrada como fica depois de cada carga. Depois da carga de 30 de dezembro de 2025: pedido e pago no dia 30, envio e entrega ainda não. Depois da carga de 31 de dezembro: enviado no dia 31, entrega ainda não. Numa carga posterior, a data de entrega seria preenchida na mesma linha. A linha é atualizada no lugar; nenhuma linha nova é acrescentada.\"><defs><marker id=\"ah-accumulating\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"300\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">pedido</text><text x=\"415\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">pago</text><text x=\"530\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">enviado</text><text x=\"645\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">entregue</text><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">carga de 30/12</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linha inserida</text><rect x=\"250\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"365\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"480\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"530\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 · Not yet</text><rect x=\"595\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"645\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 · Not yet</text><line x1=\"180\" y1=\"100\" x2=\"180\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-accumulating)\"></line><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">carga de 31/12</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesma linha, atualizada</text><rect x=\"250\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"365\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"480\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251231</text><rect x=\"595\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"645\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 · Not yet</text><line x1=\"180\" y1=\"170\" x2=\"180\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-accumulating)\"></line><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma carga depois</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesma linha, atualizada</text><rect x=\"250\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"365\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"480\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251231</text><rect x=\"595\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026…</text></svg>", "caption": "Um snapshot acumulado: uma linha por pedido, preenchida conforme cada etapa é alcançada."}
```

A pergunta para a qual ela foi construída:

```sql
SELECT d.year, d.month_name,
       count(*)                          AS orders,
       round(avg(f.days_to_ship), 1)     AS avg_days_to_ship,
       round(avg(f.days_to_deliver), 1)  AS avg_days_to_deliver,
       count(*) FILTER (WHERE f.delivered_date_key = 0) AS not_delivered_yet
FROM fact_fulfilment f
JOIN dim_date d ON d.date_key = f.ordered_date_key
WHERE d.month IN (11, 12)
GROUP BY ALL ORDER BY d.year, d.month_name DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < lead-times.sql
┌───────┬────────────┬────────┬──────────────────┬─────────────────────┬───────────────────┐
│ year  │ month_name │ orders │ avg_days_to_ship │ avg_days_to_deliver │ not_delivered_yet │
│ int64 │  varchar   │ int64  │      double      │       double        │       int64       │
├───────┼────────────┼────────┼──────────────────┼─────────────────────┼───────────────────┤
│  2024 │ November   │  12078 │              2.4 │                 6.5 │                 0 │
│  2024 │ December   │  17504 │              2.1 │                 6.2 │                 0 │
│  2025 │ November   │  16490 │              2.3 │                 6.4 │                 0 │
│  2025 │ December   │  20054 │              2.2 │                 6.2 │              4071 │
└───────┴────────────┴────────┴──────────────────┴─────────────────────┴───────────────────┘
```

O despacho levou cerca de dois dias e a entrega cerca de seis, nos dois Natais. E 4.071 pedidos de
dezembro de 2025 ainda estavam a caminho quando os dados terminam. **Uma tabela de transação
responderia aos dois primeiros números com algum esforço; só o snapshot responde ao terceiro
diretamente**, porque os pedidos em aberto são linhas, e não a ausência de linhas.

Três tabelas, três formas de tempo. Errar o tipo é fácil de ver depois. Uma tabela de estoque feita
como transação não tem linha para um livro que não se moveu, então não sabe o que havia na
prateleira. Uma tabela de entregas feita como transação tem uma linha por marco, e toda pergunta de
prazo vira uma auto-junção.
