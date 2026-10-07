---
title: A mesma chave com valores diferentes
version: 1
---

**Uma chave que aparece duas vezes com valores diferentes não é um duplicado a remover; é uma
contradição a resolver.** Remover uma cópia ao acaso escolhe um valor ao acaso. O catálogo tem
três:

```
ana@lab:~/clean$ psql -c 'SELECT product_code, name, price FROM raw.products WHERE product_code IN (SELECT product_code FROM raw.products GROUP BY product_code HAVING count(*) > 1) ORDER BY product_code, price'
 product_code |        name         | price  
--------------+---------------------+--------
 00325        | Rúcula              | 4.90
 00325        | Rúcula              | 5.20
 00343        | Açúcar mascavo 1 kg | 12.90
 00343        | Açúcar mascavo 1 kg | 134.90
 00467        | Banana prata        | 6.90
 00467        | Banana prata        | 7.90
(6 rows)
```

Três produtos listados duas vezes, com dois preços cada. Os compradores mudaram o preço de três
produtos em 1º de julho, e a exportação do catálogo lista o preço velho e o novo sem dizer qual é
qual. **Nada no arquivo diz qual preço vale**, e qualquer junção dos itens dos pedidos com esta
tabela vai casar cada um desses itens duas vezes — a aula 11 mede exatamente o que isso faz com a
receita.

Dois dos pares parecem mudanças comuns de preço: rúcula de R$ 4,90 para R$ 5,20, banana de R$ 6,90
para R$ 7,90. O terceiro não. Açúcar indo de R$ 12,90 para R$ 134,90 é um aumento de mais de dez
vezes para um quilo de açúcar, e se parece muito mais com um preço digitado com um dígito a mais. A
aula 9 é sobre distinguir as duas coisas, e segue este caso até os pedidos.

O que resolver isso exige é uma informação que falta no arquivo: **a data a partir da qual cada
preço vale**. Com ela, a tabela vira um histórico de preços e cada item de pedido se liga ao preço
em vigor no seu dia. Sem ela, as opções honestas são perguntar aos compradores, ou inferir a data
pelos pedidos — o preço unitário em cada item diz qual preço foi cobrado e quando.
