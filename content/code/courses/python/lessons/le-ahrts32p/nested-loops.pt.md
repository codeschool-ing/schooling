---
title: Dois laços, e trabalho que cresce com o produto
version: 2
---

```python
for a in xs:
    for b in ys:
        ...
```

O laço de dentro roda inteiro para cada item do de fora. Dez e dez são cem; mil e mil são um milhão.

**É essa a forma que a aula 20 chama de O(n²)**, e é o motivo mais comum de um programa que funcionou
na amostra levar quatro minutos no arquivo de verdade.

## O que se esconde

```python
for name in names:            # 100_000
    if name in banned:        # a LIST of 5_000
        ...
```

Há um laço visível. O segundo está dentro do `in`, porque o `in` numa lista a percorre. Mesma
aritmética, mesmo custo, e nada no código diz `for` duas vezes.

**A resposta da aula 3 se aplica:** faça `banned` um conjunto e o percurso interno vira um passo.

## Quando os pares são o objetivo

Às vezes você quer mesmo todo par — comparar cada registro com cada outro, uma grade, uma tabuada.
Aí o aninhamento é o algoritmo e o custo é honesto.

O `itertools.product` da aula 7 escreve a mesma coisa como um laço só, o que fica mais limpo quando o
aninhamento tem três níveis.

## Saindo dos dois

O `break` sai de um laço. Para sair dos dois, as respostas comuns são:

```python
found = None
for a in xs:
    for b in ys:
        if ok(a, b):
            found = (a, b)
            break
    if found:
        break
```

— ou pôr o par de laços numa função e dar `return`, que a aula 5 disponibiliza e que quase sempre é
mais claro que a bandeira.

## A regra prática

**Um laço tudo bem. Dois é uma pergunta. Três precisa de resposta.** A pergunta é se a coleção
interna poderia ser um dicionário ou um conjunto, o que transforma o produto de volta numa soma.
