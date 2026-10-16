---
title: Conciliando dois números que discordam
version: 1
---

Mesmo com definições escritas, dois números vão discordar, porque alguém vai usar a outra. O
relatório trimestral do marketing diz R$ 329.036,20 e o do financeiro diz R$ 294.209,60, e a
pergunta na reunião é se um deles está errado. **A resposta é uma ponte**: uma lista de passos que
vai de um número ao outro, cada passo uma diferença de definição, cada um com o próprio valor. Se
os passos fecham, os dois números estão certos e a reunião acabou; se não fecham, o passo que
falta é o erro.

A ponte do bruto ao líquido, no primeiro trimestre de 2026:

```sql
SELECT 1 AS step, 'gross, every order placed' AS line, round(sum(gross_cents) / 100.0, 2) AS brl
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 2, 'minus discounts', round(-sum(discount_cents) / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 3, 'minus refunded orders', round(-sum(net_cents) FILTER (WHERE status = 'refunded') / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 4, 'minus the test account', round(-coalesce(sum(net_cents) FILTER (WHERE customer_id = 1 AND status = 'paid'), 0) / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 5, 'net revenue', round(sum(net_cents) FILTER (WHERE status = 'paid' AND customer_id <> 1) / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
ORDER BY step;
```

```
lantern=# SELECT 1 AS step, 'gross, every order placed' AS line, round(sum(gross_cents) / 100.0, 2) AS brl
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 2, 'minus discounts', round(-sum(discount_cents) / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 3, 'minus refunded orders', round(-sum(net_cents) FILTER (WHERE status = 'refunded') / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 4, 'minus the test account', round(-coalesce(sum(net_cents) FILTER (WHERE customer_id = 1 AND status = 'paid'), 0) / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 5, 'net revenue', round(sum(net_cents) FILTER (WHERE status = 'paid' AND customer_id <> 1) / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# ORDER BY step;
 step |           line            |    brl    
------+---------------------------+-----------
    1 | gross, every order placed | 329036.20
    2 | minus discounts           | -23768.58
    3 | minus refunded orders     | -11058.02
    4 | minus the test account    |      0.00
    5 | net revenue               | 294209.60
(5 rows)
```

Leia como aritmética: R$ 329.036,20, menos R$ 23.768,58 de descontos, menos R$ 11.058,02 de pedidos
estornados, menos nada pela conta de teste, que não fez pedido neste trimestre, dá R$ 294.209,60.
Cada linha é uma célula da tabela de anatomia vista antes nesta aula — uma medida diferente, um
filtro diferente — transformada em dinheiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"bridge\" aria-label=\"Uma ponte da receita bruta à líquida no primeiro trimestre de 2026, desenhada em cinco colunas. A receita bruta é uma coluna inteira de 329.036,20 reais. Os descontos pendem do topo dela como uma queda de 23.768,58. Os estornos pendem logo abaixo como uma queda de 11.058,02. A conta de teste é uma queda de zero, desenhada como uma linha. A receita líquida é uma coluna inteira de 294.209,60, cujo topo fica na altura do fim da última queda.\"><rect x=\"60\" y=\"65.58219999999997\" width=\"100\" height=\"184.41780000000003\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"53.58219999999997\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 329.036,20</text><text x=\"110.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bruto</text><rect x=\"190\" y=\"65.58219999999997\" width=\"100\" height=\"55.46002000000004\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"135.04222000000001\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">−R$ 23.768,58</text><text x=\"240.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">descontos</text><rect x=\"320\" y=\"121.04222000000001\" width=\"100\" height=\"25.802046666666712\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"160.84426666666673\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">−R$ 11.058,02</text><text x=\"370.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estornos</text><line x1=\"450\" y1=\"146.84426666666673\" x2=\"550\" y2=\"146.84426666666673\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"500.0\" y=\"160.84426666666673\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 0,00</text><text x=\"500.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conta de teste</text><rect x=\"580\" y=\"146.84426666666673\" width=\"100\" height=\"103.15573333333327\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"134.84426666666673\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 294.209,60</text><text x=\"630.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">líquido</text><line x1=\"50\" y1=\"250\" x2=\"690\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"50\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">a escala começa em R$ 250.000, não em zero</text></svg>", "caption": "Cada queda é uma diferença entre as duas definições, e elas fecham: a última queda termina exatamente onde começa a receita líquida."}
```

Três coisas tornam uma ponte confiável:

- **Ela fecha.** A última linha é calculada de forma independente, e não como a soma das linhas de
  cima; se fosse, a ponte fecharia por construção e poderia esconder qualquer coisa.
- **A ordem dos passos é declarada.** Os estornos aqui entram pelo valor líquido, depois do
  desconto, porque o passo 2 já tirou o desconto. Tire-os pelo bruto e o desconto dos pedidos
  estornados sai duas vezes.
- **Um passo de zero fica.** "Menos a conta de teste: 0,00" diz que a exclusão foi conferida neste
  trimestre. Omitir a linha não diz nada, e no próximo trimestre, quando o time testar um checkout
  novo na loja de verdade, a linha vai importar.

A mesma técnica concilia quaisquer dois números, não só receita: clientes ativos por duas janelas,
um painel contra uma exportação, o número deste mês contra o que foi reportado no mês passado antes
de chegar uma carga atrasada. Ache as diferenças entre as definições, calcule cada uma, e confira
que elas fecham.
