---
title: O que ele pega
version: 1
---

Rode o prompt delimitado e escapado com temperatura 0 e peça ao substituto que confira cada
resposta:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl selfcheck runs/v6.jsonl
t26  wrong  WRONG: the answer is not valid JSON
t37  right  WRONG: it could also be other
t39  wrong  WRONG: the answer is not valid JSON
h01  wrong  OK
h04  wrong  OK
h07  right  WRONG: it could also be account
h11  wrong  OK
h13  wrong  WRONG: it could also be billing
h14  wrong  OK
h15  wrong  WRONG: it could also be other
h16  wrong  WRONG: it could also be delivery
h19  wrong  WRONG: it could also be billing
h20  wrong  WRONG: it could also be billing
h26  wrong  OK
h27  wrong  OK
h28  wrong  WRONG: it could also be other
h30  right  WRONG: it could also be billing

               really wrong  really right
flagged                   8             3
not flagged               6            53
precision 0.73   recall 0.57
```

O `pl selfcheck` lista cada resposta que foi marcada ou estava errada, e depois a tabela. Das
setenta respostas, catorze estavam mesmo erradas. A verificação marcou onze, e oito delas estavam
entre as catorze.

Dois números resumem a tabela. A **precisão** pergunta quantas marcações estavam certas: 8 de 11,
0,73. A **revocação** pergunta quantos erros foram marcados: 8 de 14, 0,57. Uma verificação com
precisão alta e revocação baixa é quieta e confiável quando fala; uma com o contrário faz barulho e
pega mais. Nenhum dos dois números quer dizer algo sem o outro.

## Lendo a tabela

Duas das oito marcações certas são `t26` e `t39`, respostas que não são JSON. Qualquer programa
teria achado essas, e a última seção desta aula acha.

As outras seis são erros de rótulo, e todas foram pegas do mesmo jeito, com *it could also be*. O
revisor duvidou dessas respostas porque os dois melhores rótulos dele estavam próximos. Veja o que
ele sugeriu no lugar, contra o que a pessoa disse:

```
ana@lab:~/triage$ grep -E '"(h13|h15|h16|h19|h20|h28)"' cases/all.jsonl | grep -o '"category": "[a-z]*"'
"category": "returns"
"category": "account"
"category": "returns"
"category": "account"
"category": "delivery"
"category": "billing"
```

Returns, account, returns, account, delivery, billing. O revisor sugeriu billing, other, delivery,
billing, billing e other. **Nenhuma das seis alternativas dele é o rótulo da pessoa.** Ele sabia
que a resposta era duvidosa e não sabia qual deveria ser, o que é uma marcação útil e uma correção
inútil.

## O que ele deixa passar

Seis respostas erradas voltaram com OK. Aqui está uma:

```
ana@lab:~/triage$ grep h27 cases/all.jsonl
{"id": "h27", "message": "Someone used my gift card balance before I did.", "expect": {"category": "account", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v6.jsonl h27
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "Someone used their gift card balance before they did."
│ }
stop: end, tokens in 116, out 34
```

Um estranho gastou o saldo do cartão-presente do cliente. A pessoa que rotulou chamou isso de
problema de conta, alguém entrando no que é dele. O substituto lê `card`, uma palavra de billing, e
diz billing. Quando pedem que confira, ele lê `card` de novo e concorda consigo mesmo. **Um erro que
o modelo cometeria de novo é um erro que a verificação dele não enxerga**, e cada um dos seis que
passaram é desse tipo.

Os três alarmes falsos são o mesmo mecanismo pelo outro lado: `t37`, `h07` e `h30` foram
respondidas corretamente, e em casos limítrofes, então o revisor duvidou delas mesmo assim. Uma
marcação aqui quer dizer *este foi um caso limítrofe*. Vale saber disso, desde que ninguém a leia
como *isto está errado*.
