---
title: O que uma execução padrão manda
version: 2
---

A primeira execução usou o padrão, e a resposta levou dois pedidos. O `wire.py` lê o log do gravador e imprime, para cada pedido, quantas ferramentas ele ofereceu, os primeiros nomes e os tokens que o modelo leu:

```python
"""What each request in the recorder's log carried: tools offered, their names, and tokens in."""
import json

for n, line in enumerate(open("requests.jsonl"), 1):
    r = json.loads(line)
    tools = [t["name"] for t in r["request"].get("tools", [])]
    tokens_in = r["usage"].get("input_tokens", 0)
    print(f"request {n}: {len(tools):2} tools, {tokens_in:6} tokens in  {', '.join(tools[:6])}"
          + (", ..." if len(tools) > 6 else ""))
```

```
ana@lab:~/agents$ python wire.py
request 1: 23 tools,   4098 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
request 2: 23 tools,   4098 tokens in  Agent, Bash, CronCreate, CronDelete, CronList, Edit, ...
```

**23 ferramentas, e 4.098 tokens em cada pedido, para uma pergunta sobre um pedido.** Três das ferramentas são da loja. As outras vinte são do próprio Claude Code: `Bash`, `Edit`, `Read`, `Write`, `WebFetch`, uma ferramenta `Agent` para subagentes, ferramentas de agendamento e mais, cada uma com uma descrição longa escrita para um assistente de programação. O prompt de sistema foi o passado em `SYSTEM`, depois de duas linhas que o CLI acrescenta (um cabeçalho de cobrança e *"You are a Claude agent, built on Anthropic's Claude Agent SDK."*).

E 4.098 não é o que o CLI mandou. É o que o modelo leu. A aula 18 encontra o mesmo número pelo outro lado: com o contexto de 8.192 tokens da aula 1, o Ollama guarda 4.098 tokens de um prompt que não cabe, os primeiros e os últimos, e joga fora o meio sem avisar o cliente. O próprio log dele diz o que aconteceu aqui: um prompt de **12.247 tokens**, cortado para 4.098. O corte levou a pergunta junto, e o modelo respondeu com o que sobrou: execuções de CI, mensagens e skills são o assunto das descrições das ferramentas do Claude Code. Um fornecedor hospedado com uma janela grande teria lido os doze mil tokens, e cobrado por eles, em todo pedido.

Passar um prompt de sistema trocou o prompt, mas **não as ferramentas**. A opção que as controla é `tools`:

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python cs_run.py no-builtins "Where is my order M-1043?"
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
system     informational
assistant  Your order M-1043 has been placed on September 28, 2026. It is currently in the "shipped" status. The books are being shipped with the tracking number BR5512340003. You have ordered one book each from book IDs b13, b14, and b26. The total amount for the order is 11070 cents. There is no refund history for this order yet. Please keep the order tracking information for your records.
result     success turns=2 24934 ms cost_usd=0.0068 session=187ff694
ana@lab:~/agents$ python wire.py
request 1:  3 tools,    468 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
request 2:  3 tools,    699 tokens in  mcp__shop__get_order, mcp__shop__refund, mcp__shop__search_help
```

`tools=[]` remove toda ferramenta embutida. Agora o pedido inteiro coube: 468 tokens no primeiro, 699 no segundo, nada cortado, e o modelo consultou o M-1043 e respondeu sobre ele. A estimativa do próprio CLI foi de 0.0188 para 0.0068; contra um fornecedor que cobra os 12.247 tokens inteiros, a diferença seria bem maior.

Nem o custo nem uma janela pequena são o único motivo. Uma ferramenta oferecida ao agente é uma ferramenta que o modelo pode chamar: um agente que atende clientes tinha nas mãos um shell, um editor de arquivos e um buscador de páginas sem motivo nenhum, o oposto do privilégio mínimo de que trata a aula 17. **Decida a lista de ferramentas de propósito**, partindo do nada, como faz o `no-builtins`.
