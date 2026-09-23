---
title: A list is a good stack and a bad queue
version: 2
---

```python
stack = []
stack.append(x)      # push   O(1)
stack.pop()          # pop    O(1)
```

**A list is a perfectly good stack.** Both ends of the operation are at the end of the list, where
nothing has to move. There is no `Stack` class in Python because there is no need for one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Taking the first item out of a list moves every remaining item up one slot, so draining a list from the front costs a pass per item. A deque has an end at both ends, so taking from the front moves nothing.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">list.pop(0)</text> <rect x=\"180\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <rect x=\"258\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"291\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text> <path d=\"M278 98 L246 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"336\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"369\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text> <path d=\"M356 98 L324 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"414\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"447\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text> <path d=\"M434 98 L402 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"492\" y=\"40\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"525\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text> <path d=\"M512 98 L480 98\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"600\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">every remaining item moves up one slot</text> <text x=\"686\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">0.7216 s</text> <text x=\"20\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">deque.popleft()</text> <rect x=\"180\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <rect x=\"258\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"291\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text> <rect x=\"336\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"369\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text> <rect x=\"414\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"447\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text> <rect x=\"492\" y=\"148\" width=\"66\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"525\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text> <text x=\"600\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">nothing moves</text> <text x=\"686\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">0.0048 s</text> <text x=\"686\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">draining 100 000 items from the front</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">and it gets worse with size: a pass per item is O(n squared) over the whole drain</text> </svg>", "caption": "Both ends of a stack are the end of a list, which is why a list is a fine stack and a poor queue."}
```

## And a bad queue

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

**A hundred and fifty times**, and it gets worse with size: every `pop(0)` moves the whole
remaining list up one slot, so the drain is `O(n²)` overall.

## `deque`

```python
from collections import deque

q = deque()
q.append(x)          # O(1)
q.popleft()          # O(1)
q.appendleft(x)      # O(1)
q.pop()              # O(1)
```

A double-ended queue: constant time at **both** ends, because it is a linked sequence of blocks
rather than one contiguous run.

```sh
list.insert(0, x):    33,428 ns
deque.appendleft(x):      29 ns
```

## What you give up

```python
q[len(q) // 2]       # O(n) on a deque, O(1) on a list
```

Indexing into the middle. A deque has to walk to get there, so it is the wrong structure for
anything you index randomly — which is most lists. **Use a deque when you work at the ends and a
list when you work by position.**

## `maxlen`, which is a small gift

```python
recent = deque(maxlen=100)
recent.append(line)          # when full, the oldest falls off the other end
```

A fixed-size window in one argument — the last hundred log lines, the last sixty readings — with
no length check anywhere.

## And the ones you do not have to write

```python
import heapq
heapq.heappush(h, (priority, item))   # O(log n)
heapq.heappop(h)                      # O(log n), smallest first
```

A priority queue. `heapq` works on an ordinary list and keeps it in heap order; `queue.Queue` is
a different thing again — a thread-safe queue with locking, which you want between threads and
not inside one function.
