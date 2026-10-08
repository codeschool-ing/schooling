---
title: Regras para a forma de uma resposta
version: 2
---

Um fato precisa de uma resposta esperada. Uma **regra** não: ela é uma propriedade que toda boa resposta
tem, seja qual for a pergunta. Isso faz das regras a avaliação mais barata que existe, e a única que
consegue olhar uma resposta para a qual ninguém escreveu gabarito.

O `checks.py` tem seis:

```python
"""checks.py: rules a reply can be held to without a model, each a function that says pass or fail.

    import checks
    for name, ok, why in checks.run(reply, sources):
        ...

Every check is deterministic: the same reply and sources give the same verdict
on every run, in microseconds, at no cost. Which is why they can run on every
reply in production, and why lesson 15 can make a build fail on them.
"""
import re

import redact

REFUSAL = "I could not find that in our documents."
CITE = re.compile(r"\[(\d+)\]")
NUMBER = re.compile(r"\d+(?:[.,]\d+)?")


def sentences(reply):
    return [s for s in re.split(r"(?<=[.!?\]])\s+(?=[A-Z])", reply.strip()) if s]


def is_refusal(reply):
    return reply.strip() == REFUSAL


def cites_every_sentence(reply, sources):
    """Every sentence of an answer ends with a citation like [1]."""
    if is_refusal(reply):
        return True, "a refusal cites nothing"
    bare = [s for s in sentences(reply) if not CITE.search(s)]
    return not bare, f"{len(bare)} sentence(s) with no citation" if bare else "every sentence cited"


def citations_exist(reply, sources):
    """Every [n] points at a source the model was given."""
    bad = sorted({int(n) for n in CITE.findall(reply) if not 0 < int(n) <= len(sources)})
    return not bad, f"no source {bad}" if bad else "every citation has a source"


def numbers_in_sources(reply, sources):
    """Every number in the reply appears in the text of the sources: no figure comes from nowhere."""
    text = " ".join(s["text"] for s in sources)
    found = set(NUMBER.findall(text))
    stray = [n for n in NUMBER.findall(CITE.sub("", reply)) if n not in found]
    return not stray, f"not in any source: {stray}" if stray else "every number is in a source"


def no_personal_data(reply, sources):
    """The reply repeats no address, telephone, card or order number."""
    f = redact.found(reply)
    return not f, f"repeats {f}" if f else "nothing personal"


def refusal_is_exact(reply, sources):
    """A reply that says it cannot answer says so in the agreed words, so that it can be counted."""
    looks = re.search(r"\b(could not find|do not say|cannot answer|no information)\b", reply, re.I)
    return (not looks or is_refusal(reply)), "not the agreed refusal" if looks and not is_refusal(reply) else "ok"


def short_enough(reply, sources, words=80):
    """An answer to a customer stays under a word limit."""
    n = len(CITE.sub("", reply).split())
    return n <= words, f"{n} words"


CHECKS = [cites_every_sentence, citations_exist, numbers_in_sources, no_personal_data, refusal_is_exact,
          short_enough]


def run(reply, sources):
    """[(name, passed, detail)] for every check."""
    return [(c.__name__, *c(reply, sources)) for c in CHECKS]
```

Cada uma é uma função que recebe uma resposta e as fontes que ela recebeu, e responde passa ou falha e
por quê. Elas codificam o que o prompt de sistema da Marginalia pede e o que importa para a equipe de
atendimento:

- **toda frase cita uma fonte**, como o prompt exige;
- **toda citação aponta para uma fonte que o modelo recebeu**, para que um `[4]` no meio de três fontes
  seja pego;
- **todo número aparece nas fontes**, uma verificação estreita e determinística de fidelidade: um
  preço, um número de dias ou uma porcentagem que não está em fonte nenhuma veio do nada;
- **nenhum dado pessoal volta**, os padrões da aula 2 aplicados à saída;
- **uma recusa usa as palavras combinadas**, para que recusas possam ser contadas e nada que pareça uma
  escape como resposta;
- **uma resposta fica abaixo de 80 palavras**.

Para ver cada uma disparar quando se quer, o `broken.py` passa cinco respostas **escritas pelo curso**
pelas seis, contra o trecho sobre a entrega padrão, que diz que ela custa R$ 12,90 e é grátis acima de
R$ 40:

```python
"""broken.py: five replies the course wrote, each breaking one rule, through every check."""
import json

import checks

source = [c for c in json.load(open("data/index.json"))["chunks"] if c["id"] == "shipping-and-delivery:standard-delivery"]
for reply in ["Standard delivery is free on orders over R$ 40.",
              "Standard delivery is free on orders over R$ 40. [2]",
              "Standard delivery costs R$ 9.90. [1]",
              "Joana, we sent the details to joana.prado@example.com. [1]",
              "Sorry, I could not find anything about that."]:
    failed = [f"{name}: {why}" for name, ok, why in checks.run(reply, source) if not ok]
    print(f"{reply}\n    {'; '.join(failed) or 'passes every check'}")
```

```
ana@dev:~/obs$ python broken.py
Standard delivery is free on orders over R$ 40.
    cites_every_sentence: 1 sentence(s) with no citation
Standard delivery is free on orders over R$ 40. [2]
    citations_exist: no source [2]
Standard delivery costs R$ 9.90. [1]
    numbers_in_sources: not in any source: ['9.90']
Joana, we sent the details to joana.prado@example.com. [1]
    no_personal_data: repeats {'email': 1}
Sorry, I could not find anything about that.
    cites_every_sentence: 1 sentence(s) with no citation; refusal_is_exact: not the agreed refusal
```

Cada resposta quebra a regra que foi escrita para quebrar, e a última quebra duas: uma recusa com
palavras próprias não cita nada e não é a frase combinada, então escaparia de toda contagem de recusas
da aula 5.

Repare no que a regra dos números pegou: **R$ 9,90 é um preço que a fonte não contém**. Um modelo
que "lembra" um preço de outro lugar, ou calcula um número que devia ter copiado, produz exatamente
isso, e nenhum cliente consegue perceber. A próxima seção pega o `llama3.2:3b` fazendo a segunda
coisa. É o único tipo de fidelidade que um programa confere com certeza, e para uma loja cujas
respostas são quase sempre preços, dias e limites, ele cobre uma boa parte do que importa.