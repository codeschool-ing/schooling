---
title: Duas granularidades, duas tabelas
version: 1
---

Pagamentos têm a sua própria granularidade. A maioria dos pedidos é paga uma vez; alguns são pagos com
um vale-presente e um cartão juntos, e ganham dois pagamentos. É por isso que `fact_payments` é uma
tabela separada, com uma linha por pagamento, e não colunas nos itens de venda.

A tentação é ligar as duas sempre que uma pergunta envolve ambas: receita contra dinheiro recebido,
por exemplo. As duas tabelas carregam o número do pedido, então a junção é uma linha:

```sql
-- Two fact tables at two grains, joined on the order number.
SELECT (SELECT sum(net_cents) FROM fact_sales)                    AS sold,
       (SELECT sum(amount_cents) FROM fact_payments)              AS paid,
       sum(s.net_cents)                                           AS sold_after_join,
       sum(p.amount_cents)                                        AS paid_after_join
FROM fact_sales s JOIN fact_payments p USING (order_id);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fan-out.sql
┌────────────┬────────────┬─────────────────┬─────────────────┐
│    sold    │    paid    │ sold_after_join │ paid_after_join │
│   int128   │   int128   │     int128      │     int128      │
├────────────┼────────────┼─────────────────┼─────────────────┤
│ 9574389852 │ 9799636132 │      9811600086 │     20368271993 │
└────────────┴────────────┴─────────────────┴─────────────────┘
```

Leia os dois primeiros números. A rede vendeu R$ 95.743.898,52 em livros e recebeu R$ 97.996.361,32. A
diferença é exatamente o R$ 2.252.462,80 de frete, que é pago mas não é livro. Os dois totais estão
certos.

Depois, a junção. **As vendas cresceram R$ 2.372.102,34 e os pagamentos mais que dobraram, para
R$ 203.682.719,93.** Um pedido com três itens e um pagamento repete o pagamento três vezes; um pedido
com um item e dois pagamentos repete o item duas vezes; um pedido com três itens e dois pagamentos
produz seis linhas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um pedido com três itens e dois pagamentos. Ligados pelo número do pedido, cada um dos três itens encontra cada um dos dois pagamentos, e saem seis linhas: cada item aparece duas vezes e cada pagamento três vezes. Somar qualquer coluna das seis linhas exagera o valor.\"><defs><marker id=\"ah-fan-out\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales: 3 itens</text><text x=\"90\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">fact_payments: 2 pagamentos</text><rect x=\"20\" y=\"36\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">item 1</text><rect x=\"20\" y=\"74\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">item 2</text><rect x=\"20\" y=\"112\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">item 3</text><rect x=\"20\" y=\"186\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pagamento 1</text><rect x=\"20\" y=\"224\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pagamento 2</text><text x=\"395\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">ligados por order_id: 6 linhas</text><rect x=\"250\" y=\"36\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">item 1</text><text x=\"400\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pagamento 1</text><rect x=\"250\" y=\"72\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">item 1</text><text x=\"400\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pagamento 2</text><rect x=\"250\" y=\"108\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">item 2</text><text x=\"400\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pagamento 1</text><rect x=\"250\" y=\"144\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">item 2</text><text x=\"400\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pagamento 2</text><rect x=\"250\" y=\"180\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">item 3</text><text x=\"400\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pagamento 1</text><rect x=\"250\" y=\"216\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">item 3</text><text x=\"400\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pagamento 2</text><line x1=\"165\" y1=\"135\" x2=\"240\" y2=\"135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-fan-out)\"></line><text x=\"630\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cada item ×2</text><text x=\"630\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cada pagamento ×3</text><text x=\"630\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">some cada um por pedido</text><text x=\"630\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes, e depois junte</text></svg>", "caption": "Fan-out: ligar duas tabelas fato de granularidades diferentes repete cada linha de uma para cada linha correspondente da outra."}
```

Isso se chama **fan-out** (leque), e é o que acontece sempre que duas tabelas em granularidades
diferentes são ligadas por uma chave que não é única em nenhuma das duas.

**A regra é a que o drill-across usou na lição 3: some cada tabela fato até uma granularidade comum
primeiro, depois ligue.** Aqui a granularidade comum é o pedido. Some os itens por pedido, some os
pagamentos por pedido, e ligue uma linha a uma linha. Nunca ligue duas tabelas fato linha a linha.
