---
title: Um cache que você precisa conferir
version: 1
---

A seção 05 da aula 6 leu quanto custa o cache de prompt: gravar um prefixo em cache custa um quarto a
mais que a entrada comum, ler de volta custa um décimo, e abaixo de um tamanho mínimo nada vai para o
cache. Aqui está como uma requisição pede o cache, e como saber se conseguiu. A documentação é direta
sobre a segunda parte:

```
# https://platform.claude.com/docs/en/build-with-claude/prompt-caching, read 2026-10-05
 786: Shorter prompts cannot be cached, even if marked with
 788: . Any requests to cache fewer than this number of tokens will be processed without
      caching, and no error is returned. To verify whether a prompt was cached, check the
```

Uma requisição marca o fim do prefixo que quer em cache com `cache_control` num bloco. O
`lab/cache.py` manda o prompt de triagem da ana marcado assim, depois o mesmo prompt com trinta e
nove exemplos resolvidos acrescentados, duas vezes. O mínimo do substituto para o `standin-large` é
de 1.024 tokens, o mesmo do Sonnet 4.5:

```python
import json

import anthropic

client = anthropic.Anthropic()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]
examples = "".join(f"E-mail: {c['text']}\nLabel: {c['label']}\n\n" for c in cases[:39])


def sort(system, label):
    r = client.messages.create(
        model="standin-large", max_tokens=16,
        system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": cases[39]["text"]}])
    u = r.usage
    print(f"{label:22} written {u.cache_creation_input_tokens:4}  read {u.cache_read_input_tokens:4}  "
          f"uncached {u.input_tokens:3}  -> {r.content[0].text}")


sort(prompt, "prompt alone")
sort(prompt + "\nExamples:\n\n" + examples, "with 39 examples")
sort(prompt + "\nExamples:\n\n" + examples, "the same, again")
```

```
ana@desk:~/desk$ python lab/cache.py
prompt alone           written    0  read    0  uncached  60  -> order-status
with 39 examples       written 1104  read    0  uncached  24  -> order-status
the same, again        written    0  read 1104  uncached  24  -> order-status
```

Três linhas, três resultados:

- **O prompt sozinho** foi marcado para cache e tem 60 tokens. Nada foi gravado e nada lido, a
  requisição deu certo, e a conta foi de entrada comum. Esse é o caso silencioso.
- **Com os exemplos** o prefixo tem 1.104 tokens, acima do mínimo, e foi **gravado**: 1.104 tokens ao
  preço de gravação, mais 24 que vêm depois da marca.
- **O mesmo de novo**, dentro de cinco minutos, e os 1.104 foram **lidos** a um décimo do preço.

Repare no que `input_tokens` quer dizer aqui: só os tokens **depois** do prefixo em cache. O total
lido pelo modelo é a soma dos três números, e um relatório de custo que usasse só o `input_tokens`
contaria a menos toda requisição com cache.

Quanto isso vale aos preços do Sonnet 4.5, na entrada:

```
ana@desk:~/desk$ sheet show claude-sonnet-4-5 | grep -E "^(input_cost_per_token|cache_creation_input_token_cost|cache_read_input_token_cost|prompt_cache_min_tokens) "
cache_creation_input_token_cost            3.75e-06
cache_read_input_token_cost                3e-07
input_cost_per_token                       3e-06
prompt_cache_min_tokens                    1024
```

```
ana@desk:~/desk$ python -c "print(f\"uncached {1128 * 3e-6 * 1000:.2f}  cached {(1104 * 3e-7 + 24 * 3e-6) * 1000:.2f}  dollars per 1,000 e-mails, input only\")"
uncached 3.38  cached 0.40  dollars per 1,000 e-mails, input only
```

Oito vezes mais barato na entrada, para o prompt longo. Sem cache, os exemplos fariam cada requisição
custar dezenove vezes o prompt sozinho, US$ 3,38 por mil e-mails contra US$ 0,18; com cache, cerca do
dobro, US$ 0,40. Se os exemplos melhoram a *classificação* é pergunta da aula 5, não do cache: **um
cache deixa um prompt longo barato; não o deixa certo.** E a vida de cinco minutos quer dizer que uma
mesa que recebe um e-mail a cada poucos minutos mantém o cache quente, enquanto uma noite tranquila o
deixa expirar e paga a gravação de novo de manhã.
