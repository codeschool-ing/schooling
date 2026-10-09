---
title: Timeouts, e como escolher um
version: 2
---

Uma nova tentativa ajuda com uma recusa. Não ajuda com um pedido que nunca volta. Para isso o cliente
precisa de um **timeout**: um limite de quanto espera antes de desistir e, talvez, tentar de novo. O
padrão do SDK da OpenAI é dez minutos, escolhido para as respostas mais longas que um modelo consegue
escrever, e longo demais para um cliente esperando numa caixa de ajuda.

O `timeout.py` define dois segundos e pede uma resposta logo depois que o `ollama stop` tirou o
modelo da memória, para que o Ollama tenha de carregá-lo de novo antes do primeiro token. É a espera
que a primeira chamada da aula 1 incluiu, 11,7 segundos dela:

```python
"""timeout.py: one call with a two-second timeout, to a model that has to be loaded first."""
import time

from openai import APITimeoutError, OpenAI

client = OpenAI(timeout=2.0, max_retries=0)
start = time.monotonic()
try:
    client.chat.completions.create(model="llama3.2:3b", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
    print(f"answered after {time.monotonic() - start:.1f} s")
except APITimeoutError as e:
    print(f"{type(e).__name__} after {time.monotonic() - start:.1f} s: {e}")
```

```
ana@dev:~/obs$ ollama stop llama3.2:3b
ana@dev:~/obs$ python timeout.py
APITimeoutError after 2.0 s: Request timed out.
```

Dois segundos, uma exceção, e nenhuma resposta. Se esse é o resultado certo depende do que acontece
depois, e os percentis da semana são de onde um timeout se escolhe.

## Escolhendo um a partir da semana

A linha `first token` dos percentis da semana tinha p95 de 1.431 ms, p99 de 1.954 e máximo de 2.190.
Três escolhas, três trocas:

- **Um timeout de 3 s no primeiro token** não corta nada nesta semana, e só corta as chamadas que
  estão esperando por outra coisa que não a leitura do modelo: um modelo sendo carregado, como no
  `timeout.py`, uma máquina ocupada com outra coisa, um fornecedor que parou de responder. Para um
  cliente, uma resposta lenta vira uma nova tentativa, ou um pedido de desculpas, alguns segundos
  antes.
- **Um timeout de 3 s na chamada inteira** cortaria também toda resposta com mais de uns 20 tokens,
  que é mais da metade da semana. Ele confunde uma resposta longa com uma travada.
- **Nenhum timeout próprio**, os dez minutos do SDK, significa que os começos lentos são só lentos, e
  um fornecedor que trava segura um worker até alguém perceber.

Então o timeout útil para uma chamada em streaming é **no primeiro token, e entre tokens**, não na
chamada inteira. O `timeout` do SDK é o do cliente HTTP: ele limita a conexão e cada leitura, o que,
num stream, significa a espera pelo primeiro pedaço e o intervalo entre pedaços, e foi ele que disparou
acima. Um limite na chamada inteira, se for preciso, pertence ao código da própria aplicação.

Todo timeout pertence ao span quando dispara, como um erro com o seu tipo. O cliente do assistente
espera até 60 segundos, coisa de que nada nesta semana chegou perto, e o seu laço de novas
tentativas trata um timeout como qualquer outro `APIError`: mais uma tentativa, depois de um recuo.