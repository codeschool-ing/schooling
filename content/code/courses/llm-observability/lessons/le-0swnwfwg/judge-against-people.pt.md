---
title: O juiz, medido contra as pessoas
version: 2
---

Com uma referência em que duas pessoas concordam, o juiz pode ser medido do mesmo jeito que elas foram.
O `judge_runs.py` pede ao juiz da aula 9 um veredicto de relevância para cada uma das quarenta e oito
respostas e os escreve onde o `agree.py` os lê:

```python
"""judge_runs.py: the judge's relevance verdict on every reply of the two runs, written where agree.py reads it.

    python judge_runs.py [--refusals-by-key] [--rubric data/rubrics/relevance-v2.md]

--refusals-by-key decides the agreed refusal without the judge, as version 2
of the rubric says: it passes when the evaluation set has no facts for the
question, so the documents do not answer it, and fails when it has some.
--rubric gives the judge that file in place of judge.py's own sentence.
"""
import argparse
import json

import checks
import judge
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--refusals-by-key", action="store_true")
p.add_argument("--rubric")
a = p.parse_args()
if a.rubric:
    judge.RUBRIC["relevance"] = open(a.rubric).read()
facts = {c["id"]: c["facts"] for c in map(json.loads, open("data/eval.jsonl"))}
telemetry.setup("judge-spans.jsonl", service="judge")
asked = total = 0
with open("runs/judged.jsonl", "w") as out:
    for run in ("old", "new"):
        for r in map(json.loads, open(f"runs/{run}.jsonl")):
            if a.refusals_by_key and checks.is_refusal(r["reply"]):
                label = "fail" if facts[r["id"]] else "pass"
            else:
                label = judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"]
                asked += 1
            out.write(json.dumps({"case": r["id"], "release": r["release"], "label": label}) + "\n")
            total += 1
print(f"runs/judged.jsonl: {total} replies, {asked} sent to the judge, {total - asked} decided by the key")
```

```
ana@dev:~/obs$ python judge_runs.py
runs/judged.jsonl: 48 replies, 48 sent to the judge, 0 decided by the key
ana@dev:~/obs$ python agree.py relevance-v2/agreed judge
48 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      20    21
  fail       0     7
agreement 56.2%   by chance 44.1%   kappa 0.22
apart on 21: 10 refusals, 11 other replies
  e01 2026.10.1  pass / fail  You have 30 days from the date of delivery to return a pri
  e02 2026.10.1  pass / fail  According to [1], the customer pays for the return postage
  e03 2026.09.4  pass / fail  According to [1], we refund within three working days of t
  e03 2026.10.1  pass / fail  According to [1], we refund within three working days of t
  e04 2026.09.4  pass / fail  According to [1], signed copies are items that cannot be r
  e07 2026.09.4  pass / fail  According to source [1], standard delivery is free on orde
  e08 2026.09.4  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e08 2026.10.1  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e11 2026.09.4  pass / fail  You can read your e-books on up to six devices at the same
  e16 2026.09.4  pass / fail  According to [1], payments-and-invoices, every order comes
  e16 2026.10.1  pass / fail  You will receive the invoice for your order as soon as it 
  e20 2026.09.4  pass / fail  I could not find that in our documents.
  e20 2026.10.1  pass / fail  I could not find that in our documents.
  e21 2026.09.4  pass / fail  I could not find that in our documents.
  e21 2026.10.1  pass / fail  I could not find that in our documents.
  e22 2026.09.4  pass / fail  I could not find that in our documents.
  e22 2026.10.1  pass / fail  I could not find that in our documents.
  e23 2026.09.4  pass / fail  I could not find that in our documents.
  e23 2026.10.1  pass / fail  I could not find that in our documents.
  e24 2026.09.4  pass / fail  I could not find that in our documents.
  e24 2026.10.1  pass / fail  I could not find that in our documents.
```

**O kappa é 0,22**, e as discordâncias do juiz com as pessoas são de dois tipos:

- **Ele reprovou toda recusa**, como a aula 9 achou: as dez certas, a perguntas que os documentos não
  respondem, e as sete erradas, que as pessoas também reprovaram. O juiz não consegue separá-las,
  porque nada do que ele vê diz se os documentos respondem à pergunta. Uma recusa chega sem fonte
  nenhuma.
- **Ele reprovou onze respostas que respondem à pergunta**: o prazo de devolução, o tempo do reembolso,
  o preço da entrega expressa, a nota fiscal. Não são casos difíceis. As pessoas aprovaram todas elas
  nas duas versões da rubrica.

