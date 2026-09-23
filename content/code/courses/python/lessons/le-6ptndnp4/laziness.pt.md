---
title: Nada acontece até alguém pedir
version: 2
---

```python
def naturals():
    n = 0
    while True:
        yield n
        n += 1
```

Aquele laço não termina nunca, e a função é perfeitamente segura — porque nada roda até alguém
chamar `next`. Um gerador infinito é uma coisa válida e comum.

```python
from itertools import islice
list(islice(naturals(), 5))       # [0, 1, 2, 3, 4]
```

## O que a preguiça compra

- **Memória**: um valor por vez, por mais que sejam.
- **Tempo**: o trabalho do valor seiscentos nunca acontece se você parar no cinco.
- **Composição**: uma cadeia de geradores continua sendo um valor por vez, que é a próxima seção.
- **O impossível**: um fluxo sem fim — um log sendo escrito, uma sequência, uma sondagem.

## Onde ela acaba

```python
sorted(gen)       # needs everything
len(list(gen))    # needs everything
max(gen)          # needs everything, but only one at a time
```

**A preguiça sobrevive exatamente até a primeira coisa que precisa da coleção inteira.** O
`sorted` e o `list` a constroem; o `max`, o `sum` e o `any` não. Saber qual é qual é saber onde a
memória do seu programa chega.

## A consequência na depuração

```python
rows = (parse(line) for line in f)
# ... fifty lines later, in another function
for row in rows:        # the parse errors appear HERE
```

O traceback aponta o laço, e o defeito está no `parse`, cinquenta linhas e uma função de
distância. Esse é o preço da preguiça, e é por isso que um gerador com trabalho de verdade dentro
merece um nome que diga de onde ele veio.

## E o arquivo que foi fechado

```python
def rows(path):
    with open(path) as f:
        for line in f:
            yield line      # the file stays open while this is iterated
```

O `with` fecha quando o gerador se esgota — ou quando ele é coletado, que é mais tarde do que você
pensa. Um gerador abandonado no meio mantém o arquivo aberto até lá.
