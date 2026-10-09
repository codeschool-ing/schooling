---
title: Um juiz, em código
version: 2
---

A aula 8 terminou onde as regras param: se uma resposta responde à pergunta, e se o que ela diz é
verdade segundo as suas fontes. O instrumento de costume para isso é um segundo modelo, a quem se pede
que leia a pergunta, a resposta e as fontes e diga se passa ou falha. Chama-se **LLM-as-judge**, e a
aula 8 de `rag` e a aula 13 de `prompt-reliability` descrevem o método e os seus vieses conhecidos. Esta
aula é sobre usar um no **tráfego real**, onde não há gabarito, e sobre quanto isso custa.

O tráfego real decide quais critérios são possíveis. **Correção** precisa de uma resposta esperada, e a
pergunta de um cliente não tem nenhuma. **Relevância**, se a resposta trata da pergunta, e
**fidelidade**, se tudo o que ela diz tem apoio nas fontes que recebeu, só precisam do que o trace já
guarda. São esses dois que um juiz consegue fazer em produção.

O `judge.py` pede ao juiz um critério de cada vez e faz o trace da chamada como de qualquer outra
chamada de modelo:

```python
"""judge.py: a model asked to grade one reply on one criterion, with the call traced and priced like any other.

    import judge
    verdict = judge.grade("relevance", question, reply, sources)   # {"criterion", "score", "verdict", "reason"}

The judge is llama3.2:3b, the same model that writes the replies, through the
same Ollama: the judge a team has when it has one model. It is asked at
temperature 0, so that the same reply is graded the same way twice as far as
the model allows. A reply it grades in a shape this file cannot read comes back
with the verdict "unreadable", never as a pass or a fail.
"""
import json

from openai import OpenAI

from telemetry import span

MODEL = "llama3.2:3b"
SYSTEM = """You grade replies written by Marginalia's help assistant to its customers.
Criterion: {criterion}
{rubric}
Reply with a JSON object and nothing else: {{"score": a number from 0 to 1, "verdict": "pass" or "fail", "reason": one sentence}}."""
RUBRIC = {
    "faithfulness": "Is every statement in the reply supported by the sources? A refusal states nothing and passes.",
    "relevance": "Does the reply address the question the customer asked?",
    "correctness": "Does the reply give the same answer as the expected one?",
}
client = OpenAI(max_retries=2, timeout=120)


def grade(criterion, question, reply, sources=(), expected=None):
    numbered = "\n".join(f"[{n}] {s['id']}\n{s['text']}" for n, s in enumerate(sources, 1))
    user = f"<question>{question}</question>\n<reply>{reply}</reply>\n<sources>\n{numbered}\n</sources>"
    if expected is not None:
        user += f"\n<expected>{expected}</expected>"
    with span(f"chat {MODEL}", **{"gen_ai.operation.name": "chat", "gen_ai.request.model": MODEL,
                                   "gen_ai.request.temperature": 0, "app.criterion": criterion}) as s:
        r = client.chat.completions.create(model=MODEL, temperature=0, response_format={"type": "json_object"},
                                           messages=[{"role": "system", "content": SYSTEM.format(
                                                         criterion=criterion, rubric=RUBRIC[criterion])},
                                                     {"role": "user", "content": user}])
        s.set_attribute("gen_ai.response.model", r.model)
        s.set_attribute("gen_ai.usage.input_tokens", r.usage.prompt_tokens)
        s.set_attribute("gen_ai.usage.output_tokens", r.usage.completion_tokens)
        text = r.choices[0].message.content
        try:
            verdict = json.loads(text)
            if verdict.get("verdict") not in ("pass", "fail"):
                raise ValueError
        except (ValueError, AttributeError):
            verdict = {"score": None, "verdict": "unreadable", "reason": text[:120]}
        s.set_attribute("app.verdict", verdict["verdict"])
    return {"criterion": criterion, **verdict}
```

