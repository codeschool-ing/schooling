---
title: O que uma métrica pronta pergunta
version: 1
---

A maior parte das métricas de cada framework é avaliada por modelo: um prompt mandado a um modelo à sua
escolha, e aritmética sobre o que volta. O `builtin.py` aponta a answer relevancy do DeepEval para o
juiz do laboratório:

```python
"""builtin.py: one of DeepEval's own metrics, answer relevancy, pointed at the lab's judge."""
from deepeval.metrics import AnswerRelevancyMetric
from deepeval.models import OpenAIModel
from deepeval.test_case import LLMTestCase

metric = AnswerRelevancyMetric(model=OpenAIModel(model="judge-1"), async_mode=False)
case = LLMTestCase(input="How much is express delivery?",
                   actual_output="Express delivery is not free at any order value. [1]")
try:
    metric.measure(case)
except Exception as e:
    print(type(e).__name__, e)
```

```
ana@lab:~/obs$ python builtin.py

BadRequestError Error code: 400 - {'error': {'message': 'judge-1 needs a system prompt naming a Criterion and <question> and <reply>', 'type': 'invalid_request_error', 'code': None}}
```

O judge-1 recusa, porque só responde a prompts que nomeiam um critério e levam uma pergunta e uma
resposta entre tags, o formato que o `judge.py` manda. **Nenhuma métrica avaliada por modelo de nenhum
dos dois frameworks roda neste laboratório**, e esta aula não finge o contrário. O que a recusa dá é uma
olhada no que a métrica perguntou, porque o labobs registra toda requisição que recebe, recusada ou não:

```python
"""last_request.py: the last request the lab's model server received, as its log recorded it."""
import json

last = json.loads(open("/var/log/labgen/requests.jsonl").read().splitlines()[-1])
body = last["request"]
print("model ", body["model"], "  status", last["status"])
for m in body["messages"]:
    text = m["content"] if isinstance(m["content"], str) else m["content"][0]["text"]
    print(f"{m['role']}:\n{text}")
```

```
ana@lab:~/obs$ python last_request.py
model  judge-1   status 400
user:
Given the text, breakdown and generate a list of statements presented. Ambiguous statements and single words can be considered as statements, but only if outside of a coherent statement.

Example:
Example text: 
Our new laptop model features a high-resolution Retina display for crystal-clear visuals. It also includes a fast-charging battery, giving you up to 12 hours of usage on a single charge. For security, we’ve added fingerprint authentication and an encrypted SSD. Plus, every purchase comes with a one-year warranty and 24/7 customer support.



{
  "statements": [
    "The new laptop model has a high-resolution Retina display.",
    "It includes a fast-charging battery with up to 12 hours of usage.",
    "Security features include fingerprint authentication and an encrypted SSD.",
    "Every purchase comes with a one-year warranty.",
    "24/7 customer support is included."
  ]
}
===== END OF EXAMPLE ======

**
IMPORTANT: Please make sure to only return in valid and parseable JSON format, with the "statements" key mapping to a list of strings. No words or explanation are needed. Ensure all strings are closed appropriately. Repair any invalid JSON before you output it.
**

Text:
Express delivery is not free at any order value. [1]

JSON:
```

Esse é o primeiro dos três passos da métrica. A answer relevancy do DeepEval pede a um modelo que
quebre a resposta em **afirmações** (*statements*), depois pergunta se cada afirmação é relevante para
o input, depois divide as relevantes pelo total. O que o log mostra é o primeiro passo, palavra por
palavra: uma instrução, um exemplo resolvido sobre um notebook, um pedido de JSON, e a resposta.

Três coisas nele importam mais que a redação:

- **Cada métrica são várias chamadas de modelo por resposta.** Esta faz pelo menos duas, e o preço da
  métrica de um framework é o preço de todas as suas chamadas, que a aula 9 ensinou a contar. O span que
  uma chamada dessas gera, se o cliente do juiz estiver instrumentado, diz quantas.
- **O exemplo faz parte do instrumento.** Um juiz que segue de perto o exemplo do notebook quebra
  "Express delivery is not free at any order value" de um jeito diferente de um que não segue, e a nota
  se mexe com a quebra. Trocar o modelo de juiz muda como o prompt é seguido.
- **O prompt está no pacote instalado**, e pode ser lido antes da primeira execução. Uma equipe que
  adota uma métrica de framework lê o prompt dela do jeito que lê uma função que chama.

Para rodar esta métrica de verdade, o modelo é um argumento: `OpenAIModel(model=...)`, ou qualquer classe
que o DeepEval aceite para outro provedor. O método da aula 10 vale então sem mudança: rodá-la nas
sessenta respostas rotuladas e medir o kappa dela antes de acreditar num número que ela relate.
