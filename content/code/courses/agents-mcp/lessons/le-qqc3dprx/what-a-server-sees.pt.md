---
title: O que um servidor vê
version: 2
---

A outra metade do princípio é o que um servidor recebe. O servidor `orders` foi iniciado com o `tee` (o truque da aula 11, `orders:tee` no `hosts.py`) enquanto cada hospedeiro respondia *"Where is my order M-1043?"*. O `said.py` imprime o método de cada mensagem e o que o cliente declarou, e para a chamada de ferramenta, os argumentos e qualquer `_meta` além dos campos do próprio protocolo:

```python
"""What each server's client sent it: the method, and anything the client declared about itself."""
import json
import sys

for name in sys.argv[1:]:
    print(name)
    for line in open(f"{name}.in.jsonl"):
        m = json.loads(line)
        p = m.get("params", {})
        meta = p.get("_meta", {})
        extra = p.get("capabilities", meta.get("io.modelcontextprotocol/clientCapabilities", ""))
        if m["method"] == "tools/call":
            extra = {"arguments": p["arguments"], "_meta": {k: v for k, v in meta.items() if "/protocolVersion" not in k
                                                          and "/clientInfo" not in k and "/clientCapabilities" not in k}}
        print(f"  {m['method']:26} {json.dumps(extra) if extra != '' else ''}")
```

```
ana@lab:~/agents$ python said.py OpenAI Claude Google
OpenAI
  server/discover            {}
  tools/list                 {}
  tools/call                 {"arguments": {"order_id": "M-1043"}, "_meta": {}}
  tools/list                 {}
Claude
  initialize                 {"roots": {"listChanged": true}, "elicitation": {}}
  notifications/initialized  
  tools/list                 
  prompts/list               
  resources/list             
  tools/call                 {"arguments": {"order_id": "M-1043"}, "_meta": {"claudecode/toolUseId": "call_r5k7x8tt", "progressToken": 4}}
Google
  initialize                 {}
  notifications/initialized  
  tools/list                 
  tools/call                 {"arguments": {"order_id": "M-1043"}, "_meta": {}}
```

**O servidor nunca recebeu a mensagem do cliente.** Ele recebeu um pedido de lista e uma chamada com `{"order_id": "M-1043"}`. Que palavras o cliente usou, o que mais havia na conversa, o que o modelo disse depois: nada disso chegou ao servidor, com nenhum dos três hospedeiros. É o princípio se sustentando, e ele se sustenta porque o hospedeiro só manda a um servidor o que o protocolo pede. Um hospedeiro poderia pôr mais nos argumentos; um servidor só consegue pedir, pelo esquema de entrada, o que precisa.

O hospedeiro do Claude acrescentou dois campos ao `_meta` da chamada: `claudecode/toolUseId`, o id da chamada de ferramenta do modelo, e um `progressToken`, que deixa um servidor informar o progresso de uma chamada longa. Nenhum dos dois leva conversa; os dois são o hospedeiro dizendo um pouco sobre si.

As primeiras mensagens são os clientes **declarando capacidades**. O cliente do Claude declarou `roots` e `elicitation`: que consegue dizer a um servidor que diretórios ele pode usar, e que consegue fazer uma pergunta à pessoa em nome de um servidor. O cliente do Google não declarou nada. A lista do cliente da OpenAI está vazia em todo pedido. Um servidor lê isso para saber o que pode pedir; um servidor que precisa da confirmação de uma pessoa não a consegue de um cliente que não declarou elicitation. (Roots está obsoleto na revisão 2026-07-28, como a aula 11 listou; este cliente falava 2025-11-25.)
