---
title: A correlação, e o grupo escondido atrás dela
version: 1
---

Uma **correlação** mede quanto duas colunas numéricas andam juntas, numa escala de −1 a 1. Perto
de 1, quando uma é alta a outra tende a ser alta; perto de −1, o contrário; perto de 0, saber uma
não diz nada sobre a outra em linha reta. O PostgreSQL calcula o coeficiente de correlação de
Pearson, normalmente escrito *r*, com `corr`.

Alguém do marketing tem uma teoria: desconto faz as pessoas comprarem mais. Os dados parecem
concordar:

```
lantern=# SELECT round(corr(discount_pct, gross_cents)::numeric, 3) AS r FROM order_totals;
   r   
-------
 0.271
(1 row)

lantern=# SELECT c.segment, count(*) AS orders,
lantern-#        round(corr(t.discount_pct, t.gross_cents)::numeric, 3) AS r
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# GROUP BY c.segment;
 segment | orders |   r    
---------+--------+--------
 office  |    684 |       
 home    |   6418 | -0.005
(2 rows)

lantern=# SELECT c.segment, t.discount_pct, count(*) AS orders,
lantern-#        round(avg(t.gross_cents) / 100.0, 2) AS mean_brl
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 segment | discount_pct | orders | mean_brl 
---------+--------------+--------+----------
 home    |            0 |   4990 |   120.50
 home    |            5 |    317 |   138.71
 home    |           10 |   1111 |   113.65
 office  |           15 |    684 |   639.51
(4 rows)
```

Sobre todos os pedidos, o *r* é 0,271: pedidos com desconto maior são maiores. Perguntada dentro
de cada segmento, a relação some. Entre os pedidos home, o *r* é −0,005, que não é nada. Entre os
de escritório ele vem vazio — `NULL` — e a última consulta diz por quê: todo pedido de escritório
tem desconto de exatamente 15%, e uma coluna que nunca varia não pode variar *junto* com nada.

A última tabela é a história inteira. Pedidos home sem desconto valem em média R$ 120,50, com 5%
R$ 138,71, com 10% R$ 113,65: nenhum padrão. Pedidos de escritório levam todos 15% e valem em média
R$ 639,51. **O desconto e o tamanho do pedido são causados os dois pelo segmento.** Escritórios
ganham desconto por volume e fazem pedidos grandes; não é o desconto que os faz pedir muito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"two-clouds\" aria-label=\"Valor médio do pedido contra o desconto do pedido. Três pontos do segmento home ficam baixos e na horizontal: sem desconto, 120,50 reais; 5 por cento, 138,71; 10 por cento, 113,65. Um ponto office fica muito acima, em 15 por cento, 639,51 reais. Uma reta tracejada passando pelos quatro pontos sobe forte, que é o que uma correlação de 0,271 sobre todos os pedidos enxerga. Uma reta só pelos pontos home é plana, que é o que uma correlação de -0,005 dentro do segmento home enxerga.\"><line x1=\"90\" y1=\"280\" x2=\"660\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"90\" y1=\"280\" x2=\"90\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"90.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"280.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5%</text><text x=\"470.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10%</text><text x=\"660.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">15%</text><text x=\"80\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 0</text><text x=\"80\" y=\"211.42857142857144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 200</text><text x=\"80\" y=\"142.85714285714286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 400</text><text x=\"80\" y=\"74.28571428571428\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 600</text><text x=\"375.0\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">desconto do pedido</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">valor médio do pedido</text><line x1=\"90.0\" y1=\"244.69942857142857\" x2=\"660.0\" y2=\"137.67657142857144\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></line><text x=\"637.2\" y=\"166.85714285714286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">todos os pedidos: r = 0,271</text><line x1=\"90.0\" y1=\"238.5142857142857\" x2=\"470.0\" y2=\"238.5142857142857\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"280.0\" y=\"264.51428571428573\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">só home: r = −0,005</text><circle cx=\"90.0\" cy=\"238.68571428571428\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"102.0\" y=\"224.68571428571428\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">home · R$ 120,50</text><circle cx=\"280.0\" cy=\"232.4422857142857\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"292.0\" y=\"218.4422857142857\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">home · R$ 138,71</text><circle cx=\"470.0\" cy=\"241.03428571428572\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"482.0\" y=\"227.03428571428572\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">home · R$ 113,65</text><circle cx=\"660.0\" cy=\"60.73942857142859\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"648.0\" y=\"46.73942857142859\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">office · R$ 639,51</text></svg>", "caption": "A correlação sobre todos os pedidos é a reta entre dois grupos, não uma reta dentro de nenhum deles."}
```

Esse formato tem nome: **confundidor**, uma terceira variável por trás das duas que você mediu.
Uma correlação calculada sobre uma mistura de grupos pode ser produzida inteiramente pela
diferença entre os grupos, e é por isso que o hábito de duas seções atrás — perguntar se a coluna
guarda uma população só — vale para toda estatística que você calcula, e não só para médias.

## Para que serve uma correlação no trabalho exploratório

Não para provar nada. Uma correlação é uma seta: diz que vale olhar duas colunas juntas, e a
próxima consulta — separada por um grupo, ou desenhada — diz por quê. Três cuidados, cada um dos
quais já custou a alguém uma decisão errada:

- **Ela mede uma linha reta.** Duas colunas ligadas por uma curva, digamos vendas que sobem e
  depois caem com o preço, podem ter um *r* perto de zero.
- **Ela se move com poucas linhas extremas**, e a próxima consulta mostra quanto.
- **Ela não diz nada sobre a direção.** Clientes que pedem com frequência podem receber mais
  cupons, ou os cupons podem fazê-los pedir com frequência; o *r* é o mesmo número nos dois casos.

Deixe de fora os três pedidos com preço errado da última seção — três linhas de 7.102 — e a mesma
correlação muda muito:

```
lantern=# SELECT round(corr(discount_pct, gross_cents)::numeric, 3) AS r
lantern-# FROM order_totals
lantern-# WHERE order_id NOT IN (412, 415, 431);
   r   
-------
 0.447
(1 row)
```

De 0,271 para 0,447. Três pedidos home com valores enormes e pouco ou nenhum desconto estavam
puxando a reta para baixo. **Encontre os erros antes de calcular qualquer coisa feita de
distâncias ao quadrado**, e uma correlação, um desvio-padrão e uma regressão são todos isso.
