---
title: Anotações
version: 2
---

A palavra do Phoenix para nota é **anotação** (annotation): um rótulo, um número, ou os dois, com uma
explicação, posta num span por um anotador de um de três tipos, `HUMAN`, `LLM` ou `CODE`. Os três tipos
são os três tipos de avaliação que este curso constrói em seguida: uma regra em código (aula 8), um juiz
modelo (aula 9) e uma pessoa (aula 10). Registrar que tipo produziu um veredito é o que deixa uma equipe
perguntar depois com que frequência o juiz modelo e as pessoas concordaram.

Os polegares são o veredito de um humano. O Phoenix anota spans, não traces, então o `px_thumbs.py` põe
cada polegar no span raiz do seu trace, que ele acha no `spans.jsonl` pelo id de trace:

```python
"""px_thumbs.py: each thumb in feedback.jsonl, as an annotation on its trace's root span in Phoenix."""
import json

import pandas as pd
from phoenix.client import Client

root = {s["trace"]: s["span"] for s in map(json.loads, open("spans.jsonl")) if s["parent"] is None}
thumbs = [f for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"]
rows = pd.DataFrame({"span_id": [root[f["trace"]] for f in thumbs], "label": [f["value"] for f in thumbs],
                     "score": [1 if f["value"] == "up" else 0 for f in thumbs]})
client = Client(base_url="http://127.0.0.1:6006")
client.spans.log_span_annotations_dataframe(dataframe=rows, annotation_name="thumbs", annotator_kind="HUMAN", sync=True)
got = client.spans.get_span_annotations_dataframe(span_ids=rows["span_id"], project_identifier="default")
print(len(rows), "sent;", len(got), "read back:", got["result.label"].value_counts().to_dict())
```

```
ana@dev:~/obs$ python px_thumbs.py
4 sent; 4 read back: {'up': 4}
```

Quatro polegares de domingo, os quatro para cima, agora nos spans que julgam. Os poucos clientes que
avaliaram uma resposta naquele dia gostaram do que receberam. Nas telas do Phoenix eles aparecem ao
lado de cada trace, e um filtro pode listar os traces com polegar para baixo.

A ligação foi por id duas vezes: o polegar levava o id de trace, e o `spans.jsonl` o transformou no id
do span raiz, os dois escritos pelo OpenTelemetry quando o pedido rodou e idênticos no Phoenix. Os mesmos
polegares foram para o Langfuse na aula 6 pelo mesmo caminho. É esse o objetivo de ligar por id desde o
começo: **o feedback não está preso a nenhuma ferramenta**, e levá-lo para uma nova é um laço.
