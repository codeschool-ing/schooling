---
title: Um prompt é código, então tem versão e revisor
version: 1
---

Tudo o que este curso mediu sobre o assistente da Tarefa foi medido com um prompt específico, um
modelo específico e configurações específicas. Os onze acertos em doze da aula 14, os dois vazamentos
da aula 15, o CPF recusado da aula 16: **mude uma frase do prompt e cada um desses números pode
mudar**, e ninguém vai saber se a mudança não for visível. O registro da aula 13 tinha uma ameaça aberta
exatamente sobre isso, o `T10`: uma resposta que ninguém consegue ligar ao prompt que a produziu.

Então os arquivos que decidem o que o assistente diz são tratados como código. Moram no repositório,
uma mudança neles passa por revisão como qualquer outra, e **cada chamada registra qual versão deles
usou**. Na Tarefa há três tipos:

- **prompts**, as instruções que o modelo recebe;
- **as páginas da central de ajuda** de onde o assistente responde, desde a aula 2. Uma página que diz
  algo falso é repetida pelo assistente, e esse era o `T12` no registro da aula 13;
- **o modelo e suas configurações**, `data/model.json`, porque o mesmo prompt em outro modelo é outro
  programa.

O classificador da aula 14 vira um arquivo, e o modelo dele um segundo arquivo. Cole:

```sh
mkdir -p ~/guard/data/prompts
cat > ~/guard/data/prompts/classify.txt <<'EOF'
You classify support tickets for Tarefa, a freelance marketplace. Reply with JSON and nothing else: {"category": C}, where C is one of refund, delivery, account, other.
EOF
cat > ~/guard/data/model.json <<'EOF'
{"model": "llama3.2:3b", "temperature": 0, "seed": 1}
EOF
```

Uma versão são os dez primeiros dígitos hexadecimais do SHA-256 dos bytes do arquivo, então qualquer
edição, uma palavra ou um espaço, é uma versão nova, e ninguém precisa lembrar de aumentar um número. O
programa que guarda o registro das versões aprovadas imprime o estado de cada arquivo. Salve-o como
`~/guard/tools/prompts.py`:

```python
# prompts.py: the files that decide what the assistant says, under review.
#
#   guard prompts status
#   guard prompts approve FILE --by NAME --on DATE --reason TEXT
#   guard prompts rollback FILE VERSION
#
# The files under review are the prompts in data/prompts/, the help centre
# pages the assistant answers from in data/helpdesk/, and data/model.json,
# which names the model and its settings. A file's VERSION is the first ten
# hex digits of the SHA-256 of its bytes, so any edit, a word or a space, is a
# new version.
#
# status prints every file with its version and whether that exact version
# was approved, and exits with 1 while any is not. approve records who
# approved the current version, when and why, and keeps a copy of its text in
# data/prompt-store/, which is what rollback copies back. Nothing is approved
# without a name.
import argparse
import glob
import hashlib
import json
import os
import shutil

HOME = os.path.expanduser("~/guard")
REGISTRY = os.path.join(HOME, "data", "prompt-registry.json")
STORE = os.path.join(HOME, "data", "prompt-store")


def version(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:10]


def files():
    found = sorted(glob.glob(os.path.join(HOME, "data", "prompts", "*.txt")))
    found += sorted(glob.glob(os.path.join(HOME, "data", "helpdesk", "*.md")))
    return found + [os.path.join(HOME, "data", "model.json")]


def load():
    if not os.path.exists(REGISTRY):
        return []
    with open(REGISTRY, encoding="utf-8") as f:
        return json.load(f)


def approved(registry, rel, ver):
    return next((e for e in registry if e["file"] == rel and e["version"] == ver), None)


if __name__ == "__main__":
    p = argparse.ArgumentParser(prog="guard prompts")
    p.add_argument("action", choices=["status", "approve", "rollback"])
    p.add_argument("file", nargs="?")
    p.add_argument("version", nargs="?")
    p.add_argument("--by")
    p.add_argument("--on")
    p.add_argument("--reason")
    a = p.parse_args()
    registry = load()

    if a.action == "status":
        bad = 0
        for path in files():
            rel = os.path.relpath(path, HOME)
            ver = version(path)
            e = approved(registry, rel, ver)
            bad += e is None
            print("%-28s %s  %s" % (rel, ver, "approved by %s on %s" % (e["by"], e["on"])
                                    if e else "NOT APPROVED"))
        raise SystemExit(1 if bad else 0)

    rel = os.path.relpath(os.path.abspath(a.file), HOME)
    if a.action == "approve":
        if not (a.by and a.on and a.reason):
            p.exit(2, "an approval names who gave it, when and why: --by, --on and --reason\n")
        ver = version(a.file)
        os.makedirs(STORE, exist_ok=True)
        shutil.copyfile(a.file, os.path.join(STORE, ver))
        registry.append({"file": rel, "version": ver, "by": a.by, "on": a.on, "reason": a.reason})
        with open(REGISTRY, "w", encoding="utf-8") as f:
            json.dump(registry, f, indent=1)
        print("approved %s %s by %s" % (rel, ver, a.by))
    else:
        if not approved(registry, rel, a.version):
            p.exit(1, "%s was never approved at version %s\n" % (rel, a.version))
        shutil.copyfile(os.path.join(STORE, a.version), a.file)
        print("restored %s to approved version %s" % (rel, a.version))
```

