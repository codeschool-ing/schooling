---
title: Cinco métricas, cada uma com a sua definição
version: 2
---

Os frameworks de avaliação de geração aumentada por recuperação relatam uma família de métricas com
nomes parecidos. Quatro são as que as equipes citam, e a quinta é a que a aula 8 montou:

| Métrica | Pergunta que responde | Precisa de referência? |
| --- | --- | --- |
| context precision | os trechos que o modelo recebeu são os certos, e estão no topo? | sim: quais trechos têm a resposta |
| context recall | o modelo recebeu todo trecho de que a resposta precisa? | sim: o mesmo |
| faithfulness (fidelidade) | toda afirmação da resposta tem apoio nesses trechos? | não |
| relevance (relevância) | a resposta trata da pergunta? | não |
| correctness (correção) | a resposta é a resposta certa? | sim: a resposta esperada |

A coluna da direita é a que decide onde uma métrica pode rodar. **As três que precisam de referência só
funcionam num conjunto de avaliação**, onde alguém escreveu a resposta e onde ela está. As duas que não
precisam, fidelidade e relevância, podem rodar no tráfego de produção, e é por isso que o juiz da aula
9 avaliou essas duas.

O `metrics.py` calcula as cinco para uma execução, cada uma numa função de poucas linhas cuja docstring
é a sua definição. A referência para context precision e recall é o `gold` do conjunto de avaliação: para cada pergunta, os
ids dos trechos que têm a resposta, que a aula 8 escreveu ao lado dos fatos:

```python
"""metrics.py: five numbers for each run of the evaluation set, each defined in its function.

    python metrics.py old new
"""
import json
import sys

import checks
import judge
import telemetry
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


def context_precision(chunks, gold):
    """How high the gold chunks sit among those the model was given: the precision at each gold
    chunk's rank, averaged. None when nothing was given."""
    if not chunks:
        return None
    hits = [c in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return sum(at) / len(at) if at else 0.0


def context_recall(chunks, gold):
    """The share of the gold chunks that the model was given. None when there is no gold."""
    if not gold:
        return None
    return sum(g in chunks for g in gold) / len(gold)


def faithfulness(r):
    """The judge's score for whether the reply's statements are supported by its sources."""
    return judge.grade("faithfulness", r["question"], r["reply"], r["sources"])["score"]


def relevance(r, case):
    """The judge's relevance verdict, with the refusal decided by the answer key as lesson 10 did."""
    if checks.is_refusal(r["reply"]):
        return 0.0 if case["facts"] else 1.0
    return float(judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"] == "pass")


def correctness(r, case):
    """Lesson 8's normalised fact check: the fact is in the reply, or an unanswerable question was refused."""
    return float(normalised(r["reply"], case["facts"]))


telemetry.setup("judge-spans.jsonl", service="judge")
mean = lambda xs: sum(x for x in xs if x is not None) / len([x for x in xs if x is not None])
count = lambda xs: len([x for x in xs if x is not None])
print("run  release  " + "".join(f"{h:>16}" for h in ("ctx precision", "ctx recall", "faithfulness", "relevance", "correctness")))
for name in sys.argv[1:]:
    run = [json.loads(line) for line in open(f"runs/{name}.jsonl")]
    cols = {"p": [], "r": [], "f": [], "v": [], "c": []}
    for r in run:
        case = cases[r["id"]]
        chunks = [s["id"] for s in r["sources"]]
        cols["p"].append(context_precision(chunks, set(case["gold"])))
        cols["r"].append(context_recall(chunks, case["gold"]))
        cols["f"].append(faithfulness(r))
        cols["v"].append(relevance(r, case))
        cols["c"].append(correctness(r, case))
    print(f"{name:4} {run[0]['release']}" + "".join(f"{mean(v):>9.2f} (n={count(v):2})" for v in cols.values()))
```

Três das definições são escolhas que vale notar:

- **Context precision pesa a posição.** Ela tira a média da precisão na posição de cada trecho gold,
  então um trecho certo em primeiro conta mais que o mesmo trecho em terceiro. É a definição que o
  RAGAS usa; uma simples proporção de trechos certos é outra, e daria números diferentes para a mesma
  recuperação.
- **Uma recusa sem trechos não tem context precision**, em vez de precisão zero ou um. Nada foi dado,
  então nada pode estar certo ou errado nisso. Ela ainda tem context recall zero quando a pergunta tinha
  resposta, porque a resposta não foi dada ao modelo.
- **A relevância decide a recusa por regra**, pelo gabarito, como a aula 10 fez: uma recusa passa
  quando a pergunta não tem fatos e reprova quando tem. Um framework que dá nota de irrelevante a toda
  recusa mede outra coisa com o mesmo nome, e a última seção desta aula acha um que faz isso.
