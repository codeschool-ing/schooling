---
title: Fixa, e por isso utilizável como chave
version: 2
---

```python
point = (3, 4)
```

Parênteses, e tudo que uma lista pode guardar. O que ela não faz é mudar:

```python
>>> point[0] = 5
TypeError: 'tuple' object does not support item assignment
```

## A vírgula é o que faz a tupla

```python
>>> x = (5)
>>> type(x)
<class 'int'>
>>> x = (5,)
>>> type(x)
<class 'tuple'>
```

**Os parênteses agrupam; a vírgula é a tupla.** `1, 2` é uma tupla sem parêntese nenhum, que é por
que uma função pode fazer `return a, b`.

Aquela vírgula final pega todo mundo uma vez, em geral numa chamada como `f((x,))`.

## Desempacotar

```python
>>> x, y = point
>>> a, b = b, a            # swap, with no temporary
>>> first, *rest = [1, 2, 3, 4]
>>> first, rest
(1, [2, 3, 4])
```

Isto está em toda parte no Python. `for name, score in pairs:` é desempacotamento; `for i, item in
enumerate(itens):` também.

## Por que ela existe

**Uma tupla pode ser chave de dicionário e uma lista não pode**, porque uma chave precisa ser
hashável, e hashável significa que ela não pode mudar debaixo dos pés do dicionário:

```python
>>> grid = {(0, 0): "start", (1, 0): "wall"}
```

**E ela diz que a forma é fixa.** Uma função que devolve `(name, score)` está devolvendo duas coisas
que andam juntas; uma lista sugeriria que quem chamou poderia acrescentar uma terceira.

O `namedtuple` e o `dataclass`, das aulas 7 e 6, são a mesma ideia com nomes nos campos, e são para
onde se gradua quando a tupla tem mais de três.
