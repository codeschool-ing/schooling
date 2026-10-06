---
title: Um span em volta de uma chamada
version: 1
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
      "code": "\"\"\"One model call, with a span around it, printed to the terminal when it ends.\"\"\"\nfrom openai import OpenAI\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"one_call\")",
      "note": "As três partes do SDK: um provedor que cria spans, um processador que passa adiante cada span terminado, e um exportador que o escreve em algum lugar. Aqui, no terminal, um span por vez."
    },
    {
      "code": "client = OpenAI()\nwith tracer.start_as_current_span(\"chat extract-1\") as span:\n    span.set_attribute(\"gen_ai.operation.name\", \"chat\")\n    span.set_attribute(\"gen_ai.request.model\", \"extract-1\")",
      "note": "O span abre antes de o pedido sair, então a sua duração inclui a espera pelo fornecedor. O nome e os dois primeiros atributos dizem o que foi pedido, antes de existir qualquer resposta."
    },
    {
      "code": "    reply = client.chat.completions.create(\n        model=\"extract-1\", messages=[{\"role\": \"user\", \"content\": \"How long is a gift card valid?\"}])",
      "note": "A chamada em si, sem mudança."
    },
    {
      "code": "    span.set_attribute(\"gen_ai.response.model\", reply.model)\n    span.set_attribute(\"gen_ai.response.finish_reasons\", [reply.choices[0].finish_reason])\n    span.set_attribute(\"gen_ai.usage.input_tokens\", reply.usage.prompt_tokens)\n    span.set_attribute(\"gen_ai.usage.output_tokens\", reply.usage.completion_tokens)\nprint(reply.choices[0].message.content)",
      "note": "O que voltou: qual modelo respondeu, por que parou, e os tokens de cada lado, lidos do `usage` da resposta. O span fecha no fim do bloco."
    }
  ]
}
```

```
ana@lab:~/obs$ python one_call.py
{
    "name": "chat extract-1",
    "context": {
        "trace_id": "0xd4a8903817f935061c7255069d52f5c8",
        "span_id": "0x15f2ef0a0e59a80f",
        "trace_state": "[]"
    },
    "kind": "SpanKind.INTERNAL",
    "parent_id": null,
    "start_time": "2026-10-06T06:47:23.748671Z",
    "end_time": "2026-10-06T06:47:24.383897Z",
    "status": {
        "status_code": "UNSET"
    },
    "attributes": {
        "gen_ai.operation.name": "chat",
        "gen_ai.request.model": "extract-1",
        "gen_ai.response.model": "extract-1",
        "gen_ai.response.finish_reasons": [
            "stop"
        ],
        "gen_ai.usage.input_tokens": 11,
        "gen_ai.usage.output_tokens": 13
    },
    "events": [],
    "links": [],
    "resource": {
        "attributes": {
            "telemetry.sdk.language": "python",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.version": "1.45.0",
            "service.instance.id": "66df69dd-62b0-4bf2-8ac7-a4f835754534",
            "service.name": "unknown_service:python"
        },
        "schema_url": ""
    }
}
Marginalia gift cards are valid for one year from purchase.
```

Tudo nesse registro é algo que uma linha de log também poderia dizer, menos duas coisas: o **id de
trace e o id de span**, que deixam este span ser encontrado e ligado a outros, e os **horários de
início e de fim**, que estão a 635 ms um do outro. Essa é a chamada ao modelo inteira, da saída do
pedido à leitura da resposta.

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
resposta diz qual foi. A aula 14 é sobre o dia em que os dois divergem.

## O que o span não pegou

Leia a resposta: *Marginalia gift cards are valid for one year from purchase.* Os vale-presentes
valeriam um ano, e isso está errado; os documentos dizem dois. O `one_call.py` mandou a pergunta sem
fontes, então o extract-1 respondeu com o que "aprendeu no treino", que a aula 1 do `rag` mostrou
serem as regras do ano passado. **O span está perfeito e a resposta está errada**, e nada no span
consegue distinguir as duas coisas: o status é `UNSET`, o motivo de parada é `stop`, as contagens de
tokens são plausíveis.

Essa é a linha que este curso não para de traçar. Um trace diz **o que aconteceu**: quais etapas
rodaram, em que ordem, quanto tempo cada uma levou, quanto cada uma custou. Se a resposta prestava é
outra pergunta, com outros instrumentos, e as aulas 8 a 13 os constroem.
