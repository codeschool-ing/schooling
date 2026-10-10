---
title: Três fornecedores contra uma lista
version: 1
---

Três fornecedores responderam ao questionário. **Os fornecedores e as respostas são inventados pelo
curso**; nenhum termo de empresa real é descrito aqui, e uma avaliação de verdade lê o contrato atual
de cada fornecedor, que muda. Para cada resposta há também a evidência: a cláusula, o documento
assinado ou o relatório em que ela se apoia, ou `null` quando a resposta é só a palavra do
fornecedor. Cole:

```sh
cat > ~/guard/data/providers.json <<'EOF'
{
 "provider-a": {
  "training": {"value": false, "evidence": "contract 4.2"},
  "retention_days": {"value": 30, "evidence": "contract 5.1"},
  "dpa": {"value": true, "evidence": "DPA signed 2026-03-10"},
  "region": {"value": "US", "evidence": "contract 2.3"},
  "incident_hours": {"value": 72, "evidence": "contract 9.1"},
  "subprocessors": {"value": true, "evidence": "published list, 2026-08"},
  "audit": {"value": true, "evidence": "SOC 2 Type II report, 2026"},
  "pinning": {"value": true, "evidence": "versioning policy page"},
  "exit_deletion": {"value": true, "evidence": null}
 },
 "provider-b": {
  "training": {"value": true, "evidence": "terms 7: used unless the customer opts out"},
  "retention_days": {"value": 0, "evidence": "contract annex B"},
  "dpa": {"value": true, "evidence": "DPA signed 2026-05-02"},
  "region": {"value": "EU", "evidence": "contract 3.1"},
  "incident_hours": {"value": 24, "evidence": "contract 11"},
  "subprocessors": {"value": false, "evidence": null},
  "audit": {"value": true, "evidence": "ISO/IEC 27001 certificate, 2025"},
  "pinning": {"value": false, "evidence": null},
  "exit_deletion": {"value": true, "evidence": "contract 14.2"}
 },
 "provider-c": {
  "training": {"value": false, "evidence": null},
  "retention_days": {"value": 30, "evidence": null},
  "dpa": {"value": true, "evidence": "DPA signed 2026-06-18"},
  "region": {"value": "BR", "evidence": "contract 2.1"},
  "incident_hours": {"value": 24, "evidence": "contract 8.4"},
  "subprocessors": {"value": true, "evidence": null},
  "audit": {"value": false, "evidence": null},
  "pinning": {"value": true, "evidence": null},
  "exit_deletion": {"value": true, "evidence": null}
 }
}
EOF
```

O programa aplica a lista. Salve-o como `~/guard/tools/vendor.py`:

```python
# vendor.py: model providers' answers held against Tarefa's requirements.
#
#   guard vendor [--evidence]
#
# data/requirements.json is what Tarefa asks of any provider it sends data
# to, each question a MUST or a SHOULD with the answer it accepts.
# data/providers.json is what each provider answered, and for every answer
# the evidence behind it: a contract clause, a signed agreement, an audit
# report, or null when the answer is only the provider's word.
#
# A provider failing any MUST is out, whatever else it offers. The SHOULDs
# are counted. An answer that meets a requirement with nothing behind it is
# UNBACKED: a questionnaire answer is a claim until something else says it,
# and the claims that matter are the ones a decision rests on. --evidence
# lists them.
import argparse
import json
import os


def meets(req, value):
    if "want" in req:
        return value == req["want"]
    if "max" in req:
        return isinstance(value, int) and value <= req["max"]
    return value in req["allowed"]


p = argparse.ArgumentParser(prog="guard vendor")
p.add_argument("--evidence", action="store_true")
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "requirements.json"), encoding="utf-8") as f:
    reqs = json.load(f)
with open(os.path.join(home, "providers.json"), encoding="utf-8") as f:
    providers = json.load(f)

for name, answers in providers.items():
    failed, should, claims = [], 0, []
    for r in reqs:
        ans = answers[r["id"]]
        ok = meets(r, ans["value"])
        if r["kind"] == "must" and not ok:
            failed.append("%s = %s" % (r["id"], json.dumps(ans["value"])))
        if r["kind"] == "should" and ok:
            should += 1
        if ok and ans["evidence"] is None:
            claims.append("%s %s" % (r["kind"].upper(), r["id"]))
    n_should = sum(1 for r in reqs if r["kind"] == "should")
    verdict = "OUT" if failed else "in"
    print("%-11s %-3s  should %d/%d  unbacked %d%s" % (
        name, verdict, should, n_should, len(claims),
        "  fails " + "; ".join(failed) if failed else ""))
    if a.evidence:
        for c in claims:
            print("            unbacked: %s" % c)
```

```
ana@lab:~/guard$ guard vendor
provider-a  OUT  should 4/4  unbacked 1  fails incident_hours = 72
provider-b  OUT  should 2/4  unbacked 0  fails training = true
provider-c  in   should 3/4  unbacked 5
```

**O fornecedor com a melhor nota está fora.** O `provider-a` atende os quatro SHOULDs, tem relatório
de auditoria e lista publicada de subprocessadores, e avisa os clientes de um incidente em até 72
horas, quando o prazo da própria Tarefa para avisar a ANPD já passou. Uma nota que somasse MUSTs e
SHOULDs o teria posto em primeiro; é por isso que os dois ficam separados.

O `provider-b` está fora por outro motivo: os termos dele usam dados de clientes para treinamento, a
menos que o cliente recuse. Esse é um MUST que um contrato consegue corrigir. **Um MUST que falha é uma
pergunta ao fornecedor, nem sempre o fim da conversa**: se o `provider-b` assinar uma cláusula
desligando o treinamento para a Tarefa, a resposta muda, a evidência dela vira essa cláusula, e o
programa roda de novo. O que não acontece é a Tarefa decidir que a recusa provavelmente basta e
assinar mesmo assim.

O `provider-c` está dentro, com três SHOULDs de quatro. Nesta lista ele é o único fornecedor com quem a
Tarefa poderia assinar hoje, e a próxima seção é sobre quanto desse resultado se apoia em alguma
coisa.

## A comparação é o começo

O `vendor.py` não decide nada sobre preço, qualidade ou latência, e não deveria: essas coisas são
comparadas só entre os fornecedores que passam, por quem é dono do produto. O que o programa garante é
mais estreito e mais importante. **Nenhum fornecedor chega à comparação de preços reprovando numa linha
que a Tarefa escreveu antes**, e o motivo da reprovação fica impresso ao lado do nome dele para quem
precisar explicar a escolha depois.
