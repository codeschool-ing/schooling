---
title: Uma métrica sua
version: 2
---

O que um framework dá antes de qualquer métrica é a sua **estrutura**: casos de teste, um executor, um relatório, um
cache, uma integração com o pytest. Uma métrica é qualquer classe que saiba dizer uma nota, uma razão e
se passou, então as verificações que este curso já tem rodam dentro do DeepEval como estão.

O `deepeval_run.py` escreve duas. A `JudgeRelevance` é o juiz da aula 10 com a regra das recusas. A
`FactCheck` é a verificação de fatos normalizada da aula 8, que lê os fatos dos metadados do caso de
teste. E ao lado delas ele roda uma das do próprio DeepEval, a fidelidade, com o modelo local como juiz,
nas quarenta e oito respostas. Uma recusa não recuperou nada, e a fidelidade recusa um contexto vazio,
então esses casos levam um texto provisório dizendo isso:

```python
"""deepeval_run.py: the forty-eight replies of lesson 10 as DeepEval test cases, under two metrics
written here and one of DeepEval's own."""
import json
from collections import defaultdict

from deepeval import evaluate
from deepeval.evaluate.configs import AsyncConfig, DisplayConfig, ErrorConfig
from deepeval.metrics import BaseMetric, FaithfulnessMetric
from deepeval.models import LocalModel
from deepeval.test_case import LLMTestCase

import checks
import judge
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


class JudgeRelevance(BaseMetric):
    """The judge's relevance verdict, with the refusal decided by the answer key as lesson 10 did."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        if checks.is_refusal(case.actual_output):
            self.score = 0.0 if case.metadata["facts"] else 1.0
            self.reason = "the agreed refusal, decided by the answer key"
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
        return "judge relevance"


class FactCheck(BaseMetric):
    """Lesson 8's normalised fact check: the expected fact is in the reply, or an unanswerable question was refused."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        self.score = float(normalised(case.actual_output, case.metadata["facts"]))
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


model = LocalModel(model="llama3.2:3b", base_url="http://127.0.0.1:11434/v1", api_key="ollama", temperature=0)
tests = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        tests.append(LLMTestCase(name=f"{r['id']} {r['release']}", input=r["question"], actual_output=r["reply"],
                                 retrieval_context=[s["text"] for s in r["sources"]] or ["(nothing was retrieved)"],
                                 metadata={"facts": cases[r["id"]]["facts"], "release": r["release"]}))
metrics = [JudgeRelevance(), FactCheck(), FaithfulnessMetric(model=model, async_mode=False)]
# ignore_errors: a metric that fails on one case is recorded as an error, and the run goes on
result = evaluate(tests, metrics, async_config=AsyncConfig(run_async=False),
                  display_config=DisplayConfig(print_results=False, show_indicator=False),
                  error_config=ErrorConfig(ignore_errors=True))
passed, errors = defaultdict(int), defaultdict(int)
for t in result.test_results:
    for m in t.metrics_data:
        if m.error:
            errors[t.metadata["release"], m.name] += 1
            continue
        passed[t.metadata["release"], m.name] += m.success
        if m.name == "Faithfulness" and not m.success:
            print(f"  faithfulness failed {t.name}: {t.actual_output[:60]}")
for release in ("2026.09.4", "2026.10.1"):
    print(release, "  ".join(f"{name} {passed[release, name]}/24"
                             + (f" ({errors[release, name]} errors)" if errors[release, name] else "")
                             for name in ("judge relevance", "fact check", "Faithfulness")))
```

