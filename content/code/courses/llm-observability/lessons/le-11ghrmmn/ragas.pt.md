---
title: O RAGAS, com e sem modelo
version: 2
---

O RAGAS tem uma família de métricas que **não precisam de modelo**: elas comparam textos. Duas delas
são context precision e context recall, as que a aula 11 calculou pela própria definição. As versões do
RAGAS recebem **contextos de referência**, o texto que deveria ter sido recuperado, e julgam relevante
um trecho recuperado quando a semelhança de texto dele com alguma referência é de pelo menos 0,5. E ele
tem métricas que precisam de um, das quais a **relevância da resposta** (*response relevancy*) é a que a
aula 11 descreveu: um modelo escreve as perguntas que uma resposta responderia, e a nota é quão perto
elas estão da pergunta real, vezes zero se a resposta for evasiva.

O `ragas_run.py` roda os dois tipos. Os contextos de referência são o texto dos trechos gold de cada
pergunta, e os números da aula 11 para as mesmas perguntas são impressos ao lado dos do RAGAS. A
relevância da resposta roda em toda resposta, com o modelo local como juiz; leia o comentário acima de
`llm` antes de rodá-lo, porque foram precisas três tentativas para tirar alguma nota do RAGAS nesta
máquina:

```python
"""ragas_run.py: RAGAS on the forty-eight replies of lesson 10. Its context precision and recall that
need no model, beside lesson 11's own, and its response relevancy with the local model as judge.

The reference contexts are the text of each question's gold chunks."""
import json
import math
from statistics import mean

from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from ragas import EvaluationDataset, RunConfig, SingleTurnSample, evaluate
from ragas.embeddings import LangchainEmbeddingsWrapper
from ragas.llms import LangchainLLMWrapper
from ragas.metrics import NonLLMContextPrecisionWithReference, NonLLMContextRecall, ResponseRelevancy

import checks

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}
text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
# One call at a time, ten minutes each, and JSON mode: without these a small model on a processor
# times out at RAGAS's default of three minutes, or answers in prose RAGAS cannot parse.
llm = LangchainLLMWrapper(ChatOpenAI(model="llama3.2:3b", temperature=0,
                                     model_kwargs={"response_format": {"type": "json_object"}}))
embeddings = LangchainEmbeddingsWrapper(OpenAIEmbeddings(model="all-minilm", check_embedding_ctx_length=False))
slow = RunConfig(max_workers=1, timeout=600)


def ours(chunks, gold):
    """Lesson 11's two definitions: precision weighted by rank, recall as the share of gold chunks given."""
    hits = [c in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return (sum(at) / len(at) if at else 0.0), sum(g in chunks for g in gold) / len(gold)


for run in ("old", "new"):
    rows = [json.loads(line) for line in open(f"runs/{run}.jsonl")]
    with_context = [r for r in rows if cases[r["id"]]["gold"] and r["sources"]]   # RAGAS needs both
    context = evaluate(EvaluationDataset(samples=[SingleTurnSample(
        user_input=r["question"], response=r["reply"], retrieved_contexts=[s["text"] for s in r["sources"]],
        reference_contexts=[text[g] for g in cases[r["id"]]["gold"]]) for r in with_context]),
        metrics=[NonLLMContextPrecisionWithReference(), NonLLMContextRecall()], show_progress=False).to_pandas()
    own = [ours([s["id"] for s in r["sources"]], cases[r["id"]]["gold"]) for r in with_context]
    relevancy = evaluate(EvaluationDataset(samples=[SingleTurnSample(user_input=r["question"], response=r["reply"])
                                                    for r in rows]),
                         metrics=[ResponseRelevancy(llm=llm, embeddings=embeddings)], show_progress=False,
                         run_config=slow).to_pandas()["answer_relevancy"].tolist()
    print(f"{run} {rows[0]['release']}, {len(with_context)} questions with gold and chunks")
    print(f"  RAGAS      precision {context['non_llm_context_precision_with_reference'].mean():.2f}"
          f"   recall {context['non_llm_context_recall'].mean():.2f}")
    print(f"  lesson 11  precision {mean(p for p, _ in own):.2f}   recall {mean(r for _, r in own):.2f}")
    for kind in ("answers", "refusals"):
        scores = [s for r, s in zip(rows, relevancy) if checks.is_refusal(r["reply"]) == (kind == "refusals")]
        got = [s for s in scores if not math.isnan(s)]
        print(f"  response relevancy, {kind}: {len(scores)} replies, {len(scores) - len(got)} with no score"
              + (f", the rest a mean of {mean(got):.2f}" if got else ""))
```

```
ana@dev:~/obs$ python ragas_run.py 2>/dev/null
old 2026.09.4, 19 questions with gold and chunks
  RAGAS      precision 0.99   recall 1.00
  lesson 11  precision 1.00   recall 1.00
  response relevancy, answers: 17 replies, 10 with no score, the rest a mean of 0.70
  response relevancy, refusals: 7 replies, 7 with no score
new 2026.10.1, 17 questions with gold and chunks
  RAGAS      precision 1.00   recall 1.00
  lesson 11  precision 1.00   recall 1.00
  response relevancy, answers: 15 replies, 8 with no score, the rest a mean of 0.79
  response relevancy, refusals: 9 replies, 9 with no score
```

**As métricas de texto concordam com a aula 11, quase exatamente.** Precisão 0,99 e 1,00, recall 1,00
nas duas versões, sobre as perguntas em que o modelo recebeu alguma coisa. É porque as referências são
os próprios trechos gold, então um trecho gold recuperado bate palavra por palavra com a referência.
Faça referências mais longas que um trecho, uma seção inteira dividida em três trechos, e o recall do
RAGAS cairia onde o da aula 11 não cairia: o RAGAS pergunta se cada texto de referência foi achado, e a
aula 11 se cada trecho gold foi. **A referência decide a nota tanto quanto a métrica**, e um recall
publicado sem dizer quais eram as referências não se compara com nada.

**A relevância da resposta deu nota a 14 das 48 respostas.** Nenhuma das dezesseis recusas tem nota, e
dezoito das respostas também não. Para cada uma delas a resposta do modelo local a um dos prompts do
RAGAS não pôde ser lida, e o RAGAS registrou a nota como ausente e seguiu, sem parar a execução e sem
dizer isso na tabela: o programa acima conta as ausentes porque a média do próprio RAGAS as pularia em
silêncio. Numa primeira tentativa com os padrões do RAGAS, duas respostas de teste ficaram sem nota
nenhuma: uma chamada estourou o limite de três minutos, e para a recusa o modelo escreveu a pergunta
dentro de um parágrafo de explicação. Com o modo JSON, a mesma recusa voltou com uma pergunta sobre onde
Albert Einstein nasceu, que é o exemplo do próprio prompt do RAGAS.

Então a afirmação da aula 11, de que o RAGAS dá 0 à recusa combinada porque ela é evasiva, não pôde ser
conferida aqui: com este juiz o RAGAS não dá nota nenhuma a uma recusa. As catorze respostas que ele
pontuou têm média 0,70 e 0,79, o que diz pouco quando dois terços das respostas estão fora dela. **Uma
média sobre as respostas que uma métrica conseguiu pontuar é um número sobre a métrica**, não sobre as
respostas.

Nada disso é o RAGAS quebrado. As métricas dele são escritas para modelos que seguem uma instrução de
JSON sempre, e um modelo de três bilhões de parâmetros num processador não segue. Com um juiz maior a
maioria das notas ausentes apareceria; a lição a guardar é contá-las, a cada execução, ao lado da média.
