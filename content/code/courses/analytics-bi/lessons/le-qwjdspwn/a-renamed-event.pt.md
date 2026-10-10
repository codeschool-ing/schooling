---
title: O que um evento renomeado faz com um funil
version: 1
---

As checagens da última seção são sobre eventos. O que o negócio vê é o funil montado a partir deles, e
aqui está o daquele dia, por aparelho, contado como um painel conta — sessões que chegam a cada etapa do
plano:

```
lantern=# SELECT p.step, p.event,
lantern-#        count(DISTINCT i.session_id) FILTER (WHERE i.device = 'desktop') AS desktop,
lantern-#        count(DISTINCT i.session_id) FILTER (WHERE i.device = 'mobile') AS mobile
lantern-# FROM tracking.plan p LEFT JOIN tracking.incoming i USING (event)
lantern-# GROUP BY p.step, p.event ORDER BY p.step;
 step |    event     | desktop | mobile 
------+--------------+---------+--------
    1 | visit        |      75 |    138
    2 | product_view |      41 |     55
    3 | add_to_cart  |      16 |      0
    4 | checkout     |       8 |     12
    5 | purchase     |       6 |      8
(5 rows)
```

No desktop o funil afunila como sempre. No celular, **nenhuma sessão pôs nada no carrinho**, e mesmo
assim doze chegaram ao checkout e oito compraram. Lido ingenuamente, o carrinho converte 0% e o checkout
converte a partir do nada. Num painel de taxas de conversão, a taxa de produto para carrinho no
celular cai do nível de costume para zero no dia de uma versão nova, e alguém passa uma manhã procurando
o bug no carrinho.

Não há bug no carrinho. Há 19 sessões que puseram itens no carrinho e disseram isso com um nome que o
funil não procura. **O funil só é tão bom quanto os nomes de eventos que ele conta**, e nada numa
consulta de funil distingue uma etapa que ninguém fez de uma etapa cujo nome mudou.

Esse é o argumento para rodar as checagens *antes* de os eventos do dia serem carregados, em vez de ler
o funil e ficar pensando. Uma checagem que falha na manhã de 18 de junho diz "`addToCart` não está no
plano"; um funil diz "os clientes de celular pararam de usar o carrinho". A primeira é uma correção no
app ou no plano, combinada entre duas pessoas. A segunda é uma reunião.

Duas correções são possíveis, e o plano decide qual. Se `add_to_cart` é o nome combinado, o app está
errado e é corrigido, e os eventos em espera são renomeados antes de carregar. Se a empresa decidir que
`addToCart` é o nome melhor, o plano muda primeiro, e toda consulta que conta o nome antigo muda junto.
O que não é correção é um `CASE` na consulta de um painel que trata os dois nomes como iguais, porque o
próximo painel não vai tê-lo.
