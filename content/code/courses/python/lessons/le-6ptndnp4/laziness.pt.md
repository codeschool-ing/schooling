---
title: Nada acontece até alguém pedir
version: 1
---

```python
def naturais():
    n = 0
    while True:
        yield n
        n += 1
```

Aquele laço não termina nunca, e a função é perfeitamente segura — porque nada roda até alguém
chamar `next`. Um gerador infinito é uma coisa válida e comum.

```python
from itertools import islice
list(islice(naturais(), 5))       # [0, 1, 2, 3, 4]
```

## O que a preguiça compra

- **Memória**: um valor por vez, por mais que sejam.
- **Tempo**: o trabalho do valor seiscentos nunca acontece se você parar no cinco.
- **Composição**: uma cadeia de geradores continua sendo um valor por vez, que é a próxima seção.
- **O impossível**: um fluxo sem fim — um log sendo escrito, uma sequência, uma sondagem.

## Onde ela acaba

```python
sorted(g)         # precisa de tudo
len(list(g))      # precisa de tudo
max(g)            # precisa de tudo, mas um por vez
```

**A preguiça sobrevive exatamente até a primeira coisa que precisa da coleção inteira.** O
`sorted` e o `list` a constroem; o `max`, o `sum` e o `any` não. Saber qual é qual é saber onde a
memória do seu programa chega.

## A consequência na depuração

```python
linhas = (analisar(l) for l in f)
# ... cinquenta linhas depois, em outra função
for linha in linhas:      # os erros do analisar aparecem AQUI
```

O traceback aponta o laço, e o defeito está no `analisar`, cinquenta linhas e uma função de
distância. Esse é o preço da preguiça, e é por isso que um gerador com trabalho de verdade dentro
merece um nome que diga de onde ele veio.

## E o arquivo que foi fechado

```python
def linhas(caminho):
    with open(caminho) as f:
        for linha in f:
            yield linha      # o arquivo fica aberto enquanto isto é iterado
```

O `with` fecha quando o gerador se esgota — ou quando ele é coletado, que é mais tarde do que você
pensa. Um gerador abandonado no meio mantém o arquivo aberto até lá.
