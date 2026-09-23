---
title: Posicionais, nomeados, e o padrão que é construído uma vez
version: 2
---

```python
def connect(host, port=5432, timeout=10):
    ...

connect("db.example.tld")
connect("db.example.tld", 6543)
connect("db.example.tld", timeout=30)
```

Argumentos posicionais casam por ordem; argumentos nomeados casam por nome. Um parâmetro com padrão
dá para ser deixado de fora, e **todo parâmetro com padrão vem depois de todo parâmetro sem um** —
senão não haveria como dizer qual posicional foi para onde.

## Qual usar na chamada

`connect("db.example.tld", 6543)` se lê bem porque um host e uma porta são obviamente um host e
uma porta. `charge(account, 1200, True)` não se lê, nem por quem escreveu.

**Um booleano numa chamada quase sempre deveria ser nomeado**: `cobrar(conta, 1200,
reembolsavel=True)` diz o que o `True` significa, no lugar em que alguém está lendo.

## O padrão é avaliado uma vez, no `def`

```python
def add(item, basket=[]):       # ONE list, for the life of the program
    basket.append(item)
    return basket

add("apple")     # ['apple']
add("pear")      # ['apple', 'pear']   ← the same list
```

Esta é a armadilha do compartilhamento de mutáveis da aula 3 na fantasia mais comum dela. A
expressão do padrão roda quando a linha do `def` roda, então existe exatamente uma lista e toda
chamada que não traz a sua recebe aquela.

**O conserto são quatro palavras:**

```python
def add(item, basket=None):
    if basket is None:
        basket = []
```

`None` é a marca de "quem chamou não disse", e a lista nova é construída por chamada. Vale igual
para `{}`, para `set()` e para qualquer outra coisa que dê para mudar. Um número, uma string ou uma
tupla como padrão são seguros, porque não há o que mudar.

## Argumentos apontam para o mesmo objeto

```python
def append_one(xs):
    xs.append(1)      # the caller's list changes

def rebind(xs):
    xs = [1]          # only the local name changes
```

Nenhum dos dois copia. O primeiro altera o objeto para onde os dois nomes apontam; o segundo aponta
o nome local para outro lugar e quem chamou não vê nada. É a distinção `b = a` da aula 3, numa
fronteira de função — e **é por isso que uma função que recebe uma lista e a altera deveria dizer
isso no nome**.
