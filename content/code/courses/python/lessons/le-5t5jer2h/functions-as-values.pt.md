---
title: Uma função é um objeto, como todo o resto
version: 1
---

```python
def gritar(s): return s.upper()

f = gritar         # sem parênteses: a própria função
f("ada")           # 'ADA'
```

Uma função dá para atribuir, passar, devolver e guardar num contêiner. Nada de especial está
acontecendo — um `def` liga um nome a um objeto, exatamente como o `=` faz.

## Passar uma

```python
def aplicar_a_todos(itens, fn):
    return [fn(x) for x in itens]

aplicar_a_todos(nomes, str.strip)
```

É o que o `key=` vem fazendo desde a aula 3, e o que `sorted`, `max`, `map` e `filter` recebem.
**Quem chama decide o comportamento e a função decide a forma.**

## Um dicionário de funções

```python
ACOES = {
    "iniciar": iniciar,
    "parar":   parar,
    "estado":  estado,
}

ACOES[comando]()          # um KeyError nomeia o comando desconhecido
```

Uma tabela de comportamento, e ela substitui uma cadeia de `elif` que cresce um ramo por
funcionalidade. As duas coisas a acertar: **os valores não têm parênteses** — a função, e não o
resultado dela — e uma chave ausente é um erro que você trata em vez de um silêncio.

## Devolver uma

```python
def multiplicador(n):
    def multiplicar(x):
        return x * n        # o n vem do escopo envolvente
    return multiplicar

dobro = multiplicador(2)
dobro(5)                    # 10
```

`multiplicar` lembra de `n` depois que `multiplicador` já devolveu. Isso é um FECHAMENTO, é a
maquinaria do `nonlocal` de duas seções atrás, e é a única ideia com que a aula 12 constrói
decoradores.

## Por que isso importa antes da aula 12

Todo framework que você vai encontrar faz isso: você escreve uma função e a entrega, e outra coisa
decide quando chamá-la. Um handler de rota, um teste, um callback, um `key=`. **No momento em que
uma função é um valor, "chame isto quando aquilo acontecer" é só um argumento.**
