---
title: Fixa, e por isso utilizável como chave
version: 1
---

```python
ponto = (3, 4)
```

Parênteses, e tudo que uma lista pode guardar. O que ela não faz é mudar:

```python
>>> ponto[0] = 5
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
>>> x, y = ponto
>>> a, b = b, a            # troca, sem variável temporária
>>> primeiro, *resto = [1, 2, 3, 4]
>>> primeiro, resto
(1, [2, 3, 4])
```

Isto está em toda parte no Python. `for nome, nota in pares:` é desempacotamento; `for i, item in
enumerate(itens):` também.

## Por que ela existe

**Uma tupla pode ser chave de dicionário e uma lista não pode**, porque uma chave precisa ser
hashável, e hashável significa que ela não pode mudar debaixo dos pés do dicionário:

```python
>>> grade = {(0, 0): "início", (1, 0): "parede"}
```

**E ela diz que a forma é fixa.** Uma função que devolve `(nome, nota)` está devolvendo duas coisas
que andam juntas; uma lista sugeriria que quem chamou poderia acrescentar uma terceira.

O `namedtuple` e o `dataclass`, das aulas 7 e 6, são a mesma ideia com nomes nos campos, e são para
onde se gradua quando a tupla tem mais de três.
