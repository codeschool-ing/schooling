---
title: O Arize Phoenix
version: 2
---

A Arize é uma empresa com dois produtos para isso. O **Arize AX** é a sua plataforma hospedada, para
monitorar e avaliar modelos em produção, de aprendizado de máquina além de modelos de linguagem. O
**Phoenix** é o seu rastreador e ferramenta de avaliação de código aberto, construído sobre o
OpenTelemetry e sobre o OpenInference, a convenção que a aula 1 encontrou. O AX é um serviço hospedado
e não é rodado aqui. O Phoenix é um pacote Python sem nenhum outro serviço por trás, então ele se instala
no ambiente do curso como qualquer biblioteca:

```sh
pip install arize-phoenix==20.18.0
```

```
ana@dev:~/obs$ du -sh ~/llmobs
1.7G	/home/ana/llmobs
ana@dev:~/obs$ pip list 2>/dev/null | grep -E "^opentelemetry-sdk "
opentelemetry-sdk                        1.45.1
```

O ambiente agora tem 1,7 GB, a maior parte do Phoenix e do que ele traz: um servidor web, uma camada de
banco de dados e o pandas, entre outros. O pip também levou o SDK do OpenTelemetry de 1.45.0, a versão
que a aula 1 fixou, para 1.45.1, porque uma das dependências do próprio Phoenix pede essa versão. É uma
correção, e nada que este curso lê muda com ela.

Depois inicie-o em segundo plano, com duas configurações que não são as padrão dele:

```sh
PHOENIX_HOST=127.0.0.1 PHOENIX_TELEMETRY_ENABLED=false phoenix serve > ~/phoenix.log 2>&1 &
```

**Deixado por conta própria, o Phoenix escuta em todas as interfaces de rede**, `0.0.0.0`, e qualquer
pessoa na mesma rede que o seu computador consegue abri-lo, traces e tudo. O `PHOENIX_HOST` o mantém na
sua máquina. E as telas dele informam como são usadas a dois serviços de análise, FullStory e Scarf, a
menos que `PHOENIX_TELEMETRY_ENABLED` seja falso. Nenhum dos dois padrões é incomum numa ferramenta feita
para ser compartilhada por uma equipe; os dois valem ser conhecidos antes de as perguntas dos clientes
irem para ela. Ele guarda os dados num arquivo SQLite em `~/.phoenix`, e para quando você o encerra, com
`kill %1` no mesmo terminal.

```
ana@dev:~/obs$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:6006/
200
ana@dev:~/obs$ curl -s -o /dev/null -w "%{http_code}\n" http://$(hostname -I | cut -d" " -f1):6006/
000
```

O primeiro endereço é a sua própria máquina, e o Phoenix responde. O segundo é o endereço do mesmo
computador na rede dele, o que o navegador de um colega usaria, e ali nada responde: `000` é o `curl`
dizendo que não conseguiu conectar. É o `PHOENIX_HOST` fazendo o trabalho dele.

Ele recebe OTLP na porta 6006, então o assistente precisa, de novo, só de uma variável de ambiente. A
reprodução do domingo, mandada para ele:

```
ana@dev:~/obs$ OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://127.0.0.1:6006/v1/traces python replay.py --from 2026-10-04 --to 2026-10-05
replayed 32 requests from data/traffic.jsonl: 34 asked, 0 failed, 7 feedback events
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
ana@dev:~/obs$ python px_spans.py
182 spans; 34 traces
span_kind
UNKNOWN      90
LLM          60
EMBEDDING    32
                  spans       kind  median_ms  prompt_tokens
name                                                        
ask                  34        LLM     2857.0            0.0
chat llama3.2:3b     26        LLM     3058.0         4379.0
check_citations      32    UNKNOWN        0.0            0.0
embed                32  EMBEDDING      146.0          478.0
generate             26    UNKNOWN     3059.0            0.0
search               32    UNKNOWN        0.0            0.0
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

Repare também nos tokens de prompt do `embed`: 478. O Phoenix conta a entrada de um embedding como
tokens de prompt, o que é justo, e um total de tokens de prompt somando todos os tipos misturaria então
dois preços.