Isso muda o que os números da aula 9 queriam dizer. A taxa de aprovação em relevância do juiz caiu de
43,3% para 34,0% com a versão, e a versão de fato recusou mais: mas toda recusa contou como reprovação,
as certas inclusive, e cerca de um terço das respostas contou como reprovação também. O número se mexeu
por um motivo real e era feito das coisas erradas. É isso que um juiz que ninguém mediu faz: produz um
número que se mexe quando as coisas mudam, e ninguém sabe dizer o que o número quer dizer.

## Decidindo por regra o que dá para decidir

A versão 2 resolve as recusas sem ler a resposta: a recusa combinada passa se os documentos não
respondem à pergunta, e reprova se respondem. Se respondem está no conjunto de avaliação, como os fatos
de cada pergunta, então uma regra decide toda recusa antes de o juiz ser chamado. O
`--refusals-by-key` faz isso:

```
ana@dev:~/obs$ python judge_runs.py --refusals-by-key
runs/judged.jsonl: 48 replies, 31 sent to the judge, 17 decided by the key
ana@dev:~/obs$ python agree.py relevance-v2/agreed judge
48 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      30    11
  fail       0     7
agreement 77.1%   by chance 58.9%   kappa 0.44
apart on 11: 0 refusals, 11 other replies
  e01 2026.10.1  pass / fail  You have 30 days from the date of delivery to return a pri
  e02 2026.10.1  pass / fail  According to [1], the customer pays for the return postage
  e03 2026.09.4  pass / fail  According to [1], we refund within three working days of t
  e03 2026.10.1  pass / fail  According to [1], we refund within three working days of t
  e04 2026.09.4  pass / fail  According to [1], signed copies are items that cannot be r
  e07 2026.09.4  pass / fail  According to source [1], standard delivery is free on orde
  e08 2026.09.4  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e08 2026.10.1  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e11 2026.09.4  pass / fail  You can read your e-books on up to six devices at the same
  e16 2026.09.4  pass / fail  According to [1], payments-and-invoices, every order comes
  e16 2026.10.1  pass / fail  You will receive the invoice for your order as soon as it 
```

**Kappa 0,44**, de 0,22, e dezessete chamadas ao juiz economizadas, uma em três. Toda recusa agora está
certa por construção, e o que sobra é do próprio juiz: as onze respostas que ele reprova. É o tamanho
honesto do problema deste juiz, e agora é uma lista que dá para ler.

## Dando ao juiz a rubrica das pessoas

O próximo passo óbvio é dar ao juiz o que as pessoas receberam: a versão 2, com as âncoras, no lugar da
frase única que o `judge.py` manda. O `--rubric` faz isso, e as recusas ficam com a regra:

```
ana@dev:~/obs$ python judge_runs.py --refusals-by-key --rubric data/rubrics/relevance-v2.md
runs/judged.jsonl: 48 replies, 31 sent to the judge, 17 decided by the key
ana@dev:~/obs$ python agree.py relevance-v2/agreed judge
48 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      13    28
  fail       0     7
agreement 41.7%   by chance 33.8%   kappa 0.12
apart on 28: 0 refusals, 28 other replies
  e01 2026.09.4  pass / fail  According to [1], you have 30 days from delivery to return
  e01 2026.10.1  pass / fail  You have 30 days from the date of delivery to return a pri
  e02 2026.09.4  pass / fail  According to [1], returns are free, and you will receive a
  e02 2026.10.1  pass / fail  According to [1], the customer pays for the return postage
  e03 2026.09.4  pass / fail  According to [1], we refund within three working days of t
  e03 2026.10.1  pass / fail  According to [1], we refund within three working days of t
  e04 2026.09.4  pass / fail  According to [1], signed copies are items that cannot be r
  e06 2026.09.4  pass / fail  According to source [1], standard delivery takes three to 
  e06 2026.10.1  pass / fail  According to [1], standard delivery takes three to six wor
  e07 2026.09.4  pass / fail  According to source [1], standard delivery is free on orde
  e07 2026.10.1  pass / fail  According to [1], standard delivery is free on orders over
  e08 2026.09.4  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e08 2026.10.1  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e09 2026.09.4  pass / fail  According to [1], a standard parcel is considered lost whe
  e09 2026.10.1  pass / fail  According to [1], a standard parcel is considered lost whe
  e10 2026.09.4  pass / fail  According to [1], a pickup point keeps a parcel for 10 day
  e10 2026.10.1  pass / fail  According to [1], a pickup point keeps a parcel for 10 day
  e11 2026.09.4  pass / fail  You can read your e-books on up to six devices at the same
  e13 2026.09.4  pass / fail  According to [1], audiobooks can be played in the app, on 
  e14 2026.09.4  pass / fail  Yes, you can pay in instalments. According to [1], on a cr
  e15 2026.09.4  pass / fail  According to [1], an order paid by bank slip ships after t
  e15 2026.10.1  pass / fail  According to [1], an order paid by bank slip ships after t
  e16 2026.09.4  pass / fail  According to [1], payments-and-invoices, every order comes
  e16 2026.10.1  pass / fail  You will receive the invoice for your order as soon as it 
  e17 2026.09.4  pass / fail  According to [1], a gift card is valid for two years from 
  e17 2026.10.1  pass / fail  According to [1], a gift card is valid for two years from 
  e18 2026.09.4  pass / fail  According to [1], if the order costs more than the card ho
  e19 2026.09.4  pass / fail  According to [1], the statutory right of withdrawal is sev
```

