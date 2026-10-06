---
title: Uma segunda rede, para spans que você não escreveu
version: 1
---

O `redact()` no `assistant.py` cobre os atributos que o assistente escreve. Ele não faz nada pelos spans
que outro código escreve, e a aula 1 mostrou uma biblioteca de instrumentação escrevendo o prompt
inteiro e a resposta inteira por conta própria. A segunda rede fica onde todo span passa, seja quem
for que o fez: **o exportador**.

O `leak.py` manda uma mensagem de cliente pelo SDK da OpenAI com o OpenInference instrumentando, e
escreve os spans ou direto num arquivo ou através de um invólucro que antes passa cada atributo de
texto pela remoção:

```schooling-example
{
  "language": "python",
  "file": "leak.py",
  "parts": [
    {
      "code": "\"\"\"leak.py: one customer message through an instrumented SDK, with and without a redacting exporter.\"\"\"\nimport sys\n\nfrom openai import OpenAI\nfrom openinference.instrumentation.openai import OpenAIInstrumentor\nfrom opentelemetry.sdk.trace import ReadableSpan, TracerProvider\nfrom opentelemetry.sdk.trace.export import SimpleSpanProcessor, SpanExporter\n\nimport redact\nimport telemetry"
    },
    {
      "code": "class Redacting(SpanExporter):\n    \"\"\"Hands every span on to INNER with each string attribute, and each event's, passed through redact().\"\"\"\n\n    def __init__(self, inner):\n        self.inner = inner\n\n    def export(self, spans):\n        clean = lambda attrs: {k: redact.redact(v) if isinstance(v, str) else v for k, v in attrs.items()}\n        return self.inner.export([ReadableSpan(\n            name=s.name, context=s.context, parent=s.parent, resource=s.resource,\n            attributes=clean(s.attributes), links=s.links, kind=s.kind, status=s.status,\n            events=[type(e)(e.name, clean(e.attributes), e.timestamp) for e in s.events],\n            start_time=s.start_time, end_time=s.end_time, instrumentation_scope=s.instrumentation_scope)\n            for s in spans])\n\n    def shutdown(self):\n        self.inner.shutdown()",
      "note": "O invólucro: uma classe que é ela mesma um exportador e guarda o de verdade. Não muda nada em como os spans são feitos, só o que é passado adiante. Para cada span, uma cópia com cada atributo de texto passado pelo `redact()`, e o mesmo para os atributos de cada evento, porque a mensagem de uma exceção é um evento e pode citar o prompt. Ids, horários e status são copiados como estão."
    },
    {
      "code": "out = sys.argv[1]\nexporter = telemetry.JsonlExporter(out)\nif \"--redact\" in sys.argv:\n    exporter = Redacting(exporter)\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(exporter))\nOpenAIInstrumentor().instrument(tracer_provider=provider)\nOpenAI().chat.completions.create(model=\"extract-1\", messages=[{\"role\": \"user\", \"content\":\n    \"Hi, I'm Joana Prado (joana.prado@example.com, +55 11 5550-0142). Is my order MG-20481937 lost?\"}])",
      "note": "A demonstração: o exportador de linhas JSON do laboratório, embrulhado ou não, atrás do OpenInference, que a aula 1 mostrou guardar o prompt inteiro. Uma mensagem de cliente, com um endereço, um telefone e um pedido."
    }
  ]
}
```

```
ana@lab:~/obs$ python leak.py raw.jsonl && grep -o "joana.prado@example.com" raw.jsonl | wc -l
2
ana@lab:~/obs$ python leak.py clean.jsonl --redact && grep -o "joana.prado@example.com" clean.jsonl | wc -l
0
ana@lab:~/obs$ python tree.py --spans clean.jsonl --attrs | grep "message.content"
                     llm.input_messages.0.message.content = "Hi, I'm Joana Prado ([email], [phone]). Is my order [order] lost?"
                     llm.output_messages.0.message.content = "You can call Marginalia's customer service on 0800 555 0199, every day from 9 am to 6 pm."
```

Sem o invólucro, o endereço está no arquivo duas vezes: no prompt como o OpenInference o registrou,
`input.value`, e de novo em `llm.input_messages`. Com ele, em nenhum dos dois. A resposta, uma frase
sobre o atendimento da Marginalia tirada da memória do extract-1, ficou intocada porque não carrega
nada que os padrões peguem. A resposta de um modelo de verdade a essa mensagem poderia ter
cumprimentado a Joana pelo nome e repetido o endereço dela, e o invólucro teria tirado o endereço
dali também.

## Por que no exportador, e não no início do span

O SDK do OpenTelemetry deixa o código acompanhar spans começando e terminando por meio de um
**processador de spans**. Seria o lugar natural, só que, quando um processador vê um span terminado,
o span já é somente leitura no SDK de Python, e no início os atributos que uma biblioteca acrescenta
durante a chamada ainda não estão lá. O exportador é o último ponto dentro do processo em que todo
atributo existe e nada saiu ainda. É por isso que o invólucro constrói um span novo para cada um em vez
de editá-lo.

A mesma ideia existe fora do processo. **O OpenTelemetry Collector**, que a aula 2 do `observability`
põe entre os serviços e os seus backends, tem processadores exatamente para isso: regras que apagam ou
trocam atributos, ou comparam os seus valores com padrões, antes de encaminhar qualquer coisa. A aula
10 do `observability` faz isso para logs; para spans não foi rodado aqui. É o lugar certo quando
vários serviços mandam spans e cada um, de outro modo, carregaria a sua própria cópia das regras.

## Quanto custa uma segunda rede

Cada atributo de texto de cada span passa por quatro expressões regulares, o que são microssegundos
para um span deste tamanho. O preço que importa são os **falsos positivos**: um padrão que pega algo
inofensivo o remove de todo trace, inclusive dos que alguém precisa depurar. A próxima seção acha um.
