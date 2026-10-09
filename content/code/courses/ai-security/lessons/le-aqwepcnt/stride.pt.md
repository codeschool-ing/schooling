---
title: Seis perguntas para cada fluxo que importa
version: 1
---

Um modelo de ameaças falha, na maioria das vezes, por perguntar o que vier à cabeça. Uma pessoa pensa
em vazamentos, a seguinte em sobrecarga, e a terceira pergunta que ninguém faz é a que importa. **Uma
lista fixa de perguntas torna a revisão repetível**: duas pessoas percorrendo o mesmo diagrama chegam
a um registro parecido, e um fluxo que ninguém questionou salta aos olhos.

A lista que a maioria das equipes usa é o **STRIDE**, escrito na Microsoft em 1999. Cada letra é um
tipo de falha, e cada uma é o oposto de uma propriedade que a aplicação deveria manter:

| letra | a falha | a propriedade que ela quebra | na Tarefa |
|---|---|---|---|
| **S** | falsificação de identidade (spoofing) | quem alguém é | um cliente agindo como a conta de outro cliente |
| **T** | adulteração (tampering) | que os dados são o que eram | texto numa mensagem ou num arquivo que muda o que o modelo faz |
| **R** | repúdio (repudiation) | que uma ação pode ser rastreada | uma resposta que ninguém consegue ligar ao prompt que a produziu |
| **I** | divulgação de informação (information disclosure) | que os dados chegam só a quem deve lê-los | um CPF numa resposta, um prompt enviado inteiro ao fornecedor |
| **D** | negação de serviço (denial of service) | que o serviço continua disponível | um parceiro gastando o orçamento do mês numa tarde |
| **E** | elevação de privilégio (elevation of privilege) | que cada parte faz só o que pode | uma chamada de ferramenta que alcança o pedido de outro cliente |

As seis letras foram escritas para software comum, e servem para uma aplicação com LLM com um ajuste.
**Ali, adulteração inclui o texto que conduz o modelo**, porque para o modelo uma instrução dentro da
mensagem de um cliente e uma instrução da Tarefa são o mesmo tipo de coisa. Esse único ajuste é o
motivo de o `T` aparecer em quatro fluxos do registro da Tarefa, e de as aulas 5, 9 e 10 existirem.

## O registro

As respostas vão para um arquivo, uma entrada por ameaça. Cada entrada nomeia o fluxo, a letra do
STRIDE, a ameaça em uma linha, um **impacto** e uma **probabilidade** de 1 a 3, e o **controle** que a
responde, que é o nome de um comando de uma aula anterior, ou `null` enquanto nada responde. O curso
escreveu este registro; cole:

```sh
cat > ~/guard/data/threats.json <<'EOF'
[
 {"id": "T1", "flow": "f1", "stride": "S", "impact": 3, "likelihood": 1, "control": "sign-in session", "threat": "a client acts as another client's account"},
 {"id": "T2", "flow": "f1", "stride": "T", "impact": 3, "likelihood": 3, "control": "check-in, filter", "threat": "a message carries text written to steer the model"},
 {"id": "T3", "flow": "f2", "stride": "I", "impact": 3, "likelihood": 2, "control": "filter", "threat": "a reply repeats personal data or the system prompt"},
 {"id": "T4", "flow": "f3", "stride": "D", "impact": 2, "likelihood": 2, "control": "ratelimit", "threat": "one partner spends the whole budget"},
 {"id": "T5", "flow": "f3", "stride": "S", "impact": 2, "likelihood": 2, "control": "onboard", "threat": "a company signs up under a false identity"},
 {"id": "T6", "flow": "f7", "stride": "I", "impact": 3, "likelihood": 3, "control": "minimise", "threat": "personal data reaches the provider"},
 {"id": "T7", "flow": "f8", "stride": "T", "impact": 2, "likelihood": 3, "control": "check-out", "threat": "a reply breaks the shape the code expects"},
 {"id": "T8", "flow": "f9", "stride": "E", "impact": 3, "likelihood": 2, "control": "gate", "threat": "a call reaches another client or moves money"},
 {"id": "T9", "flow": "f11", "stride": "I", "impact": 2, "likelihood": 3, "control": "redact, sweep", "threat": "the log keeps personal data too long"},
 {"id": "T10", "flow": "f11", "stride": "R", "impact": 2, "likelihood": 2, "control": null, "threat": "a reply cannot be traced to the prompt that made it"},
 {"id": "T11", "flow": "f12", "stride": "T", "impact": 3, "likelihood": 3, "control": null, "threat": "an upload carries text written to steer the model"},
 {"id": "T12", "flow": "f5", "stride": "T", "impact": 2, "likelihood": 1, "control": null, "threat": "a help page is edited to say something false"}
]
EOF
```

O programa o ordena e o confere contra o diagrama. Salve-o como `~/guard/tools/threats.py`:

