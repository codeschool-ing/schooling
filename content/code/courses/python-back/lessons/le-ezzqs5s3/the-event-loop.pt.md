---
title: O event loop, e o que await quer dizer
version: 1
---

Uma função `async def` não roda quando você a chama. Ela devolve uma **corrotina**, um objeto que
descreve o trabalho, e algo precisa rodá-la. Esse algo é o **event loop**: uma thread que roda uma
corrotina até ela chegar a um `await` em algo que não está pronto, então troca para outra corrotina que
está pronta, e volta quando a coisa aguardada termina. Salve isto como `loop.py`:

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

Linha a linha, contra o relógio:

- **`made a coroutine; nothing has run yet`** veio antes de `alone starts waiting`: chamar `wait(...)`
  só montou a corrotina. Uma corrotina que nunca é aguardada nunca roda, e o Python imprime um
  `RuntimeWarning` quando ela é jogada fora sem rodar.
- O `await coroutine` a rodou, e o programa esperou um segundo, porque não havia mais nada a fazer.
- **O `gather` começou as três em 1,0 s.** Cada uma rodou até o seu `await asyncio.sleep(...)`, devolveu
  o loop, e o loop começou a próxima. Depois o loop acordou cada uma quando o timer dela terminou: `b`
  depois de 1 s, `c` depois de 1,5 s, `a` depois de 2 s.
- O `gather` retornou em 3,0 s com os três resultados **na ordem em que foram passados**, não na ordem
  em que terminaram.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Uma linha do tempo em segundos desenhada a partir da saída do loop.py. A corrotina alone espera de 0 a 1. Depois a, b e c começam todas em 1 e esperam juntas: b termina em 2, c em 2,5 e a em 3, quando o gather retorna. Três esperas de 2, 1 e 1,5 segundos levaram 2 segundos de relógio, não 4,5.\"> <text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">segundos</text> <path d=\"M140 192 L140 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"140\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text> <path d=\"M300 192 L300 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"300\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text> <path d=\"M460 192 L460 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"460\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text> <path d=\"M620 192 L620 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"620\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text> <path d=\"M140 196 L620 196\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <text x=\"120\" y=\"57\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">alone</text> <rect x=\"140\" y=\"40\" width=\"160\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"148\" y=\"56\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(1)</text> <text x=\"120\" y=\"95\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a</text> <rect x=\"300\" y=\"78\" width=\"320\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.25\" stroke=\"var(--phosphor)\"></rect> <text x=\"308\" y=\"94\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(2)</text> <text x=\"120\" y=\"133\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b</text> <rect x=\"300\" y=\"116\" width=\"160\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.25\" stroke=\"var(--phosphor)\"></rect> <text x=\"308\" y=\"132\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(1)</text> <text x=\"120\" y=\"171\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text> <rect x=\"300\" y=\"154\" width=\"240.0\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.25\" stroke=\"var(--phosphor)\"></rect> <text x=\"308\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await asyncio.sleep(1.5)</text> <text x=\"630\" y=\"120\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o gather</text> <text x=\"630\" y=\"136\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">retorna</text> </svg>", "caption": "O loop roda uma corrotina por vez e troca sempre que uma faz await. A espera é a parte que se sobrepõe."}
```

## A regra que faz funcionar, e que quebra

**O loop só consegue trocar num `await`.** Entre dois awaits, uma corrotina tem a thread só para ela, e
toda outra corrotina espera ela chegar ao próximo. É isso que torna código `async` fácil de entender, já
que nada interrompe você entre awaits, e é o motivo inteiro da seção sobre bloquear o loop: uma
corrotina que espera sem fazer await segura toda outra corrotina parada. O `asyncio.sleep` faz await. O
`time.sleep` não.
