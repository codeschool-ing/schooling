---
title: Quanto custa uma execução
version: 2
---

Um fornecedor cobra por tokens: os que lê (entrada) e os que escreve (saída), a preços diferentes por milhão, que variam por modelo e mudam com o tempo. O Ollama na sua própria máquina não cobra nada por token e paga em tempo, que esta aula também mede. Os preços ficam para a página de cada fornecedor, porque um preço escrito num curso já está velho quando alguém o lê.

O `cost_run.py` é o agente da aula 1 com uma fita métrica: as mesmas duas ferramentas, um prompt de sistema que leva os catorze artigos de ajuda da Marginalia como política, e uma linha por pedido com os tokens de entrada e de saída e o tempo que levou.

```python
"""One agent run, measured: tokens and time per request, per tool, and in total."""
import argparse
import json
import time

import anthropic

import shop

parser = argparse.ArgumentParser()
parser.add_argument("model")
parser.add_argument("--cache", action="store_true", help="mark the policy as a cacheable prefix")
parser.add_argument("--stamp", action="store_true", help="put the current time at the top of the system prompt")
args = parser.parse_args()

POLICY = "\n\n".join(f"## {a['title']}\n{a['body']}" for a in map(json.loads, open("data/help.jsonl")))
SYSTEM = [{"type": "text", "text": "You answer Marginalia's customers in the cost lesson. Use the tools; never guess."},
          {"type": "text", "text": "Marginalia's policies, which every answer must respect:\n\n" + POLICY}]
if args.stamp:                                    # a value that changes on every request, at the very front
    SYSTEM.insert(0, {"type": "text", "text": ""})
if args.cache:                                    # everything up to here is the same on every request
    SYSTEM[-1]["cache_control"] = {"type": "ephemeral"}
TOOLS = [
    {"name": "get_order", "description": "Look up one Marginalia order by its id, M- and four digits.",
     "input_schema": {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}},
    {"name": "search_help", "description": "Search Marginalia's help centre by meaning.",
     "input_schema": {"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]}},
]
RUN = {"get_order": lambda a: shop.get_order(a["order_id"]),
       "search_help": lambda a: [x["title"] for x in shop.search_help(a["query"])]}

client = anthropic.Anthropic()
messages = [{"role": "user", "content": "Where is my order M-1043?"}]
totals = {"input": 0, "cache_write": 0, "cache_read": 0, "output": 0}
start = time.perf_counter()
print("step   input  c.write  c.read  output     ms  stop")
for step in range(1, 7):
    if args.stamp:
        SYSTEM[0]["text"] = f"Request sent at {time.time():.3f}."
    t0 = time.perf_counter()
    reply = client.messages.create(model=args.model, max_tokens=1024, system=SYSTEM, tools=TOOLS, messages=messages)
    ms = (time.perf_counter() - t0) * 1000
    u = reply.usage
    row = {"input": u.input_tokens, "cache_write": u.cache_creation_input_tokens or 0,
           "cache_read": u.cache_read_input_tokens or 0, "output": u.output_tokens}
    for k in totals:
        totals[k] += row[k]
    print(f"{step:4} {row['input']:7} {row['cache_write']:8} {row['cache_read']:7} {row['output']:7} {ms:6.0f}  {reply.stop_reason}")
    messages.append({"role": "assistant", "content": reply.content})
    calls = [b for b in reply.content if b.type == "tool_use"]
    if not calls:
        break
    results = []
    for call in calls:
        t0 = time.perf_counter()
        print(f"       tool {call.name} {json.dumps(call.input)}", end="", flush=True)
        out = json.dumps(RUN[call.name](call.input))
        print(f": {(time.perf_counter() - t0) * 1000:.0f} ms")
        results.append({"type": "tool_result", "tool_use_id": call.id, "content": out})
    messages.append({"role": "user", "content": results})
print(f"total {totals['input']:7} {totals['cache_write']:8} {totals['cache_read']:7} {totals['output']:7} "
      f"{(time.perf_counter() - start) * 1000:6.0f}")
```

```
ana@lab:~/agents$ python cost_run.py llama3.2:3b
step   input  c.write  c.read  output     ms  stop
   1     994        0      15      16  10447  tool_use
       tool search_help {"query": "M-1043"}: 166 ms
   2      65        0     847      67   8629  end_turn
total    1059        0     862      83  19242
```

As colunas vêm do `usage` da resposta, no formato da API da Anthropic. **`input`** é a entrada que o modelo leu do zero; **`c.read`** é entrada que ele não precisou ler de novo, porque o Ollama ainda a guardava do pedido anterior; **`c.write`** é o que um fornecedor informa quando guarda um prefixo a pedido, e o Ollama nunca informa isso, então a coluna fica em zero aqui. Os tempos são desta máquina: uma CPU, sem mais nada rodando. Os seus vão ser outros, e também as palavras do modelo e até a escolha da ferramenta: perguntado sobre o pedido, ele buscou *"M-1043"* na central de ajuda em vez de consultar o pedido. Uma execução é uma amostra, e as próximas seções são mais três delas.

A resposta levou **dois pedidos**. O primeiro leu 994 tokens e escreveu 16; o segundo leu 65 tokens novos além dos 847 que reaproveitou, e escreveu a resposta de 67 tokens. Cada pedido levou tudo o que veio antes: as ferramentas, o prompt de sistema com as políticas e a conversa até ali. A aula 1 disse isso numa frase: a API não guarda nada, então o que o modelo precisa lembrar viaja em todo pedido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 140\" role=\"img\" aria-label=\"Os dois pedidos de uma execução, como barras de tokens de entrada. O primeiro leu 994 tokens e reaproveitou 15. O segundo reaproveitou 847 tokens que o Ollama guardou do primeiro, entre eles o prompt de sistema com as políticas, e leu só 65 novos.\"><defs></defs><text x=\"20\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido 1</text><rect x=\"110\" y=\"30\" width=\"8\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"117\" y=\"30\" width=\"447\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"127\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lidos: 994</text><text x=\"577\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reaproveitados: 15</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido 2</text><rect x=\"110\" y=\"85\" width=\"381\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reaproveitados: 847</text><rect x=\"491\" y=\"85\" width=\"29\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lidos: 65</text></svg>", "caption": "Quase todo o segundo pedido é texto que o modelo já tinha lido."}
```

Daí saem duas coisas. **A parte fixa domina**: as políticas são a maior parte de cada pedido, e a conversa acrescentou só 65 tokens no segundo. E **a entrada cresce a cada passo**, então um agente que dá dez passos paga pelos primeiros turnos dez vezes. Aqui o reaproveitamento escondeu a maior parte desse custo, e as próximas seções mostram quando ele esconde e quando não.