```python
# threats.py: the threat register, ranked, and the flows it has not reviewed.
#
#   guard threats [--open] [--text]
#
# Each entry in data/threats.json names a flow of data/flows.json, a STRIDE
# category, the threat in one line, an impact and a likelihood from 1 to 3,
# and the control that answers it, or null while nothing does. Risk is impact
# times likelihood, and the register is printed riskiest first, ties in the order written. --open prints
# only the entries with no control.
#
# Then the part a list cannot do for itself: every flow `guard flows` marks
# for review (with --text, the same rule as there) and no entry names is
# printed as UNREVIEWED, and the exit status is 1 while any is. A register
# is judged by what it left out.
import argparse
import json
import os
import sys

STRIDE = {"S": "spoofing", "T": "tampering", "R": "repudiation",
          "I": "information disclosure", "D": "denial of service",
          "E": "elevation of privilege"}

p = argparse.ArgumentParser(prog="guard threats")
p.add_argument("--open", action="store_true")
p.add_argument("--text", action="store_true")
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "flows.json"), encoding="utf-8") as f:
    model = json.load(f)
with open(os.path.join(home, "threats.json"), encoding="utf-8") as f:
    register = json.load(f)
zone = {c["id"]: c["zone"] for c in model["components"]}
flows = {fl["id"]: fl for fl in model["flows"]}

for t in register:
    if t["flow"] not in flows:
        sys.exit("threats: %s names flow %s, which flows.json does not have" % (t["id"], t["flow"]))
    if t["stride"] not in STRIDE:
        sys.exit("threats: %s has STRIDE letter %r; use one of %s" % (t["id"], t["stride"], "".join(STRIDE)))
    for k in ("impact", "likelihood"):
        if t[k] not in (1, 2, 3):
            sys.exit("threats: %s has %s %r; use 1, 2 or 3" % (t["id"], k, t[k]))

order = {t["id"]: n for n, t in enumerate(register)}
ranked = sorted(register, key=lambda t: (-t["impact"] * t["likelihood"], order[t["id"]]))
print("%-4s %-4s %-4s %4s  %-17s %s" % ("id", "flow", "kind", "risk", "control", "threat"))
for t in ranked:
    if a.open and t["control"]:
        continue
    print("%-4s %-4s %-4s %4d  %-17s %s" % (t["id"], t["flow"], t["stride"],
                                          t["impact"] * t["likelihood"],
                                          t["control"] or "OPEN", t["threat"]))

named = {t["flow"] for t in register}
missing = 0
for fl in model["flows"]:
    crosses = zone[fl["from"]] != zone[fl["to"]]
    outside = a.text and fl["text_from"] != "tarefa"
    if (crosses or outside) and fl["id"] not in named:
        missing += 1
        print("UNREVIEWED %s %s -> %s (%s)" % (fl["id"], fl["from"], fl["to"], fl["carries"]))
print("%d threats, %d open, %d marked flows with no entry" % (
    len(register), sum(1 for t in register if not t["control"]), missing))
sys.exit(1 if missing else 0)
```

```
ana@lab:~/guard$ guard threats
id   flow kind risk  control           threat
T2   f1   T       9  check-in, filter  a message carries text written to steer the model
T6   f7   I       9  minimise          personal data reaches the provider
T11  f12  T       9  OPEN              an upload carries text written to steer the model
T3   f2   I       6  filter            a reply repeats personal data or the system prompt
T7   f8   T       6  check-out         a reply breaks the shape the code expects
T8   f9   E       6  gate              a call reaches another client or moves money
T9   f11  I       6  redact, sweep     the log keeps personal data too long
T4   f3   D       4  ratelimit         one partner spends the whole budget
T5   f3   S       4  onboard           a company signs up under a false identity
T10  f11  R       4  OPEN              a reply cannot be traced to the prompt that made it
T1   f1   S       3  sign-in session   a client acts as another client's account
T12  f5   T       2  OPEN              a help page is edited to say something false
12 threats, 3 open, 0 marked flows with no entry
```

Doze ameaças, três delas abertas, e todo fluxo que cruza uma zona tem ao menos uma entrada. A coluna
`control` parece um índice deste curso: `check-in` é a aula 9, `filter` a aula 5, `minimise` a aula
12, `gate` a aula 10. **Uma ameaça com controle é uma ameaça que alguém já pagou para resolver.** O
valor do registro está nas outras três.

## Lendo as abertas

- **`T11`, um arquivo enviado que carrega texto escrito para conduzir o modelo**, vale 9: o maior
  impacto, porque o assistente que lê um anexo pode propor chamadas de ferramenta, e a maior
  probabilidade, porque qualquer pessoa com conta pode anexar um arquivo. As duas fronteiras da aula 14
  são o controle dela: o que lê um anexo não tem ferramentas e só entrega valores fechados.
- **`T10`, uma resposta que não pode ser ligada ao prompt que a produziu**, é uma ameaça de repúdio.
  Quando um cliente reclama de algo que o assistente disse, a Tarefa tem a resposta no log e não sabe
  dizer qual versão do prompt de sistema a produziu. A aula 20 versiona os prompts.
- **`T12`, uma página de ajuda editada para dizer algo falso**, vale 2. A central de ajuda é escrita
  pela Tarefa, então poucas pessoas podem editá-la e a probabilidade é 1, mas o assistente repete o
  que a página disser. A aula 20 põe a central de ajuda sob a mesma revisão dos prompts, para que uma
  página alterada seja uma mudança que alguém aprovou.

A letra do STRIDE sozinha não decide a ordem. **O risco decide**, e risco aqui é impacto vezes
probabilidade. A escala é grossa de propósito: uma equipe que discute se uma probabilidade é 0,35 ou
0,4 está gastando a reunião num número que ninguém mediu.
