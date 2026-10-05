---
title: Tarefas, não só chat
version: 1
---

Toda família das aulas 6 a 11 era de modelos de chat: texto entra, texto sai, qualquer tarefa que dê
para descrever. O Hugging Face é onde a maioria dos modelos abertos é publicada, pelos autores e por
todo mundo, e ele os organiza por **tarefa**. A lista de tarefas mora no próprio código-fonte do Hugging
Face, que o laboratório lê num commit fixado; o comentário acima dela diz para que ela serve:

```
ana@desk:~/desk$ sources quote hf-tasks "To determine which|filters at the left"
# huggingface/huggingface.js@3064743f packages/tasks/src/pipelines.ts
  60: ///  - To determine which widget to show.
  61: ///  - To determine which endpoint of Inference Endpoints to use.
  62: ///  - As filters at the left of models and datasets page.
```

O `lab/tasks.py` tira desse arquivo a chave, o nome e a modalidade de cada tarefa:

```python
import re
import subprocess
import sys
from collections import Counter

src = subprocess.run(["sources", "lines", "hf-tasks", "1", "664"], capture_output=True, text=True).stdout
text = "\n".join(line.split("| ", 1)[1] if "| " in line else "" for line in src.splitlines()[1:])
# one entry per task: its key, its display name, and the modality it belongs to
tasks = re.findall(r'\n\t"([a-z0-9-]+)": \{\n\t\tname: "([^"]+)",.*?\n\t\tmodality: "(\w+)"', text, re.S)
print(len(tasks), "tasks:", dict(Counter(m for _, _, m in tasks).most_common()))
for key, name, modality in tasks:
    if modality == (sys.argv[1] if len(sys.argv) > 1 else "nlp"):
        print(f"  {key:32} {name}")
```

```
ana@desk:~/desk$ python lab/tasks.py nlp
53 tasks: {'cv': 19, 'nlp': 13, 'multimodal': 9, 'audio': 6, 'tabular': 4, 'rl': 1, 'other': 1}
  text-classification              Text Classification
  token-classification             Token Classification
  table-question-answering         Table Question Answering
  question-answering               Question Answering
  zero-shot-classification         Zero-Shot Classification
  feature-extraction               Feature Extraction
  text-generation                  Text Generation
  fill-mask                        Fill-Mask
  sentence-similarity              Sentence Similarity
  table-to-text                    Table to Text
  multiple-choice                  Multiple Choice
  text-ranking                     Text Ranking
  text-retrieval                   Text Retrieval
```

**Cinquenta e três tarefas**, o maior grupo sobre imagem, e treze sobre texto. `text-generation` é a tarefa a
que pertence todo modelo de chat. As outras são o que a lista existe para tornar visível: **modelos
feitos para um trabalho só**, geralmente bem menores que um modelo de chat, muitas vezes mais rápidos e
mais baratos de rodar.

## Por que isso importa para a ana

A tarefa de classificação dela é **text-classification**: um texto entra, um de cinco rótulos sai. Um
modelo de chat faz isso porque o prompt lhe diz os rótulos. Um modelo de classificação faz isso porque
foi treinado com exemplos rotulados, e responde com um rótulo e uma nota, nunca com uma frase, nunca com
`Refund.`. Para uma tarefa de alto volume e rótulos fixos, um classificador pequeno ajustado com alguns
milhares de e-mails da própria loja pode ser mais barato, mais rápido e mais consistente que qualquer
modelo de chat, e é o tipo de modelo que a aula 1 seção 07 tinha em mente no quarto degrau.

Duas outras linhas merecem nome por causa dos cursos seguintes: `feature-extraction` e
`sentence-similarity` são os modelos de embedding de que trata o `embeddings-vectors`, e `text-ranking`
é o reranker da aula 9 seção 03, como tarefa.
