---
title: As repetições que o SDK faz por você
version: 1
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

## Duas falhas, depois um sucesso

O labllm pode ser mandado a responder 529, "sobrecarregado", às próximas requisições. Com duas
delas:

```python
"""One request, with the SDK's default retries, and how long it took."""
import time

import anthropic

t0 = time.monotonic()
try:
    r = anthropic.Anthropic().messages.create(
        model="scripted-1", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
    print(f"{r.content[0].text!r} after {time.monotonic() - t0:.1f} s")
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code} after {time.monotonic() - t0:.1f} s")
```

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"fail_next": 529, "fail_count": 2}' >/dev/null; python once.py
"Hello from the shop's assistant." after 1.6 s
ana@dev:~/shop$ tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r["status"], r.get("error", "")) for r in map(json.loads, sys.stdin)]'
529 Overloaded
529 Overloaded
200 
```

**O script não viu erro nenhum.** O SDK recebeu 529, esperou, recebeu 529 de novo, esperou mais, e a
terceira tentativa deu certo; o log mostra as três. As esperas crescem a cada vez e têm uma parte
aleatória, para dois clientes que falharam juntos não repetirem juntos. Isso se chama espera
exponencial com jitter, e é por isso que o tempo muda um pouco a cada execução.

## Três falhas

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"fail_next": 529, "fail_count": 3}' >/dev/null; python once.py
OverloadedError 529 after 1.4 s
```

Uma falha a mais do que o SDK absorve, e o erro chega ao seu código: `OverloadedError`, 529. **As
repetições do SDK terminam onde a sua política começa.** As escolhas são falhar e avisar a pessoa,
pôr o trabalho numa fila para depois, ou perguntar a outro provedor, que a aula 10 seção 08 monta.

## O que não repetir

Um 400 é uma requisição errada que vai estar errada de novo; um 401 é uma chave que não vai começar
a funcionar. **Repita só o que o tempo conserta**: erros de conexão, 429 e a família 5xx, que é o que
os SDKs fazem. Um laço de repetição seu em volta do do SDK, pegando tudo, multiplica as esperas e
repete os erros que deveriam ter parado o programa.