```
ana@lab:~/guard$ guard prompts status; echo "exit status $?"
data/prompts/classify.txt    aa32449d3f  NOT APPROVED
data/helpdesk/hc-fees.md     ff40a81202  NOT APPROVED
data/helpdesk/hc-payouts.md  0fe2b8eec1  NOT APPROVED
data/helpdesk/hc-refunds.md  f32fa16253  NOT APPROVED
data/model.json              3138932013  NOT APPROVED
exit status 1
```

Cinco arquivos, nenhum aprovado, e o status de saída é 1. Num repositório novo, esse é o ponto de
partida honesto.

## Rodar com uma versão, depois aprová-la

O roteador classifica os tickets da aula 14 com o que estiver valendo e grava uma linha de log por
chamada com a versão do prompt e o modelo. Salve-o como `~/guard/tools/route.py`; ele importa o
`ask.py` da aula 1 e a `version` do `prompts.py`:

```python
# route.py: tickets routed with whatever prompt and model are current, logged.
#
#   guard route TICKETS
#
# It reads the prompt from data/prompts/classify.txt and the model and its
# settings from data/model.json, classifies every ticket, and appends one line
# per call to data/prompt-log.jsonl naming the prompt's version and the model.
# That line is what lets a reply be traced, later, to exactly what produced it.
# The summary names the tickets it got wrong, because two runs can share a
# count and not a single failure.
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

import ask
from prompts import version

HOME = os.path.expanduser("~/guard")
PROMPT = os.path.join(HOME, "data", "prompts", "classify.txt")
LOG = os.path.join(HOME, "data", "prompt-log.jsonl")

p = argparse.ArgumentParser(prog="guard route")
p.add_argument("tickets")
a = p.parse_args()

with open(PROMPT, encoding="utf-8") as f:
    system = f.read().strip()
with open(os.path.join(HOME, "data", "model.json"), encoding="utf-8") as f:
    model = json.load(f)
ver = version(PROMPT)
n = 0
if os.path.exists(LOG):
    with open(LOG, encoding="utf-8") as f:
        n = sum(1 for _ in f)

right = total = 0
missed = []
with open(a.tickets, encoding="utf-8") as f, open(LOG, "a", encoding="utf-8") as log:
    for t in map(json.loads, f):
        body = dict(model, messages=[{"role": "system", "content": system},
                                     {"role": "user", "content": "Classify this ticket: " + t["text"]}])
        req = urllib.request.Request(ask.URL + "/chat/completions", json.dumps(body).encode(),
                                     {"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                text = json.load(r)["choices"][0]["message"]["content"]
        except urllib.error.URLError as e:
            sys.exit("route: cannot reach %s (%s). Is Ollama running?" % (ask.URL, e.reason))
        try:
            value = json.loads(text)
            ok = set(value) == {"category"} and value["category"] == t["expect"]
        except (json.JSONDecodeError, TypeError):
            ok = False
        right += ok
        if not ok:
            missed.append(t["id"])
        total += 1
        n += 1
        log.write(json.dumps({"call": "c%d" % n, "ticket": t["id"], "prompt": "data/prompts/classify.txt",
                              "version": ver, "model": model["model"], "reply": text}) + "\n")
print("prompt version %s, model %s: %d of %d right, missed %s" % (
    ver, model["model"], right, total, ", ".join(missed) or "none"))
```

```
ana@lab:~/guard$ guard route data/tickets.jsonl
prompt version aa32449d3f, model llama3.2:3b: 10 of 12 right, missed t5, t8
ana@lab:~/guard$ guard route data/tickets.jsonl
prompt version aa32449d3f, model llama3.2:3b: 10 of 12 right, missed t5, t8
```

Ele rodou duas vezes, para que uma diferença entre duas versões, mais adiante, não seja uma diferença
entre duas execuções. Essa é a medida que quem revisa olha antes de aprovar: este prompt, neste
modelo, encaminha certo dez dos doze tickets, e erra o `t5` e o `t8`, os dois que a aula 14 já
explicou. Aprovar registra **quem, quando e por quê**, e guarda uma cópia do texto aprovado. Uma
aprovação sem nome, data e motivo é recusada, pelo motivo que a aula 10 deu para as confirmações:

```
ana@lab:~/guard$ guard prompts approve data/prompts/classify.txt --by ana.lima --on 2026-10-01
an approval names who gave it, when and why: --by, --on and --reason
ana@lab:~/guard$ for f in data/prompts/classify.txt data/helpdesk/*.md data/model.json; do guard prompts approve $f --by ana.lima --on 2026-10-01 --reason "reviewed, tickets measured"; done
approved data/prompts/classify.txt aa32449d3f by ana.lima
approved data/helpdesk/hc-fees.md ff40a81202 by ana.lima
approved data/helpdesk/hc-payouts.md 0fe2b8eec1 by ana.lima
approved data/helpdesk/hc-refunds.md f32fa16253 by ana.lima
approved data/model.json 3138932013 by ana.lima
ana@lab:~/guard$ guard prompts status; echo "exit status $?"
data/prompts/classify.txt    aa32449d3f  approved by ana.lima on 2026-10-01
data/helpdesk/hc-fees.md     ff40a81202  approved by ana.lima on 2026-10-01
data/helpdesk/hc-payouts.md  0fe2b8eec1  approved by ana.lima on 2026-10-01
data/helpdesk/hc-refunds.md  f32fa16253  approved by ana.lima on 2026-10-01
data/model.json              3138932013  approved by ana.lima on 2026-10-01
exit status 0
```

Todo arquivo está agora numa versão aprovada, e o status de saída é 0, o que permite rodar o
`prompts.py status` no build com as outras verificações.
