---
title: As repetições que o SDK faz por você
version: 2
---

Nem toda falha é sua. Um provedor pode estar sobrecarregado, uma conexão pode cair, um servidor pode
falhar por um segundo. **Os SDKs repetem essas sozinhos**, e vale saber quantas vezes e por quanto
tempo antes de contar com isso.

```
ana@dev:~/shop$ python -c 'import anthropic, openai; a = anthropic.Anthropic(); o = openai.OpenAI(); print("anthropic:", a.max_retries, a.timeout); print("openai:   ", o.max_retries, o.timeout)'
anthropic: 2 Timeout(connect=5.0, read=600, write=600, pool=600)
openai:    2 Timeout(connect=5.0, read=600, write=600, pool=600)
```

Os dois SDKs repetem duas vezes e esperam até 600 segundos para uma resposta ser lida. **Dez minutos
é muito tempo para uma pessoa olhar um indicador girando.** Uma funcionalidade interativa quer um
timeout bem menor; um job em lote pode querer mais repetições. Os dois são argumentos na criação do
cliente: `anthropic.Anthropic(max_retries=4, timeout=30)`.

## Um servidor que não está lá

A falha mais fácil de provocar de propósito é o servidor estar ausente. A ana para o Ollama e
pergunta, com `ANTHROPIC_LOG=info`, que faz o SDK dizer o que está fazendo:

```python
"""One request, with the SDK's default retries, and how long it took."""
import time

import anthropic

t0 = time.monotonic()
try:
    r = anthropic.Anthropic().messages.create(
        model="llama3.2:3b", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
    print(f"{r.content[0].text!r} after {time.monotonic() - t0:.1f} s")
except anthropic.APIError as e:
    print(f"{type(e).__name__} after {time.monotonic() - t0:.1f} s")
```

```
ana@dev:~/shop$ sudo pkill -x ollama; ANTHROPIC_LOG=info python once.py
[2026-10-07 16:30:00 - anthropic._base_client:1358 - INFO] Retrying request to /v1/messages in 0.380106 seconds
[2026-10-07 16:30:00 - anthropic._base_client:1358 - INFO] Retrying request to /v1/messages in 0.994649 seconds
APIConnectionError after 1.5 s
```

**Duas repetições, depois o erro.** O SDK esperou uns quatro décimos de segundo, depois um segundo, e
depois da terceira tentativa que falhou lançou `APIConnectionError` para o script, um segundo e meio
depois de começar. As esperas crescem a cada vez e têm uma parte aleatória, para dois clientes que
falharam juntos não repetirem juntos. Isso se chama espera exponencial com jitter, e é por isso que os
tempos mudam um pouco a cada execução.

O mesmo comando de novo, com o Ollama iniciado noutro terminal um segundo depois dele:

```
ana@dev:~/shop$ ANTHROPIC_LOG=info python once.py
[2026-10-07 16:30:03 - anthropic._base_client:1358 - INFO] Retrying request to /v1/messages in 0.483649 seconds
[2026-10-07 16:30:09 - httpx2:1085 - INFO] HTTP Request: POST http://127.0.0.1:11434/v1/messages "HTTP/1.1 200 OK"
'Hello, how are you today?' after 6.5 s
```

**Uma repetição, depois uma resposta, e o script não viu erro nenhum.** A primeira tentativa não achou
ninguém, o SDK esperou meio segundo, e a segunda chegou ao servidor, que então passou seis segundos
carregando o modelo antes de responder. **As repetições do SDK terminam onde a sua política começa**:
uma falha a mais do que ele absorve e o erro chega ao seu código. As escolhas então são falhar e
avisar a pessoa, pôr o trabalho numa fila para depois, ou perguntar a outro provedor, que a aula 10
seção 08 monta.

Um provedor falha de mais jeitos que um servidor ausente: 429 quando você passou do limite, 500
quando ele quebra, 529 quando está sobrecarregado. Os SDKs repetem todos do mesmo jeito. Nenhum deles
pode ser provocado aqui sem um provedor, e o que mais importa para o seu código volta na seção 08.

## O que não repetir

Um 400 é uma requisição errada que vai estar errada de novo; um 401 é uma chave que não vai começar
a funcionar. **Repita só o que o tempo conserta**: erros de conexão, 429 e a família 5xx, que é o que
os SDKs fazem. O Ollama teria respondido a uma chave errada sem reclamar, como a seção 03 mostrou,
então teste que um 401 para o seu programa contra um provedor, não contra o seu notebook. Um laço de repetição seu em volta do do SDK, pegando tudo, multiplica as esperas e
repete os erros que deveriam ter parado o programa.
