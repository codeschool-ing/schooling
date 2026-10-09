---
title: O que uma métrica pronta pergunta
version: 2
---

A maioria das métricas de cada framework é avaliada por modelo: um prompt mandado a um modelo à sua
escolha, e aritmética sobre o que volta. O DeepEval chega a um modelo que fala a API da OpenAI, o
Ollama inclusive, pela classe `LocalModel`. O `builtin.py` roda duas métricas do DeepEval, relevância da
resposta e fidelidade, na resposta que a aula 8 achou, a que diz a um cliente que ele paga o frete da
devolução. Inicie antes o `flaky.py` da aula 4, com `python flaky.py &` em `~/obs`: as métricas chegam ao
modelo por ele, e o log dele conta as chamadas.

```python
"""builtin.py: two of DeepEval's own metrics on the reply lesson 8 found, with the local model as their judge.

The model is reached through flaky.py, lesson 4's proxy, so that flaky.log
counts the calls each metric makes.
"""
import json
import os
import time

from deepeval.metrics import AnswerRelevancyMetric, FaithfulnessMetric
from deepeval.models import LocalModel
from deepeval.test_case import LLMTestCase

text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
model = LocalModel(model="llama3.2:3b", base_url="http://127.0.0.1:11435/v1", api_key="ollama", temperature=0)
case = LLMTestCase(input="Who pays for the return postage?",
                   actual_output="According to [1], the customer pays for the return postage.",
                   retrieval_context=[text["returns-policy:how-to-start-a-return"]])
calls = lambda: sum(1 for _ in open("flaky.log")) if os.path.exists("flaky.log") else 0
for metric in (AnswerRelevancyMetric(model=model, async_mode=False), FaithfulnessMetric(model=model, async_mode=False)):
    before, started = calls(), time.monotonic()
    metric.measure(case)
    print(f"{type(metric).__name__}: score {metric.score}, {calls() - before} model calls, "
          f"{time.monotonic() - started:.0f} s")
    for step in ("statements", "claims", "truths"):
        if getattr(metric, step, None):
            print(f"  {step}: {getattr(metric, step)}")
    print("  verdicts:", [v.verdict for v in metric.verdicts])
    print("  reason:", metric.reason)
```

```
ana@dev:~/obs$ python builtin.py


AnswerRelevancyMetric: score 1.0, 3 model calls, 9 s
  statements: ['According to [1], the customer pays for the return postage.']
  verdicts: [<Verdict.YES: 'yes'>]
  reason: The score is 1.00 because there are no irrelevant statements in the actual output, making it a perfect answer that directly addresses the question.
FaithfulnessMetric: score 0.0, 4 model calls, 15 s
  claims: ['According to [1], the customer pays for the return postage.']
  truths: ['Returns are free', "You can return an item by choosing 'Return an item' in your account", 'A prepaid label is emailed to you for returns', 'You can drop the parcel at any post office']
  verdicts: [<Verdict.NO: 'no'>]
  reason: The score is 0.00 because there are no contradictions in the actual output to justify a higher faithfulness score.
```

Os dois veredictos estão certos. A resposta é sobre quem paga o frete, então é relevante, e diz o
contrário da fonte, então não é fiel. E os passos impressos embaixo de cada nota mostram como uma
métrica chega ao número, que é a parte que vale aprender:

- **A relevância da resposta** pediu ao modelo que quebrasse a resposta em **afirmações**
  (*statements*), depois se cada uma é relevante para a pergunta, e dividiu os sins pelo total. Uma
  afirmação, um sim, 1,0.
- **A fidelidade** pediu as **alegações** da resposta (*claims*) e as **verdades** do texto recuperado
  (*truths*), depois se cada alegação tem apoio nas verdades. "The customer pays" contra "Returns are
  free": não, e a nota é 0.

Três coisas nessa saída importam mais que as notas:

- **Cada métrica são várias chamadas de modelo por resposta**: três para relevância e quatro para
  fidelidade aqui, nove e quinze segundos nesta máquina. O preço de uma métrica de framework é o
  preço de todas as suas chamadas, que a aula 9 ensinou a contar, e uma métrica em toda resposta de
  uma semana é esse tanto de chamadas vezes a semana.
- **O motivo é uma chamada separada, e pode estar errado quando a nota está certa.** A fidelidade deu 0
  e explicou com "there are no contradictions in the actual output", o contrário do que o próprio
  veredicto achou. O juiz da aula 9 fez o mesmo. Leia os passos, não a frase do final.
- **Os prompts estão no pacote instalado**, um arquivo de texto por passo, em
  `deepeval/metrics/answer_relevancy/templates/` e nos vizinhos, e dá para lê-los antes da primeira
  execução. O prompt das afirmações trabalha a partir de um exemplo sobre um notebook; um modelo pequeno
  que segue o exemplo de perto demais quebra uma resposta de outro jeito, e a nota se mexe com a quebra.
  Uma equipe que adota uma métrica de framework lê os prompts dela como lê uma função que chama.

O método da aula 10 vale então sem mudança: rode a métrica nas quarenta e oito respostas rotuladas e
meça-a contra pessoas antes de acreditar num número que ela relata.
