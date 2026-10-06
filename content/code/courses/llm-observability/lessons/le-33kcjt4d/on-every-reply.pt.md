---
title: Em toda resposta, em produção
version: 1
---

Uma regra custa microssegundos e nenhum token, então pode rodar em **toda** resposta, não numa amostra.
Dois lugares para rodá-la: na execução de avaliação, antes de uma mudança ir ao ar, e no tráfego, depois.

O `check_run.py` conta quantas vezes cada verificação passa numa execução:

```python
"""check_run.py: every check in checks.py on every reply of a run, counted, and the failures listed."""
import json
import sys
from collections import Counter

import checks

run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
failed, examples = Counter(), {}
for r in run:
    for name, ok, why in checks.run(r["reply"], r["sources"]):
        if not ok:
            failed[name] += 1
            examples.setdefault(name, f"{r['id']}: {why}")
for c in checks.CHECKS:
    print(f"{c.__name__:22} {len(run) - failed[c.__name__]:3}/{len(run)} pass   {examples.get(c.__name__, '')}")
```

```
ana@lab:~/obs$ python check_run.py current
cites_every_sentence    30/30 pass   
citations_exist         30/30 pass   
numbers_in_sources      30/30 pass   
no_personal_data        30/30 pass   
refusal_is_exact        30/30 pass   
short_enough            30/30 pass   
```

E o `check_week.py` faz o mesmo na semana reproduzida, lendo cada resposta do seu span raiz e as fontes
dos ids de trechos no span de busca, que acham o texto no banco:

```python
"""check_week.py: the checks on every reply of the replayed week, from the spans, per release."""
import json
from collections import Counter, defaultdict

import psycopg

import checks

text = dict(psycopg.connect().execute("SELECT id, text FROM chunks").fetchall())
by_trace = defaultdict(dict)
for s in map(json.loads, open("spans.jsonl")):
    by_trace[s["trace"]][s["name"]] = s["attributes"]
seen, failed = Counter(), defaultdict(Counter)
for spans in by_trace.values():
    root = spans["ask"]
    if root["app.feature"] == "summary":
        continue
    sources = [{"id": c, "text": text[c]} for c in spans["search"]["app.search.chunks"]]
    release = root["app.release"]
    seen[release] += 1
    for name, ok, _ in checks.run(root["app.reply"], sources):
        failed[release][name] += not ok
print(f"{'check':22}" + "".join(f"{r:>12}" for r in sorted(seen)))
for c in checks.CHECKS:
    print(f"{c.__name__:22}" + "".join(f"{failed[r][c.__name__]:6} fail" for r in sorted(seen)))
print(f"{'replies':22}" + "".join(f"{seen[r]:12}" for r in sorted(seen)))
```

```
ana@lab:~/obs$ python check_week.py
check                    2026.09.4   2026.10.1
cites_every_sentence       0 fail     0 fail
citations_exist            0 fail     0 fail
numbers_in_sources         0 fail     0 fail
no_personal_data           0 fail     0 fail
refusal_is_exact           0 fail     0 fail
short_enough               0 fail     0 fail
replies                        789         432
```

**Nenhuma falha, em trinta respostas ou em 1.221.** Isso é o extract-1: ele copia frases das fontes e
cita cada uma, então não consegue quebrar essas regras. Um modelo de verdade as quebra de vez em quando:
uma citação a uma fonte que não recebeu, uma frase sem citação, um número do seu treino. Os zeros aqui
são uma propriedade do substituto, e a aula não finge o contrário.

## Por que vale rodar uma regra que nunca dispara

Porque o dia em que ela dispara é o dia em que algo mudou. Uma versão nova do modelo, um prompt novo,
uma atualização de biblioteca que formata citações de outro jeito: cada um pode começar a quebrar uma
regra da noite para o dia, e a regra é o alarme. Uma verificação com um longo histórico de aprovações
deixa de ser uma medição e vira um **fio de disparo**, e o valor de um fio de disparo não está em quantas
vezes ele dispara.

Duas coisas tornam um fio de disparo útil em vez de ignorado:

- **Ele é registrado onde o trace está.** O resultado de cada verificação vai para o trace como uma
  nota, como os polegares nas aulas 6 e 7, com tipo de anotador `CODE`. Uma resposta que falha numa
  verificação fica então a um clique do seu prompt e das suas fontes.
- **A taxa dele é acompanhada, não as falhas avulsas.** Uma resposta em dez mil com uma citação solta é
  ruído. Uma em cinquenta, a partir do dia de uma versão, é o alerta da aula 16.

## O que roda onde

| | onde | com que frequência | quanto custa |
|---|---|---|---|
| regras de forma | na aplicação, depois de cada resposta, ou num job sobre os traces | toda resposta | nada mensurável |
| comparação com resposta esperada | no conjunto de avaliação, antes de ir ao ar | toda mudança | a própria execução |
| um modelo como juiz (aula 9) | numa amostra do tráfego, e no conjunto de avaliação | uma parte das respostas | uma chamada a modelo por resposta julgada |
| pessoas (aula 10) | numa amostra menor | toda semana | horas |

A ordem dessa tabela é a ordem de custo, e também a ordem de confiança: quanto mais barata a
verificação, menos ela vê, e mais do tráfego ela consegue olhar.
