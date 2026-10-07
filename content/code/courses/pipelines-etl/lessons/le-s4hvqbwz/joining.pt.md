---
title: Joins, e as linhas que se multiplicam
version: 1
---

Um join é onde uma transformação mais erra sem erro nenhum, e sempre erra do mesmo jeito. **A
receita está no pagamento, um por pedido. Os livros estão nas linhas, várias por pedido.** Junte as
duas para ter ambos numa consulta, e cada pagamento se repete uma vez por linha:

```
ana@vm:~/etl$ psql -d wh -c "SELECT sum(p.amount_cents) AS revenue_cents FROM raw.orders o JOIN raw.payments p USING (order_id) WHERE o.status = 'completed'"
 revenue_cents 
---------------
     212162290
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT sum(p.amount_cents) AS revenue_cents FROM raw.orders o JOIN raw.payments p USING (order_id) JOIN raw.order_lines l USING (order_id) WHERE o.status = 'completed'"
 revenue_cents 
---------------
     417391350
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS orders, (SELECT count(*) FROM raw.orders o JOIN raw.order_lines l USING (order_id) WHERE o.status = 'completed') AS after_the_join FROM raw.orders WHERE status = 'completed'"
 orders | after_the_join 
--------+----------------
  18608 |          29152
(1 row)
```

A primeira consulta soma os pagamentos dos pedidos concluídos: R$ 2.121.622,90. A segunda acrescenta
as linhas ao join e soma a mesma coluna — e dá R$ 4.173.913,50, quase o dobro, porque um pedido com
três linhas agora tem o pagamento três vezes. A terceira consulta diz isso em linhas: 18.608 pedidos
viraram 29.152 linhas depois do join, e a figura abaixo é um deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l06-fanout\" aria-label=\"Um pedido com três linhas e um pagamento de R$ 159,70. Depois do join, o resultado tem três linhas, cada uma levando o mesmo pagamento, então uma soma da coluna de pagamento diz R$ 479,10 para um pedido que pagou R$ 159,70.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"40.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pedido 1</text><text x=\"125.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 pagamento: R$ 159,70</text><rect x=\"60.0\" y=\"120.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha 1</text><rect x=\"60.0\" y=\"160.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha 2</text><rect x=\"60.0\" y=\"200.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha 3</text><text x=\"125.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 linhas</text><text x=\"470.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">depois do join</text><rect x=\"330.0\" y=\"50.0\" width=\"280.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha 1</text><text x=\"595.0\" y=\"64.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 159,70</text><path d=\"M192.0 134.0 L328.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"330.0\" y=\"90.0\" width=\"280.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha 2</text><text x=\"595.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 159,70</text><path d=\"M192.0 174.0 L328.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"330.0\" y=\"130.0\" width=\"280.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha 3</text><text x=\"595.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 159,70</text><path d=\"M192.0 214.0 L328.0 144.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"330.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">soma da coluna de pagamento</text><text x=\"610.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">R$ 479,10</text><text x=\"330.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que foi pago</text><text x=\"610.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 159,70</text></svg>", "caption": "O join desce do pedido para as suas linhas, e tudo o que está no grão do pedido se repete uma vez por linha."}
```

Isso se chama **fan-out**, e tem três propriedades que o tornam perigoso:

- **nada falha** — o SQL é válido e o número é plausível;
- **depende dos dados** — num dia em que todo pedido tem uma linha, os totais estão certos, e o bug
  aparece no primeiro sábado movimentado;
- **ele se esconde em agregados** — as linhas do join nunca são olhadas, só a soma delas.

## A regra que o evita

**Conheça o grão de cada tabela, e nunca agregue uma coluna de uma tabela cujas linhas o join
multiplicou.** O grão de `payments` é uma linha por pedido; o grão de `order_lines` é uma linha por
linha de pedido. Juntar as duas produz uma tabela no grão da linha, e tudo o que está no grão do
pedido — o valor pago — agora se repete. Então, ou:

- some no grão onde a coluna mora — receita das linhas como `quantity * unit_price_cents`, que
  pertence à linha; ou
- agregue cada lado a um grão comum primeiro, e depois faça o join.

E confira do jeito barato, toda vez que um join é acrescentado: **conte as linhas antes e depois.**
Se a contagem mudou e você não esperava, o join fez fan-out. Essa comparação é toda a terceira
consulta acima.
