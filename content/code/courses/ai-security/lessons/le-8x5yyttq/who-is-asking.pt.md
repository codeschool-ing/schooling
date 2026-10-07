---
title: Quem está pedindo a chave
version: 2
---

A Tarefa está prestes a abrir o assistente a outras empresas por uma API: uma confeitaria que quer que
ele responda clientes, uma agência de tradução, um escritório de advocacia. Cada uma recebe uma chave,
e a chave chega ao fornecedor do modelo pela conta da própria Tarefa. **O que um cliente fizer com essa
chave, o fornecedor vê a Tarefa fazendo**, e o acordo da Tarefa com o fornecedor, como a maioria
deles, torna a Tarefa responsável por como os próprios clientes usam o acesso. A aula 7 tratou de
distinguir os usuários da Tarefa; esta aula trata de decidir quais empresas viram usuárias.

O primeiro instinto costuma ser que um formulário e um cartão de crédito bastam, já que quem paga é
cliente. O problema é que quem quer abusar de um modelo em escala prefere fazê-lo **pela conta de outra
pessoa**, para que o aviso, a conta e o banimento caiam em outro lugar. Uma API que entrega chaves a
qualquer um com cartão vira exatamente essa conta.

## O que a Tarefa confere

Um pedido de acesso é uma linha de JSON com uma empresa, o CNPJ, um e-mail de contato, um site e o
caso de uso que ela declara. Oito deles, escritos pelo curso para empresas que ele inventou:

```sh
cat > ~/guard/data/applications.jsonl <<'EOF'
{"id": "ap-01", "company": "Doce Lar Confeitaria", "cnpj": "45.781.296/0001-63", "contact": "ana@docelar.example", "website": "docelar.example", "use_case": "customer-support", "description": "Answer our customers' questions about orders, delivery times and opening hours."}
{"id": "ap-02", "company": "Contrata Já RH", "cnpj": "23.045.678/0001-96", "contact": "talentos@contrataja.example", "website": "contrataja.example", "use_case": "hiring-screening", "description": "Rank CVs for our clients' job openings and reject the weakest automatically."}
{"id": "ap-03", "company": "Avalia+ Marketing", "cnpj": "38.901.745/0001-02", "contact": "contato@avaliamais.example", "website": "avaliamais.example", "use_case": "marketing-copy", "description": "Write 5-star reviews of our clients' products to post on marketplaces."}
{"id": "ap-04", "company": "Nuvem Tradutora", "cnpj": "61.527.384/0001-90", "contact": "nuvem.tradutora@webmail.example", "website": "nuvemtradutora.example", "use_case": "translation", "description": "Translate product manuals from English into Portuguese."}
{"id": "ap-05", "company": "Clínica Bem Viver", "cnpj": "70.491.836/0001-11", "contact": "ti@bemviver.example", "website": "bemviver.example", "use_case": "health-information", "description": "Answer patients' questions about their symptoms before an appointment."}
{"id": "ap-06", "company": "Disparo Total", "cnpj": "52.836.417/0001-92", "contact": "vendas@disparototal.example", "website": "disparototal.example", "use_case": "mass-messaging", "description": "Send personalised WhatsApp messages to 200 thousand leads a day."}
{"id": "ap-07", "company": "Studio Pixel", "cnpj": "19.384.756/0001-01", "contact": "oi@studiopixel.example", "website": "studiopixel.example", "use_case": "customer-support", "description": "Answer questions from our design clients about invoices and deadlines."}
{"id": "ap-08", "company": "Lima Advocacia", "cnpj": "11.222.333/0001-81", "contact": "socios@limaadv.example", "website": "limaadv.example", "use_case": "legal-drafting", "description": "Draft first versions of contracts, which one of our lawyers reviews before use."}
EOF
```

```
ana@lab:~/guard$ head -1 data/applications.jsonl
{"id": "ap-01", "company": "Doce Lar Confeitaria", "cnpj": "45.781.296/0001-63", "contact": "ana@docelar.example", "website": "docelar.example", "use_case": "customer-support", "description": "Answer our customers' questions about orders, delivery times and opening hours."}
```

A primeira verificação é aritmética. Um CNPJ traz dois dígitos verificadores, calculados a partir dos
doze anteriores, e um número digitado errado quase sempre falha. As regras desta aula ficam num
módulo, o `~/guard/tools/kyc.py`, e o `guard cnpj` roda a primeira delas:

