---
title: Aprender sem rótulo
version: 1
---

Todo modelo até aqui tinha uma resposta de onde aprender: `churned`, `minutes`, `complaint`. A equipe de
marketing agora faz uma pergunta sem coluna de resposta nenhuma: *"que tipos de cliente nós temos?"*. Ela
quer escrever uma newsletter diferente para cada tipo, e ninguém nunca rotulou um cliente como um tipo.

Isso é **aprendizado não supervisionado**: achar estrutura em linhas sem rótulo para conferir. A forma
mais comum dele é o **agrupamento**, pôr linhas em grupos de modo que linhas de um grupo se pareçam e
linhas de grupos diferentes não. O que *se parecer* quer dizer é uma escolha, e a maior parte desta aula é
sobre fazê-la de propósito.

Os dados são o `baskets.csv`, uma linha por cliente: quantos pedidos por mês, a cesta média em reais, e
que parte do gasto vai para cada tipo de alimento. Salve isto como `baskets.py`:

```python
# baskets.py
import pandas as pd

baskets = pd.read_csv("data/baskets.csv")
print(f"{len(baskets):,} customers, {baskets.shape[1] - 1} columns, no label")
print(baskets.drop(columns="customer_id").describe().loc[["mean", "std", "min", "max"]].round(1)
      .to_string())
```

```
ana@lab:~/ml$ python baskets.py
1,200 customers, 8 columns, no label
      orders_month  avg_basket  fruit  vegetables  greens  eggs_dairy  bakery  extras
mean           2.8       221.8   24.5        27.1    14.9        13.6    11.3     8.7
std            1.1        68.8   13.7         9.2     7.4         5.5     9.1     5.9
min            0.5        67.7    5.0         7.9     3.0         3.4     0.9     0.6
max            5.0       395.8   60.2        58.0    38.8        31.3    37.2    31.5
```

Dois tipos de coluna. `orders_month` e `avg_basket` dizem quanto um cliente compra; as seis partes dizem
o quê, e somam 100 para todo cliente. As unidades diferem muito: uma cesta varia R$ 68,8 de um cliente
para outro, uma parte de ovos 5,5 pontos, pedidos 1,1 por mês. Essa diferença vai importar daqui a duas
seções.

**Sem rótulo não há conjunto de teste**, e isso muda o que se pode afirmar. Um modelo de churn acerta ou
erra nos meses de teste. Um agrupamento não faz nem um nem outro: é uma proposta de como ver os clientes,
e é julgado por ser estável, por poder ser descrito e por alguém poder agir com ele. Esta aula mede o
primeiro e pratica os outros dois.

Há um luxo aqui que dados reais nunca oferecem. O `make_data.py` da aula 1 sorteou estes clientes de
quatro tipos de família, e a seção *Seus dados, de um programa que você pode ler* da aula 1 mostra como. Uma equipe de marketing de verdade não teria
página nenhuma para conferir, e a aula só se apoia nisso no fim.
