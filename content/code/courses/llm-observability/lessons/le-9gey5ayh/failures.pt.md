---
title: Falhas, e as novas tentativas que as escondem
version: 1
---

Um fornecedor recusa pedidos. Ele está sobrecarregado (503, ou o 529 da Anthropic), está limitando a
taxa desta chave (429), ou algo do lado dele quebrou (500). A maioria disso se resolve num segundo, e é
por isso que todo SDK tenta de novo, e por isso que uma falha no fornecedor em geral não é uma falha
para o cliente. A pergunta para o monitoramento é se alguém ainda consegue vê-la.

O labobs pode ser instruído a recusar uma parte dos pedidos ao acaso. Com 30% recusados:

```
ana@lab:~/obs$ curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_rate\": 0.3}"; echo
{"fail": 0, "status": 429, "seed": 7, "slow_rate": 0.01, "fail_rate": 0.3, "fail_status": 503, "cut_after": null}
ana@lab:~/obs$ rm -f spans.jsonl; python ten.py
4115d849  ok      You have 30 days from delivery to return a printed book in t
6baa11fa  ok      Express delivery is not free at any order value. [1]
6f924a7e  ok      We refund within three working days of the return reaching o
959c4df5  ok      Express delivery is not free at any order value. [1]
d91cac9c  ok      You can use the same account on up to six devices at a time.
6436fc01  ok      A gift card is valid for two years from the day it was bough
331a29ae  ok      Kindle readers cannot open our e-books, because Amazon's dev
90c747d8  ok      I could not find that in our documents.
3111c5fa  ok      A standard parcel whose tracking has not changed for 10 work
9ff6b156  ok      I could not find that in our documents.
```

Dez perguntas, dez respostas. Nada do que o cliente viu falhou. O `errors.py` lê os spans:

```python
"""errors.py: the model attempts in spans.jsonl, and what became of the requests that made them."""
import json
from collections import Counter

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ")]
asks = [s for s in spans if s["name"] == "ask"]
gens = [s for s in spans if s["name"] == "generate"]
print(f"attempts {len(chats)}, failed {sum(s['status'] == 'ERROR' for s in chats)}")
print("requests by attempts needed:", dict(sorted(Counter(s["attributes"]["app.attempts"] for s in gens).items())))
print(f"requests {len(asks)}, failed {sum(s['status'] == 'ERROR' for s in asks)}")
```

```
ana@lab:~/obs$ python errors.py
attempts 10, failed 2
requests by attempts needed: {1: 6, 2: 2}
requests 10, failed 0
```

**Duas das dez tentativas falharam, e nenhum dos dez pedidos falhou.** Seis pedidos precisaram de uma
tentativa, dois precisaram de duas, e dois recusaram antes de qualquer chamada a modelo. Um dos traces
com nova tentativa:

```
ana@lab:~/obs$ python tree.py 6baa11fa
trace 6baa11fae7dec0ff4b543047a8106bf2   start(ms) took(ms)
      0   1,185 ms  ask
      0      47 ms    embed
     48       3 ms    search
     51   1,134 ms    generate
     51      48 ms      chat extract-1  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'The server is overloaded', 'type': 'overloaded_error', 'code': None}}
    599     585 ms      chat extract-1
  1,185       0 ms    check_citations
ana@lab:~/obs$ python tree.py --attrs 6baa11fa | grep -E "ERROR|attempts"
                       app.attempts = 2
     51      48 ms      chat extract-1  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'The server is overloaded', 'type': 'overloaded_error', 'code': None}}
```

A primeira tentativa foi recusada com um 503 em 48 ms. O assistente esperou meio segundo, o seu
primeiro recuo, e pediu de novo; a segunda tentativa foi respondida. O pedido levou 1.185 ms, meio
segundo deles esperando para tentar de novo, e o cliente só viu uma resposta mais lenta.

## Duas taxas de erro

A semana precisa das duas, e elas significam coisas diferentes:

- **A taxa de erro por tentativa**, chamadas a modelo que falharam sobre todas as chamadas: 2 em 10
  aqui. É a saúde do fornecedor. Quando sobe, o fornecedor está num dia ruim, e as novas tentativas
  estão absorvendo.
- **A taxa de erro por pedido**, pedidos que chegaram ao cliente como erro: 0 em 10. É a experiência
  do cliente. Quando sobe, as novas tentativas se esgotaram.

Um alerta só na segunda dispara quando já é tarde demais. Um alerta só na primeira dispara a cada
soluço do fornecedor que as novas tentativas absorveram e ninguém percebeu. **Uma taxa de erro por
tentativa subindo com a taxa por pedido estável é um aviso; as duas subindo é um incidente.** A aula 16
transforma isso em regras.

## Uma nova tentativa que o trace não vê

O assistente tenta de novo no próprio código para que cada tentativa seja um span. A maior parte do
código deixa isso para o SDK, cujo padrão é duas novas tentativas. O `sdk_retry.py` faz uma chamada
desse jeito, com um span em volta, enquanto o labobs recusa os dois próximos pedidos:

```python
"""sdk_retry.py: the SDK retrying inside one span, where the trace cannot see it."""
from openai import OpenAI

import telemetry

telemetry.setup()
client = OpenAI(max_retries=2)
with telemetry.span("chat extract-1", **{"gen_ai.request.model": "extract-1"}):
    client.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
```

```
ana@lab:~/obs$ rm -f spans.jsonl; python sdk_retry.py; python tree.py
trace d1ed988996915d550df75b7bf41c8866   start(ms) took(ms)
      0   1,835 ms  chat extract-1
ana@lab:~/obs$ tail -3 /var/log/labgen/requests.jsonl | python -c "import json, sys; [print(json.loads(l)[\"n\"], json.loads(l)[\"status\"]) for l in sys.stdin]"
2362 503
2363 503
2364 200
```

O trace mostra **um span de 1.835 ms, e nenhum erro**. O log do labobs mostra o que aconteceu: os
pedidos 2362 e 2363 foram recusados com 503, e o 2364 foi respondido. O SDK esperou, tentou de novo
duas vezes e devolveu sucesso, e de dentro da aplicação nada disso é visível. O span não está errado, a
chamada deu certo mesmo, mas uma semana disso mostraria um fornecedor ficando mais lento quando na
verdade ele estava falhando um terço das vezes.

Duas saídas. Tentar de novo no próprio código, como faz o `assistant.py`, com `max_retries=0` no
cliente. Ou manter as novas tentativas do SDK e instrumentar por baixo delas: uma instrumentação no
nível do HTTP vê cada pedido que o SDK manda, novas tentativas incluídas, como um span próprio. De
qualquer jeito, **as falhas do fornecedor têm de ser contadas em algum lugar, ou o primeiro sinal delas
vai ser um cliente**.