```python
# kyc.py: deciding which companies get a key to the model.
#
# The policy is in data/use-cases.json; data/cnpj-registry.json stands in for
# the Receita Federal's public CNPJ data, which a real check would query. The
# CNPJ check digits are the real algorithm. Every decision names each rule
# that made it, so that a refusal can be explained to the company refused.
# cnpj.py and onboard.py import it; it prints nothing on its own.
import datetime as dt
import re

YOUNG = 180  # days: a company this new has no history to judge by


def cnpj_ok(cnpj):
    d = [int(c) for c in cnpj if c.isdigit()]
    if len(d) != 14 or len(set(d)) == 1:
        return False
    for n, w in ((12, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]),
                 (13, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])):
        r = sum(x * y for x, y in zip(d[:n], w)) % 11
        if d[n] != (0 if r < 2 else 11 - r):
            return False
    return True


def domain(address):
    return address.split("@")[-1].lower()


def onboard(app, registry, use_cases, now):
    """(decision, tier, reasons). Every check runs, so the reasons list
    everything that is wrong, not only the first thing."""
    reasons, stop, review = [], False, False
    if not cnpj_ok(app["cnpj"]):
        reasons.append("CNPJ check digits are wrong")
        stop = True
    elif app["cnpj"] not in registry:
        reasons.append("CNPJ not in the registry")
        stop = True
    elif registry[app["cnpj"]]["status"] != "ATIVA":
        reasons.append("CNPJ status is %s" % registry[app["cnpj"]]["status"])
        stop = True
    else:
        age = (now - dt.date.fromisoformat(registry[app["cnpj"]]["opened"])).days
        if age < YOUNG:
            reasons.append("company opened %d days ago" % age)
    if domain(app["contact"]) != domain(app["website"]):
        reasons.append("contact %s is not at %s" % (domain(app["contact"]), app["website"]))
    case = app["use_case"]
    if case in use_cases["prohibited"]:
        reasons.append("use case %s is prohibited" % case)
        stop = True
    elif case in use_cases["review"]:
        reasons.append("use case %s needs a person to approve it" % case)
        review = True
    elif case not in use_cases["allowed"]:
        reasons.append("use case %s is on no list" % case)
        review = True
    hits = [m.group(0) for m in (re.search(p, app["description"], re.I)
                                 for p in use_cases["prohibited_phrases"]) if m]
    if hits:
        reasons.append("description says \"%s\", a prohibited use" % "\", \"".join(hits))
        review = True
    if stop:
        return "REFUSE", "-", reasons
    if review:
        return "REVIEW", "sandbox", reasons
    if reasons:
        return "VERIFY", "sandbox", reasons
    return "ACCEPT", "tier-1", ["all checks passed"]
```

```python
# cnpj.py: whether a CNPJ's two check digits are right.
#
#   guard cnpj NUMBER
import sys

from kyc import cnpj_ok

ok = cnpj_ok(sys.argv[1])
print("%s  check digits %s" % (sys.argv[1], "right" if ok else "WRONG"))
sys.exit(0 if ok else 1)
```

```
ana@lab:~/guard$ guard cnpj 19.384.756/0001-01
19.384.756/0001-01  check digits WRONG
ana@lab:~/guard$ guard cnpj 19.384.756/0001-00
19.384.756/0001-00  check digits right
```

A conta diz que o número está bem formado, não que a empresa existe. A segunda verificação pergunta ao
cadastro. A Receita Federal publica dados de CNPJ, inclusive a situação cadastral e a data de abertura;
o `data/cnpj-registry.json` é um substituto curto, escrito pelo curso, porque nada neste curso chega à
rede. Depois vêm dois sinais mais baratos: se o e-mail de contato está no domínio da própria empresa,
e há quanto tempo ela foi aberta. O caso de uso é lido contra uma política, que é o assunto da próxima
seção. Cole o cadastro e a política:

```sh
cat > ~/guard/data/cnpj-registry.json <<'EOF'
{
"45.781.296/0001-63": {"status": "ATIVA", "opened": "2019-03-12"},
"23.045.678/0001-96": {"status": "ATIVA", "opened": "2021-07-01"},
"38.901.745/0001-02": {"status": "ATIVA", "opened": "2026-08-20"},
"61.527.384/0001-90": {"status": "ATIVA", "opened": "2017-11-30"},
"70.491.836/0001-11": {"status": "ATIVA", "opened": "2012-05-08"},
"52.836.417/0001-92": {"status": "INAPTA", "opened": "2020-02-14"},
"19.384.756/0001-00": {"status": "ATIVA", "opened": "2023-04-03"},
"11.222.333/0001-81": {"status": "ATIVA", "opened": "2009-09-21"}
}
EOF
cat > ~/guard/data/use-cases.json <<'EOF'
{
 "allowed": [
  "customer-support",
  "translation",
  "proposal-drafting"
 ],
 "review": [
  "hiring-screening",
  "health-information",
  "legal-drafting",
  "marketing-copy"
 ],
 "prohibited": [
  "mass-messaging",
  "fake-reviews",
  "impersonation",
  "tracking-individuals"
 ],
 "prohibited_phrases": [
  "5-star reviews?",
  "fake",
  "impersonat",
  "without (their )?consent",
  "track (a|one) person"
 ]
}
EOF
```

