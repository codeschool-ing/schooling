---
title: A granularidade, e o join que multiplica
version: 1
---

Toda tabela fato tem uma **granularidade**, e a aula 1 pediu que você a escrevesse da primeira vez
que a conferisse. Eis o porquê. Uma medida pertence à granularidade em que foi registrada: um
desconto é uma propriedade do **pedido**, então ele mora em `orders`, uma vez por pedido. Junte
`orders` a `order_lines` e cada pedido aparece uma vez por linha — e o desconto junto.

```
lantern=# SELECT sum(o.discount) AS discount_joined
lantern-# FROM semantic.orders o JOIN semantic.order_lines l USING (order_id)
lantern-# WHERE o.order_date BETWEEN '2026-01-01' AND '2026-03-31';
 discount_joined 
-----------------
        46481.30
(1 row)

lantern=# SELECT sum(discount) AS discount_alone
lantern-# FROM semantic.orders
lantern-# WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
 discount_alone 
----------------
       23768.58
(1 row)
```

O mesmo trimestre, os mesmos descontos, e a primeira consulta reporta o dobro do dinheiro. **Nada
falhou.** O join fez exatamente o que joins fazem: um pedido com três linhas virou três linhas, e o
`sum` somou o desconto dele três vezes. Isso se chama **fan-out**, e produz números grandes demais
por um fator que depende de quantas linhas os pedidos têm — e é por isso que pode sobreviver num
painel por meses, errado por um fator que ninguém adivinha.

Três regras o evitam, e a camada existe em parte para aplicá-las para que ninguém mais precise:

- **Uma medida é somada na própria granularidade.** Desconto e receita líquida se somam de
  `orders`; quantidade se soma de `order_lines`.
- **Para combinar duas granularidades, agregue a mais fina primeiro.** Se uma pergunta precisa da
  receita e do número de pacotes por pedido, some as linhas por pedido numa subconsulta, e depois
  junte uma linha por pedido a `orders`. É exatamente assim que a view `orders` calcula `gross` a
  partir das linhas.
- **Junte o fato com dimensões, e não fato com fato.** Uma dimensão tem uma linha por chave, então
  um join com ela nunca multiplica o fato. `orders` juntada a `customers` mantém uma linha por
  pedido.

Uma ferramenta que deixa qualquer um juntar qualquer coisa com qualquer coisa vai produzir fan-outs
para alguém. O trabalho da camada é tornar os caminhos seguros os óbvios — e os produtos citados no
fim desta aula existem em boa parte para tornar os inseguros impossíveis.
