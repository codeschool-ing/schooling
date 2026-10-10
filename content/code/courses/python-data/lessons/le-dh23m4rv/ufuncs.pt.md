---
title: Funções universais, elemento a elemento
version: 1
---

**Uma ufunc é uma função que recebe arrays e trabalha elemento a elemento, em código compilado.**
`+`, `*` e `>` em arrays são ufuncs com outros nomes (`np.add`, `np.multiply`, `np.greater`), e
também `np.sqrt`, `np.log`, `np.abs`, `np.maximum` e umas sessenta mais. Qualquer coisa que você
escreveria como "para cada valor, calcule isto" provavelmente já é uma delas.

```python
temp[:4], np.round(temp[:4]), np.maximum(temp[:4], 30.0)
```
```
(array([29.9, 30. , 30.7, 31.2]),
 array([30., 30., 31., 31.]),
 array([30. , 30. , 30.7, 31.2]))
```

`np.maximum` compara dois arrays elemento a elemento e fica com o maior de cada par; aqui o segundo
"array" é o número 30 sozinho, que o NumPy estica para combinar, o assunto da aula 6.

## Comparações dão arrays de booleanos

```python
hot = temp > 31.5
hot[:6], hot.sum(), hot.mean()
```
```
(array([False, False, False, False, False, False]),
 np.int64(19),
 np.float64(0.052054794520547946))
```

`temp > 31.5` faz a pergunta a cada dia e responde com um array de `True` e `False`. **Somá-lo
conta os dias quentes, e a média dele é a fração do ano**, porque `True` vale 1. A aula 7 usa
arrays como `hot` para selecionar valores; aqui eles já são uma estatística.

## Escolhendo por elemento com `np.where`

`np.where(condição, a, b)` pega `a` onde a condição vale e `b` onde não vale, elemento a elemento.
Ele substitui o `if` de dentro de um laço:

```python
label = np.where(rain > 10, "wet", "dry")
label[:6], (label == "wet").sum()
```
```
(array(['dry', 'dry', 'dry', 'wet', 'dry', 'dry'], dtype='<U3'), np.int64(63))
```

`np.clip` é o caso especial de limitar valores a uma faixa, e poupa dois `where`:

```python
np.clip(rain[:6], 1, 10)
```
```
array([ 1. ,  6.8,  7.9, 10. ,  1. ,  1. ])
```

## O que uma ufunc faz com `nan`

**Um valor faltante se espalha.** Qualquer aritmética com `nan` dá `nan`, e qualquer comparação
com ele dá `False`:

```python
rain[np.isnan(rain)][:2] + 1, np.nan > 0, np.nan == np.nan
```
```
(array([nan, nan]), False, False)
```

A última surpreende todo mundo uma vez: `nan` não é igual a si mesmo, e é por isso que `np.isnan`
existe e `== np.nan` nunca acha nada. E é por isso que a contagem de `wet` acima, como a list
comprehension da aula 1, deixou de fora em silêncio os seis dias sem leitura: `nan > 10` é
`False`, então cada um virou `"dry"`. **Uma operação vetorizada é tão silenciosa sobre valores
faltantes quanto um laço.** A próxima seção é sobre as funções que deixam você dizer o que fazer
com eles.