E o programa que roda toda regra sobre todo pedido, o `~/guard/tools/onboard.py`:

```python
# onboard.py: applications for API access, each decided with its reasons.
#
#   guard onboard FILE [--id ID] [--now YYYY-MM-DD]
#
# FILE has one application per line, as JSON. --now is the day they are
# judged on, so that a company's age is the same on every run.
import argparse
import datetime as dt
import json
import os

from kyc import onboard

p = argparse.ArgumentParser(prog="guard onboard")
p.add_argument("file")
p.add_argument("--id")
p.add_argument("--now")
a = p.parse_args()

data = os.path.expanduser("~/guard/data/")
with open(data + "cnpj-registry.json") as f:
    registry = json.load(f)
with open(data + "use-cases.json") as f:
    use_cases = json.load(f)
now = dt.date.fromisoformat(a.now) if a.now else dt.date.today()

with open(a.file, encoding="utf-8") as f:
    for line in f:
        if not line.strip():
            continue
        app = json.loads(line)
        if a.id and app["id"] != a.id:
            continue
        decision, tier, reasons = onboard(app, registry, use_cases, now)
        print("%-5s  %-22s %-7s %-8s %s" % (app["id"], app["company"], decision, tier, reasons[0]))
        for r in reasons[1:]:
            print("%-5s  %-22s %-7s %-8s %s" % ("", "", "", "", r))
```

Eis os oito pedidos, julgados em 30 de setembro de 2026:

```
ana@lab:~/guard$ guard onboard data/applications.jsonl --now 2026-09-30
ap-01  Doce Lar Confeitaria   ACCEPT  tier-1   all checks passed
ap-02  Contrata Já RH         REVIEW  sandbox  use case hiring-screening needs a person to approve it
ap-03  Avalia+ Marketing      REVIEW  sandbox  company opened 41 days ago
                                               use case marketing-copy needs a person to approve it
                                               description says "5-star reviews", a prohibited use
ap-04  Nuvem Tradutora        VERIFY  sandbox  contact webmail.example is not at nuvemtradutora.example
ap-05  Clínica Bem Viver      REVIEW  sandbox  use case health-information needs a person to approve it
ap-06  Disparo Total          REFUSE  -        CNPJ status is INAPTA
                                               use case mass-messaging is prohibited
ap-07  Studio Pixel           REFUSE  -        CNPJ check digits are wrong
ap-08  Lima Advocacia         REVIEW  sandbox  use case legal-drafting needs a person to approve it
```

Cada decisão nomeia todas as regras que a produziram, não só a primeira, para que uma recusa possa ser
explicada à empresa e um erro possa ser corrigido. O Studio Pixel digitou o CNPJ com o último dígito
errado; o cadastro tem o certo, e a recusa diz qual verificação falhou. A Disparo Total é recusada duas
vezes: a Receita a lista como *inapta*, situação que ela atribui, entre outros motivos, a uma empresa
que deixou de entregar as declarações obrigatórias; e o caso de uso dela é proibido, assunto da próxima
seção.

## Sinais, não provas

Nenhuma dessas verificações prova que uma empresa é honesta. Um CNPJ real pode ser comprado junto com a
empresa dona dele, um domínio custa pouco, e uma empresa aberta há 41 dias pode ser uma startup
perfeitamente boa. Cada sinal encarece um pouco a mentira, e **o que eles decidem é com quanto a
empresa começa**, não se ela é confiável para sempre. É por isso que a Nuvem Tradutora, cujo contato
está num webmail e não no próprio domínio, recebe `VERIFY` e um sandbox em vez de uma recusa: confirmar
o e-mail no domínio resolve.

Os dados coletados aqui também são dados pessoais, ao menos o nome e o e-mail do contato, e a aula 12
vale para eles como para qualquer outra coisa: colete o que a decisão exige, e diga por quê.
