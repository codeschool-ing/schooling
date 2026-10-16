---
title: loc, por rótulo
version: 1
---

**`loc` recebe uma seleção de linhas e uma de colunas, separadas por vírgula, e as duas são
rótulos.** Um rótulo, uma lista de rótulos, uma fatia de rótulos ou uma máscara booleana: cada um
funciona dos dois lados.

```python
weather.loc["2025-03-22", "rain_mm"]
```

```
np.float64(45.9)
```

Uma linha, uma coluna: um valor. Deixe um lado de fora com `:` para dizer "tudo":

```python
weather.loc["2025-03-22", :]
```

```
rain_mm     45.9
temp_max    30.0
Name: 2025-03-22, dtype: float64
```

## Fatias de rótulos incluem o fim

```python
weather.loc["2025-03-20":"2025-03-22", "rain_mm"]
```

```
date
2025-03-20    25.0
2025-03-21    14.3
2025-03-22    45.9
Name: rain_mm, dtype: float64
```

Três dias, o 20 **e** o 22. Uma fatia por posição em Python para antes do fim; uma fatia de rótulos
não pode, porque "o rótulo antes de `2025-03-22`" não é algo que você conseguiria escrever. A aula 9
encontrou isso; eis a regra: **fatias de `loc` são fechadas nas duas pontas, as de `iloc` só no
início.**

## Máscaras, com as colunas escolhidas no mesmo passo

O uso mais comum de `loc` é uma condição nas linhas e uma escolha de colunas de uma vez:

```python
wet = weather["rain_mm"] > 40
weather.loc[wet, ["rain_mm", "temp_max"]]
```

```
            rain_mm  temp_max
date                         
2025-03-22     45.9      30.0
2025-06-17     41.0      27.7
2025-07-01     41.4      28.5
2025-09-03     40.9      30.6
```

A máscara é uma Series booleana com o mesmo índice de `weather`, e o `loc` fica com as linhas em que
ela é `True`. Combine condições com `&` e `|`, cada uma entre parênteses, exatamente como a aula 7
fez com o NumPy:

```python
weather.loc[(weather["rain_mm"] > 20) & (weather["temp_max"] > 31), "rain_mm"]
```

```
date
2025-08-02    23.9
2025-08-14    21.0
Name: rain_mm, dtype: float64
```

## Um rótulo que não existe

```python
weather.loc["2025-02-30"]
```

```
KeyError: '2025-02-30'
```

`KeyError`, nomeando o rótulo. É uma boa falha: o `loc` nunca entrega em silêncio outra coisa quando
o rótulo pedido não existe.
