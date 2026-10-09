---
title: O modelo propõe uma memória, o código decide
version: 1
---

Um assistente que lembra é mais útil: um cliente que pediu respostas em português não deveria ter de
pedir em toda conversa, e um que sempre paga com Pix não deveria ser perguntado como vai pagar. **A
memória também é um depósito de dados pessoais que o modelo escreve para si mesmo**, a partir do que o
cliente calhou de dizer, guardado por mais tempo que qualquer conversa e lido de volta em todo prompt
depois dela. A aula 13 a desenharia como dois fluxos: texto do cliente para o depósito, e o depósito
de volta para o prompt.

A pergunta de projeto é a que a aula 10 respondeu para as ferramentas. **O modelo propõe; o código
decide.** O modelo é bom em perceber que uma frase é sobre o cliente. Não faz ideia do que a política
de privacidade da Tarefa permite guardar, e nada na resposta dele merece confiança de que isso foi
conferido.

Três mensagens de um cliente, escritas pelo curso, do tipo que um chat de suporte junta num mês. O CPF
tem dígitos verificadores válidos de propósito, como na aula 11, e não é de ninguém. Cole:

```sh
cat > ~/guard/data/conversations.jsonl <<'EOF'
{"id": "k1", "account": "ac-7Q2M", "date": "2026-03-02", "text": "Hi, it's Marcos again. Please answer me in Portuguese from now on, my English is not great. The logo for job 4471 should use dark blue, like my shop's sign."}
{"id": "k2", "account": "ac-7Q2M", "date": "2026-03-09", "text": "Sorry for the delay in approving the draft, I was in hospital for a surgery last week. For the invoice my CPF is 111.444.777-35. I always pay by Pix."}
{"id": "k3", "account": "ac-7Q2M", "date": "2026-03-20", "text": "My new phone is (11) 98765-4321, please call me there. Also, I prefer to get updates once a week rather than every day."}
EOF
```

O programa pede memórias ao modelo num esquema que o servidor impõe, que a aula 14 mostrou fechar o
formato da resposta: no máximo cinco, cada uma um tipo e uma frase de no máximo 120 caracteres. Depois,
cada proposta passa por três regras escritas em código. Ele importa o `ask.py` da aula 1, o
`detect.py` da aula 11 e a lista de palavras sensíveis do `minimise.py` da aula 12. Salve-o como
`~/guard/tools/memory.py`:

```python
# memory.py: what the assistant remembers about a client between conversations.
#
#   guard memory learn CONVERSATIONS --as ACCOUNT
#   guard memory show --as ACCOUNT --now DATE
#   guard memory forget ID --as ACCOUNT
#   guard memory sweep --now DATE
#
# The model PROPOSES memories from a client's messages, in a JSON Schema the
# server enforces: at most five, each a kind and one sentence of at most 120
# characters. The code DECIDES. A proposal is refused when it holds personal
# data detect.py finds (lesson 11), words from the sensitive list of
# minimise.py (lesson 12), or a kind with no retention here; contact details
# belong in the account record, where the client edits them. What is kept is
# written to data/memory/ACCOUNT.jsonl with the date it stops being used.
#
# show lists what the assistant may use on a date, and never another
# account's file. forget deletes one entry. sweep deletes every entry past its
# date from the disk: an expired memory that is still in the file is still
# personal data Tarefa holds.
import argparse
import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.request

import ask
from detect import find
from minimise import sensitive_terms

KEEP_DAYS = {"preference": 365, "job": 90}
FOLDER = os.path.expanduser("~/guard/data/memory")
SYSTEM = ("You maintain the memory of Tarefa's support assistant. From the client's message, "
          "list the facts worth remembering for future conversations with this client, each "
          "as one short sentence about the client, with a kind: preference, job, contact or other.")
SCHEMA = {"type": "object", "required": ["memories"], "additionalProperties": False,
          "properties": {"memories": {"type": "array", "maxItems": 5, "items": {
              "type": "object", "required": ["kind", "text"], "additionalProperties": False,
              "properties": {"kind": {"type": "string",
                                      "enum": ["preference", "job", "contact", "other"]},
                             "text": {"type": "string", "maxLength": 120}}}}}}


def propose(message):
    body = {"model": ask.MODEL, "temperature": 0, "seed": 1,
            "messages": [{"role": "system", "content": SYSTEM},
                         {"role": "user", "content": message}],
            "response_format": {"type": "json_schema", "json_schema": {
                "name": "memories", "schema": SCHEMA, "strict": True}}}
    req = urllib.request.Request(ask.URL + "/chat/completions", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    if ask.KEY:
        req.add_header("Authorization", "Bearer " + ask.KEY)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            return json.loads(json.load(r)["choices"][0]["message"]["content"])["memories"]
    except urllib.error.HTTPError as e:
        sys.exit("memory: %s answered %d: %s" % (ask.URL, e.code, e.read().decode().strip()))
    except urllib.error.URLError as e:
        sys.exit("memory: cannot reach %s (%s). Is Ollama running?" % (ask.URL, e.reason))


def refuse(m):
    """Why a proposed memory may not be kept, or None."""
    found = sorted({kind for kind, _, _, ok in find(m["text"]) if ok})
    if found:
        return "personal data: " + ", ".join(found)
    words = sensitive_terms(m["text"])
    if words:
        return "sensitive (%s)" % ", ".join(words)
    if m["kind"] not in KEEP_DAYS:
        return "kind %s is not kept" % m["kind"]
    return None


def path(account):
    return os.path.join(FOLDER, account + ".jsonl")


def read(account):
    if not os.path.exists(path(account)):
        return []
    with open(path(account), encoding="utf-8") as f:
        return [json.loads(line) for line in f]


def write(account, rows):
    os.makedirs(FOLDER, exist_ok=True)
    with open(path(account), "w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


p = argparse.ArgumentParser(prog="guard memory")
p.add_argument("action", choices=["learn", "show", "forget", "sweep"])
p.add_argument("target", nargs="?")
p.add_argument("--as", dest="account")
p.add_argument("--now")
a = p.parse_args()

if a.action == "learn":
    rows = read(a.account)
    with open(a.target, encoding="utf-8") as f:
        conversations = [json.loads(line) for line in f]
    for c in conversations:
        if c["account"] != a.account:
            continue
        for m in propose(c["text"]):
            why = refuse(m)
            if why:
                print("%s  REFUSE %-10s %-40s %s" % (c["id"], m["kind"], m["text"][:40], why))
                continue
            day = dt.date.fromisoformat(c["date"])
            n = max([int(r["id"][1:]) for r in rows] + [0]) + 1
            rows.append({"id": "m%d" % n, "kind": m["kind"], "text": m["text"],
                         "from": c["id"], "kept": c["date"],
                         "until": str(day + dt.timedelta(days=KEEP_DAYS[m["kind"]]))})
            print("%s  KEEP   %-10s %-40s until %s" % (c["id"], m["kind"], m["text"][:40], rows[-1]["until"]))
    write(a.account, rows)
elif a.action == "show":
    now = dt.date.fromisoformat(a.now)
    rows = [r for r in read(a.account) if dt.date.fromisoformat(r["until"]) >= now]
    print("%s on %s, memories in use: %d" % (a.account, a.now, len(rows)))
    for r in rows:
        print("  %-3s %-10s until %s  %s" % (r["id"], r["kind"], r["until"], r["text"]))
elif a.action == "forget":
    rows = read(a.account)
    left = [r for r in rows if r["id"] != a.target]
    if len(left) == len(rows):
        p.exit(1, "memory: %s has no memory %s\n" % (a.account, a.target))
    write(a.account, left)
    print("forgot %s for %s" % (a.target, a.account))
elif a.action == "sweep":
    now = dt.date.fromisoformat(a.now)
    for name in sorted(os.listdir(FOLDER)) if os.path.isdir(FOLDER) else []:
        account = name[:-len(".jsonl")]
        rows = read(account)
        left = [r for r in rows if dt.date.fromisoformat(r["until"]) >= now]
        write(account, left)
        print("%s: %d deleted, %d kept" % (account, len(rows) - len(left), len(left)))
```

