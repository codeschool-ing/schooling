---
title: Com que velocidade você pode pedir
version: 1
---

Um provedor limita a velocidade com que uma conta pode mandar, e a documentação da Anthropic diz em
que unidades e como o limite se recompõe:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 217: You might hit rate limits over shorter time intervals. For instance, a rate of 60
      requests per minute (RPM) might be enforced as 1 request per second. Short bursts of
      requests can exceed the limit and trigger rate limit errors.
 222: token bucket algorithm
 223: to do rate limiting. This means that your capacity is continuously replenished up to
      your maximum limit, rather than being reset at fixed intervals.
 322: The rate limits for the Messages API are measured in requests per minute (RPM), input
      tokens per minute (ITPM), and output tokens per minute (OTPM) for each model class.
```

Três limites, qualquer um dos quais pode ser o que barra uma requisição: requisições, tokens lidos e
tokens escritos, cada um por minuto. E **um balde, não um calendário**: a capacidade volta
continuamente, então uma rajada pode bater no limite mesmo quando o total do minuto caberia. Quando
bate, a resposta é um 429, e um cabeçalho diz quanto esperar:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 689: The number of seconds to wait until you can retry the request. Earlier retries will
      fail. Not sent with the spend-cap 429 (see
```

O Ollama não tem limite nenhum, então o relay da seção 03 da aula 9 faz o papel de um. Pare-o no
segundo terminal e suba com `--rpm 5`, cinco requisições por minuto; passado isso ele responde 429
com um `retry-after`, como a documentação descreve:

```
ana@desk:~/desk$ python relay.py --rpm 5
relay on 127.0.0.1:8500, to Ollama on 11434, writing wire.jsonl
```

No terminal em que você trabalha, mande as duas bibliotecas para o relay, como as aulas 16 e 17
fizeram:

```
ana@desk:~/desk$ export OPENAI_BASE_URL=http://127.0.0.1:8500/v1 ANTHROPIC_BASE_URL=http://127.0.0.1:8500
```

O `burst.py` classifica oito casos com as novas tentativas desligadas. Com `--pace`, um 429 o faz
esperar o tempo que o `retry-after` diz e mandar o mesmo caso de novo:

```python
import json
import sys
import time

import anthropic

client = anthropic.Anthropic(max_retries=0)
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][:8]
pace = sys.argv[1:] == ["--pace"]

start = time.monotonic()
for c in cases:
    while True:
        try:
            r = client.messages.create(model="llama3.2:3b", max_tokens=16, system=prompt,
                                       messages=[{"role": "user", "content": c["text"]}])
            print(f"{time.monotonic() - start:5.1f}s {c['id']} {r.content[0].text}")
            break
        except anthropic.RateLimitError as e:
            wait = int(e.response.headers["retry-after"])
            print(f"{time.monotonic() - start:5.1f}s {c['id']} 429, retry-after {wait}")
            if not pace:
                break
            time.sleep(wait)   # the header says how long; an earlier retry would fail
```

```
ana@desk:~/desk$ python burst.py
  1.4s c01 order-status, product-question.
  2.6s c02 order-status, refund
  3.6s c03 address-change
  4.5s c04 order-status
  5.2s c05 order-status
  5.2s c06 429, retry-after 55
  5.2s c07 429, retry-after 55
  5.3s c08 429, retry-after 55
```

Cinco respostas, depois três recusas, cada uma dizendo quanto esperar, e o programa mandou a
seguinte assim mesmo: **a informação estava na resposta que ele tinha acabado de ler.** Seus
rótulos e tempos vão ser outros; os cinco e os três não. Suba o relay de novo com `--rpm 5` para o
minuto começar vazio, e rode outra vez com `--pace`:

```
ana@desk:~/desk$ python burst.py --pace
  1.0s c01 order-status
  2.2s c02 order-status, refund
  3.3s c03 address-change
  4.1s c04 order-status
  5.2s c05 order-status, refund.
  5.2s c06 429, retry-after 55
 61.1s c06 order-status
 62.0s c07 refund
 62.0s c08 429, retry-after 1
 63.9s c08 address-change
```

Oito respostas em cerca de um minuto, e duas recusas, cada uma seguida da espera que pediu. A
segunda mostra como o relay conta: um minuto deslizante, então as cinco requisições anteriores
saem dele uma de cada vez, um minuto depois de cada uma chegar, e a oitava o encontrou ainda cheio
por mais um segundo. No balde de fichas da Anthropic, a capacidade volta aos poucos. De um jeito ou
de outro o princípio vale: **um programa que lê o que o limite diz espalha as requisições; um que
ignora falha em rajadas** e se apoia nas novas tentativas, que a aula 17 mostrou que também contam
no limite. A Anthropic também manda cabeçalhos que dizem quanto falta para o limite:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 694: anthropic-ratelimit-requests-remaining
 695: The number of requests remaining before being rate limited.
```

e assim um programa pode desacelerar antes do primeiro 429, e não depois dele. O Ollama e o relay
não mandam nenhum.

Para a classificação noturna de algumas centenas de e-mails da ana, isso é questão de poucas linhas.
Para uma mesa que cresce, é o motivo para pedir ao provedor um nível mais alto antes do dia mais
cheio, e não durante ele.
