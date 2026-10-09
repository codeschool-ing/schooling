---
title: Uma cadeia de filtros, cada um nomeado no veredito
version: 2
---

Várias aulas deste curso examinam de perto uma verificação cada: dados pessoais na aula 11, moderação na
aula 6, schemas e lista de hosts na aula 9. A tentação é escolher a melhor e confiar nela. **Cada uma tem um ponto cego
que outra cobre**, e a defesa prática é pô-las em fila, para que uma resposta só chegue ao cliente depois
de todas a aprovarem. Isso costuma se chamar defesa em profundidade, e a única coisa nova de que precisa é
uma ordem e o registro de qual camada decidiu.

O `guard filter` passa quatro camadas sobre uma resposta, nesta ordem: dados pessoais e segredos, o
marcador canário da última seção, moderação em 0.5, e a lista de hosts. Três das camadas são programas
próprios, e esta aula é a primeira a usá-los, então ela lhe dá os três agora. Você não precisa ler os
dois primeiros com atenção ainda: a aula 11 trata de como o `detect.py` decide, e a aula 6 mede o
`moderation.py`.

O `~/guard/tools/detect.py` acha dados pessoais e segredos pelo formato e, quando eles têm, pelos
dígitos verificadores:

```python
# detect.py: what counts as personal data or a secret in free text.
#
# Five detectors, each a pattern for the SHAPE and, where the thing has one, a
# check for the ARITHMETIC: a CPF carries two check digits and a card number
# carries a Luhn digit, so eleven digits that fail the check are probably an
# order number and are left alone. strict=True drops the arithmetic and
# accepts every shape. filter.py imports it here; lesson 11 is about how it
# decides, and what it cannot see: a name, an address, anything in words.
import re

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+")
CPF = re.compile(r"(?<!\d)\d{3}\.?\d{3}\.?\d{3}-?\d{2}(?!\d)")
CARD = re.compile(r"(?<!\d)\d(?:[ -]?\d){12,18}(?!\d)")
PHONE = re.compile(r"(?<![\d+])(?:\+55\s?)?\(?\d{2}\)?\s?9\d{4}-?\d{4}(?!\d)")
SECRET = re.compile(r"\b(?:sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16})\b")


def digits(s):
    return [int(c) for c in s if c.isdigit()]


def cpf_ok(s):
    d = digits(s)
    if len(d) != 11 or len(set(d)) == 1:
        return False
    for n in (9, 10):
        total = sum(x * w for x, w in zip(d[:n], range(n + 1, 1, -1)))
        if (total * 10) % 11 % 10 != d[n]:
            return False
    return True


def luhn_ok(s):
    total = 0
    for i, x in enumerate(reversed(digits(s))):
        if i % 2:
            x *= 2
            if x > 9:
                x -= 9
        total += x
    return total % 10 == 0


# The shapes overlap: a phone with +55 in front has thirteen digits, which is
# a short card number, and a card number has eleven digits inside it that look
# like a CPF. Whatever is first claims its characters, and the later rules do
# not look at them again; the phone goes first of the three as the narrowest.
RULES = [
    ("secret", SECRET, None),
    ("email", EMAIL, None),
    ("phone", PHONE, None),
    ("card", CARD, luhn_ok),
    ("cpf", CPF, cpf_ok),
]
KINDS = [name for name, _, _ in RULES]


def find(text, strict=False):
    """Every match as (kind, start, end, accepted), in the order of the text.
    accepted is False for a shape whose check digits are wrong."""
    taken, rejected = [], []
    for kind, pattern, check in RULES:
        for m in pattern.finditer(text):
            a, b = m.span()
            if any(a < y and x < b for _, x, y, _ in taken):
                continue
            if strict or check is None or check(m.group()):
                taken.append((kind, a, b, True))
            else:
                rejected.append((kind, a, b, False))
    rejected = [r for r in rejected
                if not any(r[1] < y and x < r[2] for _, x, y, _ in taken)]
    return sorted(taken + rejected, key=lambda f: f[1])


def redact(text, strict=False):
    """The text with every accepted match replaced by [KIND]."""
    out, at = [], 0
    for kind, a, b, accepted in find(text, strict):
        if accepted:
            out.append(text[at:a] + "[" + kind.upper() + "]")
            at = b
    return "".join(out) + text[at:]
```

