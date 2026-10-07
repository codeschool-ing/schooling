---
title: Quanto você pode gastar
version: 1
---

Um limite de requisições limita a velocidade com que o dinheiro é gasto; um teto limita quanto.
Provedores definem um e deixam a conta definir um mais baixo. O da Anthropic, nas palavras dela:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-05
 233: Each of the Start, Build, and Scale tiers carries a monthly spend cap, which is the
      maximum your organization can spend on the API each calendar month. You can view your
      organization's monthly spend cap and set your own limit on the
 307: Enter a new value. Your spend limit cannot exceed your current tier's cap.
 311: You have reached your specified API usage limits
```

Um teto por nível, escolhido pelo provedor, e um limite de gasto abaixo dele, escolhido pela ana.
Passando de qualquer um, a API recusa com uma mensagem que diz isso e diz quando o acesso volta. O
teto existe para proteger o provedor e o saldo da conta; **o limite de gasto é o que a ana define
para se proteger**, e o valor certo dele é a estimativa mensal da aula 4 com folga para uma semana
ruim, não o teto do nível.

Um roteador acrescenta um mais estreito. A documentação do OpenRouter lista três fontes de limites de
crédito, e a segunda é a que importa para uma mesa com vários programas:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 130: 2. **Per-key credit limits**, an optional spending cap configured on an individual API
      key. The `limit`, `limit_reset`, and `limit_remaining` fields in the `GET /api/v1/key`
      response above describe this cap and how much of it remains.
```

**Um limite por chave.** A chave de um programa pode secar enquanto a de outro continua funcionando.
O lab define um limite de US$ 0,0005 na chave do OpenRouter da ana, e o `lab/or_spend.py` classifica
casos até a chave pará-lo, depois pergunta à chave quanto ela gastou:

```python
import json
import os

import httpx
from openai import OpenAI, APIStatusError

base, key = os.environ["OPENROUTER_BASE_URL"], os.environ["OPENROUTER_API_KEY"]
client = OpenAI(base_url=base, api_key=key)
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

for n, c in enumerate(cases, 1):
    try:
        r = client.chat.completions.create(model="standin/large", messages=[
            {"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
    except APIStatusError as e:
        print(f"request {n}: {e.status_code} {e.body['message']} ({e.body['metadata']['limit_source']})")
        break
info = httpx.get(f"{base}/key", headers={"Authorization": f"Bearer {key}"}).json()["data"]
print({k: info[k] for k in ("limit", "usage", "limit_remaining")})
```

```
ana@desk:~/desk$ python lab/or_spend.py
request 4: 402 This API key has reached its credit limit. (openrouter_key_limit)
{'limit': 0.0005, 'usage': 0.000696, 'limit_remaining': 0.0}
```

Três requisições rodaram, a quarta foi recusada com um 402 que diz a origem, e o relatório da própria
chave diz quanto foi gasto. Repare no `usage` contra o `limit`: **0,000696 gastos sob um limite de
0,0005.** O substituto confere o limite antes de cada requisição e cobra quando ela termina, então a
terceira começou abaixo do limite e terminou acima. A documentação do OpenRouter descreve estimar o
custo de cada requisição de antemão para estreitar exatamente essa folga, e nenhum teto, em lugar
nenhum, pode ser lido como promessa ao centavo. Um limite para a próxima requisição, não a que já
está rodando.
