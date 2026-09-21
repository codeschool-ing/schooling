---
title: Atribuição é um segundo nome, e `copy` é rasa
version: 1
---

Esta é a seção para a qual a aula existe.

```python
>>> a = [1, 2, 3]
>>> b = a
>>> b.append(4)
>>> a
[1, 2, 3, 4]
```

**`b = a` não copiou nada.** Uma lista, dois nomes. Isso vale para todo valor mutável — listas,
dicionários, conjuntos, e os objetos que você escrever na aula 6.

Não é falha. É como se entrega uma tabela de um milhão de linhas para uma função sem duplicá-la. É
surpresa exatamente uma vez, e depois é ferramenta.

## Três jeitos de copiar uma lista

```python
b = a[:]
b = list(a)
b = a.copy()
```

Os três fazem o mesmo. Para um dicionário, `dict(a)` ou `a.copy()`; para um conjunto, `set(a)`.

## Os três são rasos

```python
>>> a = [[1, 2], [3, 4]]
>>> b = a.copy()
>>> b[0].append(99)
>>> a
[[1, 2, 99], [3, 4]]
```

A lista de fora foi copiada. **As de dentro não** — as duas listas de fora apontam para as mesmas
duas de dentro. Uma cópia rasa tem um nível de profundidade, sempre.

```python
import copy
b = copy.deepcopy(a)
```

O `deepcopy` segue a estrutura inteira. É mais lento, lida com ciclos, e é a resposta certa quando
você precisa mesmo de uma árvore independente.

## Quando não importa

**Números, strings e tuplas não podem ser alterados**, então compartilhar um é invisível. É por isso
que dá para passar uma string de um lado para o outro por um ano sem nunca encontrar isto.

## Como isso morde de fato

```python
def limpar(linhas):
    for linha in linhas:
        linha["nome"] = linha["nome"].strip()
    return linhas
```

Isto parece devolver linhas limpas e deixar as de quem chamou em paz. Não deixa: os dicionários são
de quem chamou, e foram editados. Ou diga isso no nome — `limpar_no_lugar` — ou copie antes:

```python
def limpar(linhas):
    return [{**linha, "nome": linha["nome"].strip()} for linha in linhas]
```

**Uma função que altera o argumento e também o devolve** é a forma que esconde isso. Faça uma coisa
ou a outra.
