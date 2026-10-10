---
title: Em toda resposta, em produção
version: 2
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
ana@dev:~/obs$ python check_run.py current
cites_every_sentence    24/24 pass   
citations_exist         24/24 pass   
numbers_in_sources      24/24 pass   
no_personal_data        24/24 pass   
refusal_is_exact        24/24 pass   
short_enough            24/24 pass   
```

E o `check_week.py` faz o mesmo na semana reproduzida, lendo cada resposta do seu span raiz e as fontes
dos ids de trechos no span de busca, que acham o texto no
`data/index.json`. Ele imprime um exemplo de cada tipo de falha:

```python
"""check_week.py: the checks on every reply of the replayed week, from the spans, per release."""
import json
from collections import Counter, defaultdict

import checks

text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
by_trace = defaultdict(dict)
for s in map(json.loads, open("spans.jsonl")):
    by_trace[s["trace"]][s["name"]] = s["attributes"]
seen, failed, example = Counter(), defaultdict(Counter), {}
for spans in by_trace.values():
    root = spans["ask"]
    if root["app.feature"] == "summary":
        continue
    sources = [{"id": c, "text": text[c]} for c in spans["search"].get("app.search.chunks", [])]
    release = root["app.release"]
    seen[release] += 1
    for name, ok, why in checks.run(root["app.reply"], sources):
        failed[release][name] += not ok
        if not ok:
            example.setdefault(name, f"{why}: {root['app.reply'][:70]}")
print(f"{'check':22}" + "".join(f"{r:>12}" for r in sorted(seen)))
for c in checks.CHECKS:
    print(f"{c.__name__:22}" + "".join(f"{failed[r][c.__name__]:6} fail" for r in sorted(seen)))
print(f"{'replies':22}" + "".join(f"{seen[r]:12}" for r in sorted(seen)))
for name, e in example.items():
    print(f"  {name}: {e}")
```

```
ana@dev:~/obs$ python check_week.py
check                    2026.09.4   2026.10.1
cites_every_sentence      21 fail    18 fail
citations_exist            0 fail     0 fail
numbers_in_sources        16 fail    14 fail
no_personal_data           0 fail     0 fail
refusal_is_exact           2 fail     0 fail
short_enough               0 fail     0 fail
replies                        134         141
  cites_every_sentence: 1 sentence(s) with no citation: According to [1], a standard parcel is considered lost when its tracki
  numbers_in_sources: not in any source: ['3']: According to [1], you can return a printed book within 30 days from de
  refusal_is_exact: not the agreed refusal: According to [1], "Returns are free: we e-mail you a prepaid label, an
```

**As vinte e quatro respostas da execução passam em tudo. A semana não.** De 275 respostas a clientes,
39 têm uma frase sem citação, 30 um número que não está em fonte nenhuma, e duas uma recusa com palavras
próprias. A execução e a semana são o mesmo assistente sob as mesmas regras; o que muda é o que as
pessoas digitaram. O conjunto de avaliação faz perguntas limpas, e os clientes da semana escreveram
sobre as próprias encomendas e as próprias datas.

Leia os exemplos, porque cada tipo é uma descoberta diferente:

- **As frases sem citação são o modelo raciocinando sobre o cliente.** "Since you received the book 3
  weeks ago, which is less than 30 days, you should be able to return it." Nada nos documentos diz isso,
  então não há o que citar, e 27 das 39 estão em pedidos de `order`, os que tratam de uma encomenda em
  particular. Se a Marginalia quer essa frase é uma decisão sobre o produto, não um fato que a regra
  resolve; o trabalho da regra é tornar a decisão visível.
- **A maioria dos números soltos é do próprio cliente.** Dos 30, 24 são um `3` ou um `12` que o cliente
  digitou: "a book I got 3 weeks ago", "after 12 working days". São alarmes falsos, e a correção é na
  regra: aceitar um número que aparece na pergunta além das fontes.
- **Os outros seis são a aritmética do modelo, e ela está errada.** "It's been two weeks, which is
  equivalent to 14 working days." Duas semanas são dez dias úteis. O número veio do nada, a regra o
  pegou, e nenhum cliente lendo a resposta pegaria.
- **As duas recusas com outras palavras são uma resposta duas vezes**, à pergunta sobre o frete da
  devolução: ela diz que o cliente paga, e depois "I could not find any information in [2] that
  contradicts this". A regra disparou nas palavras, e a resposta por baixo delas é a contradição que a
  aula 1 achou.

É isso que rodar uma regra em toda resposta compra: não uma nota, uma **lista de lugares para olhar**,
separada por tipo. Uma regra com alarmes falsos se conserta como qualquer programa, e uma regra quieta
num conjunto limpo e barulhenta no tráfego real está dizendo onde o conjunto é limpo demais.

## Tornando uma regra digna de rodar

Duas coisas tornam a lista útil em vez de ignorada:

- **Ela é registrada onde o trace está.** O resultado de cada verificação vai para o trace como uma
  nota, como os polegares nas aulas 6 e 7, com tipo de anotador `CODE`. Uma resposta que falha numa
  verificação fica então a um clique do seu prompt e das suas fontes.
- **A taxa dela é acompanhada, não as falhas avulsas.** Umas poucas frases sem citação por dia são um
  hábito do assistente. Um salto, a partir do dia de uma versão, é o alerta da aula 16: uma versão nova
  do modelo, um prompt novo ou uma atualização de biblioteca podem começar a quebrar uma regra da noite
  para o dia, e a regra é o alarme.

## O que roda onde

| | onde | com que frequência | quanto custa |
|---|---|---|---|
| regras de forma | na aplicação, depois de cada resposta, ou num job sobre os traces | toda resposta | nada mensurável |
| comparação com resposta esperada | no conjunto de avaliação, antes de ir ao ar | toda mudança | a própria execução |
| um modelo como juiz (aula 9) | numa amostra do tráfego, e no conjunto de avaliação | uma parte das respostas | uma chamada a modelo por resposta julgada |
| pessoas (aula 10) | numa amostra menor | toda semana | horas |

A ordem dessa tabela é a ordem de custo, e também a ordem de confiança: quanto mais barata a
verificação, menos ela vê, e mais do tráfego ela consegue olhar.
