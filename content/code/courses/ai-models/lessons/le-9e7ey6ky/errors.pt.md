---
title: As duas novas tentativas que você não escreveu
version: 1
---

Um serviço compartilhado às vezes está ocupado demais para responder. A API da Anthropic diz isso
com um código de status próprio, e a documentação diz o que a biblioteca faz a respeito:

```
ana@desk:~/desk$ sources quote claude-errors "overloaded_error|529 errors can occur|automatically retries"
# https://platform.claude.com/docs/en/api/errors, read 2026-10-05
 247: overloaded_error
 250: 529 errors can occur when the API experiences high traffic across all users.
 252: The official SDK automatically retries transient failures (such as connection errors,
      rate limits, and 5xx server errors) with exponential backoff, twice by default, honoring
      the
```

O `lab/retries.py` classifica um caso com um número dado de novas tentativas e mede o tempo. O lab
manda o substituto responder as duas próximas requisições com um 529, o que no mundo seria a API
ocupada:

```python
import json
import sys
import time

import anthropic

client = anthropic.Anthropic(max_retries=int(sys.argv[1]))
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

start = time.monotonic()
try:
    r = client.messages.create(model="standin-large", max_tokens=16, system=prompt,
                               messages=[{"role": "user", "content": case["text"]}])
    print(f"{r.content[0].text} after {time.monotonic() - start:.1f} s")
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code} after {time.monotonic() - start:.1f} s")
```

```
ana@desk:~/desk$ python lab/retries.py 2
other after 2.0 s
```

```
ana@desk:~/desk$ wire --count 3
POST /v1/messages -> 529 anthropic 
POST /v1/messages -> 529 anthropic 
POST /v1/messages -> 200 anthropic standin-large
```

O programa fez uma chamada e recebeu uma resposta. O substituto recebeu **três requisições**, duas
das quais falharam. A biblioteca absorveu as falhas, esperou entre as tentativas e devolveu a
terceira como se fosse a primeira; o único rastro no programa da ana são os dois segundos. Sem novas
tentativas, a mesma sobrecarga é uma exceção na hora:

```
ana@desk:~/desk$ python lab/retries.py 0
OverloadedError 529 after 0.0 s
```

Os dois padrões são razoáveis, e o ponto é saber qual está rodando:

- **As novas tentativas contam no limite de requisições.** A aula 21 define um limite de requisições
  por minuto, e um programa que faz 50 chamadas num minuto ocupado pode mandar 150.
- **O tempo entra na latência.** As medições de tempo até o primeiro token da seção 06 da aula 4
  incluem as novas tentativas que houve, a não ser que o harness as registre.
- **Um trabalho em lote as quer; uma tela talvez não.** Para a classificação noturna da ana, esperar
  e tentar de novo é o certo. Para uma página em que alguém espera um rascunho, uma falha rápida com
  uma mensagem pode ser melhor que dez segundos de silêncio.

O `max_retries` é um ajuste do cliente, e a decisão fica no código ao lado dele, onde a próxima
pessoa consegue ler.
