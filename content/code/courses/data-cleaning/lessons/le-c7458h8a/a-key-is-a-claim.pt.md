---
title: Uma chave é uma afirmação
version: 1
---

Uma junção casa linhas por uma chave: itens a pedidos por `order_id`, itens ao catálogo pelo
código do produto, pedidos a clientes por `customer_id`. **Toda junção supõe que a chave de um
dos lados nomeia exatamente uma linha**, e um arquivo pode dizer isso de si mesmo sem que seja
verdade. Então a primeira coisa a fazer com uma chave é testar a afirmação.

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str); print(len(o), o['order_id'].nunique(), o.drop_duplicates()['order_id'].is_unique)"
28551 28526 True
```

O arquivo de pedidos tem 28.551 linhas e só 28.526 números de pedido diferentes. São os 25
pedidos repetidos que a aula 5 encontrou, copiados inteiros; depois de tirar as cópias exatas, o
`is_unique` dá `True`, e `order_id` é uma chave. Essa ordem importa: **a chave só é chave depois
que as duplicatas saem**, e por isso a aula 5 vem antes desta.

O catálogo é outra história:

```
ana@lab:~/clean$ python -c "import pandas as pd; p = pd.read_csv('raw/products.csv', dtype=str); print(len(p), p['product_code'].nunique()); print(p[p['product_code'].duplicated(keep=False)].sort_values(['product_code', 'price']).to_string(index=False))"
72 69
product_code                name  category unit  price
       00325              Rúcula  Verduras   un   4.90
       00325              Rúcula  Verduras   un   5.20
       00343 Açúcar mascavo 1 kg Mercearia   un  12.90
       00343 Açúcar mascavo 1 kg Mercearia   un 134.90
       00467        Banana prata    FRUTAS   kg   6.90
       00467        Banana prata    Frutas   kg   7.90
```

72 linhas, 69 códigos. A aula 5 já encontrou estes três: cada produto aparece duas vezes, com dois
preços. A rúcula foi de R$ 4,90 para R$ 5,20 e a banana de R$ 6,90 para R$ 7,90, e a aula 9 mostrou
que os R$ 134,90 do açúcar foram um erro de digitação que a loja passou a cobrar. Nada no arquivo diz qual preço vale nem desde quando,
porque a exportação não tem coluna de data. **Isso não é duplicata para descartar; é histórico de
preço achatado numa lista**, e descartar qualquer uma das linhas jogaria fora um fato.

A mesma verificação em SQL é um `GROUP BY` que fica só com os grupos de mais de uma linha:

```
ana@lab:~/clean$ psql -c "SELECT product_code, count(*) AS rows, string_agg(price, ' / ' ORDER BY price) AS prices FROM raw.products GROUP BY product_code HAVING count(*) > 1 ORDER BY product_code"
 product_code | rows |     prices     
--------------+------+----------------
 00325        |    2 | 4.90 / 5.20
 00343        |    2 | 12.90 / 134.90
 00467        |    2 | 6.90 / 7.90
(3 rows)
```

Rode isso em toda chave que você vai usar numa junção, dos dois lados. É uma linha, e transforma
uma suposição numa medida antes de qualquer coisa ser juntada.
