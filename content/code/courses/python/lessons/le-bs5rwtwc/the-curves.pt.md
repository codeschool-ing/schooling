---
title: Cinco formas, em mil e em um milhão
version: 1
---

| | n = 1.000 | n = 1.000.000 |
| --- | --- | --- |
| **O(1)** | 1 | 1 |
| **O(log n)** | 10 | 20 |
| **O(n)** | 1.000 | 1.000.000 |
| **O(n log n)** | 9.966 | 19.931.569 |
| **O(n²)** | 1.000.000 | 1.000.000.000.000 |

**Leia a última linha.** Um laço dentro de um laço sobre um milhão de itens é um milhão de milhões
de operações. Um laço de acumulação pelado nesta máquina roda cerca de dez milhões de iterações
por segundo, então isso dá uns noventa e quatro mil segundos — **pouco mais de um dia**, para um
relatório.

## Como cada uma parece em código

```python
d[chave]                        # O(1)     um passo, seja qual for o tamanho
bisect.bisect(ordenado, x)      # O(log n) dividir, dividir, dividir
for linha in linhas: ...        # O(n)     uma passagem
sorted(linhas)                  # O(n log n)
for a in linhas:
    for b in linhas: ...        # O(n²)    uma passagem por item
```

## `O(log n)` é a que parece errada

```text
n = 1.000             10 passos
n = 1.000.000         20 passos
n = 1.000.000.000     30 passos
```

Mil vezes mais dados e dez passos a mais. É isso que dividir ao meio faz, e é por isso que todo
índice, toda árvore balanceada e toda busca binária são construídos em volta disso. **`O(log n)` é
perto o bastante de grátis** para a diferença entre ele e `O(1)` quase nunca decidir nada.

## `O(n log n)` é o que ordenar custa

```text
sorted, n =   1.000    0,088 ms
sorted, n =  10.000    1,277 ms      ← 10× os dados, 14× o tempo
sorted, n = 100.000   18,112 ms      ← 10× os dados, 14× o tempo
```

Medido. Dez vezes os dados custam cerca de catorze vezes o trabalho, toda vez — que é exatamente o
que `n log n` prevê e o que um custo linear não faria.

**Ordenar é barato o bastante para recorrer a ele.** Se ordenar os dados antes transforma uma
busca `O(n²)` numa passagem `O(n)`, ordenar saiu de graça por comparação.

## E as que passam de `O(n²)`

`O(2ⁿ)` e `O(n!)` existem — todo subconjunto, toda ordenação — e são inutilizáveis acima de uns
vinte e de uns dez respectivamente. Se você escreveu uma, em geral sabe; o perigo em código comum
é o `O(n²)`, porque ele funciona bem nos dados de teste.
