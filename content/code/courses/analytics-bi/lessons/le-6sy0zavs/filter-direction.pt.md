---
title: Para que lado um filtro anda
version: 1
---

Um modelo com relacionamentos de direção única responde certo à maioria das perguntas e errado a um
tipo delas, de um jeito que surpreende todo mundo uma vez. Ponha um cartão mostrando `[Orders]` numa
página com um filtro em `products[product]`, e escolha *Hand Grinder*.

O filtro começa em `products` e anda pelo relacionamento até `order_lines`, o lado muitos: só
sobram as linhas de moedor. Ele não segue de `order_lines` para `orders`, porque esse relacionamento
aponta para o outro lado — o lado um dele é `orders`. Então `orders` fica sem filtro, e o cartão
mostra todos os pedidos da loja. Em SQL, as duas respostas:

```
lantern=# SELECT count(*) AS orders_with_a_grinder
lantern-# FROM semantic.orders o
lantern-# WHERE EXISTS (SELECT 1 FROM semantic.order_lines l JOIN semantic.products p USING (product_id)
lantern(#               WHERE l.order_id = o.order_id AND p.product = 'Hand Grinder');
 orders_with_a_grinder 
-----------------------
                   219
(1 row)

lantern=# SELECT count(*) AS all_orders FROM semantic.orders;
 all_orders 
------------
       7098
(1 row)
```

219 pedidos tinham um moedor; o cartão mostra 7.098. Nada na página diz que o filtro não chegou nele.

Há dois jeitos de fazê-lo chegar, e eles não são iguais:

- **Pôr o relacionamento entre `order_lines` e `orders` para filtrar nas duas direções.** Funciona
  para este cartão. Também significa que todo filtro em qualquer tabela do nível da linha agora se
  espalha para os pedidos e de lá para todas as outras tabelas, e num modelo com vários caminhos
  entre duas tabelas o Power BI não consegue mais dizer por qual caminho um filtro deve ir. A própria
  orientação da Microsoft é usar isso com parcimônia.
- **Escrever a medida dizendo o que ela significa**, e deixar o modelo em paz:

```
Orders Containing Product =
    CALCULATE ( [Orders], CROSSFILTER ( order_lines[order_id], orders[order_id], BOTH ) )
```

(Não rodou.) O `CROSSFILTER` liga as duas direções para esta medida e em mais lugar nenhum. O nome
diz o que ela conta, o que o cartão que mostrou 7.098 não dizia.

A lição geral é o fan-out da aula 3 visto do outro lado. Lá, um join multiplicou uma medida porque
foi de uma granularidade para uma mais fina. Aqui, um filtro deixa de chegar porque teria de andar
da granularidade mais fina para a mais grossa. **As duas são perguntas sobre granularidade, e as duas
se respondem decidindo, no modelo, para que lado as coisas podem fluir.**
