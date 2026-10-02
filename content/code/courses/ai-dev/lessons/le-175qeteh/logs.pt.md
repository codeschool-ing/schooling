---
title: O log também é uma cópia
version: 1
---

Toda requisição que vale fazer vale registrar: que modelo, quantos tokens, por que parou, para a
conta e os incidentes poderem ser explicados depois. **Um log que guarda o prompt guarda uma cópia de
tudo o que está nele**, pelo tempo que os logs forem guardados, legível por todo mundo que lê logs.

```python
"""A log line for every request: enough to answer for it, nothing that repeats the customer."""
import hashlib
import json
import logging

import anthropic

log = logging.getLogger("llm")


def ask(messages, **kw):
    r = anthropic.Anthropic().messages.create(messages=messages, **kw)
    text = json.dumps(messages, sort_keys=True).encode()
    log.info(json.dumps({"id": r.id, "model": r.model, "in": r.usage.input_tokens,
                         "out": r.usage.output_tokens, "stop": r.stop_reason,
                         "prompt_sha256": hashlib.sha256(text).hexdigest()[:16]}))
    return r
```

```
ana@dev:~/shop$ python triage_logged.py data/emails/3.txt
httpx2 HTTP Request: POST http://127.0.0.1:8400/v1/messages "HTTP/1.1 200 OK"
llm {"id": "msg_lab_0004", "model": "scripted-1", "in": 40, "out": 26, "stop": "end_turn", "prompt_sha256": "d879892869f999c0"}
The checkout code E1042 means the payment timed out and no money was taken. The customer can try again in a minute.
```

A linha `llm` diz o que aconteceu e nada do que o cliente escreveu. **O id da requisição a liga aos
registros do próprio provedor**; os tokens explicam a conta; o hash diz se duas requisições tinham o
mesmo prompt, o que basta para achar uma repetição ou um laço, sem guardar o prompt.

## A linha que ninguém pediu

A primeira linha veio da biblioteca HTTP de dentro do SDK. **O `basicConfig(level=logging.INFO)`
ligou as mensagens informativas de toda biblioteca, não só as suas**, e esta registra toda URL que
chama. Aqui isso é inofensivo; uma biblioteca que registrasse o corpo das requisições no mesmo nível
poria o e-mail do cliente de volta no log por uma porta que você não sabia que estava aberta.

- **Defina níveis por logger**: `logging.getLogger("llm").setLevel(logging.INFO)` para o seu, só
  avisos para o resto.
- **Leia um dia de logs reais** depois de qualquer mudança no logging, procurando o que não deveria
  estar lá.

## Quando você precisa do conteúdo

Depurar uma resposta ruim às vezes exige o prompt. **Guarde-o em outro lugar**: um armazenamento
separado, com retenção curta, lido por menos gente, escrito só para as requisições que você
escolher, e redigido como na aula 11 seção 03 antes de ser escrito.
