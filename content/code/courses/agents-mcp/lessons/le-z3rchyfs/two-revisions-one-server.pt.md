---
title: Duas revisões, um servidor
version: 1
---

O `said.py` lê os três arquivos que o `tee` escreveu e imprime o método de cada mensagem e, quando a mensagem nomeia uma, a versão do protocolo:

```python
"""What each host's MCP client said to the server, one line per message."""
import json
import sys

for host in sys.argv[1:]:
    print(host)
    for line in open(f"{host}.in.jsonl"):
        m = json.loads(line)
        p = m.get("params", {})
        version = p.get("protocolVersion") or p.get("_meta", {}).get("io.modelcontextprotocol/protocolVersion", "")
        print(f"  {m['method']:28} {version}")
```

```
ana@lab:~/agents$ python said.py openai claude google
openai
  server/discover              2026-07-28
  tools/list                   2026-07-28
  tools/call                   2026-07-28
  tools/list                   2026-07-28
claude
  initialize                   2025-11-25
  notifications/initialized    
  tools/list                   
  prompts/list                 
  resources/list               
  tools/call                   
google
  initialize                   2025-11-25
  notifications/initialized    
  tools/list                   
  tools/call                   
```

**Os três clientes não falaram o mesmo protocolo.** O cliente do SDK da OpenAI, que é o do próprio SDK `mcp`, começou com `server/discover` e pôs a versão `2026-07-28` em todo pedido. O CLI do Claude Code e o ADK começaram com `initialize`, versão `2025-11-25`, seguido de `notifications/initialized`. O servidor respondeu aos dois, então os três hospedeiros funcionaram.

A especificação do MCP é publicada em **revisões datadas**. A revisão de 2026-07-28 tornou o protocolo **sem estado**: não há handshake, e todo pedido leva a versão do protocolo e as capacidades do cliente no próprio `_meta`. Um servidor tem de implementar `server/discover`, que diz que versões e capacidades ele suporta. A especificação chama as revisões com handshake (2025-11-25 e anteriores) de **legadas**, as mais novas de **modernas**, e uma implementação que fala as duas de **duas eras** (*dual-era*); o servidor do `mcp` 2.3.0 é de duas eras, e é por isso que os dois clientes mais velhos ainda funcionaram. A sessão que a aula 7 de `ai-dev` digitou à mão usava uma revisão legada anterior, 2025-06-18, com o mesmo `initialize`.

A consequência prática é a que este curso repete: **uma versão de protocolo é um fato sobre cada par, e você o descobre olhando.** Um hospedeiro feito há um ano e um servidor feito hoje podem se encontrar na revisão mais velha, e alguns recursos só existem de um lado dessa linha. A aula 13 lê os dois tipos de troca mensagem por mensagem.

Mais uma linha da captura merece atenção. O cliente do Claude Code pediu `prompts/list` e `resources/list` além das ferramentas, embora este servidor não ofereça nenhum dos dois, enquanto os outros dois pediram só ferramentas. O que um cliente pede é decisão do hospedeiro, que é o assunto da seção 06.
