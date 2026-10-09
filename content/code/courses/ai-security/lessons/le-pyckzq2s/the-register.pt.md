---
title: Um registro de todo lugar em que um modelo é usado
version: 1
---

Vinte e quatro aulas construíram controles em volta de um assistente. Uma empresa do tamanho da
Tarefa não tem um só: tem o assistente, um classificador, um resumo de disputas, uma funcionalidade
que escreve propostas para os freelancers, e o que quer que alguém do marketing tenha testado numa
terça à tarde. **A governança começa por saber o que existe**, porque um controle não protege um
sistema que ninguém sabe que está rodando.

## O que cada entrada diz

O registro é um arquivo, guardado no repositório como tudo o mais no `~/guard`. Cada sistema nomeia
um dono, o fornecedor e o modelo que chama, o projeto em que é faturado, se trata dados pessoais e
com que base legal, onde está o seu modelo de ameaças, e quando foi revisado pela última vez. O
arquivo também lista os funcionários e os fornecedores que a aula 19 avaliou, para as verificações
terem com o que comparar. Cole:

```sh
cat > ~/guard/data/ai-register.json <<'EOF'
{
 "staff": ["ana.lima", "bruno.alves", "diego.rocha"],
 "assessed": ["local", "provider-c"],
 "systems": [
  {"name": "support-assistant", "owner": "ana.lima", "provider": "local", "model": "llama3.2:3b",
   "project": "assistant", "personal_data": true, "legal_basis": "contract, art. 7 V",
   "threat_model": "data/threats.json", "last_review": "2026-10-01"},
  {"name": "ticket-classifier", "owner": "bruno.alves", "provider": "local", "model": "llama3.2:3b",
   "project": "classifier", "personal_data": true, "legal_basis": "contract, art. 7 V",
   "threat_model": "data/threats.json", "last_review": "2026-10-09"},
  {"name": "dispute-summary", "owner": "carla.dias", "provider": "provider-c", "model": "c-large-2026-03",
   "project": "disputes", "personal_data": true, "legal_basis": "contract, art. 7 V",
   "threat_model": "data/threats.json", "last_review": "2025-08-14"},
  {"name": "proposal-drafting", "owner": "diego.rocha", "provider": "provider-c", "model": "c-small-2026-03",
   "project": "proposals", "personal_data": true, "legal_basis": null,
   "threat_model": null, "last_review": "2026-06-30"}
 ]
}
EOF
```

Um registro que é só uma lista fica velho na semana seguinte. O que o mantém honesto é uma
verificação que o compara com coisas que mudam sozinhas: a lista de funcionários muda quando alguém
sai, o calendário anda, e a fatura do fornecedor lista todo projeto que gastou dinheiro, tenha alguém
anotado ou não. A fatura de setembro do `provider-c`, por projeto; cole:

```sh
cat > ~/guard/data/invoice-provider-c.json <<'EOF'
{"provider": "provider-c", "month": "2026-09", "currency": "BRL",
 "projects": [
  {"project": "disputes", "cents": 18240},
  {"project": "proposals", "cents": 40110},
  {"project": "growth-test", "cents": 9870}
 ]}
EOF
```

Salve a verificação como `~/guard/tools/register.py`:

