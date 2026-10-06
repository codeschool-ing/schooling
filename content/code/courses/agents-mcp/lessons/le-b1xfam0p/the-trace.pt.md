---
title: Um rastro com tempos
version: 1
---

O `run.py` imprime o resultado e depois uma linha por passo a partir do rastro:

```python
"""Run minagent on one customer message and print the outcome, then the trace."""
import json
import sys

from marginalia import TOOLS
from minagent import Agent, AnthropicModel

SYSTEM = ("You are Marginalia's support agent, built with minagent. Use the tools to find facts, "
          "correct a call when a tool returns an error, and then answer the customer.")

agent = Agent(AnthropicModel(), SYSTEM, TOOLS, max_steps=6, trace_path="trace.jsonl")
outcome = agent.run(sys.argv[1])
print(f"{outcome.status} after {outcome.steps} steps, {outcome.tokens} tokens")
print(outcome.answer or outcome.reason)
for r in outcome.trace:
    calls = ", ".join(f"{c['tool']}{' ERROR' if c['error'] else ''} {c['ms']} ms" for c in r["calls"])
    print(f"  step {r['step']}: model {r['model_ms']} ms, {r['tokens_in']} in / {r['tokens_out']} out"
          + (f"; {calls}" if calls else ""))
```

Um cliente pergunta sobre devolver *Drácula* e digita o id do pedido sem o hífen:

```
ana@lab:~/agents$ python run.py "Can I return the copy of Dracula I bought in September? My order is M1047."
answered after 4 steps, 2401 tokens
Yes. Order M-1047 was delivered on 18 September 2026, and printed books can be returned within 30 days of delivery, so you have until 18 October. Start the return from the order in your account; the label is prepaid and returns are free.
  step 1: model 602 ms, 433 in / 9 out; get_order ERROR 0 ms
  step 2: model 647 ms, 474 in / 10 out; get_order 1 ms
  step 3: model 567 ms, 597 in / 8 out; search_help 1053 ms
  step 4: model 2488 ms, 813 in / 57 out
```

A resposta é o fim. O rastro é como se chegou lá, e com tempos ele diz para onde o tempo foi:

- **Passo 1: o esquema fez o seu trabalho.** `get_order ERROR 0 ms`: `M1047` falhou no padrão antes de qualquer função rodar, e por isso não levou tempo nenhum. A metade do modelo no passo levou 602 ms para 9 tokens de saída.
- **Passo 2: a chamada corrigida.** `get_order` com `M-1047`, 1 ms: uma consulta SQLite num arquivo pequeno.
- **Passo 3: a busca.** O `search_help` levou 1053 ms, a ferramenta mais lenta da execução, e a maior parte disso é carregar o modelo de embeddings num processo novo antes de comparar a consulta com quarenta artigos. Na execução seguinte, o reembolso da seção 06, o mesmo tipo de busca levou 331 ms, muito provavelmente porque os arquivos do modelo já estavam no cache do sistema operacional.
- **Passo 4: a resposta.** 2488 ms para 57 tokens de saída. **A escrita do modelo domina a execução**: pela regra do labllm de 200 ms mais 40 ms por token, e com qualquer fornecedor real, respostas longas custam tempo na proporção do tamanho.

A coluna de entrada cresceu de 433 para 813 tokens em quatro passos, o crescimento que a aula 1 mediu, e o total de 2401 tokens é o que a aula 18 transforma em dinheiro.

## O arquivo por trás

O `trace.jsonl` ganha uma linha por passo, anexada durante a execução. Depois das três execuções desta aula ele tem onze, e a última é o terceiro passo da execução travada:

```
ana@lab:~/agents$ wc -l trace.jsonl
11 trace.jsonl
ana@lab:~/agents$ tail -n 1 trace.jsonl
{"step": 3, "stop": "tool_use", "tokens_in": 504, "tokens_out": 10, "model_ms": 647, "text": "", "calls": [{"tool": "parcel_status", "args": {"order_id": "M-1043"}, "error": true, "ms": 0, "result": "unknown tool 'parcel_status'; the tools are get_order, search_help, find_books, refund"}]}
```

Todo campo de que uma pessoa depurando a execução precisa está lá: qual passo, por que o modelo parou, os tokens de cada lado, o tempo do modelo, o que ele disse, e cada chamada com seus argumentos, se falhou, quanto levou e os primeiros 120 caracteres do que voltou. A aula 3 disse o que um rastro deve guardar; este guarda isso com tempos, o que transforma *"o agente está lento"* num passo e numa ferramenta.

Duas cautelas da aula 3 continuam valendo. Um rastro é dado sobre clientes, e o `result` copia parte da saída de cada ferramenta para um arquivo, então ele precisa do mesmo cuidado que qualquer outro log de dados pessoais. E os tempos são desta execução: os do modelo vêm da regra do labllm, e os das ferramentas variam com o que mais a máquina está fazendo, então são evidência sobre esta execução e não um benchmark.
