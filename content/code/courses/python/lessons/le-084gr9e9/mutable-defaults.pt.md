---
title: O padrão é criado uma vez, na definição
version: 2
---

```python
def add(item, basket=[]):
    basket.append(item)
    return basket
```

```python
>>> add("apple")
['apple']
>>> add("pear")
['apple', 'pear']
```

A segunda chamada não começou com uma cesta vazia. **O valor padrão foi criado uma vez, quando a
linha do `def` foi lida**, e toda chamada que não fornece uma compartilha aquela lista única.

## Por que funciona assim

Um `def` é um comando que roda. Quando o Python o lê, ele avalia os padrões ali mesmo e os guarda no
objeto-função — dá para olhar:

```python
>>> add.__defaults__
(['apple', 'pear'],)
```

É a mesma lista, ainda presa, ainda crescendo.

## O conserto

```python
def add(item, basket=None):
    if basket is None:
        basket = []
    basket.append(item)
    return basket
```

O `None` é imutável, então compartilhá-lo é inofensivo, e a lista nova é criada **por chamada**. É
por isso que a seção `none` da aula 2 o chamou de padrão certo para um argumento que deveria receber
uma lista.

## Quais padrões são seguros

| | |
|---|---|
| seguros | `None`, números, strings, `True`/`False`, tuplas |
| **não seguros** | `[]`, `{}`, `set()`, e qualquer objeto com estado |

A regra é a mesma do resto da aula: **mutável ou não**.

## Nem sempre é defeito

```python
def fib(n, memo={}):
    ...
```

Um cache que deliberadamente sobrevive à chamada usa exatamente este comportamento. É legítimo, é
surpreendente para quem ler depois, e o `functools.cache` da aula 12 diz isso em voz alta em vez de
depender disso.

O linter da aula 17 aponta todo padrão mutável, inclusive o deliberado — o que está certo, porque a
ferramenta não consegue distinguir os dois e o deliberado merece um comentário de qualquer jeito.
