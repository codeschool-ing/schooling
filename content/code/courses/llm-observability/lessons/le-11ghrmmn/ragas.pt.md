---
title: RAGAS sem modelo
version: 1
---

O RAGAS tem uma família de métricas que **não precisam de modelo**: elas comparam textos. Duas delas são
context precision e context recall, as que a aula 11 calculou pela sua própria definição. As versões do
RAGAS recebem **contextos de referência** (*reference contexts*), o texto que deveria ter sido
recuperado, e julgam um trecho recuperado relevante quando a sua semelhança de texto com algum texto de
referência é de pelo menos 0,5.

O `ragas_run.py` dá ao RAGAS o texto de todos os trechos das seções gold de cada pergunta como contextos
de referência, roda as duas métricas pelo `evaluate`, e imprime ao lado os números da aula 11 para as
mesmas perguntas:

```python
"""ragas_run.py: RAGAS's context precision and recall that need no model, beside lesson 11's own, per release.

The reference contexts are the text of every chunk in the question's gold sections."""
import json
from statistics import mean

import psycopg
from ragas import EvaluationDataset, SingleTurnSample, evaluate
from ragas.metrics import NonLLMContextPrecisionWithReference, NonLLMContextRecall

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}
by_section, section = {}, {}
for cid, doc, path, text in psycopg.connect().execute("SELECT id, doc_id, path, text FROM chunks ORDER BY doc_id, position"):
    section[cid] = (doc, path.split(" > ")[-1])
    by_section.setdefault(section[cid], []).append(text)


def ours(chunks, gold):
    """Lesson 11's two definitions: precision weighted by rank over chunks in a gold section,
    recall as the share of gold sections at least one chunk came from."""
    hits = [section[c] in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return (sum(at) / len(at) if at else 0.0), sum(g in {section[c] for c in chunks} for g in gold) / len(gold)


for run in ("old", "new"):
    rows = [json.loads(line) for line in open(f"runs/{run}.jsonl")]
    samples, own = [], []
    for r in rows:
        gold = [tuple(g) for g in cases[r["id"]]["gold"]]
        if not gold or not r["sources"]:
            continue   # RAGAS needs both lists non-empty; lesson 11 left these out too
        samples.append(SingleTurnSample(user_input=r["question"], response=r["reply"],
                                        retrieved_contexts=[s["text"] for s in r["sources"]],
                                        reference_contexts=[t for g in gold for t in by_section[g]]))
        own.append(ours([s["id"] for s in r["sources"]], gold))
    scores = evaluate(EvaluationDataset(samples=samples), show_progress=False,
                      metrics=[NonLLMContextPrecisionWithReference(), NonLLMContextRecall()]).to_pandas()
    print(f"{run} {rows[0]['release']}, {len(samples)} questions with gold and chunks")
    print(f"  RAGAS      precision {scores['non_llm_context_precision_with_reference'].mean():.2f}"
          f"   recall {scores['non_llm_context_recall'].mean():.2f}")
    print(f"  lesson 11  precision {mean(p for p, _ in own):.2f}   recall {mean(r for _, r in own):.2f}")
```

```
ana@lab:~/obs$ python ragas_run.py
old 2026.09.4, 20 questions with gold and chunks
  RAGAS      precision 0.91   recall 0.72
  lesson 11  precision 0.91   recall 0.95
new 2026.10.1, 16 questions with gold and chunks
  RAGAS      precision 0.94   recall 0.48
  lesson 11  precision 0.94   recall 0.91
```

**A precisão bate exatamente, e a revocação não, por muito.** Na versão nova o RAGAS diz que a busca
achou menos da metade do que devia; a aula 11 diz que achou nove décimos.

Os dois estão certos sobre coisas diferentes. A aula 11 pergunta, para cada **seção** gold, se algum
trecho dela foi dado ao modelo. O RAGAS pergunta, para cada **texto** de referência, se algum trecho
recuperado é parecido com ele, e as referências aqui são todos os trechos de todas as seções gold. Uma
seção dividida em três trechos dos quais a busca devolveu um conta como achada na aula 11 e como um em
três no RAGAS. A versão nova devolve um trecho só na maioria das perguntas, então a diferença é maior
nela.

Qual é a revocação certa depende do que a resposta precisa. Se um trecho da seção basta para responder,
a da aula 11 é a medida honesta; se a resposta está espalhada pela seção, a do RAGAS é. Isso é uma
propriedade das perguntas, e se decide quando as referências são escritas, não quando a métrica é
escolhida.

**E a referência decide a nota tanto quanto a métrica.** Troque os contextos de referência e a mesma
métrica relata outra revocação para a mesma recuperação. Uma revocação publicada sem dizer quais eram os
contextos de referência não pode ser comparada com nada.
