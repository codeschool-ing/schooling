---
title: Quando o teste vaza para o prompt
version: 1
---

A aula 1 avisou que um exemplo que também é caso de teste é respondido por cópia. O
`v11-contaminated.txt` faz isso de propósito. Os três exemplos dele são três casos de dev, palavra por
palavra:

```
ana@lab:~/triage$ grep -n "Message:" prompts/v11-contaminated.txt
9:Message: I returned a book three weeks ago and I still haven't had the refund.
14:Message: The parcel came but it was soaked and the books inside are ruined.
19:Message: The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.
23:Message: {{message}}
ana@lab:~/triage$ grep -E "\"t(21|23|37)\"" cases/dev.jsonl
{"id": "t21", "message": "I returned a book three weeks ago and I still haven't had the refund.", "expect": {"category": "returns", "urgency": "high"}}
{"id": "t23", "message": "The parcel came but it was soaked and the books inside are ruined.", "expect": {"category": "returns", "urgency": "high"}}
{"id": "t37", "message": "The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/dev.jsonl --out runs/v11.jsonl
40 calls, prompt c725469f, written to runs/v11.jsonl
ana@lab:~/triage$ pl compare runs/v3.jsonl runs/v11.jsonl
runs/v3.jsonl            passes 36/40
runs/v11.jsonl           passes 37/40
fixed 1, broken 0, still passing 36, still failing 3
sign test on the 1 that changed: p = 1.000
ana@lab:~/triage$ pl check runs/v11.jsonl --failures
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     40     0
urgency      37     3
all          37     3

t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
```

A nota foi de 36 para 37, e a única mensagem que mudou é `t37`, o terceiro exemplo. **Esses três
casos não conseguem mais falhar**: o prompt contém as respostas deles. `t21` e `t23` já passavam,
então copiá-los não rendeu nada visível, e os 37 agora incluem três casos que não medem nada.

Tire-os e compare igual com igual. Nas 37 mensagens que não lhe foram mostradas, a `v11` falha em
`t14`, `t24` e `t28` e passa em 34. A `v3` falhava nas mesmas três e em `t37`, então nessas mesmas 37
também passa em 34. **Em tudo o que o prompt contaminado não tinha visto, os dois prompts são
iguais**, e o holdout concorda:

```
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/holdout.jsonl --out runs/v11-holdout.jsonl
30 calls, prompt c725469f, written to runs/v11-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v3-holdout.jsonl runs/v11-holdout.jsonl
runs/v3-holdout.jsonl    passes 11/30
runs/v11-holdout.jsonl   passes 12/30
fixed 2, broken 1, still passing 10, still failing 17
broken: h28
sign test on the 3 that changed: p = 1.000
```

Onze contra doze, três mensagens mudaram, e um teste do sinal de 1.000: diferença nenhuma.

## Por que um ponto é o tamanho perigoso

Neste laboratório o número se moveu um ponto, e esse é o resultado honesto. É pouco porque dois dos
três casos copiados passavam de qualquer jeito, e só `t37` tinha algo a ganhar.

Essa pequenez é o perigo. A contaminação não se anuncia com um salto; ela chega como uma nota que
subiu um ponto depois que alguém melhorou os exemplos, o que parece exatamente progresso. **O tamanho
da inflação depende de quantos casos vazaram e de quantos deles estavam falhando**, e um conjunto em
que dez de quarenta estão colados no prompt mede trinta enquanto informa quarenta.

Acontece sem má intenção. Os melhores exemplos são casos difíceis de fronteira, e os melhores casos de
teste também, então a mesma mensagem é a escolha óbvia para os dois. A proteção é mecânica: mantenha
exemplos e casos em arquivos separados e, antes de qualquer execução, verifique que nenhuma mensagem
de exemplo aparece num arquivo de casos. Essa verificação é uma única busca, e sai mais barata que
descobrir pelo holdout.
