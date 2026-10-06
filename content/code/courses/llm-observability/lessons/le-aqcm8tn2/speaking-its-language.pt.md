---
title: Acrescentando os nomes que ele lê
version: 1
---

O Langfuse documenta um conjunto de atributos que lê além dos do OpenTelemetry:
`langfuse.observation.type` para dizer o que um span é, `langfuse.trace.input` e `output`,
`langfuse.user.id` e `langfuse.session.id`, e também os simples `user.id` e `session.id`. O assistente
poderia escrevê-los ele mesmo. Melhor não: são os nomes de uma ferramenta, e no dia em que os spans
forem para outro lugar eles serão ruído nos metadados de outra.

Então eles são acrescentados **na saída**, por um processador de spans que a reprodução só carrega
quando pedido. O OpenTelemetry chama o `on_start` de um processador quando cada span começa, com o span
ainda gravável e com os atributos com que foi criado já nele:

```python
"""lf_names.py: a span processor that adds, as each span starts, the names Langfuse reads."""
from opentelemetry.sdk.trace import SpanProcessor


class LangfuseNames(SpanProcessor):
    def on_start(self, span, parent_context=None):
        if span.name == "ask":
            a = span.attributes
            span.set_attribute("langfuse.observation.type", "span")   # the root is not a model call
            span.set_attribute("user.id", a["user.hash"])               # the pseudonym, under the name it reads
            span.set_attribute("langfuse.trace.input", a["app.question"])
```

O `replay.py` aceita `--processor MODULO:CLASSE` e acrescenta cada um ao provedor antes dos
exportadores. A reprodução do sábado, com ele:

```
ana@lab:~/obs$ export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_HOST/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"; python replay.py --from 2026-10-03 --to 2026-10-04 --processor lf_names:LangfuseNames
replayed 120 requests from data/traffic.jsonl: 153 asked, 0 failed, 70 feedback events
ana@lab:~/obs$ python lf.py traces 2026-10-03 1
2026-10-03T03:01:53 e1a355f5 ask user 845c4ccdf2b1e0d8 session s0890 cost 0 input 'how long do I have to return a book'
```

O usuário é o pseudônimo, sob um nome que o Langfuse lê, e o trace tem a pergunta como entrada. A raiz
não é mais uma geração. Nada no `assistant.py` mudou, e o arquivo para onde foram os mesmos spans
continua sem nenhum dos nomes `langfuse.*`.

## Por que a resposta não está lá

O `on_start` vê aquilo com que o span foi criado, e a resposta é posta na raiz no fim do pedido. Para
copiá-la também, a cópia teria de acontecer quando o span termina, e a essa altura o SDK de Python já
tornou o span somente leitura; a aula 2 bateu no mesmo muro e reconstruiu o span num exportador. A
troca aqui foi para o outro lado: a pergunta basta para achar um trace numa tela, e a resposta está a
um clique, no atributo `app.reply` que o Langfuse guarda como metadado.

O ponto geral é o mesmo que a aula 1 fez sobre o OpenInference. **Toda ferramenta tem uma lista de
nomes que lê.** Descubra quais são antes de escolher o que escrever, e mantenha os nomes próprios da
ferramenta num adaptador pequeno, aqui de onze linhas, em vez de espalhados pela aplicação.
