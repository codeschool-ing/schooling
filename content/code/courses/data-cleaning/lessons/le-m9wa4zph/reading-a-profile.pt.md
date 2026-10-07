---
title: Lendo um perfil: o que os números entregam
version: 1
---

**Os números úteis de um perfil são os que discordam entre si, ou do que a coluna existe para
guardar.** Preenchidos contra distintos, menor contra maior, vazios numa coluna contra preenchidos
na seguinte. O arquivo de pedidos mostra cada tipo:

```
ana@lab:~/clean$ python profile.py raw/orders.csv
raw/orders.csv: 28551 rows
          column  filled  empty  distinct  shortest  longest          most_common  times
        order_id   28551      0     28526         6        6               102757      2
     customer_id   28551      0      2273         6        6               C00208     54
         channel   28551      0         2         3        4                 site  15755
      ordered_at   28551      0     28519        19       20 2025-02-20T14:22:01Z      2
      fulfilment   28551      0         2         6        8             delivery  22834
           total   28551      0      5741         4        8                15.80    237
        discount   14668  13883         5         1        5                    0  11233
    delivery_fee   28551      0         2         4        4                 9.90  20542
         payment   28551      0         3         3        6                 card  15767
          status   28551      0         3         8        9            delivered  26533
         courier   22834   5717         2         7        7              propria  15971
delivery_minutes   14872  13679       108         2        3                   47    351
```

## Preenchidos contra distintos

`order_id` está preenchido 28.551 vezes com 28.526 valores distintos: os 25 pedidos repetidos. Numa
chave, **distintos deveria ser igual a preenchidos**, e qualquer diferença é o número de cópias a
mais.

`ordered_at` é o caso oposto. Não é chave, então repetições são permitidas; dois pedidos podem
chegar no mesmo segundo. Uma contagem de distintos próxima da de linhas é a cara de um horário, e
uma baixa indicaria muitos pedidos carimbados com o mesmo instante, tipicamente uma carga em lote
que gravou a própria hora no lugar da hora do pedido.

`discount` tem 5 valores distintos em 14.668 linhas. Poucos distintos numa coluna numérica dizem que
ela é, na verdade, uma categoria — aqui, os quatro valores de cupom e o zero.

## Menor contra maior

`ordered_at` vai de 19 a 20 caracteres. Um formato tem tamanho fixo, então dois tamanhos são dois
formatos: o `2025-01-01 07:00:30` do aplicativo e o `2025-01-01T11:24:01Z` do site, um caractere
mais longo por causa do `Z`. **Uma variação de tamanho numa coluna que deveria ter uma forma só é o
detector de formato mais barato que existe.**

`total` vai de 4 caracteres (`9.90`) a 8 (`26928.50`). Um pedido de quase vinte e sete mil reais
numa mercearia que vende verdura por quilo é ou um cliente grande ou um erro, e a próxima seção olha
os números direito.

## Vazios contra preenchidos, entre colunas

Três colunas têm lacunas, e as lacunas se alinham com outras colunas de jeitos que vale notar.

**`courier`** está preenchido 22.834 vezes, exatamente o número de pedidos `delivery` em
`fulfilment`. Os 5.717 entregadores vazios são as retiradas. Quando duas contagens batem
exatamente, uma coluna explica os vazios da outra, e esses vazios estão certos.

**`delivery_minutes`** está vazio 13.679 vezes. As retiradas explicam 5.717 deles e a Rapidex
vários milhares a mais; a aula 3 descobre o que o resto tem em comum.

**`discount`** está vazio 13.883 vezes, e o valor mais comum é `0`, 11.233 vezes. Dois jeitos de
escrever "sem cupom"? Separar por canal resolve:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str, keep_default_na=False); print(pd.crosstab(o['discount'], o['channel']))"
channel     app   site
discount              
              0  13883
0         11233      0
10.00       392    474
15.00       382    479
20.00       378    463
5.00        411    456
```

O texto vazio na primeira linha é o vazio. Todo vazio vem do site e todo `0` vem do aplicativo, e os
cupons em si são os mesmos quatro valores nos dois.

**Nada disso aparece no `head()`.** As primeiras linhas do arquivo mostraram um desconto vazio e um
zero, o que parece dois pedidos com descontos diferentes. O perfil mostra que são dois sistemas com
um significado.
