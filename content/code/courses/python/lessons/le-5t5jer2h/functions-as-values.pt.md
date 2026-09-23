---
title: Uma função é um objeto, como todo o resto
version: 2
---

```python
def shout(s): return s.upper()

f = shout          # no parentheses: the function itself
f("ada")           # 'ADA'
```

Uma função dá para atribuir, passar, devolver e guardar num contêiner. Nada de especial está
acontecendo — um `def` liga um nome a um objeto, exatamente como o `=` faz.

## Passar uma

```python
def apply_to_all(items, fn):
    return [fn(x) for x in items]

apply_to_all(names, str.strip)
```

É o que o `key=` vem fazendo desde a aula 3, e o que `sorted`, `max`, `map` e `filter` recebem.
**Quem chama decide o comportamento e a função decide a forma.**

## Um dicionário de funções

```python
ACTIONS = {
    "start": start,
    "stop":  stop,
    "status": status,
}

ACTIONS[command]()          # KeyError names the unknown command
```

Uma tabela de comportamento, e ela substitui uma cadeia de `elif` que cresce um ramo por
funcionalidade. As duas coisas a acertar: **os valores não têm parênteses** — a função, e não o
resultado dela — e uma chave ausente é um erro que você trata em vez de um silêncio.

## Devolver uma

```python
def multiplier(n):
    def multiply(x):
        return x * n        # n comes from the enclosing scope
    return multiply

double = multiplier(2)
double(5)                   # 10
```

`multiply` lembra de `n` depois que `multiplier` já devolveu. Isso é um FECHAMENTO, é a
maquinaria do `nonlocal` de duas seções atrás, e é a única ideia com que a aula 12 constrói
decoradores.

## Por que isso importa antes da aula 12

Todo framework que você vai encontrar faz isso: você escreve uma função e a entrega, e outra coisa
decide quando chamá-la. Um handler de rota, um teste, um callback, um `key=`. **No momento em que
uma função é um valor, "chame isto quando aquilo acontecer" é só um argumento.**