**O juiz é o `llama3.2:3b`, o modelo que escreveu as respostas.** É o juiz que uma equipe tem quando
tem um modelo só, e é o arranjo mais fraco que existe: um modelo avaliando a si mesmo divide os
próprios pontos cegos, e um modelo pequeno lê uma rubrica com menos cuidado que um grande. A aula o usa
mesmo assim, por dois motivos. Ele roda na sua máquina, então todo número abaixo é um que você
reproduz. E as perguntas desta aula, quantas respostas avaliar, quão certo é o resultado e quanto
custa, são sobre amostragem e sobre a conta, e têm as mesmas respostas com um juiz melhor. A aula 10
mede com que frequência este juiz concorda com pessoas.

As respostas da semana vêm dos spans: o `week.py` reconstrói cada uma como um registro com a
pergunta, a resposta, as fontes (pelos ids de trechos, como na aula 8) e o polegar, se houve:

```python
"""week.py: the week's replies as records to grade: question, reply, sources, release, and the thumb if any."""
import json
from collections import defaultdict

text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}


def replies(path="spans.jsonl"):
    by = defaultdict(dict)
    for s in map(json.loads, open(path)):
        by[s["trace"]][s["name"]] = s
    for trace, spans in sorted(by.items(), key=lambda kv: kv[1]["ask"]["start"]):
        a = spans["ask"]["attributes"]
        if a["app.feature"] == "summary":
            continue
        yield {"trace": trace, "release": a["app.release"], "feature": a["app.feature"],
               "question": a["app.question"], "reply": a["app.reply"], "outcome": a["app.outcome"],
               "sources": [{"id": c, "text": text[c]} for c in spans["search"]["attributes"].get("app.search.chunks", [])],
               "thumb": thumbs.get(trace)}
```

Uma resposta, dois critérios:

```python
"""one.py: one reply of the week, graded on two criteria by the judge."""
import judge
import telemetry
import week

telemetry.setup("judge-spans.jsonl", service="judge")
r = next(r for r in week.replies() if "the customer pays" in r["reply"])   # the reply lesson 8 found
print(r["question"], "->", r["reply"])
for criterion in ("relevance", "faithfulness"):
    print(criterion, judge.grade(criterion, r["question"], r["reply"], r["sources"]))
```

```
ana@dev:~/obs$ python one.py
Order [order] - I want to return it. Who pays for the return postage? Rafael Lima, [phone] -> According to [1], "Returns are free: we e-mail you a prepaid label, and you drop the parcel at any post office." This indicates that the customer pays for the return postage.

I could not find any information in [2] that contradicts this statement, as it only mentions the right of withdrawal under Brazil's Consumer Protection Code, which does not specify who pays for return postage.
relevance {'criterion': 'relevance', 'score': 0, 'verdict': 'fail', 'reason': 'The reply does not directly address the question of who pays for the return postage, but rather cites the general return policy and the right of withdrawal, which is not directly relevant to the question.'}
faithfulness {'criterion': 'faithfulness', 'score': 0.5, 'verdict': 'fail', 'reason': 'The reply partially contradicts the statement, as it does not explicitly state that the customer pays for the return postage, but rather that the company emails a prepaid label.'}
```

É a resposta que a aula 8 achou na semana: o cliente pergunta quem paga o frete da devolução, e a
resposta cita o documento dizendo que a devolução é grátis e depois conclui que o cliente paga. **O
juiz a reprova nos dois critérios, e os dois motivos estão errados.** Em relevância ele diz que a
resposta não trata de quem paga, quando ela não faz outra coisa. Em fidelidade ele diz que a resposta
"não afirma explicitamente que o cliente paga", quando é exatamente o que ela afirma, em falso. O
veredicto é o certo para fidelidade, e o motivo enganaria quem o lesse.

E nem é o mesmo motivo duas vezes. Rode o `one.py` de novo e o motivo de fidelidade pode voltar com
outras palavras, com temperatura 0, porque o servidor agrupa e arredonda de outro jeito de uma chamada
para a outra; a aula 1 disse o mesmo das respostas do assistente. O veredicto de um juiz é uma medida
com um erro próprio, e o resto desta aula e a próxima o tratam assim.
