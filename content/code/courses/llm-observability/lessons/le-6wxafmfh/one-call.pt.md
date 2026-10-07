---
title: Um span em volta de uma chamada
version: 2
---

Um **span** é o registro de uma operação: um nome, quando começou e terminou, se falhou, e atributos,
que são pares chave-valor dizendo do que ela tratava. Um **trace** são os spans de um trabalho, presos
uns aos outros pelo id de trace que compartilham, cada um apontando para o seu pai. A aula 2 do
`observability` os constrói em geral, com o SDK do OpenTelemetry; este curso usa o mesmo SDK e
pergunta o que há de particular num span cuja operação é uma chamada a um modelo.

Comece pelo caso menor: uma chamada, um span, escrito no terminal quando termina.

```schooling-example
{
  "language": "python",
  "file": "one_call.py",
  "parts": [
    {
      "code": "\"\"\"one_call.py: one model call, with a span around it, printed to the terminal when it ends.\"\"\"\nfrom openai import OpenAI\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"one_call\")\n\n",
      "note": "As três partes do SDK: um provider que cria spans, um processor que repassa cada span terminado, e um exporter que o escreve em algum lugar. Aqui, no terminal, um span de cada vez."
    },
    {
      "code": "client = OpenAI()\nwith tracer.start_as_current_span(\"chat llama3.2:3b\") as span:\n    span.set_attribute(\"gen_ai.operation.name\", \"chat\")\n    span.set_attribute(\"gen_ai.request.model\", \"llama3.2:3b\")\n",
      "note": "O span abre antes que o pedido saia, então a sua duração inclui a espera pelo modelo. O nome e os dois primeiros atributos dizem o que foi pedido, antes que exista qualquer resposta."
    },
    {
      "code": "    reply = client.chat.completions.create(\n        model=\"llama3.2:3b\", temperature=0,\n        messages=[{\"role\": \"user\", \"content\": \"How long is a Marginalia gift card valid?\"}])\n",
      "note": "A chamada em si. A pergunta cita a loja, e mais nada: nenhum documento vai junto."
    },
    {
      "code": "    span.set_attribute(\"gen_ai.response.model\", reply.model)\n    span.set_attribute(\"gen_ai.response.finish_reasons\", [reply.choices[0].finish_reason])\n    span.set_attribute(\"gen_ai.usage.input_tokens\", reply.usage.prompt_tokens)\n    span.set_attribute(\"gen_ai.usage.output_tokens\", reply.usage.completion_tokens)\nprint(reply.choices[0].message.content)\n",
      "note": "O que voltou: qual modelo respondeu, por que parou, e os tokens de cada lado, lidos do `usage` da resposta. O span fecha no fim do bloco, e o exporter o imprime."
    }
  ]
}
```

```
ana@dev:~/obs$ python one_call.py
{
    "name": "chat llama3.2:3b",
    "context": {
        "trace_id": "0x4180c8f065f602f38fb728f61f5a079f",
        "span_id": "0x9dd954745af919d3",
        "trace_state": "[]"
    },
    "kind": "SpanKind.INTERNAL",
    "parent_id": null,
    "start_time": "2026-10-07T23:47:44.760014Z",
    "end_time": "2026-10-07T23:47:56.454514Z",
    "status": {
        "status_code": "UNSET"
    },
    "attributes": {
        "gen_ai.operation.name": "chat",
        "gen_ai.request.model": "llama3.2:3b",
        "gen_ai.response.model": "llama3.2:3b",
        "gen_ai.response.finish_reasons": [
            "stop"
        ],
        "gen_ai.usage.input_tokens": 36,
        "gen_ai.usage.output_tokens": 75
    },
    "events": [],
    "links": [],
    "resource": {
        "attributes": {
            "telemetry.sdk.language": "python",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.version": "1.45.0",
            "service.instance.id": "932c115f-77a5-4a12-962c-e4c90052f169",
            "service.name": "unknown_service:python"
        },
        "schema_url": ""
    }
}
I couldn't find any information on a gift card called "Marginalia." It's possible that it's a lesser-known or regional gift card, or it may be a misspelling or incorrect name.

If you could provide more context or clarify the name of the gift card, I'd be happy to try and help you find the information you're looking for.
```

Tudo nesse registro é algo que uma linha de log também poderia dizer, menos duas coisas: o **id de
trace e o id de span**, que deixam este span ser encontrado e ligado a outros, e os **horários de
início e de fim**, que estão a 11,7 segundos um do outro. Essa é a chamada ao modelo inteira, da
saída do pedido à leitura da resposta, e desta vez a maior parte dela foi o Ollama carregando o
modelo na memória: era a primeira pergunta feita ao servidor desde que ele subiu. Os traces da seção
07 mostram quanto leva uma chamada comum.

## Nomes que outra pessoa escolheu

Os nomes dos atributos não são deste curso. São as **convenções semânticas do OpenTelemetry para IA
generativa**, o espaço de nomes `gen_ai.*`: `gen_ai.operation.name` diz que tipo de chamada foi
(`chat`, `embeddings`, `execute_tool`), `gen_ai.request.model` o que foi pedido,
`gen_ai.response.model` o que respondeu, e `gen_ai.usage.input_tokens` e `output_tokens` quanto
custou em tokens. A convenção diz também como dar nome ao span: a operação, um espaço e o modelo.

Usar os nomes de outra pessoa é o objetivo. Uma ferramenta que conhece a convenção acha as contagens
de tokens em qualquer programa que a siga, e as aulas 6 e 7 mandam estes mesmos spans para duas
ferramentas a quem nunca se disse nada sobre a Marginalia. A convenção ainda estava marcada como em
desenvolvimento quando este curso foi escrito, e um nome já tinha mudado: o que hoje é
`gen_ai.provider.name` se chamava `gen_ai.system`. Fixe a versão do que quer que os escreva, e conte
com uma ou duas renomeações a cada atualização.

Modelo do pedido e modelo da resposta são dois atributos por um motivo. Um pedido para um apelido
(alias) como `gpt-4o` é respondido pela versão datada para a qual o apelido aponta naquele dia, e a
resposta diz qual foi. Os nomes do Ollama funcionam do mesmo jeito: `llama3.2:3b` é uma etiqueta, e
baixá-la de novo noutro dia pode trazer outro arquivo com o mesmo nome, por isso o `ollama list`
mostra um id ao lado. A aula 14 é sobre o dia em que pedido e resposta divergem.

## O que o span não pegou

Leia a resposta. O modelo nunca ouviu falar de um vale-presente chamado Marginalia, diz isso, e pede
mais contexto: 75 tokens com que um cliente não conseguiria fazer nada. Os documentos da loja dizem
que um vale vale dois anos, mas o `one_call.py` mandou a pergunta sem mais nada, e um modelo só sabe o
que aprendeu no treino e o que recebe junto. É por isso que o assistente da seção 07 entrega a ele os
documentos. Desta vez o modelo admitiu; perguntado sobre algo mais perto do que aprendeu, ele teria
dado com a mesma facilidade um número seguro, e errado.

**O span está perfeito e a resposta não serve para nada**, e nada no span consegue distinguir as
duas coisas: o status é `UNSET`, o motivo de parada é `stop`, as contagens de tokens são plausíveis.

Essa é a linha que este curso não para de traçar. Um trace diz **o que aconteceu**: quais etapas
rodaram, em que ordem, quanto tempo cada uma levou, quanto cada uma custou. Se a resposta prestava é
outra pergunta, com outros instrumentos, e as aulas 8 a 13 os constroem.
