---
title: Um gerador, e a semente que o faz repetir
version: 1
---

**Os números aleatórios de um computador não são aleatórios: são uma sequência longa e fixa que
parece aleatória, calculada a partir de um valor inicial chamado semente.** Mesma semente, mesma
sequência, em toda execução e toda máquina. Isso não é uma fraqueza a desculpar. É o que torna uma
amostra, um embaralhamento ou uma simulação algo que outra pessoa consegue conferir.

A ferramenta do NumPy é um **Generator**, criado por `np.random.default_rng`:

```python
import numpy as np

rng = np.random.default_rng(2025)
rng.integers(1, 7, size=10)
```

```
array([3, 6, 6, 3, 6, 5, 4, 6, 5, 6])
```

Dez lançamentos de um dado, a partir da semente 2025. Crie um segundo gerador com a mesma semente e
ele lança os mesmos dez:

```python
again = np.random.default_rng(2025)
again.integers(1, 7, size=10)
```

```
array([3, 6, 6, 3, 6, 5, 4, 6, 5, 6])
```

`integers(1, 7)` inclui o 1 e exclui o 7, como o `range`. O gerador guarda o lugar na sequência,
então a **próxima** chamada em `rng` continua de onde a última parou em vez de recomeçar:

```python
rng.integers(1, 7, size=5), again.integers(1, 7, size=5)
```

```
(array([3, 1, 3, 2, 3]), array([3, 1, 3, 2, 3]))
```

Os dois geradores fizeram dez sorteios, então estão no mesmo lugar e sorteiam os mesmos cinco. Um
gerador é uma posição numa sequência: a semente decide onde começa, e cada sorteio o faz avançar.

## Sem semente

`default_rng()` sem argumento pede ao sistema operacional uma semente nova e imprevisível. Dois
geradores assim sorteiam números diferentes, e nada impresso aqui bateria com a sua tela:

```python
a = np.random.default_rng().integers(0, 1_000_000, size=3)
b = np.random.default_rng().integers(0, 1_000_000, size=3)
(a == b).all()
```

```
np.False_
```

Essa é a escolha certa para tudo o que não pode ser previsível, e a errada para análise. **Um
notebook que sorteia sem semente dá outra resposta a cada execução**, e o reiniciar-e-rodar-tudo da
aula 2 vai aprová-lo toda vez enquanto os números dele se mexem.

## Onde vai a semente

Uma vez, no topo do notebook, com as outras configurações, e em nenhum outro lugar:

```py
SEED = 2025
rng = np.random.default_rng(SEED)
```

Todo sorteio do notebook passa então por esse único `rng`. Qualquer número serve de semente; o que
importa é que ele esteja escrito, para que a execução possa ser repetida.
