---
title: Uma lista é uma boa pilha e uma fila ruim
version: 2
---

```python
stack = []
stack.append(x)      # push   O(1)
stack.pop()          # pop    O(1)
```

**Uma lista é uma pilha perfeitamente boa.** As duas pontas da operação ficam no fim da lista,
onde nada precisa se mover. Não existe uma classe `Stack` no Python porque não há necessidade de
uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Tirar o primeiro item de uma lista move todos os itens restantes uma casa para cima, então esvaziar uma lista pela frente custa uma passagem por item. Um deque tem uma ponta dos dois lados, então tirar pela frente não move nada.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">list.pop(0)</text> <rect x=\"180\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <rect x=\"258\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"291\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text> <path d=\"M278 98 L246 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"336\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"369\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text> <path d=\"M356 98 L324 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"414\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"447\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text> <path d=\"M434 98 L402 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"492\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"525\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text> <path d=\"M512 98 L480 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"600\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cada item restante sobe uma casa</text> <text x=\"686\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">0,7216 s</text> <text x=\"20\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">deque.popleft()</text> <rect x=\"180\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <rect x=\"258\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"291\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text> <rect x=\"336\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"369\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text> <rect x=\"414\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"447\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text> <rect x=\"492\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"525\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text> <text x=\"600\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">nada se move</text> <text x=\"686\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">0,0048 s</text> <text x=\"686\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">esvaziando 100 000 itens pela frente</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">e piora com o tamanho: uma passagem por item é O(n ao quadrado) no esvaziamento todo</text> </svg>", "caption": "As duas pontas de uma pilha são o fim de uma lista, e é por isso que uma lista é uma boa pilha e uma fila ruim."}
```

## E uma fila ruim

```python
queue = []
queue.append(x)      # enqueue   O(1)
queue.pop(0)         # dequeue   O(n)  ← everything shifts
```

```sh
draining 100,000 items from the front
  list.pop(0):        0.7216s
  deque.popleft():    0.0048s
```

**Cento e cinquenta vezes**, e piora com o tamanho: cada `pop(0)` move a lista restante inteira
uma posição acima, então a drenagem é `O(n²)` no total.

## `deque`

```python
from collections import deque

q = deque()
q.append(x)          # O(1)
q.popleft()          # O(1)
q.appendleft(x)      # O(1)
q.pop()              # O(1)
```

Uma fila de duas pontas: tempo constante nas **duas**, porque ela é uma sequência encadeada de
blocos em vez de um trecho contíguo.

```sh
list.insert(0, x):    33,428 ns
deque.appendleft(x):      29 ns
```

## O que você abre mão

```python
q[len(q) // 2]       # O(n) on a deque, O(1) on a list
```

Indexar o meio. Um deque precisa caminhar até lá, então é a estrutura errada para qualquer coisa
que você indexe aleatoriamente — que é a maioria das listas. **Use um deque quando você trabalha
nas pontas e uma lista quando trabalha por posição.**

## `maxlen`, que é um presente pequeno

```python
recent = deque(maxlen=100)
recent.append(line)          # when full, the oldest falls off the other end
```

Uma janela de tamanho fixo num argumento — as últimas cem linhas de log, as últimas sessenta
leituras — sem checagem de comprimento em lugar nenhum.

## E as que você não precisa escrever

```python
import heapq
heapq.heappush(h, (priority, item))   # O(log n)
heapq.heappop(h)                      # O(log n), smallest first
```

Uma fila de prioridade. O `heapq` trabalha sobre uma lista comum e a mantém em ordem de heap; o
`queue.Queue` é outra coisa ainda — uma fila segura entre threads, com travas, que você quer entre
threads e não dentro de uma função.
