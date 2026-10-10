---
title: Runbooks, escritos antes da noite em que são precisos
version: 1
---

A aula 22 terminou com uma regra: todo alerta leva um link para o seu runbook. Esta aula os escreve,
e depois usa um, porque um incidente é o único momento em que ninguém tem tempo de pensar a partir
do zero. **Um runbook é o pensamento feito à luz do dia**, por alguém que estava acordado, para a
pessoa que vai lê-lo às três da manhã.

## Quatro perguntas, sempre as mesmas quatro

Um runbook que é uma página de conselhos é lido por cima. Um que responde às mesmas quatro perguntas
na mesma ordem é usado, porque quem lê sabe onde olhar:

| título | responde |
|---|---|
| What it means | o que aconteceu, em uma ou duas frases, e quão grave é |
| Look first | os comandos que confirmam e dimensionam, na ordem de rodar |
| Safe now | o que a pessoa de plantão pode fazer sozinha, antes de mais alguém acordar |
| Call | quem precisa ser avisado, e quando |

*Safe now* é o título que mais importa e o que mais falta. Revogar uma chave quebra o que a usa;
fazer rollback de um prompt desfaz o trabalho de alguém. O runbook decide antes que a pessoa de
plantão **pode** fazer isso sem perguntar, porque esperar permissão é como uma chave vazada fica viva
por mais quatro horas.

Dois runbooks, para duas das três regras da aula 22. Os títulos ficam em inglês, como o resto dos
arquivos do laboratório, porque é por eles que a verificação procura. Cole:

```sh
mkdir -p ~/guard/data/runbooks
cat > ~/guard/data/runbooks/canary.md <<'EOF'
# canary: the system prompt reached a reply

## What it means
A reply carried CANARY-7F3A-TAREFA, so the system prompt, or part of it,
reached a client. Everything the prompt holds has leaked with it.

## Look first
- the call the alert names: guard trace CALL
- what the prompt includes, and whether any of it is a credential
- guard keys --now TODAY, for what each credential may do

## Safe now
- revoke every credential the prompt held; guard blast KEY says what stops
- open an incident with guard incident, and write each step with its time
- keep the call log: it is the evidence, so pause the sweep

## Call
- the owner of each revoked key, to issue its replacement
- the encarregado, if the prompt or a key reaches personal data
EOF
cat > ~/guard/data/runbooks/rejects.md <<'EOF'
# rejects: replies the schema refused, above their usual level

## What it means
More of the classifier's replies than usual fail lesson 9's schema. The
clients reach a person instead of an answer: slower, not harmful.

## Look first
- guard prompts status: did a file under review change unapproved?
- the latest deployment, and data/model.json

## Safe now
- guard prompts rollback FILE VERSION, to the last approved version

## Call
- whoever approved the latest change, in working hours
EOF
```

Cada linha em *Look first* e *Safe now* é um comando deste curso. É de propósito: um runbook que diz
"verifique se a chave foi usada" deixa o leitor descobrir como; um que diz `guard blast KEY` já fez
isso por ele.

## Uma verificação de que todo alerta tem o seu

Runbooks apodrecem como todo o resto: uma regra é criada e ninguém escreve o runbook dela, uma regra
é apagada e o runbook fica, descrevendo um alerta que já não dispara. Salve a verificação como
`~/guard/tools/runbooks.py`:

```python
# runbooks.py: every alert has a runbook, and every runbook says the same four things.
#
#   guard runbooks [--rules SET]
#
# For each rule of SET in data/alerts.json (tuned unless told otherwise) it
# looks for data/runbooks/METRIC.md and checks the four headings a person
# woken at night needs: what the alert means, what to look at first, what is
# safe to do now, and whom to call. A runbook with no rule is reported too:
# it describes an alert that no longer fires. The exit status is 1 while
# anything is missing.
import argparse
import glob
import json
import os

HEADINGS = ["## What it means", "## Look first", "## Safe now", "## Call"]

p = argparse.ArgumentParser(prog="guard runbooks")
p.add_argument("--rules", default="tuned")
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "alerts.json"), encoding="utf-8") as f:
    rules = json.load(f)[a.rules]

missing = 0
metrics = []
for r in rules:
    metrics.append(r["metric"])
    path = os.path.join(home, "runbooks", r["metric"] + ".md")
    if not os.path.exists(path):
        print("%-8s %-6s no runbook" % (r["metric"], r["severity"]))
        missing += 1
        continue
    with open(path, encoding="utf-8") as f:
        lines = [line.rstrip() for line in f]
    absent = [h[3:] for h in HEADINGS if h not in lines]
    if absent:
        print("%-8s %-6s runbook lacks: %s" % (r["metric"], r["severity"], ", ".join(absent)))
        missing += 1
    else:
        print("%-8s %-6s ok" % (r["metric"], r["severity"]))
for path in sorted(glob.glob(os.path.join(home, "runbooks", "*.md"))):
    name = os.path.basename(path)[:-3]
    if name not in metrics:
        print("%-8s %-6s runbook for no rule" % (name, "-"))
        missing += 1
print("%d rules, %d problem(s)" % (len(rules), missing))
raise SystemExit(1 if missing else 0)
```

```
ana@lab:~/guard$ guard runbooks; echo "exit status $?"
canary   page   ok
rejects  ticket ok
denies   page   no runbook
3 rules, 1 problem(s)
exit status 1
```

**A regra que acorda alguém por chamadas de ferramenta negadas não tem runbook.** A aula 22 fez dela
um alerta de madrugada porque um agente forçando o portão é grave, e hoje a pessoa que ela acorda
estaria sozinha. A prática pergunta o que o `denies.md` deveria dizer. Como toda verificação da suíte
da aula 23, esta sai com 1 enquanto faltar alguma coisa, então ela também entra lá.