O que o modelo propôs, e o que o código fez com cada proposta:

```
ana@lab:~/guard$ guard memory learn data/conversations.jsonl --as ac-7Q2M
k1  REFUSE contact    Marcos                                   kind contact is not kept
k1  KEEP   job        4471                                     until 2026-05-31
k1  KEEP   preference dark blue logo color                     until 2027-03-02
k2  REFUSE contact    CPF: 111.444.777-35                      personal data: cpf
k2  KEEP   job        always pays by Pix                       until 2026-06-07
k2  REFUSE preference was in hospital for a surgery last week  sensitive (health)
k3  REFUSE contact    (11) 98765-4321                          personal data: phone
k3  KEEP   preference weekly updates preferred                 until 2027-03-20
```

**O modelo propôs guardar um CPF, um telefone e uma cirurgia**, e arquivou a cirurgia como
`preference`. O código recusou os três, cada um com seu motivo: o `detect.py` achou o CPF e o
telefone, e a lista de palavras sensíveis achou as palavras de saúde. Ele também recusou o nome do
cliente, arquivado como `contact`, porque dados de contato moram no cadastro da conta, onde o cliente
os vê e altera, e uma segunda cópia numa memória fica velha no dia em que eles mudam.

## O que as regras não veem

Duas coisas na captura são as regras funcionando como foram escritas e, ainda assim, não sendo o que
uma pessoa gostaria.

- **O fato mais útil nunca foi proposto.** O Marcos pediu respostas em português, e nenhuma memória diz
  isso. O código só consegue recusar o que o modelo oferece. Perder uma boa memória custa ao cliente
  um pedido repetido; guardar uma ruim custa um incidente de privacidade, e é por isso que as regras
  pendem para onde pendem.
- **O tipo decide a retenção, e quem escolheu o tipo foi o modelo.** "Sempre paga com Pix" é uma
  preferência, arquivada como `job`, então será guardada 90 dias em vez de 365. Esse erro encurta uma
  memória, que é a direção segura. Um erro que a alongasse não seria, e esse é um motivo para dar a
  retenção mais longa ao tipo mais estreito.

**Uma lista de coisas recusadas nunca está completa.** O `detect.py` vê cinco formatos de dado pessoal
e a lista sensível vê algumas palavras em inglês. Uma memória que dissesse "a escola da filha dela fica
em Moema" passaria pelas duas. As regras diminuem o risco; a próxima seção limita o que sobra dele,
decidindo de quem é a memória e quanto tempo ela vive.
