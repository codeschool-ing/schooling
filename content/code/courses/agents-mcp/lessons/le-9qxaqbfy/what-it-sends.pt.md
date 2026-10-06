---
title: O que uma execução padrão manda
version: 1
---

A primeira execução usou o padrão, e a resposta levou dois pedidos. O `wire.py` lê o log do labllm e imprime, para cada pedido, quantas ferramentas ele ofereceu, os primeiros nomes e os tokens que levou:

```python
"""What each request in labllm's log carried: tools offered, their names, and tokens in."""
import json

for n, line in enumerate(open("/var/log/labllm/requests.jsonl"), 1):
    r = json.loads(line)
    tools = [t["name"] for t in r["request"].get("tools", [])]
    u = r["usage"]
    tokens_in = u["input_tokens"] + u.get("cache_creation_input_tokens", 0) + u.get("cache_read_input_tokens", 0)
    print(f"request {n}: {len(tools):2} tools, {tokens_in:6} tokens in  {', '.join(tools[:6])}"
          + (", ..." if len(tools) > 6 else ""))
```

```
ana@lab:~/agents$ python wire.py
request 1: 23 tools,  13531 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
request 2: 23 tools,  13713 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
```

**23 ferramentas e 13.531 tokens, para uma pergunta sobre um pedido.** Três das ferramentas são da loja. As outras vinte são do próprio Claude Code: `Bash`, `Edit`, `Read`, `Write`, `WebFetch`, uma ferramenta `Agent` para subagentes, ferramentas de agendamento e mais, cada uma com uma descrição longa escrita para um assistente de programação. O prompt de sistema foi o passado em `SYSTEM`, depois de duas linhas que o CLI acrescenta (um cabeçalho de cobrança e *"You are a Claude agent, built on Anthropic's Claude Agent SDK."*); a maior parte dos tokens são as definições de ferramentas.

Passar um prompt de sistema trocou o prompt, mas **não as ferramentas**. A opção que as controla é `tools`:

```
ana@lab:~/agents$ python cs_run.py no-builtins "Where is my order M-1043?"
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
system     informational
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
assistant  Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
result     success turns=2 1723 ms cost_usd=0.0047 session=d19656ec
ana@lab:~/agents$ python wire.py
request 1:  3 tools,    399 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
request 2:  3 tools,    581 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
```

`tools=[]` remove toda ferramenta embutida. A mesma resposta levou 399 tokens no primeiro pedido e 581 no segundo, contra 13.531 e 13.713. A estimativa de custo do próprio CLI foi de 0.1370 para 0.0047, umas 29 vezes menos, pelas mesmas duas chamadas e a mesma resposta.

O custo não é o único motivo. Uma ferramenta oferecida ao agente é uma ferramenta que o modelo pode chamar: um agente que atende clientes tinha nas mãos um shell, um editor de arquivos e um buscador de páginas sem motivo nenhum, o oposto do privilégio mínimo de que trata a aula 17. **Decida a lista de ferramentas de propósito**, partindo do nada, como faz o `no-builtins`.
