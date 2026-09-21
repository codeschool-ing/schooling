---
title: Quatro perguntas que resolvem
version: 1
---

| | lista | tupla | dict | conjunto |
|---|---|---|---|---|
| ordenado | sim | sim | por inserção | **não** |
| pode mudar | sim | **não** | sim | sim |
| duplicatas | sim | sim | chaves: não | **não** |
| indexado por | posição | posição | chave | — |
| custo do `in` | **um percurso** | **um percurso** | um passo | um passo |
| serve de chave | não | **sim** | não | não |

## As perguntas, em ordem

**Existe um nome para cada pedaço?** Então um dicionário. `pessoa["cidade"]` diz o que é;
`pessoa[1]` exige que você lembre. Esta é a resposta na maior parte das vezes, e uma lista de
dicionários é no que quase todo arquivo que você ler vai virar.

**Você só precisa saber se algo está lá?** Um conjunto. Sem duplicatas e sem percurso.

**É um grupo fixo de coisas que andam juntas?** Uma tupla — uma coordenada, um valor de retorno, uma
chave.

**Caso contrário uma lista**, que é o padrão honesto: uma coleção ordenada de coisas do mesmo tipo.

## A que custa tempo de verdade

```python
for nome in nomes:            # 100_000 nomes
    if nome in banidos:       # banidos é uma lista de 5_000
        ...
```

São quinhentos milhões de comparações. Troque `banidos` por um conjunto e são cem mil passos, e a
linha de código não muda em mais nada. A aula 20 mede exatamente isso e a resposta é onze segundos
contra quarenta milissegundos.

**A regra prática:** se o `in` está dentro de um laço, a coisa à direita deveria ser um conjunto ou
um dicionário.

## O que os quatro têm em comum

Os quatro são iteráveis, os quatro têm `len`, os quatro funcionam com `in`, e os quatro podem ser
construídos a partir de outro com `list()`, `tuple()`, `set()` ou `dict()`. Converter entre eles é
barato e muitas vezes é o jeito mais limpo de dizer alguma coisa:

```python
>>> sorted(set(palavras))    # únicas, em ordem
>>> dict(pares)              # uma lista de tuplas de dois numa dicionário
```
