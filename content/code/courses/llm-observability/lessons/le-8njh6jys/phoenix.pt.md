---
title: O Arize Phoenix
version: 1
---

A Arize é uma empresa com dois produtos para isso. O **Arize AX** é a sua plataforma hospedada, para
monitorar e avaliar modelos em produção, de aprendizado de máquina além de modelos de linguagem. O
**Phoenix** é o seu rastreador e ferramenta de avaliação de código aberto, construído sobre o
OpenTelemetry e sobre o OpenInference, a convenção que a aula 1 encontrou. O AX é um serviço hospedado
e não foi rodado. O Phoenix roda como um pacote Python, sem precisar de nenhum outro serviço, e o
laboratório o inicia com `sudo bash lab.sh phoenix`, guardando os dados em SQLite no disco:

```
ana@lab:~/obs$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:6006/
200
```

Ele recebe OTLP na porta 6006, então o assistente precisa, de novo, só de uma variável de ambiente. A
reprodução do domingo, mandada para ele:

```
ana@lab:~/obs$ OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://127.0.0.1:6006/v1/traces python replay.py --from 2026-10-04 --to 2026-10-05
replayed 118 requests from data/traffic.jsonl: 143 asked, 0 failed, 54 feedback events
```

O Phoenix tem um cliente Python, e o `px_spans.py` lê os spans de volta dele como uma tabela, agrupada
por nome, do jeito que as telas dele agrupam:

```python
"""px_spans.py: the spans Phoenix holds, read back through its client, as a table per span name."""
from phoenix.client import Client

spans = Client(base_url="http://127.0.0.1:6006").spans.get_spans_dataframe(project_identifier="default", limit=5000)
print(len(spans), "spans;", spans["context.trace_id"].nunique(), "traces")
print(spans["span_kind"].value_counts().to_string())
spans["ms"] = (spans["end_time"] - spans["start_time"]).dt.total_seconds() * 1000
table = spans.groupby("name").agg(spans=("name", "size"), kind=("span_kind", "first"), median_ms=("ms", "median"),
                                  prompt_tokens=("attributes.llm.token_count.prompt", "sum"))
print(table.round(0).to_string())
```

```
ana@lab:~/obs$ python px_spans.py
747 spans; 143 traces
span_kind
UNKNOWN      367
LLM          250
EMBEDDING    130
                 spans       kind  median_ms  prompt_tokens
name                                                       
ask                143        LLM      760.0            0.0
chat extract-1     107        LLM     1185.0        21815.0
check_citations    130    UNKNOWN        0.0            0.0
embed              130  EMBEDDING       58.0         1325.0
generate           107    UNKNOWN     1185.0            0.0
search             130    UNKNOWN        3.0            0.0
```

## O que ele fez dos spans

O Phoenix separa spans por **tipo**, o `openinference.span.kind` do OpenInference: `LLM`, `EMBEDDING`,
`RETRIEVER`, `TOOL`, `CHAIN` e alguns outros, e desenha cada tipo de um jeito. O assistente não escreve
nenhum nome do OpenInference, e o Phoenix leu os seus atributos `gen_ai.*` e os traduziu: os spans de
chat viraram `LLM` com os tokens de prompt contados, os embeddings `EMBEDDING`. A convergência que a aula
1 viu do lado do OpenInference está acontecendo do lado do Phoenix também.

E a raiz de novo. **`ask` é um span `LLM` sem tokens**, pelo mesmo motivo que o fez geração no Langfuse:
ele leva `gen_ai.request.model`. Duas ferramentas, feitas por duas empresas, leram do mesmo jeito o
mesmo atributo. Isso é boa evidência de que o atributo está no lugar errado, e a correção pertence ao
`assistant.py` e não a um adaptador por ferramenta: registrar o modelo da versão como `app.model` na
raiz, e deixar `gen_ai.*` para os spans que são chamadas a modelo. O curso deixa o `assistant.py` como
está para que a transcrição de toda aula continue batendo, e o exercício pergunta o que a mudança
afetaria.

A outra coisa a ler na tabela: **`search` é `UNKNOWN`**. O Phoenix tem um tipo `RETRIEVER` feito para
ele, que mostra os documentos recuperados e as suas notas num painel próprio; o span de busca do
assistente não diz que é um. Acrescentar `openinference.span.kind = RETRIEVER`, e os ids dos trechos
como o `retrieval.documents` do OpenInference, é um adaptador da mesma forma que o da aula 6.

Repare também nos tokens de prompt do `embed`: 1.325. O Phoenix conta a entrada de um embedding como
tokens de prompt, o que é justo, e um total de tokens de prompt somando todos os tipos misturaria então
dois preços.
