---
title: Uma lista é uma boa pilha e uma fila ruim
version: 1
---

```python
pilha = []
pilha.append(x)      # empilhar    O(1)
pilha.pop()          # desempilhar O(1)
```

**Uma lista é uma pilha perfeitamente boa.** As duas pontas da operação ficam no fim da lista,
onde nada precisa se mover. Não existe uma classe `Stack` no Python porque não há necessidade de
uma.

## E uma fila ruim

```python
fila = []
fila.append(x)      # enfileirar    O(1)
fila.pop(0)         # desenfileirar O(n)  ← tudo desloca
```

```text
drenando 100.000 itens pela frente
  list.pop(0):        0,7216s
  deque.popleft():    0,0048s
```

**Cento e cinquenta vezes**, e piora com o tamanho: cada `pop(0)` move a lista restante inteira
uma posição acima, então a drenagem é `O(n²)` no total.

## `deque`

```python
from collections import deque

f = deque()
f.append(x)          # O(1)
f.popleft()          # O(1)
f.appendleft(x)      # O(1)
f.pop()              # O(1)
```

Uma fila de duas pontas: tempo constante nas **duas**, porque ela é uma sequência encadeada de
blocos em vez de um trecho contíguo.

```text
list.insert(0, x):    33.428 ns
deque.appendleft(x):      29 ns
```

## O que você abre mão

```python
f[len(f) // 2]       # O(n) num deque, O(1) numa lista
```

Indexar o meio. Um deque precisa caminhar até lá, então é a estrutura errada para qualquer coisa
que você indexe aleatoriamente — que é a maioria das listas. **Use um deque quando você trabalha
nas pontas e uma lista quando trabalha por posição.**

## `maxlen`, que é um presente pequeno

```python
recentes = deque(maxlen=100)
recentes.append(linha)       # quando cheio, o mais velho cai pela outra ponta
```

Uma janela de tamanho fixo num argumento — as últimas cem linhas de log, as últimas sessenta
leituras — sem checagem de comprimento em lugar nenhum.

## E as que você não precisa escrever

```python
import heapq
heapq.heappush(h, (prioridade, item))   # O(log n)
heapq.heappop(h)                        # O(log n), o menor primeiro
```

Uma fila de prioridade. O `heapq` trabalha sobre uma lista comum e a mantém em ordem de heap; o
`queue.Queue` é outra coisa ainda — uma fila segura entre threads, com travas, que você quer entre
threads e não dentro de uma função.