```python
# register.py: every place Tarefa uses a model, and what each one is missing.
#
#   guard register --now DATE [--invoice FILE ...]
#
# data/ai-register.json lists the staff, the providers lesson 19 assessed,
# and every system that calls a model. Each system is checked for:
#
#   OWNER     no owner, or an owner who is no longer on the staff list
#   REVIEW    no review in the last 365 days
#   BASIS     personal data with no legal basis written down (lesson 12)
#   THREATS   no threat model (lesson 13)
#   PROVIDER  a provider nobody assessed (lesson 19)
#
# Each --invoice is a provider's bill, by project. A project billed and not in
# the register is a system nobody registered, and is reported as UNREGISTERED.
# The exit status is 1 while anything is reported.
import argparse
import datetime as dt
import json
import os

p = argparse.ArgumentParser(prog="guard register")
p.add_argument("--now", required=True)
p.add_argument("--invoice", action="append", default=[])
a = p.parse_args()
now = dt.date.fromisoformat(a.now)

with open(os.path.expanduser("~/guard/data/ai-register.json"), encoding="utf-8") as f:
    reg = json.load(f)

bad = 0
for s in reg["systems"]:
    found = []
    if not s.get("owner") or s["owner"] not in reg["staff"]:
        found.append("OWNER %s is not on the staff list" % s.get("owner"))
    age = (now - dt.date.fromisoformat(s["last_review"])).days
    if age > 365:
        found.append("REVIEW last %s, %d days ago" % (s["last_review"], age))
    if s["personal_data"] and not s.get("legal_basis"):
        found.append("BASIS personal data, no legal basis")
    if not s.get("threat_model"):
        found.append("THREATS no threat model")
    if s["provider"] not in reg["assessed"]:
        found.append("PROVIDER %s was never assessed" % s["provider"])
    bad += bool(found)
    print("%-18s %-12s %s" % (s["name"], s.get("owner") or "-", "; ".join(found) or "ok"))

known = {(s["provider"], s["project"]) for s in reg["systems"]}
total = len(reg["systems"])
for path in a.invoice:
    with open(path, encoding="utf-8") as f:
        bill = json.load(f)
    for line in bill["projects"]:
        if (bill["provider"], line["project"]) not in known:
            total += 1
            bad += 1
            print("%-18s %-12s UNREGISTERED billed by %s for %s: %s %d.%02d" % (
                line["project"], "-", bill["provider"], bill["month"], bill["currency"],
                line["cents"] // 100, line["cents"] % 100))
print("%d systems, %d with problems" % (total, bad))
raise SystemExit(1 if bad else 0)
```

```
ana@lab:~/guard$ guard register --now 2026-10-09 --invoice data/invoice-provider-c.json; echo "exit status $?"
support-assistant  ana.lima     ok
ticket-classifier  bruno.alves  ok
dispute-summary    carla.dias   OWNER carla.dias is not on the staff list; REVIEW last 2025-08-14, 421 days ago
proposal-drafting  diego.rocha  BASIS personal data, no legal basis; THREATS no threat model
growth-test        -            UNREGISTERED billed by provider-c for 2026-09: BRL 98.70
5 systems, 3 with problems
exit status 1
```

## Três tipos de lacuna

**Um dono que saiu.** A Carla escreveu o resumo de disputas e mudou de emprego; o registro ainda a
nomeia, então o sistema não tem dono e ninguém percebeu, porque nada nele quebrou. Ele também está
há 421 dias sem revisão, que é o mesmo problema visto pelo calendário: o dono é a pessoa que teria
agendado a revisão.

**Um sistema registrado sem a lição de casa.** O gerador de propostas manda perfis de freelancers a
um fornecedor e não tem base legal escrita nem modelo de ameaças. A pergunta da aula 12, *com que
base?*, e a da aula 13, *onde os dados cruzam uma fronteira?*, nunca foram feitas. Os dois campos
existem no registro; nenhum foi preenchido.

**Um sistema que ninguém registrou.** O `growth-test` custou R$ 98,70 em setembro e não aparece em
nenhum outro lugar. Alguém, provavelmente com boa intenção, deu uma chave do fornecedor a um
experimento. O que ele envia, se toca em dados pessoais, e se a revisão de usos de marketing da aula
8 se aplica, ninguém na Tarefa sabe dizer. **A fatura é o único inventário que não pode ser
esquecido**, porque quem a escreve é o fornecedor, e por isso é a coisa certa para comparar com o
registro. A chave de cada fornecedor deveria ser emitida por projeto, como a aula 17 fez por
componente, justamente para a fatura poder ser lida assim.

O status de saída é 1, então esta verificação entra na suíte da aula 23, com cada achado como falha
conhecida, com dono e data.
