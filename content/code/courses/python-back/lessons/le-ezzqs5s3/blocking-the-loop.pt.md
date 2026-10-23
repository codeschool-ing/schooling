---
title: Bloquear o loop, o erro que parece correto
version: 1
---

A terceira rota do `app/forecast.py` é um `async def` que faz uma chamada HTTP síncrona. Ela funciona,
e com uma requisição por vez é exatamente tão rápida quanto as outras:

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/blocking/django-night 1
1 requests, status [200], 1.0 s
```

Dez de uma vez:

```
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/blocking/django-night 10
10 requests, status [200], 10.2 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 10
10 requests, status [200], 1.2 s
```

**10,2 segundos, contra 1,2 do `async def` correto.** O `client.get` síncrono espera a resposta sem
`await`, então a corrotina nunca devolve o loop. Durante esse segundo, **nada mais no processo roda**:
nem as outras nove requisições, nem uma verificação de saúde, nem a requisição que só queria ler uma
lista de eventos. Elas passaram uma depois da outra, um segundo cada.

É o pior dos dois mundos, e é fácil de escrever: uma biblioteca que faz chamadas de rede sem `async` é
o padrão no Python, e nada avisa quando você a chama de um `async def`. As regras que evitam isso:

- **Num `async def`, tudo o que espera precisa de await.** HTTP pelo `httpx2.AsyncClient`, um banco por
  um driver assíncrono, arquivos por uma biblioteca que oferece leitura assíncrona, dormir pelo
  `asyncio.sleep`.
- **Se uma biblioteca não tem versão async, escreva `def`.** O FastAPI então roda a rota numa thread, e
  uma chamada bloqueante bloqueia só aquela thread, como a rota `sync` mostrou.
- **Quando uma chamada bloqueante é inevitável dentro de um `async def`**,
  `await asyncio.to_thread(função, *args)` a roda numa thread e aguarda o resultado.

## Calcular não é esperar

As duas últimas rotas fazem cerca de um segundo de conta, sem espera nenhuma:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/forecast/busy/async; echo
{"total":2666666466666670000000,"seconds":0.85}
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/busy/async 4
4 requests, status [200], 3.2 s
ana@vm:~/agenda-api$ uv run python load.py http://127.0.0.1:8001/forecast/busy/sync 4
4 requests, status [200], 3.4 s
```

**Quatro requisições levaram umas quatro vezes uma, fosse qual fosse o tipo de rota**: 3,2 segundos com
`async def` e 3,4 com `def`. No loop, a conta o segurou, exatamente como a chamada bloqueante. Em
threads também não ajudou, porque o CPython roda código Python numa thread por vez, a trava global do
interpretador, então quatro threads de conta se revezam. Trabalho que calcula precisa de mais
**processos**, que é o que os workers da aula 16 são, ou de uma fila e um worker próprio, que é a aula 13.
