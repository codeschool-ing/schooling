---
title: Um rastro com tempos
version: 2
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
answered after 2 steps, 672 tokens
I apologize for the error. It looks like the order ID "M1047" does not match the expected format of "M-YYYY". Could you please try again with a different order ID, or provide the full order details so I can assist you further?
  step 1: model 6033 ms, 434 in / 18 out; get_order ERROR 0 ms
  step 2: model 6621 ms, 166 in / 54 out
```

A resposta é o fim, e aqui ela é ruim: o modelo pede ao cliente um id diferente e descreve o formato como "M-YYYY". O rastro é como se chegou lá, e com tempos ele diz para onde o tempo foi:

- **Passo 1: o esquema fez o seu trabalho.** `get_order ERROR 0 ms`: `M1047` falhou no padrão antes de qualquer função rodar, e por isso não levou tempo nenhum. A metade do modelo no passo levou 6033 ms para 18 tokens de saída, a maior parte lendo um prompt de 434 tokens em quatro processadores.
- **Passo 2: nenhuma chamada corrigida.** O erro voltou ao modelo, que não conseguiu chamar de novo (a seção 07 da aula 1) e respondeu no lugar disso, em 6621 ms. Um modelo que consegue chamar de novo faz a correção neste passo, como os testes da seção 09 mostram com um modelo falso.

Os dois números a guardar são para onde o tempo foi, o modelo e não as ferramentas, e o pouco que as ferramentas precisaram. As outras execuções dizem o mesmo: a resposta do reembolso levou 14626 ms para 139 tokens, a do rastreio 14249 ms para 116. **A escrita do modelo domina a execução**, aqui e com qualquer fornecedor: respostas longas custam tempo na proporção do tamanho.

A coluna de entrada é menor no passo 2 do que no passo 1, 166 contra 434, embora o passo 2 carregue tudo o que o passo 1 carregava. A aula 1 descobriu por quê: o template deste modelo deixa de fora as definições de ferramenta quando um resultado de ferramenta é a última mensagem.

## O arquivo por trás

O `trace.jsonl` ganha uma linha por passo, anexada durante a execução. Depois das três execuções desta aula ele tem seis, e a última é a resposta à pergunta sobre o rastreio:

```
ana@lab:~/agents$ wc -l trace.jsonl
6 trace.jsonl
ana@lab:~/agents$ tail -n 1 trace.jsonl
{"step": 2, "stop": "end_turn", "tokens_in": 275, "tokens_out": 116, "model_ms": 14249, "text": "I've located your parcel, M-1043. According to the tracking information, your parcel has the tracking number BR5512340003. The current status of your parcel is \"shipped\", and it was placed on September 28, 2026. You can track the status of your parcel by visiting the tracking website and entering the tracking number. Please note that the parcel has not been delivered yet, and the delivery date is not specified. You can check the latest updates on the status of your parcel by visiting the tracking website or contacting our customer service team.", "calls": []}
```

Todo campo de que uma pessoa depurando a execução precisa está lá: qual passo, por que o modelo parou, os tokens de cada lado, o tempo do modelo, o que ele disse, e cada chamada com seus argumentos, se falhou, quanto levou e os primeiros 120 caracteres do que voltou. A aula 3 disse o que um rastro deve guardar; este guarda isso com tempos, o que transforma *"o agente está lento"* num passo e numa ferramenta.

Duas cautelas da aula 3 continuam valendo. Um rastro é dado sobre clientes, e o `result` copia parte da saída de cada ferramenta para um arquivo, então ele precisa do mesmo cuidado que qualquer outro log de dados pessoais. E os tempos são desta execução, nesta máquina: um modelo pequeno em quatro processadores, e ferramentas que variam com o que mais a máquina está fazendo. São evidência sobre esta execução e não um benchmark.