```
ana@dev:~/obs$ python deepeval_run.py | grep -E "faithfulness failed|^2026"
  faithfulness failed e01 2026.09.4: According to [1], you have 30 days from delivery to return a
  faithfulness failed e08 2026.09.4: According to source [1], express delivery costs R$ 29.90.
  faithfulness failed e12 2026.09.4: I could not find that in our documents.
  faithfulness failed e02 2026.10.1: According to [1], the customer pays for the return postage.
  faithfulness failed e06 2026.10.1: According to [1], standard delivery takes three to six worki
  faithfulness failed e07 2026.10.1: According to [1], standard delivery is free on orders over R
  faithfulness failed e08 2026.10.1: According to source [1], express delivery costs R$ 29.90.
  faithfulness failed e12 2026.10.1: Unfortunately, according to [1], e-books purchased from us a
  faithfulness failed e13 2026.10.1: According to [1], yes, you can download audiobooks to listen
  faithfulness failed e16 2026.10.1: You will receive the electronic invoice for your order as so
  faithfulness failed e18 2026.10.1: According to [1], if the order costs more than the card hold
2026.09.4 judge relevance 15/24  fact check 22/24  Faithfulness 6/24 (15 errors)
2026.10.1 judge relevance 16/24  fact check 18/24  Faithfulness 3/24 (13 errors)
```

O `grep` guarda as linhas do próprio script e tira o cabeçalho e o resumo do DeepEval. O resumo conta
um caso de teste como aprovado só quando toda métrica nele passou, uma regra justa para um teste e ruim
para um relatório, porque esconde qual métrica falhou; as contagens por métrica do script são o
relatório. Leia primeiro as
duas contagens do fim, depois a lista acima delas.

**As verificações que este curso escreveu passam sem mudança.** A verificação de fatos aprova 22 e 18
respostas de 24, a aritmética da aula 8 dentro do executor do DeepEval. A relevância do juiz aprova 15 e
16, com as recusas decididas pelo gabarito como a aula 10 fez. Embrulhar uma verificação num framework
não acrescenta conhecimento; acrescenta a maquinaria em volta dela.

**A fidelidade do DeepEval deu número para vinte respostas de quarenta e oito.** Para as outras 28 a
resposta do modelo local num dos passos não foi o JSON que a métrica pediu, e a métrica parou com o
conselho do próprio DeepEval: *"Evaluation LLM outputted an invalid JSON. Please use a better evaluation
model."* Sem `ignore_errors` a primeira delas para a execução inteira, que foi o que aconteceu na
primeira vez que este script rodou. Com ele, cada falha é um erro no seu caso, contado ao lado da nota.

**E das onze respostas que ela reprovou, uma é infiel.** A e02 na versão nova, a resposta que contradiz
a fonte, está na lista, com razão. Também estão o prazo de devolução, o preço da entrega expressa, o
prazo de entrega, o limite de frete grátis, a nota fiscal e o Kindle, cada uma dizendo o que a sua fonte
diz, e uma recusa, que não diz nada. Uma métrica que dá nota a menos da metade das respostas, e erra dez
das suas onze reprovações, não está medindo fidelidade com este juiz, seja qual for o nome dela. É o
conselho da mensagem de erro, e o método da aula 10 teria dito o mesmo antes de o número chegar a um
relatório.

Mais uma coisa que a lista mostra: a e12 na versão nova não é a recusa que era na aula 10. As execuções
foram feitas de novo para esta captura, e desta vez o modelo respondeu à pergunta do Kindle. Respostas
mudam de uma execução para a outra, com temperatura 0, e é por isso que toda aula que corrige respostas
guarda a execução que corrigiu.

## Quanto vale a maquinaria

- **Uma forma só para toda verificação.** O juiz, os fatos e uma métrica de framework recebem o mesmo
  caso de teste e devolvem a mesma nota, razão e sucesso, então acrescentar uma métrica é uma linha numa
  lista.
- **Um executor.** O `evaluate()` rodou 48 casos e três métricas, registrando um erro por caso em vez
  de parar quando pedido. Com `run_async=True` ele os rodaria ao mesmo tempo; aqui roda um de cada vez,
  porque o juiz divide um processador com todo o resto.
- **Um registro.** A pasta `.deepeval` guarda a última execução por inteiro.

```
ana@dev:~/obs$ ls -a .deepeval
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
