---
title: Com que velocidade você pode pedir
version: 1
---

Um provedor limita a velocidade com que uma conta pode mandar, e a documentação da Anthropic diz em
que unidades e como o limite se recompõe:

```
ana@desk:~/desk$ sources quote claude-rate-limits "measured in requests per minute|token bucket algorithm|continuously replenished|Short bursts"
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-05
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
ana@desk:~/desk$ sources lines claude-rate-limits 686 687
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-05
 686| retry-after
 687| The number of seconds to wait until you can retry the request. Earlier retries will fail. Not sent with the spend-cap 429 (see
```

O lab ajusta o substituto para 5 requisições por minuto, e o `lab/burst.py` classifica oito casos com
as novas tentativas desligadas, imprimindo o que cada resposta diz sobre o limite:

```python
import calendar
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
    raw = None
    try:
        raw = client.messages.with_raw_response.create(
            model="standin-small", max_tokens=16, system=prompt,
            messages=[{"role": "user", "content": c["text"]}])
        h = raw.headers
        print(f"{time.monotonic() - start:5.1f}s {c['id']} {raw.parse().content[0].text:16} "
              f"remaining {h['anthropic-ratelimit-requests-remaining']}, full at {h['anthropic-ratelimit-requests-reset']}")
    except anthropic.RateLimitError as e:
        print(f"{time.monotonic() - start:5.1f}s {c['id']} 429, retry-after {e.response.headers['retry-after']}")
    if pace and raw is not None and raw.headers["anthropic-ratelimit-requests-remaining"] == "0":
        # out of requests: wait until the limit says it is full again
        reset = time.strptime(raw.headers["anthropic-ratelimit-requests-reset"], "%Y-%m-%dT%H:%M:%SZ")
        wait = max(0.0, calendar.timegm(reset) - time.time())
        print(f"       waiting {wait:.0f}s")
        time.sleep(wait)
```

```
ana@desk:~/desk$ python lab/burst.py
  0.2s c01 order-status     remaining 4, full at 2026-10-05T21:42:07Z
  0.4s c02 Refund           remaining 3, full at 2026-10-05T21:42:07Z
  0.6s c03 address-change   remaining 2, full at 2026-10-05T21:42:08Z
  0.8s c04 product-question remaining 1, full at 2026-10-05T21:42:08Z
  1.0s c05 other            remaining 0, full at 2026-10-05T21:42:08Z
  1.1s c06 429, retry-after 59
  1.1s c07 429, retry-after 59
  1.2s c08 429, retry-after 59
```

Cinco respostas em um segundo, cada uma dizendo quantas restam, depois três recusas. A contagem
chegou a 0 no `c05` e o programa mandou mais três assim mesmo: **a informação estava na resposta que
ele tinha acabado de ler.** Com `--pace`, o programa a lê:

```
ana@desk:~/desk$ python lab/burst.py --pace
  0.2s c01 order-status     remaining 4, full at 2026-10-05T21:42:09Z
  0.4s c02 Refund           remaining 3, full at 2026-10-05T21:42:09Z
  0.6s c03 address-change   remaining 2, full at 2026-10-05T21:42:10Z
  0.8s c04 product-question remaining 1, full at 2026-10-05T21:42:10Z
  1.0s c05 other            remaining 0, full at 2026-10-05T21:42:10Z
       waiting 60s
 61.4s c06 order-status     remaining 4, full at 2026-10-05T21:43:11Z
 61.6s c07 refund           remaining 3, full at 2026-10-05T21:43:11Z
 61.9s c08 address-change   remaining 2, full at 2026-10-05T21:43:11Z
```

Oito respostas e nenhuma recusa, em cerca de um minuto. O limite do substituto é um minuto
deslizante, então esperar pela hora do cabeçalho de reset é esperar as cinco voltarem; contra um
balde de verdade, a capacidade volta aos poucos e quem controla o ritmo pode mandar de novo mais
cedo. De um jeito ou de outro o princípio vale: **um programa que lê os cabeçalhos de limite espalha
as requisições; um que os ignora falha em rajadas** e se apoia nas novas tentativas, que a aula 17
mostrou que também contam no limite.

Para a classificação noturna de algumas centenas de e-mails da ana, isso é questão de poucas linhas.
Para uma mesa que cresce, é o motivo para pedir ao provedor um nível mais alto antes do dia mais
cheio, e não durante ele.
