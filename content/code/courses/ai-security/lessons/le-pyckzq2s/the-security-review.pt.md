---
title: A revisão de segurança, como uma lista que a mudança precisa cumprir
version: 1
---

Quase tudo o que este curso construiu é verificado por um programa. Algumas decisões não são: se o
assistente deve poder devolver dinheiro sozinho é uma pergunta para pessoas. A revisão de segurança
é onde essas decisões são tomadas, e ela tem dois jeitos de falhar, como os alertas. **Pesada
demais, e as equipes dão a volta nela**, que é como o `growth-test` aconteceu. **Leve demais, e vira
uma assinatura num formulário.**

## O que dispara uma

Uma revisão é necessária quando uma mudança altera o que um sistema alcança, não toda vez que alguém
edita uma linha. A lista do curso:

- um sistema novo, ou um sistema mudando de fornecedor;
- uma ferramenta nova, ou uma ferramenta com mais poder, como escrever onde antes só lia;
- um tipo novo de dado chegando ao modelo, sobretudo dados pessoais;
- memória, recuperação de documentos ou qualquer outra coisa que guarde o que os usuários dizem;
- dinheiro: qualquer coisa que o gaste, devolva ou movimente.

Uma edição de prompt ou uma página nova da central de ajuda não estão na lista. A aprovação da aula
20 cobre essas, e a suíte da aula 23 mede o efeito delas.

## O que ela pede

O que a mudança acrescenta decide o que ela precisa mostrar, e cada item é algo que uma aula anterior
ensinou a produzir. O Bruno propõe deixar o assistente devolver valores pequenos sozinho; a mudança
dele, com as evidências que anexou, é escrita pelo curso. Cole:

```sh
mkdir -p ~/guard/data/changes
cat > ~/guard/data/changes/CHG-12.json <<'EOF'
{
 "id": "CHG-12",
 "system": "support-assistant",
 "author": "bruno.alves",
 "what": "the assistant refunds up to R$ 200 itself, through issue_refund",
 "adds": ["tool", "money", "personal-data"],
 "evidence": {
  "threat-model": "flows.json f9 and threats.json T-15, both reviewed",
  "gate": "tools.json: issue_refund allowed, confirmation above R$ 200",
  "authorisation": "refunds only jobs the asking account paid for; search.py --audit extended",
  "lgpd": "basis unchanged; no new data sent to a provider",
  "suite": "suite.json: refund-limit check"
 },
 "approved_by": []
}
EOF
```

Salve a revisão como `~/guard/tools/review.py`:

```python
# review.py: the security review a change needs, and what it still lacks.
#
#   guard review CHANGE
#
# CHANGE is a JSON file describing a change to a system in the register:
# what it does, what it adds, the evidence its author attached for each
# item, and who approved it. What a change adds decides what it must show,
# from the table below, each item pointing at the lesson that produces it.
# Approval takes two people: the system's owner, and a reviewer who is not
# the author. The exit status is 1 until every item has evidence and both
# have approved.
import json
import os
import sys

NEEDS = {
    "always": [("threat-model", "13: the new flows, and a threat against each"),
               ("suite", "23: a check that fails if the control is removed")],
    "tool": [("gate", "10: the tool on the allowlist, and when a person confirms"),
             ("runbook", "24: a runbook for the alert that watches it")],
    "money": [("budget", "18: a limit per account and a ceiling per day")],
    "personal-data": [("authorisation", "15: it acts only for the person asking"),
                      ("lgpd", "12: the legal basis, and what reaches a provider")],
    "provider": [("assessment", "19: the provider's answers, with evidence")],
    "memory": [("retention", "16: what is kept, for whom, and for how long")],
    "prompt": [("approval", "20: the new version approved by name")],
}

with open(sys.argv[1], encoding="utf-8") as f:
    chg = json.load(f)
with open(os.path.expanduser("~/guard/data/ai-register.json"), encoding="utf-8") as f:
    reg = json.load(f)
system = next(s for s in reg["systems"] if s["name"] == chg["system"])

print("%s  %s" % (chg["id"], chg["what"]))
missing = 0
for kind in ["always"] + chg["adds"]:
    for item, lesson in NEEDS[kind]:
        got = chg["evidence"].get(item)
        missing += got is None
        print("  %-14s %-8s lesson %s" % (item, "ok" if got else "MISSING", lesson))

owner, approvers = system["owner"], set(chg["approved_by"])
reviewers = approvers - {chg["author"], owner}
print("approvals: owner %s %s; a reviewer who is not %s %s" % (
    owner, "yes" if owner in approvers else "no",
    chg["author"], "yes" if reviewers else "no"))
ready = missing == 0 and owner in approvers and reviewers
print("%d item(s) missing; %s" % (missing, "approved" if ready else "not approved"))
raise SystemExit(0 if ready else 1)
```

```
ana@lab:~/guard$ guard review data/changes/CHG-12.json; echo "exit status $?"
CHG-12  the assistant refunds up to R$ 200 itself, through issue_refund
  threat-model   ok       lesson 13: the new flows, and a threat against each
  suite          ok       lesson 23: a check that fails if the control is removed
  gate           ok       lesson 10: the tool on the allowlist, and when a person confirms
  runbook        MISSING  lesson 24: a runbook for the alert that watches it
  budget         MISSING  lesson 18: a limit per account and a ceiling per day
  authorisation  ok       lesson 15: it acts only for the person asking
  lgpd           ok       lesson 12: the legal basis, and what reaches a provider
approvals: owner ana.lima no; a reviewer who is not bruno.alves no
2 item(s) missing; not approved
exit status 1
```

Faltam dois itens, e os dois são do tipo que se esquece porque a funcionalidade funciona sem eles.
**Sem orçamento**: uma ferramenta de reembolso sem teto por conta e por dia é o consumo sem limite da
aula 18, com dinheiro no lugar de tokens. **Sem runbook**: quando o alerta dos reembolsos disparar de
madrugada, a pergunta da aula 24, *o que é seguro fazer agora?*, não tem resposta escrita.

## Dois nomes, e por quê

A revisão precisa de duas aprovações: a do dono do sistema, e a de alguém que não é o autor. O dono
responde pelo sistema depois, então precisa concordar com o que é acrescentado a ele. O segundo
revisor existe porque **um autor revisando a própria mudança confere o que quis escrever, não o que
escreveu**. Se a Ana fosse dona e autora, o segundo nome teria de ser outra pessoa ainda.

Nenhuma das aprovações é uma assinatura no conjunto. Cada item tem a sua evidência ao lado: um
arquivo, uma verificação na suíte, uma linha no registro de ameaças. Um revisor que queira discordar
tem algo concreto de que discordar, e um revisor um ano depois vê o que foi conferido, e não só quem
assinou.
