---
title: O valor do pedido, e o formato da distribuição dele
version: 1
---

As tabelas da Lantern não guardam quanto um pedido valeu. As linhas de um pedido trazem
quantidade e preço unitário, então o valor dele é a soma delas — e um número que você calcula
toda vez é um número que deveria calcular uma vez, num lugar só. Uma **view** é uma consulta
salva que se comporta como tabela:

```sql
CREATE VIEW order_totals AS
SELECT o.order_id, o.customer_id, o.ordered_at, o.status, o.discount_pct,
       sum(l.quantity * l.unit_cents) AS gross_cents
FROM orders o
JOIN order_lines l USING (order_id)
GROUP BY o.order_id;
```

Digite no `psql lantern`. É uma linha por pedido, a granularidade de `orders`, com o valor antes
de qualquer desconto, em centavos. **Dinheiro é guardado em centavos inteiros** — `11990` é R$
119,90 — porque uma soma de frações de real em ponto flutuante desvia por frações de centavo, e um
time de finanças percebe.

## O formato, antes da média

A primeira coisa a saber sobre uma coluna numérica é a **distribuição**: quantas linhas caem em
cada valor. Um histograma é essa contagem por faixa de valores, e o SQL desenha um rústico. O
`width_bucket` põe cada valor numa de oito faixas de R$ 50 entre 0 e R$ 400, e o `repeat`
imprime um `#` a cada quarenta pedidos:

```
lantern=# SELECT (width_bucket(gross_cents, 0, 40000, 8) - 1) * 50 AS from_brl,
lantern-#        count(*), repeat('#', count(*)::int / 40) AS orders
lantern-# FROM order_totals GROUP BY 1 ORDER BY 1;
 from_brl | count |                       orders                       
----------+-------+----------------------------------------------------
        0 |  2012 | ##################################################
       50 |  1581 | #######################################
      100 |  1294 | ################################
      150 |   769 | ###################
      200 |   377 | #########
      250 |   337 | ########
      300 |   141 | ###
      350 |   121 | ###
      400 |   470 | ###########
(9 rows)
```

Leia de cima para baixo. A faixa mais alta é a primeira: 2.012 pedidos abaixo de R$ 50. Cada faixa
depois dela é mais baixa, até 121 pedidos entre R$ 350 e R$ 400 — e então a última linha, que o
`width_bucket` usa para **tudo a partir de R$ 400**, salta de volta para 470.

Há dois formatos nesse desenho. A longa descida para a direita é uma distribuição **assimétrica à
direita**: a maioria dos pedidos é pequena, poucos são grandes, e não há simetria em torno de um
meio. E o salto no fim diz que a descida não simplesmente some: há um segundo grupo de pedidos,
grande o bastante para encher a faixa final, que as faixas não resolvem. Duas seções adiante,
esta aula descobre quem os fez.

**Um histograma é uma pergunta, não uma resposta.** Ele diz onde olhar em seguida: aqui, nos
pedidos pequenos que são a maior parte da loja, e no grupo acima de R$ 400 que não pertence à
descida.
