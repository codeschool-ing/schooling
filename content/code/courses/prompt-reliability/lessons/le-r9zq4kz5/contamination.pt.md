---
title: Quando o teste vaza para o prompt
version: 2
---

A aula 1 avisou que um exemplo que também é caso de teste é respondido por cópia. Este prompt faz
isso de propósito: é o `v3-examples.txt` com os três exemplos trocados por três casos do dev, palavra
por palavra, e são três que o `v3` errou. Salve-o como `prompts/v11-contaminated.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

<example>
Message: Can I pay with a gift card and a credit card on the same order?
Output: {"category": "billing", "urgency": "low", "summary": "Asks whether two payment methods can be combined."}
</example>

<example>
Message: Your app keeps logging me out every few minutes.
Output: {"category": "account", "urgency": "normal", "summary": "The app keeps signing the customer out."}
</example>

<example>
Message: I'd like to cancel my subscription to the monthly box before the next payment.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants to cancel the monthly box before the next charge."}
</example>

Message: {{message}}
```

```
ana@lab:~/triage$ grep -n "Message:" prompts/v11-contaminated.txt
9:Message: Can I pay with a gift card and a credit card on the same order?
14:Message: Your app keeps logging me out every few minutes.
19:Message: I'd like to cancel my subscription to the monthly box before the next payment.
23:Message: {{message}}
ana@lab:~/triage$ grep -E "\"t(22|25|26)\"" cases/dev.jsonl
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "t25", "message": "Your app keeps logging me out every few minutes.", "expect": {"category": "account", "urgency": "normal"}}
{"id": "t26", "message": "I'd like to cancel my subscription to the monthly box before the next payment.", "expect": {"category": "billing", "urgency": "normal"}}
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/dev.jsonl --out runs/v11.jsonl
40 calls, prompt 9c3b6425, llama3.2:3b, written to runs/v11.jsonl
ana@lab:~/triage$ pl compare runs/v3.jsonl runs/v11.jsonl
runs/v3.jsonl            passes 28/40
runs/v11.jsonl           passes 28/40
fixed 4, broken 4
broken: t03 t16 t18 t38
sign test on the 8 that changed: p = 1.000
```

Os mesmos 28 de 40, e quatro mensagens se mexeram para cada lado. As quatro consertadas são o `t01`,
o `t22`, o `t25` e o `t26`, e três delas são os exemplos. **Esses três casos não conseguem mais errar
a categoria**: o prompt contém as respostas deles. Olhe as verificações em vez do total:

```
ana@lab:~/triage$ pl check runs/v11.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     39     1
urgency      28    12
all          28    12

t02    urgency   high, expected normal
t03    urgency   low, expected normal
t07    urgency   low, expected normal
t09    urgency   high, expected normal
t16    urgency   low, expected normal
t18    urgency   low, expected normal
t24    urgency   high, expected normal
t32    urgency   high, expected normal
t33    urgency   high, expected normal
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    urgency   low, expected normal
```

Trinta e nove categorias certas em quarenta, contra trinta e cinco do `v3`. Quem lesse esta tabela
depois de alguém "melhorar os exemplos" diria que as categorias estavam quase resolvidas e que o
trabalho que sobrava era a urgência. Três das quatro categorias ganhas foram copiadas, e as urgências
se mexeram sozinhas: o `t03`, o `t16` e o `t18` passaram de aprovados para `low`, e assim o total
ficou onde estava.

Tire os três e compare igual com igual. Nas 37 mensagens que não lhe foram mostradas, o `v11` aprova
25; nas mesmas 37, o `v3` aprova 28. O holdout diz a mesma coisa mais alto:

```
ana@lab:~/triage$ pl run prompts/v11-contaminated.txt cases/holdout.jsonl --out runs/v11-holdout.jsonl
30 calls, prompt 9c3b6425, llama3.2:3b, written to runs/v11-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v3-holdout.jsonl runs/v11-holdout.jsonl
runs/v3-holdout.jsonl    passes 14/30
runs/v11-holdout.jsonl   passes 9/30
fixed 2, broken 7
broken: h04 h12 h13 h25 h26 h28 h30
sign test on the 9 that changed: p = 0.180
```

Catorze para nove, sete quebradas e duas consertadas. As categorias dele no holdout:

```
ana@lab:~/triage$ pl check runs/v11-holdout.jsonl
check      pass  fail
json         30     0
fields       30     0
labels       30     0
category     17    13
urgency       9    21
all           9    21
```

Dezessete certas, contra dezoito do `v3`, e as urgências caíram de catorze para nove. Um teste do
sinal de 0.180 não chama a queda de mais que acaso, e nada aqui parece um ganho. **Em tudo o que o
prompt contaminado não tinha visto, ele não foi melhor, e provavelmente foi pior**: três exemplos
escolhidos por serem casos do dev que falhavam ensinaram a ele as respostas de três casos do dev.

## Por que ela se esconde

**O tamanho da inflação depende de quantos casos vazaram e de quantos deles estavam falhando**, e
aqui ela se escondeu dentro de um total que não se mexeu: três respostas copiadas ganhas, três
urgências perdidas. A contaminação não se anuncia com um salto. Ela chega como uma linha melhor em
algum ponto da tabela depois que alguém melhorou os exemplos, o que parece exatamente progresso, e
um conjunto em que dez de quarenta estão coladas no prompt mede trinta enquanto relata quarenta.

Acontece sem má intenção. Os melhores exemplos são casos difíceis de fronteira, e os melhores casos
de teste também, então a mesma mensagem é a escolha óbvia para os dois. A proteção é mecânica:
mantenha exemplos e casos em arquivos separados e, antes de qualquer execução, verifique que nenhuma
mensagem de exemplo aparece num arquivo de casos. Essa verificação é uma busca só, e sai mais barata
do que descobrir por um holdout.
