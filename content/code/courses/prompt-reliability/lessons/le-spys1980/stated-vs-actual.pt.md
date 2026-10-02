---
title: Declarado e real
version: 1
---

Pergunte a um modelo quão seguro ele está e ele responde, com um número de duas casas decimais. O
número parece uma probabilidade. **É texto que o modelo escreveu**, como a categoria ao lado, e
nada garante que tenha sido calculado a partir de alguma coisa. Calibração é a pergunta sobre se
esse número bate com a frequência com que o modelo acerta quando o diz.

O prompt desta aula acrescenta um quarto campo:

```
ana@lab:~/triage$ grep -n confidence prompts/v9-confidence.txt
7:- "confidence": how sure you are of the category, from 0 to 1
11:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "confidence": 0.9}
16:Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book.", "confidence": 0.95}
21:Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name.", "confidence": 0.85}
```

A instrução pede um número de 0 a 1, e os três exemplos mostram como ele fica.

## Como o substituto decide o que dizer

```
ana@lab:~/triage$ grep -n -A6 "^def confidence" promptlab/standin.py
242:def confidence(sc, label):
243-    """What it SAYS its confidence is. It is worked out from how much evidence
244-    it found FOR its answer, and never looks at the evidence for the others:
245-    a message full of billing words gets a confident billing, even when it is
246-    just as full of words for returns. That is the course's choice, made so
247-    that lesson 21 has an overconfident model to calibrate."""
248-    return min(0.99, round(0.62 + 0.1 * max(0.0, sc[label]), 2))
```

O substituto declara 0,62, mais um décimo da pontuação que encontrou **para o rótulo que escolheu**,
e nunca mais que 0,99. Ele não olha a pontuação dos outros rótulos. Uma mensagem com evidência forte
para dois rótulos recebe uma resposta confiante para o que venceu, e essa é a falha que a docstring
diz ter sido posta lá de propósito. É um jeito plausível de um modelo ser confiante demais, e dá a
esta aula algo para medir.

## Um erro confiante

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/all.jsonl --out runs/v9.jsonl
70 calls, prompt c31bed19, written to runs/v9.jsonl
ana@lab:~/triage$ pl check runs/v9.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     56    14
urgency      47    23
all          47    23
ana@lab:~/triage$ grep h04 cases/all.jsonl
{"id": "h04", "message": "I'd like to return the atlas, but the courier you use doesn't collect from my area.", "expect": {"category": "returns", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/v9.jsonl h04
│ {"category": "delivery", "urgency": "normal", "summary": "They'd like to return the atlas, but the courier you use doesn't collect from their area.", "confidence": 0.97}
stop: end, tokens in 287, out 54
```

Cinquenta e seis das setenta categorias estão certas, 80%. `h04` é uma das catorze que não estão, e
foi declarada com **0,97**. O cliente quer devolver um atlas e não consegue, porque a transportadora
não faz coleta na região dele. Uma pessoa chamou isso de returns. O substituto achou `courier` e
`collect`, duas palavras de delivery, e `return`, uma palavra de returns. Escolheu delivery e
declarou a confiança só com a evidência de delivery, como se a evidência de returns não estivesse na
mensagem.

Um erro confiante é uma anedota. Se o substituto é confiante demais em geral é uma pergunta sobre as
setenta respostas de uma vez, e a próxima seção a faz.
