---
title: A maldição da dimensionalidade
version: 1
---

Os vizinhos mais próximos supõem que algumas linhas de treino estão perto e outras longe. **Em muitas
dimensões, isso deixa de ser verdade**: todo ponto acaba quase igualmente distante de todos os
outros, e "mais próximo" quer dizer muito pouco. Essa é a maldição da dimensionalidade, e dá para
medi-la só com números aleatórios. Salve isto como `curse.py`:

```python
# curse.py
import numpy as np

rng = np.random.default_rng(0)
print("columns   nearest / farthest distance from one point to 1,000 others")
for d in [2, 10, 100, 1000]:
    points = rng.random((1001, d))
    gaps = np.linalg.norm(points[1:] - points[0], axis=1)
    print(f"{d:7}   {gaps.min() / gaps.max():.2f}")
```

```
ana@lab:~/ml$ python curse.py
columns   nearest / farthest distance from one point to 1,000 others
      2   0.01
     10   0.26
    100   0.67
   1000   0.89
```

O número impresso é a distância ao mais próximo de 1.000 pontos aleatórios dividida pela distância ao
mais distante. Em duas dimensões ela é **0,01**: o ponto mais próximo está cem vezes mais perto que o
mais distante, e uma vizinhança é uma coisa com sentido. Em mil dimensões ela é **0,89**: o mais
próximo mal está mais perto que o mais distante, e os k "mais próximos" são um punhado arbitrário de
uma multidão que está toda mais ou menos à mesma distância.

O motivo é aritmético. Uma distância soma uma diferença por coluna; com muitas colunas, o total é
uma soma de muitas partes pequenas e aleatórias, e somas de muitas partes aleatórias caem todas perto
do mesmo valor. A dispersão entre perto e longe encolhe em relação às próprias distâncias.

Dados reais são mais gentis que números aleatórios uniformes, porque colunas reais se relacionam e as
linhas ficam em algo muito menor que o espaço inteiro. As onze colunas numéricas da Feira em Casa não
são problema. A maldição morde em três situações comuns:

- **texto**, em que cada palavra distinta é uma coluna e há milhares delas;
- **colunas one-hot** para categorias com muitos valores, uma cidade entre cinco mil, que acrescentam
  milhares de eixos quase sempre zerados;
- **muitas colunas fracas jogadas juntas**, cada uma acrescentando um pouco de ruído a toda distância.

Os remédios são colunas em menor número e melhores (aula 14), uma redução do espaço antes de medir a
distância (aula 17), ou um modelo que não depende de distância. As árvores, que as aulas 7 e 8
constroem, dividem uma coluna por vez e quase não sofrem com a maldição, o que é parte do motivo de
lidarem tão bem com dados largos.
