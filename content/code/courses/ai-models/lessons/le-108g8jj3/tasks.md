---
title: Tasks, not only chat
version: 1
---

Every family in lessons 6 to 11 was a chat model: text in, text out, any task you can describe.
Hugging Face is where most open models are published, by their makers and by everybody else, and
it organises them by **task**. The list of tasks lives in Hugging Face's own source code, which the
lab reads at a pinned commit; the comment above it says what the list is for:

```
ana@desk:~/desk$ sources quote hf-tasks "To determine which|filters at the left"
# huggingface/huggingface.js@3064743f packages/tasks/src/pipelines.ts
  60: ///  - To determine which widget to show.
  61: ///  - To determine which endpoint of Inference Endpoints to use.
  62: ///  - As filters at the left of models and datasets page.
```

`lab/tasks.py` pulls each task's key, name and modality out of that file:

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

**Fifty-three tasks**, the largest group about images, and thirteen about text. `text-generation` is the
one every chat model belongs to. The others are what the list exists to make visible: **models
built for one job**, usually far smaller than a chat model, often faster and cheaper to run.

## Why that matters for ana

Her sorting task is **text-classification**: a text in, one of five labels out. A chat model does it
by being told the labels in a prompt. A classification model does it by having been trained on
labelled examples, and answers with a label and a score, never with a sentence, never with
`Refund.`. For a high-volume, fixed-label task, a small classifier fine-tuned on a few thousand of
the shop's own e-mails can be cheaper, faster and more consistent than any chat model, and it is
the kind of model lesson 1 section 07 meant by its fourth step.

Two other rows are worth a name for the courses that follow: `feature-extraction` and
`sentence-similarity` are the embedding models `embeddings-vectors` is about, and `text-ranking` is
section 03 of lesson 9's reranker, as a task.
