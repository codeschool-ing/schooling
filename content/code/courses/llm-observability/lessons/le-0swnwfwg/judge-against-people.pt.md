---
title: O juiz, medido contra as pessoas
version: 1
---

Com uma referência em que duas pessoas concordam, o juiz pode ser medido do mesmo jeito que elas foram.
O `judge_runs.py` pede ao judge-1 um veredicto de relevância para cada uma das sessenta respostas e os
escreve onde o `agree.py` os lê:

```python
"""judge_runs.py: judge-1's relevance verdict on every reply of the two runs, written where agree.py reads it.

    python judge_runs.py [--refusals-pass]

With --refusals-pass the agreed refusal is passed by rule, as the rubric says,
and never sent to the judge.
"""
import argparse
import json

import checks
import judge
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--refusals-pass", action="store_true")
a = p.parse_args()
telemetry.setup("judge-spans.jsonl", service="judge")
asked = total = 0
with open("runs/judged.jsonl", "w") as out:
    for run in ("old", "new"):
        for r in map(json.loads, open(f"runs/{run}.jsonl")):
            if a.refusals_pass and checks.is_refusal(r["reply"]):
                label = "pass"
            else:
                label = judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"]
                asked += 1
            out.write(json.dumps({"case": r["id"], "release": r["release"], "label": label}) + "\n")
            total += 1
print(f"runs/judged.jsonl: {total} replies, {asked} sent to judge-1, {total - asked} passed by rule")
```

```
ana@lab:~/obs$ python judge_runs.py
runs/judged.jsonl: 60 replies, 60 sent to judge-1, 0 passed by rule
ana@lab:~/obs$ python agree.py relevance-v2/agreed judge
60 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      29    24
  fail       7     0
agreement 48.3%   by chance 57.7%   kappa -0.22
apart on 31: 24 refusals, 7 other replies
  e02 2026.09.4  fail / pass  Keep the receipt the post office gives you until the refun
  e04 2026.09.4  fail / pass  We replace damaged books at no cost and you do not need to
  e06 2026.09.4  fail / pass  Express delivery is not free at any order value. [1]
  e06 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e07 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e19 2026.09.4  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
  e19 2026.10.1  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
```

**O kappa é −0,22: o juiz concorda com as pessoas menos do que o acaso concordaria.** Não porque seja
aleatório, mas porque é sistematicamente oposto num tipo de resposta. Cada uma das vinte e quatro
recusas passa pela rubrica e falha no juiz: uma recusa não divide palavras com a pergunta, então a sua
semelhança é baixa, e o judge-1 a chama de irrelevante. As sete respostas que as pessoas reprovaram,
ele aprovou.

Isso muda o que a aula 9 achou. A taxa de aprovação do judge-1 em relevância caiu de 76,6% para 62,3%
quando a versão do piso foi ao ar, e a versão de fato piorou o assistente. Mas a avaliação completa da
aula 9 diz o que o judge-1 estava contando: **cada uma das 348 respostas que ele reprovou naquela semana
era a recusa**, e todas as outras passaram. A rubrica conta uma recusa como relevante, e a aula 8 já
contou as erradas como erradas. O número mudou por uma razão real e levou o nome do critério errado. É
isso que faz um juiz que ninguém mediu: produz um número que se mexe quando as coisas mudam, e ninguém
sabe dizer o que o número quer dizer.

## Corrigir o que uma regra corrige

A rubrica resolve as recusas sem ler nada: a recusa combinada passa. Uma regra pode aplicar isso antes
de chamar o juiz, e o `--refusals-pass` faz isso:

```
ana@lab:~/obs$ python judge_runs.py --refusals-pass
runs/judged.jsonl: 60 replies, 36 sent to judge-1, 24 passed by rule
ana@lab:~/obs$ python agree.py relevance-v2/agreed judge
60 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      53     0
  fail       7     0
agreement 88.3%   by chance 88.3%   kappa 0.00
apart on 7: 0 refusals, 7 other replies
  e02 2026.09.4  fail / pass  Keep the receipt the post office gives you until the refun
  e04 2026.09.4  fail / pass  We replace damaged books at no cost and you do not need to
  e06 2026.09.4  fail / pass  Express delivery is not free at any order value. [1]
  e06 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e07 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e19 2026.09.4  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
  e19 2026.10.1  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
```

