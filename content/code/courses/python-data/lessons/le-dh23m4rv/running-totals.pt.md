---
title: Totais correntes, diferenças e a posição do maior
version: 1
---

**Algumas operações mantêm o comprimento do array e olham ao longo dele: um total corrente, a
diferença para o dia anterior, a posição do maior valor.** Elas respondem perguntas que uma redução
não responde: não "quanta chuva no ano", mas "em que dia metade dela já tinha caído".

As datas são texto, então são lidas à parte, como strings:

```python
dates = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=0, dtype=str)
dates[:2], dates.dtype
```
```
(array(['2025-01-01', '2025-01-02'], dtype='<U10'), dtype('<U10'))
```

## Totais correntes com `cumsum`

```python
so_far = np.cumsum(np.nan_to_num(rain))
so_far[-1], dates[np.argmax(so_far >= so_far[-1] / 2)]
```
```
(np.float64(1712.7999999999995), np.str_('2025-06-10'))
```

`cumsum` dá, para cada dia, o total até aquele dia inclusive; o último elemento é o total do ano em
dias conhecidos. `so_far >= so_far[-1] / 2` é `False` até metade da chuva do ano ter caído e `True`
a partir daí, e **`np.argmax` devolve a posição do primeiro maior valor**, que num array de
booleanos é o primeiro `True`. Lida em `dates`, essa posição é um dia. Metade da chuva do Recife em
2025 tinha caído até essa data, numa estação chuvosa que vai de abril a julho.

## O maior, e os maiores

```python
wettest = np.nanargmax(rain)
np.argmax(rain), wettest, dates[wettest], rain[wettest]
```
```
(np.int64(172), np.int64(80), np.str_('2025-03-22'), np.float64(45.9))
```

`np.argmax` devolveu a posição do primeiro `nan`, porque um valor faltante vence toda comparação em
que entra; `np.nanargmax` os pula e acha o dia mais chuvoso de verdade. Para os primeiros, ordene as
posições em vez dos valores, para que as datas venham junto:

```python
top = np.argsort(np.nan_to_num(rain))[::-1][:3]
dates[top], rain[top]
```
```
(array(['2025-03-22', '2025-07-01', '2025-06-17'], dtype='<U10'),
 array([45.9, 41.4, 41. ]))
```

`np.argsort` devolve as posições que ordenariam o array, do menor ao maior; `[::-1]` as inverte e
`[:3]` fica com três. **Ordenar posições em vez de valores é como manter dois arrays em passo**, e é
exatamente o que o pandas faz por você a partir da aula 9, quando as datas e a chuva vivem numa
tabela só.

## A mudança de um dia para o outro

```python
change = np.diff(temp)
change.shape, change[:4].round(1), np.abs(change).max().round(1)
```
```
((364,), array([ 0.1,  0.7,  0.5, -0.4]), np.float64(3.6))
```

`np.diff` subtrai cada elemento do seguinte, então o resultado tem **um a menos** que a entrada: 364
mudanças entre 365 dias. A aula 16 faz o mesmo com uma série de viagens, em que o índice mantém as
datas alinhadas e um elemento perdido vira um `NaN`.
