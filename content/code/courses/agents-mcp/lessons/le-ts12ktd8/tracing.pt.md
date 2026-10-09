---
title: Rastros que ficam aqui
version: 2
---

O SDK registra um **rastro** para cada execução: uma árvore de spans, um para cada chamada de modelo, chamada de ferramenta, passagem e guardrail, com tempos. Por padrão ele os manda para os servidores da OpenAI, onde a plataforma os mostra num painel. O endereço está escrito na biblioteca (`https://api.openai.com/v1/traces/ingest`), e uma implantação que não pode mandar dados de conversa para esse serviço tem de desligar a exportação ou substituí-la. O `oa_run.py` a desligou; o `oa_trace.py` a substitui por um processador que imprime cada span nesta máquina.

```python
"""The SDK's tracing, kept on this machine: a processor that prints every span as it ends."""
import sys
from datetime import datetime

from agents import Agent, Runner, set_trace_processors
from agents.tracing import TracingProcessor

from oa_tools import get_order, search_help



class PrintSpans(TracingProcessor):
    def on_trace_start(self, trace):
        print(f"trace {trace.name!r}")

    def on_span_end(self, span):
        data = span.span_data.export()
        label = data.get("name") or data.get("model") or ""
        took = datetime.fromisoformat(span.ended_at) - datetime.fromisoformat(span.started_at)
        ms = int(took.total_seconds() * 1000)
        print(f"  {data['type']:10} {label:22} {ms} ms")

    def on_trace_end(self, trace): pass
    def on_span_start(self, span): pass
    def shutdown(self): pass
    def force_flush(self): pass


set_trace_processors([PrintSpans()])  # replaces the default exporter, which sends traces to OpenAI
agent = Agent(name="Marginalia support", model="llama3.2:3b", tools=[get_order, search_help],
              instructions="You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.")
Runner.run_sync(agent, sys.argv[1])
```

`set_trace_processors([...])` substitui os processadores padrão, o exportador incluído; `add_trace_processor` teria acrescentado um ao lado dele, e os spans continuariam sendo mandados.

```
ana@lab:~/agents$ python oa_trace.py "Where is my order M-1043?"
trace 'Agent workflow'
  response                          2056 ms
  function   get_order              1 ms
  custom     turn                   2061 ms
  response                          9375 ms
  custom     turn                   9377 ms
  agent      Marginalia support     11440 ms
  custom     task                   11440 ms
```

A mesma execução da seção 03, como o SDK a vê. Cada **turn** contém um span **response** (a chamada de modelo pela Responses API, que não traz nome de modelo para imprimir) e, quando o modelo pediu uma, um span **function** para a ferramenta. O span **agent** cobre a execução inteira, dentro de uma tarefa externa. Os números contam a mesma história do rastro da aula 7: `get_order` levou 1 ms, a primeira chamada de modelo 2056 ms, e a segunda 9375 ms, porque é ela que escreve a resposta, o trecho mais longo de escrita da execução.

A aula 7 escreveu o próprio rastro em umas quinze linhas e decidiu cada campo. Aqui a estrutura é do SDK, e mais rica (spans aninhados, um formato padrão que outras ferramentas entendem), e a decisão que sobra para você é para onde ele vai. Essa decisão não é cosmética: um span guarda a entrada e a saída do modelo, ou seja, mensagens de clientes e resultados de ferramentas. **Mandar rastros a um terceiro é mandar esses dados a ele.** Guarde-os onde ficam seus outros dados pessoais, ou decida de propósito, e por escrito, que eles podem sair.