**Concordância de 88,3%, e kappa de 0,00.** Agora o juiz concorda com as pessoas em 53 de 60 respostas,
e concorda exatamente tanto quanto um juiz que aprovasse tudo sem ler. Porque foi o que ele fez: toda
resposta que o judge-1 recebeu, ele aprovou. As sete que as pessoas reprovaram dividem as palavras da
pergunta, e o judge-1 mede as palavras.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Concordância observada e concordância por acaso, num eixo de 0 a 100%, com o kappa ao lado de cada linha. Ana e Bruno na versão 1: 51,7% contra 45,7% por acaso, kappa 0,11. Na versão 2: 96,7% contra 76,8%, kappa 0,86. judge-1 contra os rótulos combinados: 48,3% contra 57,7%, kappa −0,22. judge-1 com as recusas aprovadas por regra: 88,3% contra 88,3%, kappa 0,00.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana e Bruno, versão 1</text><path d=\"M419.09 48 L441.29 48\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"419.09\" cy=\"48\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"441.29\" cy=\"48\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,11</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana e Bruno, versão 2</text><path d=\"M534.16 86 L607.79 86\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"534.16\" cy=\"86\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"607.79\" cy=\"86\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,86</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">judge-1 e os rótulos combinados</text><path d=\"M428.71 124 L463.49 124\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"463.49\" cy=\"124\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"428.71\" cy=\"124\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ −0,22</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">judge-1 mais a regra das recusas</text><path d=\"M576.71 162 L576.71 162\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"576.71\" cy=\"162\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"576.71\" cy=\"162\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,00</text><path d=\"M250 192 L620 192\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M250 192 L250 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"250\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M324 192 L324 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"324\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M398 192 L398 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"398\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M472 192 L472 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"472\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M546 192 L546 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"546\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M620 192 L620 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"620\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"435\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parcela das 60 respostas em que os dois concordam</text><circle cx=\"250\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"260\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">observada</text><circle cx=\"361\" cy=\"16\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"371\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">por acaso</text></svg>", "caption": "O kappa é a distância do ponto do acaso ao observado, medida contra o espaço que sobra acima do ponto do acaso. A última linha concorda em 88% das respostas e não é melhor que o acaso."}
```

Este é o caso para o qual o kappa existe. Uma concordância de 88% parece um juiz digno de confiança, e
num painel seria relatada como um. O kappa diz que o juiz **ainda não pegou uma única resposta
irrelevante**, e as sete listadas são exatamente as respostas para as quais um juiz de relevância
serve.

## O que a equipe faz em seguida

Três passos, na ordem em que uma equipe os dá, e cada um medido de novo contra os mesmos sessenta
rótulos:

- **Manter a regra.** Recusas aprovadas por regra não custam chamada ao juiz: 24 de 60 chamadas
  poupadas, e a discordância mais comum eliminada. A aula 9 pôs preço em cada chamada.
- **Trocar o prompt do juiz pelo da rubrica.** As âncoras da versão 2 foram escritas para pessoas e
  servem para um modelo também: um juiz de verdade que recebe o exemplo da entrega expressa tem com o
  que comparar. O judge-1 são as regras do laboratório e não dá para fazê-lo ler com um prompt, então o
  laboratório para aqui; com um modelo de verdade, este é o passo que move o kappa.
- **Medir de novo a cada troca de juiz.** Um modelo de juiz novo, um prompt novo, um limiar novo: cada
  um é um instrumento diferente, e os sessenta rótulos dizem na hora se ele concorda com as pessoas
  melhor ou pior do que o anterior. A aula 14 transforma essa comparação num teste.

Os rótulos sobrevivem a todo juiz. É por isso que são nomeados por pergunta e versão, e não por trace,
e por isso que a versão da rubrica está escrita em cada linha.
