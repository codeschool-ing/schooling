---
title: Uma métrica sua
version: 1
---

O que um framework dá sem modelo é a sua **estrutura**: casos de teste, um executor, um relatório, um
cache, uma integração com o pytest. Uma métrica é qualquer classe que saiba dizer uma nota, uma razão e
se passou, então as verificações que este curso já tem rodam dentro do DeepEval como estão.

O `deepeval_run.py` escreve duas. A `JudgeRelevance` é o juiz da aula 10 com a regra das recusas. A
`FactCheck` é a verificação de fatos normalizada da aula 8, que lê os fatos dos metadados do caso de
teste:

```python
"""deepeval_run.py: the sixty replies of lesson 10 as DeepEval test cases, graded by two metrics written here."""
import json
from collections import defaultdict

from deepeval import evaluate
from deepeval.evaluate.configs import AsyncConfig, DisplayConfig
from deepeval.metrics import BaseMetric
from deepeval.test_case import LLMTestCase

import checks
import judge
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


class JudgeRelevance(BaseMetric):
    """judge-1's relevance verdict, the agreed refusal passed by rule as lesson 10 decided."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        if checks.is_refusal(case.actual_output):
            self.score, self.reason = 1.0, "the agreed refusal, passed by rule"
        else:
            v = judge.grade("relevance", case.input, case.actual_output,
                            [{"id": "", "text": t} for t in case.retrieval_context])
            self.score, self.reason = float(v["verdict"] == "pass"), v["reason"]
        self.success = self.score >= self.threshold
        return self.score

    async def a_measure(self, case, *args, **kwargs):
        return self.measure(case)

    def is_successful(self):
        return self.success

    @property
    def __name__(self):
        return "judge-1 relevance"


class FactCheck(BaseMetric):
    """Lesson 8's normalised fact check: the expected fact is in the reply, or an unanswerable question was refused."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        facts = case.metadata["facts"]
        self.score = float(normalised(case.actual_output, facts))
        self.reason = "fact found" if self.score else "fact missing"
        self.success = self.score >= self.threshold
        return self.score

    async def a_measure(self, case, *args, **kwargs):
        return self.measure(case)

    def is_successful(self):
        return self.success

    @property
    def __name__(self):
        return "fact check"


tests = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        tests.append(LLMTestCase(name=f"{r['id']} {r['release']}", input=r["question"], actual_output=r["reply"],
                                 retrieval_context=[s["text"] for s in r["sources"]],
                                 metadata={"facts": cases[r["id"]]["facts"], "release": r["release"]}))
result = evaluate(tests, [JudgeRelevance(), FactCheck()], async_config=AsyncConfig(run_async=False),
                  display_config=DisplayConfig(print_results=False, show_indicator=False))
passed = defaultdict(int)
for t in result.test_results:
    for m in t.metrics_data:
        passed[t.metadata["release"], m.name] += m.success
for release in ("2026.09.4", "2026.10.1"):
    print(release, "  ".join(f"{name} {passed[release, name]}/30" for name in ("judge-1 relevance", "fact check")))
```

O DeepEval imprime uma faixa, um aviso e um resumo próprio, com alguns emojis que a página não desenha; o
`grep` fica com a taxa de aprovação do resumo e as duas linhas do script:

```
ana@lab:~/obs$ python deepeval_run.py | grep -E "Pass Rate|^2026"
   » Pass Rate: 58.33% | Passed: 35 | Failed: 25
2026.09.4 judge-1 relevance 30/30  fact check 19/30
2026.10.1 judge-1 relevance 30/30  fact check 16/30
```

As duas linhas no fim são as contagens do próprio script, a partir dos resultados que o DeepEval devolve, e batem com o
que este curso mediu sem framework: o judge-1 aprova toda resposta, como a aula 10 viu, e os fatos estão
em 19 e 16 respostas de 30, como a aula 8 viu. Pôr uma verificação dentro de um framework não acrescenta
conhecimento; acrescenta a maquinaria em volta da verificação.

O resumo do próprio DeepEval diz **35 aprovados e 25 reprovados**. No DeepEval um caso de teste só passa
quando todas as métricas dele passam, então os 25 são exatamente as respostas em que a verificação de
fatos falhou. É uma regra razoável para um teste e ruim para um relatório, porque esconde qual métrica
falhou; as contagens por métrica são o relatório.

## Quanto vale a maquinaria

- **Uma forma só para toda verificação.** O juiz, os fatos e uma métrica de framework recebem o mesmo
  caso de teste e devolvem a mesma nota, razão e sucesso, então acrescentar uma métrica é uma linha numa
  lista.
- **Um executor.** O `evaluate()` rodou 60 casos e duas métricas, e com `run_async=True` os teria rodado
  ao mesmo tempo. Aqui ele roda um de cada vez, para que a ordem das chamadas ao judge-1 seja a mesma em
  toda execução.
- **Um registro.** A pasta `.deepeval` guarda a última execução por inteiro.

```
ana@lab:~/obs$ ls -a .deepeval
.
..
.deepeval-cache.json
.latest_run_full.json
.latest_test_run.json
```

O registro é útil e, como a primeira seção disse, é texto de clientes: esses arquivos pedem o mesmo
cuidado que um trace.

O que a maquinaria não faz é decidir se uma métrica mede alguma coisa. Isso continua sendo o trabalho da
aula 10, e nenhum framework faz por você.
