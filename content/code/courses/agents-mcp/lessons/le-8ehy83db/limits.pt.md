---
title: Limites
version: 2
---

Todo servidor de modelos impõe limites, e cada um volta ao programa de um jeito. O `limits.py` encontra três:

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
max_tokens 'Hello! Welcome to the Cost Lesson.'
1331 ms
```

A resposta parou depois de 8 tokens, e o `stop_reason` foi `max_tokens`. Isso não é um erro: o pedido deu certo, e um programa que não confere o `stop_reason` vai entregar uma frase cortada a um cliente. Um laço de agente tem de tratar `max_tokens` como um desfecho próprio: aumentar o limite, pedir uma resposta mais curta, ou parar e relatar.

**A janela de contexto.** A aula 1 deu ao Ollama um contexto de 8.192 tokens. O `window` manda umas cinquenta mil palavras, com uma pergunta no fim:

```
ana@lab:~/agents$ python limits.py window
max_tokens input_tokens: 4094 'The last line of this message is: \n\nword word word word word word word word word word word word word word word word word word word word word word word'
53358 ms
```

Nenhum erro. O pedido deu certo depois de 53 segundos, e o `input_tokens` diz que o modelo leu **4.094** tokens de um prompt de umas doze vezes esse tamanho. O Ollama cortou o prompt para caber, guardando os primeiros tokens e o fim, e só disse isso no próprio log, numa linha `truncating input prompt` com o limite e o tamanho real do prompt (no Linux, `journalctl -u ollama` mostra); o programa recebeu uma resposta comum. O modelo então respondeu a uma pergunta sobre uma mensagem que em boa parte não tinha lido. A API da Anthropic recusa o mesmo pedido com um `400` que diz a contagem, antes de qualquer trabalho, e essa é a falha melhor. De um jeito ou de outro, um agente cuja conversa cresce sem limite chega à janela numa execução longa o bastante, e é por isso que a aula 1 mediu o crescimento e os SDKs oferecem maneiras de aparar o histórico (aula 8). Com um modelo local, **compare o `input_tokens` com o que você mandou**: é o único sinal que o cliente recebe.

**Um servidor sobrecarregado.** O `flaky.py` da aula 7 responde aos primeiros pedidos com `529`, o status que a API da Anthropic usa para sobrecarga, e passa os outros para o Ollama. Duas falhas, depois três:

```
ana@lab:~/agents$ python flaky.py 2 > flaky.log & sleep 1; ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python limits.py overloaded; kill $!; echo $(cat flaky.log)
answered: Hello! Welcome to the Cost Lesson. I'm your instructor today. How can I assist you in understanding the world of costs?
5841 ms
529 529 200
ana@lab:~/agents$ python flaky.py 3 > flaky.log & sleep 1; ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python limits.py overloaded; kill $!; echo $(cat flaky.log)
OverloadedError 529: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}}
1423 ms
529 529 529
```

Com duas falhas a chamada **deu certo**, depois de 5.841 ms: o `flaky.log` mostra `529 529 200`. O SDK anthropic repetiu sozinho, duas vezes, com uma pausa entre as tentativas; é o padrão dele (`max_retries=2`), e ele faz o mesmo para `429` (limite de taxa) e outros erros de servidor. Com três falhas, a terceira resposta foi a última que o SDK tentaria, e o programa recebeu `OverloadedError`.

Duas lições das novas tentativas. **Elas são invisíveis se você não olhar**: a primeira execução deu certo, e nada no resultado dizia que dois pedidos tinham falhado antes. E **uma nova tentativa é um novo pedido**: conta contra o limite de taxa, e se a primeira tentativa de fato fez o trabalho antes de falhar, ele pode ser feito duas vezes. Para chamadas de ferramenta que mudam alguma coisa, esse é o argumento para torná-las seguras de repetir: uma chave de idempotência, ou uma verificação de que a ação ainda não foi feita.
