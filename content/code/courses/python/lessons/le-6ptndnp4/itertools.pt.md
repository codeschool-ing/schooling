---
title: Seis que ganham a importação
version: 1
---

```python
from itertools import islice, chain, groupby, count, cycle, takewhile
```

## `islice`

```python
islice(linhas, 10)          # as dez primeiras
islice(linhas, 10, 20)      # da décima à vigésima
```

Fatiar para coisas que você não consegue indexar. Num arquivo de um milhão de linhas ele lê dez
linhas, o que `list(linhas)[:10]` não faz.

## `chain`

```python
for linha in chain(cabecalho, corpo, rodape):
```

Três iteráveis, percorridos como um, sem nada concatenado. O `chain.from_iterable(lista_de_listas)`
achata um nível, preguiçosamente.

## `groupby`

```python
for cidade, grupo in groupby(sorted(linhas, key=cidade_de), key=cidade_de):
```

Trechos de chaves iguais CONSECUTIVAS, que é por que a ordenação não é opcional — entrada
desordenada dá a mesma chave várias vezes e não diz nada. A aula 7 encontrou isto; vale encontrar
duas vezes.

## `count` e `cycle`

```python
for i, linha in zip(count(1), linhas):        # numerar, sem len
for linha, cor in zip(linhas, cycle(["impar", "par"])):
```

Os dois são infinitos, o que está bem porque o `zip` para no mais curto. O `count` é um `range` sem
fim; o `cycle` repete uma sequência para sempre e **guarda uma cópia dela**, o que importa se ela
for grande.

## `takewhile` e `dropwhile`

```python
takewhile(lambda l: l["data"] < corte, linhas)     # para no primeiro que falhar
```

O `takewhile` para no primeiro item que falha o teste — ele não filtra, ele ENCERRA. Num arquivo
ordenado essa é a diferença entre ler a parte que você quer e ler tudo.

## E uma regra sobre todos eles

Eles devolvem iteradores. Tudo desta aula se aplica: uma passada, sem comprimento, e nada
calculado até alguém pedir.
