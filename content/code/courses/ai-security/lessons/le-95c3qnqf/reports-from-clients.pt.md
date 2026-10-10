---
title: Ler o que os clientes denunciam
version: 1
---

Um botão de denúncia só vale as denúncias que alguém lê. Dez denúncias de uma semana, **escritas pelo
curso**; cada uma nomeia a chamada a que se refere e a versão do prompt que essa chamada usou, como a
aula 20 as registra, e um motivo que o cliente escolheu entre quatro. Junto, o número de chamadas que
cada versão atendeu naquela semana. Cole os dois:

```sh
cat > ~/guard/data/reports.jsonl <<'EOF'
{"id": "r1", "day": "2026-10-05", "call": "c1043", "version": "aa32449d3f", "reason": "wrong", "text": "It sent my question about a late logo to the wrong queue."}
{"id": "r2", "day": "2026-10-05", "call": "c1107", "version": "06390ce0eb", "reason": "wrong", "text": "I got a poem instead of an answer."}
{"id": "r3", "day": "2026-10-06", "call": "c1122", "version": "06390ce0eb", "reason": "other", "text": "Why is the assistant writing poetry?"}
{"id": "r4", "day": "2026-10-06", "call": "c1130", "version": "06390ce0eb", "reason": "privacy", "text": "The reply repeated my whole message back, with my CPF in it."}
{"id": "r5", "day": "2026-10-06", "call": "c1131", "version": "06390ce0eb", "reason": "wrong", "text": "It thanked me for my patience and answered nothing."}
{"id": "r6", "day": "2026-10-07", "call": "c1188", "version": "aa32449d3f", "reason": "harmful", "text": "The reply called the freelancer lazy."}
{"id": "r7", "day": "2026-10-07", "call": "c1190", "version": "06390ce0eb", "reason": "wrong", "text": "Another poem."}
{"id": "r8", "day": "2026-10-08", "call": "c1201", "version": "06390ce0eb", "reason": "wrong", "text": "The answer was in capital letters and made no sense."}
{"id": "r9", "day": "2026-10-08", "call": "c1250", "version": "aa32449d3f", "reason": "wrong", "text": "It said my refund would take 30 days; the help page says 7."}
{"id": "r10", "day": "2026-10-08", "call": "c1262", "version": "aa32449d3f", "reason": "other", "text": "Can I change my e-mail address here?"}
EOF
cat > ~/guard/data/calls-per-version.json <<'EOF'
{"aa32449d3f": 1800, "06390ce0eb": 200}
EOF
```

A triagem põe cada denúncia numa fila pelo motivo, e depois conta denúncias por mil chamadas de cada
versão. Salve-a como `~/guard/tools/reports.py`:

```python
# reports.py: what clients reported about the assistant's replies, triaged.
#
#   guard reports FILE
#
# Each report names the call it is about and the prompt version that call
# used, as lesson 20 logs them, and a reason the client picked. The reason
# decides the queue and how soon a person looks:
#
#   harmful  urgent, within the hour
#   privacy  privacy, the same day
#   wrong    quality, the weekly review
#   other    support, as a normal ticket
#
# Then the reports per thousand calls of each prompt version, with the call
# counts in data/calls-per-version.json: a version that draws far more
# reports than the others is a finding, whatever each report says.
import argparse
import json
import os

QUEUES = [("harmful", "urgent", "within the hour"), ("privacy", "privacy", "the same day"),
          ("wrong", "quality", "weekly review"), ("other", "support", "normal ticket")]

p = argparse.ArgumentParser(prog="guard reports")
p.add_argument("file")
a = p.parse_args()
with open(a.file, encoding="utf-8") as f:
    reports = [json.loads(line) for line in f]
with open(os.path.expanduser("~/guard/data/calls-per-version.json"), encoding="utf-8") as f:
    calls = json.load(f)

for reason, queue, when in QUEUES:
    for r in reports:
        if r["reason"] == reason:
            print("%-4s %-8s %-8s %-16s %s %s" % (r["id"], reason, queue, when, r["call"], r["text"][:44]))
print()
print("%-11s %6s %8s %10s" % ("version", "calls", "reports", "per 1000"))
for version, n in calls.items():
    k = sum(1 for r in reports if r["version"] == version)
    print("%-11s %6d %8d %10.1f" % (version, n, k, 1000 * k / n))
```

```
ana@lab:~/guard$ guard reports data/reports.jsonl
r6   harmful  urgent   within the hour  c1188 The reply called the freelancer lazy.
r4   privacy  privacy  the same day     c1130 The reply repeated my whole message back, wi
r1   wrong    quality  weekly review    c1043 It sent my question about a late logo to the
r2   wrong    quality  weekly review    c1107 I got a poem instead of an answer.
r5   wrong    quality  weekly review    c1131 It thanked me for my patience and answered n
r7   wrong    quality  weekly review    c1190 Another poem.
r8   wrong    quality  weekly review    c1201 The answer was in capital letters and made n
r9   wrong    quality  weekly review    c1250 It said my refund would take 30 days; the he
r3   other    support  normal ticket    c1122 Why is the assistant writing poetry?
r10  other    support  normal ticket    c1262 Can I change my e-mail address here?

version      calls  reports   per 1000
aa32449d3f    1800        4        2.2
06390ce0eb     200        6       30.0
```

## A fila é escolhida pelo que pode estar em jogo

A `r6` vem primeiro, embora tenha chegado no fim da semana: uma resposta que ofendeu um freelancer é um
dano publicado, e é olhada em até uma hora. A `r4` vem em seguida, no mesmo dia: um cliente diz que a
resposta repetiu a mensagem dele com o CPF dentro, que é dado pessoal num lugar onde não deveria
estar, e possivelmente no log da aula 11, no fornecedor da aula 12 e no filtro da aula 5 de uma vez. As
seis denúncias `wrong` esperam a revisão semanal, porque uma resposta errada custa tempo ao cliente, e
a revisão é onde os padrões aparecem. As duas `other` são perguntas comuns de suporte que chegaram pelo
botão, e são respondidas como tal.

**Quem escolheu o motivo foi o cliente, e clientes escolhem sem precisão.** A `r2` e a `r7` estão como
`wrong` e são a mesma falha que a `r3`, arquivada como `other`. Uma triagem pelo motivo do cliente é
uma primeira separação, e quem lê a fila move uma denúncia quando o motivo está errado, principalmente
para cima.

## Contar por versão acha o que denúncias isoladas não acham

A segunda tabela é o motivo de cada denúncia levar sua versão. A versão `aa32449d3f` atendeu 1.800
chamadas e recebeu quatro denúncias, 2,2 por mil. A versão `06390ce0eb` atendeu 200 e recebeu seis,
**30 por mil, mais de treze vezes a taxa**. Lidos um a um, os poemas, as maiúsculas e o "obrigado pela
paciência" parecem um modelo tendo dias estranhos. Contados por versão, são uma mudança só: a
`06390ce0eb` é o prompt não revisado da aula 20, e as denúncias o acharam em produção do jeito que o
build o teria achado antes.

A aula 22 transforma isso num número vigiado, e não lido uma vez por semana, e a aula 24 decide o que
acontece no dia em que ele salta.
