---
title: Rastros que ficam aqui
version: 1
---

O SDK registra um **rastro** para cada execução: uma árvore de spans, um para cada chamada de modelo, chamada de ferramenta, passagem e guardrail, com tempos. Por padrão ele os manda para os servidores da OpenAI, onde a plataforma os mostra num painel. O endereço está escrito na biblioteca (`https://api.openai.com/v1/traces/ingest`), e uma implantação que não pode mandar dados de conversa para esse serviço tem de desligar a exportação ou substituí-la. O `oa_run.py` a desligou; o `oa_trace.py` a substitui por um processador que imprime cada span nesta máquina.

```python
"""The SDK's tracing, kept on this machine: a processor that prints every span as it ends."""
import sys
from datetime import datetime

from agents import Agent, Runner, set_default_openai_api, set_trace_processors
from agents.tracing import TracingProcessor

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")


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
agent = Agent(name="Marginalia support", model="scripted-1", tools=[get_order, search_help],
              instructions="You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.")
Runner.run_sync(agent, sys.argv[1])
```

`set_trace_processors([...])` substitui os processadores padrão, o exportador incluído; `add_trace_processor` teria acrescentado um ao lado dele, e os spans continuariam sendo mandados.

```
ana@lab:~/agents$ python oa_trace.py "Where is my order M-1043?"
trace 'Agent workflow'
  generation scripted-1             665 ms
  function   get_order              2 ms
  custom     turn                   671 ms
  generation scripted-1             569 ms
  function   search_help            386 ms
  custom     turn                   958 ms
  generation scripted-1             1777 ms
  custom     turn                   1783 ms
  agent      Marginalia support     3413 ms
  custom     task                   3414 ms
```

A mesma execução da seção 03, como o SDK a vê. Cada **turn** contém uma **generation** (a chamada de modelo, rotulada com o nome do modelo) e, quando o modelo pediu uma, um span **function** para a ferramenta. O span **agent** cobre a execução inteira, dentro de uma tarefa externa. Os números contam a mesma história do rastro da aula 7: `get_order` levou 2 ms, `search_help` 386 ms com o modelo de embeddings carregando, e a última generation 1777 ms porque a resposta é o trecho mais longo de escrita.

A aula 7 escreveu o próprio rastro em umas quinze linhas e decidiu cada campo. Aqui a estrutura é do SDK, e mais rica (spans aninhados, um formato padrão que outras ferramentas entendem), e a decisão que sobra para você é para onde ele vai. Essa decisão não é cosmética: um span guarda a entrada e a saída do modelo, ou seja, mensagens de clientes e resultados de ferramentas. **Mandar rastros a um terceiro é mandar esses dados a ele.** Guarde-os onde ficam seus outros dados pessoais, ou decida de propósito, e por escrito, que eles podem sair.
