---
title: Um número precisa de contexto
version: 1
---

Eis o número mais importante da página da Lantern:

```
lantern=# SELECT sum(net_revenue) AS net_revenue_may
lantern-# FROM semantic.orders
lantern-# WHERE order_date >= '2026-05-01' AND order_date < '2026-06-01';
 net_revenue_may 
-----------------
       140097.06
(1 row)
```

R$ 140.097,06 de receita líquida em maio de 2026. Isso é bom? O número não sabe dizer. **Um número
sozinho não é informação; um número ao lado da comparação certa é.** Três comparações respondem à
maioria das perguntas, e um cartão deveria levar pelo menos uma:

```
lantern=# SELECT sum(net_revenue) FILTER (WHERE order_date >= '2026-05-01' AND order_date < '2026-06-01') AS may_2026,
lantern-#        sum(net_revenue) FILTER (WHERE order_date >= '2026-04-01' AND order_date < '2026-05-01') AS april_2026,
lantern-#        sum(net_revenue) FILTER (WHERE order_date >= '2025-05-01' AND order_date < '2025-06-01') AS may_2025
lantern-# FROM semantic.orders;
 may_2026  | april_2026 | may_2025 
-----------+------------+----------
 140097.06 |  119821.78 | 21811.31
(1 row)
```

| comparado com | variação | o que responde | a armadilha |
|---|---|---|---|
| o mês anterior | +16,9% | está se mexendo? | sazonalidade: dezembro contra novembro diz mais sobre o Natal que sobre a loja |
| o mesmo mês do ano passado | mais de seis vezes | está crescendo? | um negócio jovem; a aula 4 chamou isso de medir o nascimento da loja |
| a meta | as próximas seções | está onde dissemos que estaria? | uma meta mal definida faz todo mês parecer bom ou ruim |

Nenhuma das três está certa em geral. Qual delas vai no cartão depende da pergunta que ele responde, e
a pergunta está na lista de duas seções atrás: *o mês está no rumo — contra o mês passado, e contra a
meta?* Então o cartão leva essas duas, e o número de ano contra ano, que para a Lantern seria enorme e
sem sentido, fica de fora.

**Uma variação precisa da base.** "+16,9%" sozinho esconde se veio de R$ 100 ou de R$ 100.000; o cartão
mostra o número grande e a comparação pequena ao lado, e o leitor sempre consegue reconstruir o
outro.
