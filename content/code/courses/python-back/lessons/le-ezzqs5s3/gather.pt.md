---
title: O gather, e os outros jeitos de rodar corrotinas juntas
version: 1
---

O `asyncio.gather` é a ferramenta que o `three.py` e o `loop.py` usaram: ele recebe corrotinas, roda
todas juntas no loop, e devolve os resultados em ordem quando todas terminam. É a de que a maior parte
do código precisa, e tem parentes que vale conhecer pelo nome.

| ferramenta | o que faz | use quando |
|---|---|---|
| `await gather(a, b, c)` | roda todas, devolve todos os resultados em ordem | você precisa de todas as respostas |
| `asyncio.TaskGroup` | o mesmo, dentro de `async with`, e cancela o resto se uma falha | uma falha deve parar as outras |
| `asyncio.create_task(coro)` | começa uma agora; `await task` a recolhe depois | o trabalho começa antes de você saber o que mais precisa |
| `await asyncio.wait_for(coro, 2)` | desiste depois de um tempo, levantando `TimeoutError` | um parceiro pode nunca responder |

## Quando uma delas falha

Por padrão, o `gather` deixa a exceção de qualquer corrotina subir para quem o aguardava, **e as outras
continuam rodando**, com os resultados perdidos. O `gather(..., return_exceptions=True)` põe a exceção
na lista de resultados, ao lado das respostas que voltaram. Um `TaskGroup` cancela as outras na primeira
falha, que é o padrão certo para trabalho em que uma resposta faltando torna o resto inútil.

## Um timeout em tudo o que você espera

Um parceiro que às vezes leva trinta segundos vai, um dia, levar trinta segundos para toda requisição
ao mesmo tempo, e toda corrotina esperando por ele se acumula. **Toda chamada a algo fora do processo
precisa de um timeout**: o `httpx2.AsyncClient(timeout=5)` dá um a cada requisição, e o `wait_for`
limita qualquer corrotina. O `load.py`, na próxima seção, põe 120 segundos generosos de propósito,
porque é uma ferramenta de medida que não pode desistir antes do caso mais lento que mede.
