---
title: Um juiz, em código
version: 1
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
    verdict = judge.grade("relevance", question, reply, sources)   # {"score", "verdict", "reason"}

The judge here is judge-1, the lab's stand-in, which grades by embedding
similarity by rules written at the top of lab/labobs.py. The prompt is the one
a team would send a real model; only the model behind it is the lab's.
"""
import json

from openai import OpenAI

from telemetry import span

MODEL = "judge-1"
SYSTEM = """You grade replies written by Marginalia's help assistant to its customers.
Criterion: {criterion}
{rubric}
Reply with a JSON object and nothing else: {{"score": a number from 0 to 1, "verdict": "pass" or "fail", "reason": one sentence}}."""
RUBRIC = {
    "faithfulness": "Is every statement in the reply supported by the sources? A refusal states nothing and passes.",
    "relevance": "Does the reply address the question the customer asked?",
    "correctness": "Does the reply give the same answer as the expected one?",
}
client = OpenAI(max_retries=2, timeout=20)


def grade(criterion, question, reply, sources=(), expected=None):
    numbered = "\n".join(f"[{n}] {s['id']}\n{s['text']}" for n, s in enumerate(sources, 1))
    user = f"<question>{question}</question>\n<reply>{reply}</reply>\n<sources>\n{numbered}\n</sources>"
    if expected is not None:
        user += f"\n<expected>{expected}</expected>"
    with span(f"chat {MODEL}", **{"gen_ai.operation.name": "chat", "gen_ai.request.model": MODEL,
                                   "app.criterion": criterion}) as s:
        r = client.chat.completions.create(model=MODEL, response_format={"type": "json_object"}, messages=[
            {"role": "system", "content": SYSTEM.format(criterion=criterion, rubric=RUBRIC[criterion])},
            {"role": "user", "content": user}])
        s.set_attribute("gen_ai.response.model", r.model)
        s.set_attribute("gen_ai.usage.input_tokens", r.usage.prompt_tokens)
        s.set_attribute("gen_ai.usage.output_tokens", r.usage.completion_tokens)
        verdict = json.loads(r.choices[0].message.content)
        s.set_attribute("app.verdict", verdict["verdict"])
    return verdict
```

**O modelo por trás do prompt é o judge-1, o substituto do laboratório.** Ele não lê: mede a
semelhança de embeddings, por regras escritas no topo de `lab/labobs.py`, e responde no formato que o
prompt pede. O prompt é o que uma equipe mandaria a um modelo de verdade, e todo número que esta aula
tira dele (quantas respostas foram avaliadas, quanto isso custou, quão certa uma amostra pode ser) é uma
propriedade da amostragem e da conta, não da inteligência do juiz.

As respostas da semana vêm dos spans: o `traffic.py` reconstrói cada uma como um registro com a
pergunta, a resposta, as fontes (pelos ids de trechos, como na aula 8) e o polegar, se houve:

```python
"""traffic.py: the week's replies as records to grade: question, reply, sources, release, and the thumb if any."""
import json
from collections import defaultdict

import psycopg

text = dict(psycopg.connect().execute("SELECT id, text FROM chunks").fetchall())
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
               "sources": [{"id": c, "text": text[c]} for c in spans["search"]["attributes"]["app.search.chunks"]],
               "thumb": thumbs.get(trace)}
```

Uma resposta, dois critérios:

```python
"""one.py: one reply of the week, graded on two criteria by judge-1."""
import judge
import telemetry
import traffic

telemetry.setup("judge-spans.jsonl", service="judge")
r = next(r for r in traffic.replies() if r["question"].startswith("Above what order value"))
print(r["question"], "->", r["reply"])
for criterion in ("relevance", "faithfulness"):
    print(criterion, judge.grade(criterion, r["question"], r["reply"], r["sources"]))
```

```
ana@lab:~/obs$ python one.py
Above what order value is standard delivery free? -> Express delivery is not free at any order value. [1] standard three to five working days 4.90, free on orders over 40 [2] pickup point three to five working days 2.90, free on orders over 40 [2]
relevance {'criterion': 'relevance', 'score': 0.64, 'verdict': 'pass', 'reason': 'similarity of question and reply 0.64, threshold 0.4'}
faithfulness {'criterion': 'faithfulness', 'score': 1.0, 'verdict': 'pass', 'reason': '1 of 1 sentences supported'}
```

É a resposta que a aula 1 explicou pelo trace e em que a aula 8 não achou defeito: o cliente perguntou
da entrega padrão e a resposta começa pela expressa. **O judge-1 aprova nos dois critérios.** Ela é
relevante, com semelhança de 0,64 com a pergunta, porque divide as palavras da pergunta; e é fiel,
porque cada frase está numa fonte. Os dois veredictos são exatamente o que as regras do judge-1 dizem,
e os dois descrevem um ponto cego que um juiz de verdade também tem, de forma menos grosseira: uma
resposta que repete o vocabulário da pergunta parece relevante. A aula 10 mede com que frequência o
judge-1 e as pessoas discordam, e esta resposta é do tipo em que discordam.
