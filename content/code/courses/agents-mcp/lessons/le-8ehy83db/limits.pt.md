---
title: Limites
version: 1
---

Todo fornecedor impõe limites, e cada um volta ao programa de um jeito. O `limits.py` encontra quatro:

```python
"""Three limits, met one at a time: the reply's length, the context window, and a server too busy to answer."""
import sys
import time

import anthropic

client = anthropic.Anthropic()
SYSTEM = "You answer Marginalia's customers in the cost lesson."
ASK = [{"role": "user", "content": "Say hello to a customer."}]

what = sys.argv[1]
t0 = time.perf_counter()
try:
    if what == "max-tokens":
        r = client.messages.create(model="llama3.2:3b", max_tokens=8, system=SYSTEM, messages=ASK)
        print(r.stop_reason, repr(r.content[0].text))
    if what == "window":                      # about six times the 8192 tokens Ollama was given
        huge = "word " * 50_000 + "\nWhat is the last line of this message?"
        r = client.messages.create(model="llama3.2:3b", max_tokens=32, messages=[{"role": "user", "content": huge}])
        print(r.stop_reason, "input_tokens:", r.usage.input_tokens, repr(r.content[0].text))
    if what == "overloaded":                  # run with ANTHROPIC_BASE_URL at lesson 7's flaky.py
        r = client.messages.create(model="llama3.2:3b", max_tokens=64, system=SYSTEM, messages=ASK)
        print("answered:", r.content[0].text)
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code}: {e.message[:120]}")
print(f"{(time.perf_counter() - t0) * 1000:.0f} ms")
```

**O limite de saída.** `max_tokens` é um teto para o que o modelo pode escrever numa resposta:

```
ana@lab:~/agents$ python limits.py max-tokens
max_tokens "Hello! Marginalia's support team"
563 ms
```

A resposta parou no meio da frase depois de 8 tokens, e o `stop_reason` foi `max_tokens`. Isso não é um erro: o pedido deu certo, e um programa que não confere o `stop_reason` vai entregar meia frase a um cliente. Um laço de agente tem de tratar `max_tokens` como um desfecho próprio: aumentar o limite, pedir uma resposta mais curta, ou parar e relatar.

**A janela de contexto.** A entrada mais o `max_tokens` têm de caber na janela do modelo, 200.000 tokens no labllm:

```
ana@lab:~/agents$ python limits.py window
BadRequestError 400: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'prompt is too long: 210004 to
57 ms
```

Um `400` antes de qualquer trabalho, dizendo a contagem. Um agente cuja conversa cresce sem limite chega a isso numa execução longa o bastante, e é por isso que a aula 1 mediu o crescimento e os SDKs oferecem maneiras de aparar o histórico (aula 8).

**Um fornecedor sobrecarregado.** O `/lab/config` do labllm faz os próximos pedidos falharem com `529`, o status que a API da Anthropic usa para sobrecarga. Duas falhas, depois três:

```
ana@lab:~/agents$ python limits.py overloaded; python -c 'import json; print(" ".join(str(json.loads(l)["status"]) for l in open("/var/log/labllm/requests.jsonl")))'
answered: Hello! Marginalia's support team here. How can we help you today?
2345 ms
529 529 200
ana@lab:~/agents$ python limits.py overloaded-3; python -c 'import json; print(" ".join(str(json.loads(l)["status"]) for l in open("/var/log/labllm/requests.jsonl")))'
OverloadedError 529: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}, 'request_id': 'req_l
1250 ms
529 529 529
```

Com duas falhas a chamada **deu certo**, depois de 2.345 ms: o log mostra `529 529 200`. O SDK anthropic repetiu sozinho, duas vezes, com uma pausa entre as tentativas; é o padrão dele (`max_retries=2`), e ele faz o mesmo para `429` (limite de taxa) e outros erros de servidor. Com três falhas, a terceira resposta foi a última que o SDK tentaria, e o programa recebeu `OverloadedError`.

Duas lições das novas tentativas. **Elas são invisíveis se você não olhar**: a primeira execução deu certo e levou quatro vezes o tempo de uma resposta comum, e nada no resultado dizia por quê. E **uma nova tentativa é um novo pedido**: conta contra o limite de taxa, e se a primeira tentativa de fato fez o trabalho antes de falhar, ele pode ser feito duas vezes. Para chamadas de ferramenta que mudam alguma coisa, esse é o argumento para torná-las seguras de repetir: uma chave de idempotência, ou uma verificação de que a ação ainda não foi feita.
