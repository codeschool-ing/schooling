---
title: Selecionando com uma lista de posições
version: 1
---

**Um array de posições inteiras seleciona esses elementos, nessa ordem, com repetição permitida.** O
NumPy chama isso de fancy indexing. A aula 5 o usou sem o nome, quando `dates[top]` leu as datas dos
três dias mais chuvosos pelas posições que o `np.argsort` devolveu.

```python
picks = np.array([0, 90, 181, 273, 0])
dates[picks], temp[picks]
```

```
(array(['2025-01-01', '2025-04-01', '2025-07-01', '2025-10-01',
        '2025-01-01'], dtype='<U10'),
 array([29.9, 28.3, 28.5, 31.1, 29.9]))
```

O primeiro dia de cada trimestre, na ordem pedida, e o dia 0 duas vezes porque foi pedido duas vezes.
Uma fatia não faz nenhuma das duas coisas: ela só pega uma sequência com passo fixo.

## Uma cópia, não uma view

Ao contrário de uma fatia, uma lista de posições **sempre faz uma cópia**, porque os elementos que
ela escolhe não formam um padrão regular que strides novos descrevam:

```python
picked = temp[picks]
np.shares_memory(picked, temp), np.shares_memory(temp[0:300:90], temp)
```

```
(False, True)
```

A mesma regra vale para máscaras: `rain[heavy]` também é uma cópia. A tabela da aula 4 já dizia;
aqui está por que isso importa, que é a próxima seção.

## Linhas e colunas por posição

Numa tabela, uma lista de posições num eixo seleciona linhas ou colunas inteiras:

```python
weeks[[0, 51]].shape, weeks[:, [3, 4]].shape
```

```
((2, 7), (52, 2))
```

A primeira e a última semanas, e os fins de semana de toda semana. Duas listas de uma vez, uma por
eixo, **não** dão o retângulo que você talvez espere. Elas se emparelham elemento a elemento:

```python
weeks[[0, 51], [3, 4]]
```

```
array([31.2, 31.9])
```

Dois números: a posição 3 da semana 0 e a posição 4 da semana 51. Para o retângulo dessas semanas e
desses dias, `np.ix_` transforma as duas listas nos formatos que fazem broadcasting, `(2, 1)` e
`(2,)`, o produto externo da aula 6:

```python
weeks[np.ix_([0, 51], [3, 4])]
```

```
array([[31.2, 30.8],
       [30.9, 31.9]])
```
