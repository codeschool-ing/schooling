---
title: As verificações do curso, rodadas como uma suíte
version: 1
---

Vinte e duas aulas deixaram programas que saem com um status: o `threats.py` sai com 1 quando um
fluxo que cruza uma fronteira não tem ameaça escrita contra ele, o `search.py --audit` quando um
leitor consegue ver um documento que não é dele, o `prompts.py status` quando um arquivo sob revisão
mudou sem um nome ao lado. **Cada um já é um teste.** O que nenhum deles faz ainda é rodar sozinho.
Uma verificação que alguém lembra de rodar antes de uma versão é uma verificação pulada justo na
semana em que importa.

## Um arquivo de verificações

Um teste de regressão de uma defesa diz: este controle segurou ontem, e uma mudança de hoje não pode
desfazê-lo em silêncio. A suíte é uma lista de comandos e o status de saída que cada um precisa
devolver. Cole:

```sh
cat > ~/guard/data/suite.json <<'EOF'
[
 {"name": "every boundary flow has a threat", "run": "guard threats", "expect": 0},
 {"name": "retrieval shows each reader only theirs", "run": "guard search --audit data/questions.jsonl", "expect": 0},
 {"name": "files under review are approved", "run": "guard prompts status", "expect": 0},
 {"name": "screens follow the rules", "run": "guard uxcheck data/ui-copy-fixed.json", "expect": 0},
 {"name": "no credentials in the repository", "run": "guard keyscan data/repo --allow data/keyscan-allow.txt", "expect": 0,
  "known": {"ticket": "SEC-41", "until": "2026-10-31", "why": "lesson 17's findings, moving to the secret store"}},
 {"name": "keys narrow, stored and rotated", "run": "guard keys --now 2026-10-09", "expect": 0,
  "known": {"ticket": "SEC-42", "until": "2026-10-05", "why": "lesson 17's three keys: rotate, narrow, move out of the code"}}
]
EOF
```

As duas últimas verificações levam uma entrada `known`, e é a parte que vale ler devagar. A aula 17
encontrou problemas reais no repositório e nas chaves, e corrigi-los leva dias. **Uma suíte vermelha
desde o primeiro dia ensina todo mundo a ignorar o vermelho.** Uma suíte que deixa essas duas de fora
não diz nada sobre elas para sempre. Então uma falha pode ser *conhecida*: ela nomeia um chamado, o
motivo e a data até a qual será corrigida, e até essa data é relatada sem quebrar o build. Depois
dela, falha como qualquer outra.

O executor imprime um veredito por verificação e sai com 1 quando alguma coisa bloquearia um merge.
Salve-o como `~/guard/tools/defences.py`:

```python
# defences.py: the course's checks, run together as the build would run them.
#
#   guard defences SUITE --now DATE
#
# SUITE lists checks, each a guard command and the exit status it must
# return. A check that fails may be KNOWN: it names a ticket, the reason and
# the date by which it will be fixed. A known failure does not fail the
# suite until that date; after it, it is OVERDUE and fails like any other.
# The exit status is 1 when anything FAILs or is OVERDUE, which is what makes
# a pull request red.
import argparse
import datetime as dt
import json
import os
import subprocess

p = argparse.ArgumentParser(prog="guard defences")
p.add_argument("suite")
p.add_argument("--now", required=True)
a = p.parse_args()
now = dt.date.fromisoformat(a.now)

with open(a.suite, encoding="utf-8") as f:
    checks = json.load(f)
env = dict(os.environ, PATH=os.path.expanduser("~/guard/bin") + os.pathsep + os.environ["PATH"])

red = 0
for c in checks:
    code = subprocess.run(c["run"], shell=True, env=env, cwd=os.path.expanduser("~/guard"),
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode
    if code == c["expect"]:
        verdict, note = "PASS", ""
    elif "known" in c and dt.date.fromisoformat(c["known"]["until"]) >= now:
        verdict, note = "KNOWN", "%s until %s: %s" % (c["known"]["ticket"], c["known"]["until"], c["known"]["why"])
    elif "known" in c:
        verdict, note = "OVERDUE", "%s was due %s" % (c["known"]["ticket"], c["known"]["until"])
    else:
        verdict, note = "FAIL", "exit %d, expected %d" % (code, c["expect"])
    red += verdict in ("FAIL", "OVERDUE")
    print(("%-8s %-40s %s" % (verdict, c["name"], note)).rstrip())
print("%d checks, %d failing the build" % (len(checks), red))
raise SystemExit(1 if red else 0)
```

## A primeira execução

```
ana@lab:~/guard$ guard defences data/suite.json --now 2026-10-09; echo "exit status $?"
PASS     every boundary flow has a threat
PASS     retrieval shows each reader only theirs
FAIL     files under review are approved          exit 1, expected 0
PASS     screens follow the rules
KNOWN    no credentials in the repository         SEC-41 until 2026-10-31: lesson 17's findings, moving to the secret store
OVERDUE  keys narrow, stored and rotated          SEC-42 was due 2026-10-05
6 checks, 2 failing the build
exit status 1
```

Três vereditos, e cada um é a suíte fazendo o seu trabalho:

- **FAIL nos arquivos sob revisão.** Num laboratório recém-montado ninguém aprovou o prompt do
  classificador, as páginas da central de ajuda nem o `model.json`, então o `prompts status` sai
  com 1. É a regra da aula 20, agora garantida por algo que não é a memória de alguém;
- **KNOWN no repositório.** Os quatro achados da aula 17 continuam lá, e a suíte diz isso numa linha,
  com o chamado responsável por eles;
- **OVERDUE nas chaves.** A correção das três chaves da aula 17 foi prometida para 5 de outubro. Hoje
  é dia 9, então a exceção venceu e a falha conta. Uma exceção sem data é um buraco permanente; uma
  com data volta para quem a pediu.

## Aprovar, e rodar de novo

A revisora lê os cinco arquivos e os aprova, como na aula 20:

```
ana@lab:~/guard$ for f in data/prompts/classify.txt data/helpdesk/*.md data/model.json; do guard prompts approve $f --by ana.lima --on 2026-10-09 --reason "read in full"; done
approved data/prompts/classify.txt aa32449d3f by ana.lima
approved data/helpdesk/hc-fees.md ff40a81202 by ana.lima
approved data/helpdesk/hc-payouts.md 0fe2b8eec1 by ana.lima
approved data/helpdesk/hc-refunds.md f32fa16253 by ana.lima
approved data/model.json 3138932013 by ana.lima
```

```
ana@lab:~/guard$ guard defences data/suite.json --now 2026-10-09; echo "exit status $?"
PASS     every boundary flow has a threat
PASS     retrieval shows each reader only theirs
PASS     files under review are approved
PASS     screens follow the rules
KNOWN    no credentials in the repository         SEC-41 until 2026-10-31: lesson 17's findings, moving to the secret store
OVERDUE  keys narrow, stored and rotated          SEC-42 was due 2026-10-05
6 checks, 1 failing the build
exit status 1
```

**Sobrou uma falha, e é a que alguém prometeu corrigir.** A suíte não consegue trocar uma chave. Ela
consegue garantir que a promessa não vire, em silêncio, o jeito como as coisas são, que é no que uma
falha conhecida sem data se transforma.

Cada linha aqui roda em bem menos de um segundo, não precisa de modelo nem de rede, e dá a mesma
resposta em qualquer máquina. É isso que permite rodá-la a cada pull request. A próxima seção trata
da verificação que não tem nenhuma dessas propriedades.