**Piorou. Kappa 0,12, e o juiz agora reprova 28 das 31 respostas que lê**, quase toda resposta, onde
reprovava 11 com a própria frase. Uma rubrica escrita para pessoas, com as distinções entre relevância
e fidelidade e os exemplos das duas, é um prompt mais longo e mais difícil, e um modelo de três bilhões
de parâmetros entendeu menos dela que de uma pergunta simples. Não é uma lei que âncoras atrapalham um
juiz; com um modelo maior elas costumam ajudar. É um resultado neste juiz, e sem quarenta e oito
rótulos ninguém saberia que a mudança que todo mundo faria primeiro piorou a medida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Concordância observada e concordância por acaso, num eixo de 0 a 100%, com o kappa ao lado de cada linha. Ana e Bruno na versão 1: 64,6% contra 64,6% por acaso, kappa 0,00. Na versão 2: 93,8% contra 79,5%, kappa 0,69. O juiz contra os rótulos acordados: 56,2% contra 44,1%, kappa 0,22. Com as recusas decididas pelo gabarito: 77,1% contra 58,9%, kappa 0,44. Recebendo também a rubrica das pessoas: 41,7% contra 33,8%, kappa 0,12.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana e Bruno, versão 1</text><path d=\"M489.02 48 L489.02 48\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"489.02\" cy=\"48\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"489.02\" cy=\"48\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,00</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana e Bruno, versão 2</text><path d=\"M544.15 86 L597.06 86\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"544.15\" cy=\"86\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"597.06\" cy=\"86\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,69</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o juiz, sozinho</text><path d=\"M413.17 124 L457.94 124\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"413.17\" cy=\"124\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"457.94\" cy=\"124\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,22</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o juiz, recusas pelo gabarito</text><path d=\"M467.93 162 L535.27 162\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"467.93\" cy=\"162\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"535.27\" cy=\"162\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,44</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e a rubrica das pessoas</text><path d=\"M375.06 200 L404.29 200\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"375.06\" cy=\"200\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"404.29\" cy=\"200\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0,12</text><path d=\"M250 230 L620 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M250 230 L250 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"250\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M324 230 L324 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"324\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M398 230 L398 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"398\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M472 230 L472 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"472\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M546 230 L546 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"546\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M620 230 L620 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"620\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"435\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parte das 48 respostas em que os dois concordam</text><circle cx=\"250\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"260\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">observada</text><circle cx=\"361\" cy=\"16\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"371\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">por acaso</text></svg>", "caption": "O kappa é a distância do ponto por acaso até o observado, medida contra o espaço que sobra acima do ponto por acaso. A primeira linha concorda em duas respostas de cada três e não é melhor que o acaso."}
```

É para esse caso que o kappa existe, e a figura mostra por que ele não é concordância. A última linha
concorda com as pessoas em 42% das respostas; a terceira em 56%; a quarta em 77%. Cada uma pareceria um
juiz que alguém poderia relatar. O kappa as põe na ordem certa, e diz que a melhor delas ainda está
longe dos 0,69 das pessoas.

## O que a equipe faz em seguida

Três passos, na ordem em que uma equipe os dá, e cada um medido de novo contra os mesmos quarenta e
oito rótulos:

- **Manter a regra.** Recusas decididas pelo gabarito não custam chamada ao juiz, e estão certas sempre
  que o gabarito está.
- **Manter a frase própria do juiz**, até um prompt medir melhor. Uma mudança no juiz é uma mudança no
  instrumento, e esta foi uma mudança para pior.
- **Experimentar um juiz melhor**, um modelo maior ou outro, e medi-lo do mesmo jeito. Um juiz que é
  um modelo diferente do assistente também deixa de dividir os pontos cegos dele. Comparar dois
  juízes contra os mesmos rótulos é o mesmo exercício desta seção, rodado duas vezes.

Os rótulos sobrevivem a todo juiz. É por isso que são nomeados por pergunta e versão, e não por trace,
e por isso a versão da rubrica está escrita ao lado de cada veredicto.