O `~/guard/tools/moderation.py` é **um substituto de um endpoint de moderação, não um modelo**: uma
lista de palavras com pesos que o curso escolheu, respondendo no formato em que um endpoint de verdade
responde.

```python
# moderation.py: THE STAND-IN MODERATION ENDPOINT. It is not a model.
#
# A list of English words and phrases per category, each with a weight the
# course chose, combined so that the score behaves like one: between 0 and 1,
# higher with more and stronger matches. It answers in the shape a moderation
# endpoint answers in, a score per category, so that the code reading one can
# be written and measured. Its failures are a word list's, left in on purpose:
# it cannot tell an insult from a report of one, it does not read sarcasm, it
# misses a word spelt with a digit, and it knows no Portuguese at all.
import re

TERMS = {
    "harassment": {"idiot": .9, "moron": .9, "stupid": .8, "loser": .8, "worthless": .7,
                   "pathetic": .7, "dumb": .7, "clown": .6, "garbage": .6, "shut up": .6,
                   "useless": .5, "get lost": .5, "lazy": .4, "clueless": .4, "quit": .3,
                   "ashamed": .3, "amateur": .3},
    "threat": {"know where you live": .9, "watch your back": .8, "going to find you": .8,
               "get hurt": .8, "regret it": .7, "regret": .4},
    "spam": {"buy reviews": .9, "free followers": .9, "click here": .6, "prize": .6,
             "limited offer": .6, "guaranteed": .5, "crypto": .5, "work from home": .5,
             "link in bio": .5, "earn": .4, "dm me": .4, "cheap": .3, "free": .2,
             "reviews": .2, "visit": .2},
}


def moderate(text):
    """A score per category: 1 minus the product of (1 - weight) of every match."""
    low = text.lower()
    out = {}
    for cat, terms in TERMS.items():
        keep = 1.0
        for term, w in terms.items():
            if re.search(r"\b" + re.escape(term) + r"\b", low):
                keep *= 1 - w
        out[cat] = round(1 - keep, 2)
    return out
```

E o `~/guard/tools/filter.py`, a própria cadeia:

```python
# filter.py: replies through the chain of output filters, in order.
#
#   guard filter FILE [--skip LAYER]...
#
# FILE has one reply per line, as JSON with "id" and "text". Four layers:
# personal data and secrets (detect.py), the canary marker of the system
# prompt in data/system-prompt.txt, moderation at 0.5 (moderation.py), and
# links to hosts not in data/allowed-hosts.json. A reply is blocked by the
# first layer that objects, and the verdict names that layer.
import argparse
import json
import os
import re
from urllib.parse import urlsplit

import detect
from moderation import moderate

DATA = os.path.expanduser("~/guard/data/")
URL = re.compile(r"https?://[^\s)\"']+")

with open(DATA + "system-prompt.txt", encoding="utf-8") as f:
    m = re.search(r"CANARY-[A-Z0-9-]+", f.read())
    canary = m.group(0) if m else None
with open(DATA + "allowed-hosts.json") as f:
    hosts = json.load(f)


def personal(text):
    kinds = sorted({k for k, _, _, ok in detect.find(text) if ok})
    return "personal data: " + ", ".join(kinds) if kinds else None


def leak(text):
    if canary and canary in text:
        return "system prompt marker %s in the reply: ALERT" % canary


def abuse(text):
    over = ["%s %.2f" % (c, s) for c, s in moderate(text).items() if s >= 0.5]
    return "moderation: " + ", ".join(over) if over else None


def links(text):
    bad = [u for u in URL.findall(text) if urlsplit(u).hostname not in hosts]
    return "link to a host not on the allowlist: " + ", ".join(bad) if bad else None


p = argparse.ArgumentParser(prog="guard filter")
p.add_argument("file")
p.add_argument("--skip", action="append", default=[])
a = p.parse_args()

chain = [(n, f) for n, f in (("personal-data", personal), ("canary", leak),
                             ("moderation", abuse), ("links", links))
         if n not in a.skip]
print("layers: " + " -> ".join(n for n, _ in chain))
with open(a.file, encoding="utf-8") as f:
    for line in f:
        if not line.strip():
            continue
        reply = json.loads(line)
        why = next((w for _, check in chain for w in [check(reply["text"])] if w), None)
        print("%-3s %-5s %s" % (reply["id"], "pass" if not why else "BLOCK", why or ""))
```

