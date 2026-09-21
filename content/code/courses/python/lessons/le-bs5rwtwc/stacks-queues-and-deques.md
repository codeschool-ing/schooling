---
title: A list is a good stack and a bad queue
version: 1
---

```python
stack = []
stack.append(x)      # push   O(1)
stack.pop()          # pop    O(1)
```

**A list is a perfectly good stack.** Both ends of the operation are at the end of the list, where
nothing has to move. There is no `Stack` class in Python because there is no need for one.

## And a bad queue

```python
queue = []
queue.append(x)      # enqueue   O(1)
queue.pop(0)         # dequeue   O(n)  ← everything shifts
```

```text
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

```text
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
