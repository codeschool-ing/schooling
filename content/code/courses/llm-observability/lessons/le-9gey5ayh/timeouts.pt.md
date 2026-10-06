---
title: Timeouts, e como escolher um
version: 1
---

Uma nova tentativa ajuda com uma recusa. Não ajuda com um pedido que nunca volta. Para isso o cliente
precisa de um **timeout**: um limite de quanto espera antes de desistir e, talvez, tentar de novo. O
padrão do SDK da OpenAI é dez minutos, escolhido para as respostas mais longas que um modelo consegue
escrever, e longo demais para um cliente esperando numa caixa de ajuda.

O `timeout.py` define dois segundos e pede uma resposta ao labobs, instruído a fazer de todo pedido uma
partida a frio:

```python
"""timeout.py: one call with a two-second timeout, to a provider that is about to take four."""
import time

from openai import APITimeoutError, OpenAI

client = OpenAI(timeout=2.0, max_retries=0)
start = time.monotonic()
try:
    client.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
    print(f"answered after {time.monotonic() - start:.1f} s")
except APITimeoutError as e:
    print(f"{type(e).__name__} after {time.monotonic() - start:.1f} s: {e}")
```

```
ana@lab:~/obs$ python timeout.py
APITimeoutError after 2.0 s: Request timed out.
```

Dois segundos, uma exceção, e nenhuma resposta. Se esse é o resultado certo depende do que acontece
depois, e os percentis da semana são de onde um timeout se escolhe.

## Escolhendo um a partir da semana

A linha `first token` dos percentis da semana tinha p95 de 444 ms e p99 de 4.257. Três escolhas, três
trocas:

- **Um timeout de 1 s no primeiro token** corta as partidas a frio, 16 chamadas das 1.108 da semana, e
  nada mais. A nova tentativa que vem depois tem 99% de chance de ser uma chamada comum. Para um
  cliente, uma resposta lenta vira uma um pouco menos lenta.
- **Um timeout de 1 s na chamada inteira** cortaria também toda resposta com mais de uns 30 tokens, que
  é mais da metade da semana. Ele confunde uma resposta longa com uma travada.
- **Nenhum timeout próprio**, os dez minutos do SDK, significa que as partidas a frio são só lentas, e
  um fornecedor que trava segura um worker até alguém perceber.

Então o timeout útil para uma chamada em streaming é **no primeiro token, e entre tokens**, não na
chamada inteira. O `timeout` do SDK é o do cliente HTTP: ele limita a conexão e cada leitura, o que,
num stream, significa a espera pelo primeiro pedaço e o intervalo entre pedaços, e foi ele que disparou
acima. Um limite na chamada inteira, se for preciso, pertence ao código da própria aplicação.

Todo timeout pertence ao span quando dispara, como um erro com o seu tipo. O cliente do assistente
espera até 20 segundos, coisa de que nada nesta semana chegou perto, e o seu laço de novas tentativas
trata um timeout como qualquer outro `APIError`: mais uma tentativa, depois de um recuo.