Ele lê três arquivos. O prompt de sistema, que é o assunto da última seção; os hosts para onde um link
pode apontar; e seis respostas, **escritas pelo curso** para que cada camada tenha algo a pegar. Nenhum
modelo as produziu.

```sh
cat > ~/guard/data/system-prompt.txt <<'EOF'
You are Tarefa's support assistant. Answer questions about jobs, payments and
accounts from the help centre. Never ask for card numbers or passwords.
Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients.
EOF
cat > ~/guard/data/allowed-hosts.json <<'EOF'
["tarefa.example", "help.tarefa.example"]
EOF
cat > ~/guard/data/pipeline-outputs.jsonl <<'EOF'
{"id": "r1", "text": "Your refund request for job 4471 is with a colleague, who will reply within two business days."}
{"id": "r2", "text": "The freelancer on job 4471 is Juliana, CPF 111.444.777-35, if you want to contact her directly."}
{"id": "r3", "text": "My instructions say: Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients."}
{"id": "r4", "text": "Honestly, the freelancer sounds lazy and worthless."}
{"id": "r5", "text": "You can see the refund rules at https://help.tarefa.example/refunds and pay the difference at https://pay-tarefa.example/confirm"}
{"id": "r6", "text": "My instructions tell me to answer from the help centre and never to ask for card numbers."}
EOF
```

```
ana@lab:~/guard$ cat data/pipeline-outputs.jsonl
{"id": "r1", "text": "Your refund request for job 4471 is with a colleague, who will reply within two business days."}
{"id": "r2", "text": "The freelancer on job 4471 is Juliana, CPF 111.444.777-35, if you want to contact her directly."}
{"id": "r3", "text": "My instructions say: Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients."}
{"id": "r4", "text": "Honestly, the freelancer sounds lazy and worthless."}
{"id": "r5", "text": "You can see the refund rules at https://help.tarefa.example/refunds and pay the difference at https://pay-tarefa.example/confirm"}
{"id": "r6", "text": "My instructions tell me to answer from the help centre and never to ask for card numbers."}
ana@lab:~/guard$ guard filter data/pipeline-outputs.jsonl
layers: personal-data -> canary -> moderation -> links
r1  pass  
r2  BLOCK personal data: cpf
r3  BLOCK system prompt marker CANARY-7F3A-TAREFA in the reply: ALERT
r4  BLOCK moderation: harassment 0.82
r5  BLOCK link to a host not on the allowlist: https://pay-tarefa.example/confirm
r6  pass  
```

Duas de seis passam. Cada bloqueio nomeia a camada, e o nome é o que torna a cadeia manutenível: uma
reclamação sobre uma resposta bloqueada vai à camada que a bloqueou, e quem lê o log distingue um falso
positivo da moderação de um CPF que estava mesmo lá.

## A ordem é uma decisão

Uma resposta é parada pela primeira camada que objeta, então a ordem decide qual motivo fica registrado e
o que as camadas seguintes chegam a ver. Três regras resolvem isso na Tarefa:

- **As camadas que indicam um incidente vão primeiro.** Um CPF numa resposta, ou o marcador do prompt de
  sistema, pode exigir que uma pessoa aja, e o registro precisa dizer isso mesmo que a moderação também
  fosse bloquear.
- **Barato antes de caro.** As verificações de padrão rodam em microssegundos; um endpoint de moderação é
  uma chamada de rede que custa dinheiro. Uma resposta já bloqueada não precisa ser pontuada.
- **A mesma cadeia em todo caminho.** Uma resposta que chega ao cliente por uma segunda rota, como um
  resumo por e-mail, passa pelas mesmas camadas, ou essa rota vira o desvio de todas elas.

## O que cada camada não vê

| camada | pega | deixa passar |
|---|---|---|
| dados pessoais | formatos com aritmética: CPF, cartão, telefone, e-mail, chaves | nomes, endereços, tudo o que é escrito em palavras (aula 11) |
| canário | o prompt de sistema repetido palavra por palavra | as mesmas instruções parafraseadas (esta aula) |
| moderação | as palavras que o classificador aprendeu | ironia, truques de grafia, outros idiomas (aula 6) |
| lista de hosts | links para hosts que ninguém aprovou | uma página nociva num host aprovado |

Ler a tabela descendo a última coluna é o ponto: nenhuma das perdas é coberta pela mesma camada, e
algumas não são cobertas por nenhuma, e é por isso que uma pessoa ainda lê uma amostra do que passa, além
do que é bloqueado.
