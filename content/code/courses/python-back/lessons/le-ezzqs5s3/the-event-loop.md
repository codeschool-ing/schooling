---
title: The event loop, and what await means
version: 1
---

An `async def` function does not run when you call it. It returns a **coroutine**, an object that
describes the work, and something has to run it. That something is the **event loop**: one thread
that runs one coroutine until it reaches an `await` on something that is not ready, then switches to
another coroutine that is ready, and comes back when the awaited thing is done. Save this as
`loop.py`:

```python
# loop.py
import asyncio
import time

started = time.perf_counter()


def stamp(message):
    print(f"{time.perf_counter() - started:4.1f} s  {message}")


async def wait(name, seconds):
    stamp(f"{name} starts waiting {seconds} s")
    await asyncio.sleep(seconds)
    stamp(f"{name} is done")
    return name


async def main():
    coroutine = wait("alone", 1)
    stamp(f"made a {type(coroutine).__name__}; nothing has run yet")
    await coroutine
    results = await asyncio.gather(wait("a", 2), wait("b", 1), wait("c", 1.5))
    stamp(f"gathered {results}")


asyncio.run(main())
```

```
ana@vm:~/agenda-api$ uv run python loop.py
 0.0 s  made a coroutine; nothing has run yet
 0.0 s  alone starts waiting 1 s
 1.0 s  alone is done
 1.0 s  a starts waiting 2 s
 1.0 s  b starts waiting 1 s
 1.0 s  c starts waiting 1.5 s
 2.0 s  b is done
 2.5 s  c is done
 3.0 s  a is done
 3.0 s  gathered ['a', 'b', 'c']
```

Line by line, against the clock:

- **`made a coroutine; nothing has run yet`** came before `alone starts waiting`: calling `wait(...)`
  only built the coroutine. A coroutine that is never awaited never runs, and Python prints a
  `RuntimeWarning` when it is thrown away unrun.
- `await coroutine` ran it, and the program waited the one second, because there was nothing else to
  do.
- **`gather` started all three at 1.0 s.** Each one ran until its `await asyncio.sleep(...)`, gave
  the loop back, and the loop started the next. Then the loop woke each one as its timer finished:
  `b` after 1 s, `c` after 1.5 s, `a` after 2 s.
- `gather` returned at 3.0 s with the three results **in the order they were passed**, not the order
  they finished.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"A timeline in seconds drawn from loop.py's output. The coroutine alone waits from 0 to 1. Then a, b and c all start at 1 and wait together: b finishes at 2, c at 2.5 and a at 3, when gather returns. Three waits of 2, 1 and 1.5 seconds took 2 seconds of the clock, not 4.5.\"> <text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">seconds</text> <path d=\"M140 192 L140 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"140\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text> <path d=\"M300 192 L300 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"300\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text> <path d=\"M460 192 L460 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"460\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text> <path d=\"M620 192 L620 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"620\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text> <path d=\"M140 196 L620 196\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"120\" y=\"57\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">alone</text> <rect x=\"140\" y=\"40\" width=\"160\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"148\" y=\"56\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(1)</text> <text x=\"120\" y=\"95\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a</text> <rect x=\"300\" y=\"78\" width=\"320\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.25\" stroke=\"var(--phosphor)\"></rect> <text x=\"308\" y=\"94\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(2)</text> <text x=\"120\" y=\"133\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b</text> <rect x=\"300\" y=\"116\" width=\"160\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.25\" stroke=\"var(--phosphor)\"></rect> <text x=\"308\" y=\"132\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(1)</text> <text x=\"120\" y=\"171\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text> <rect x=\"300\" y=\"154\" width=\"240.0\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.25\" stroke=\"var(--phosphor)\"></rect> <text x=\"308\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(1.5)</text> <text x=\"630\" y=\"120\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">gather</text> <text x=\"630\" y=\"136\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">returns</text> </svg>", "caption": "The loop runs one coroutine at a time and switches whenever one awaits. Waiting is the part that overlaps."}
```

## The rule that makes it work, and breaks it

**The loop can only switch at an `await`.** Between two awaits, a coroutine has the thread to itself,
and every other coroutine waits for it to reach the next one. That is what makes `async` code easy
to reason about, since nothing interrupts you between awaits, and it is the whole reason the section
on blocking the loop exists: a coroutine that waits without awaiting holds every other coroutine
still. `asyncio.sleep` awaits. `time.sleep` does not.
