---
title: Declarado e real
version: 2
---

Pergunte a um modelo o quanto ele tem certeza e ele vai dizer, num número com ponto decimal. O
número parece uma probabilidade. **É texto que o modelo escreveu**, como a categoria ao lado, e
nada garante que foi calculado a partir de alguma coisa. Calibração é a pergunta sobre se esse
número bate com a frequência com que o modelo acerta quando o diz.

A aula 6 salvou um prompt com um quarto campo, o `prompts/v9-confidence.txt`. Estas são as linhas
dele sobre confiança:

```
ana@lab:~/triage$ grep -n confidence prompts/v9-confidence.txt
7:- "confidence": how sure you are of the category, from 0 to 1
11:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "confidence": 0.9}
16:Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book.", "confidence": 0.95}
21:Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name.", "confidence": 0.85}
```

A instrução pede um número de 0 a 1, e os três exemplos mostram 0.9, 0.95 e 0.85.

## O que ele disse

Rode-o sobre os setenta casos:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/all.jsonl --out runs/v9.jsonl
70 calls, prompt c31bed19, llama3.2:3b, written to runs/v9.jsonl
ana@lab:~/triage$ pl check runs/v9.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     52    18
urgency      37    33
all          37    33
```

Cinquenta e duas das setenta categorias estão certas, 74%. Agora veja os números que ele declarou,
todos os setenta:

```
ana@lab:~/triage$ grep -o 'confidence\\": [0-9.]*' runs/v9.jsonl | sort | uniq -c
      1 confidence\": 0.0
     46 confidence\": 0.8
     22 confidence\": 0.9
      1 confidence\": 0.95
```

**Quatro valores diferentes, e 68 das 70 respostas dizem 0.8 ou 0.9.** Os exemplos mostravam 0.9,
0.95 e 0.85, e o modelo escreveu números parecidos. Se ele escolheu entre 0.8 e 0.9 por algum motivo
que a mensagem deu é a pergunta que o resto desta aula mede.

## Um erro confiante, um zero estranho

```
ana@lab:~/triage$ grep h03 cases/all.jsonl
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v9.jsonl h03
│ {"category": "account", "urgency": "high", "summary": "Wants to know about a suspicious order on their account.", "confidence": 0.9}
stop: stop, tokens in 291, out 38, 4.6 s
```

Uma cobrança por um pedido que o cliente nunca fez. A pessoa que rotulou chamou isso de billing:
dinheiro tirado que não deveria ter sido. O modelo chamou de account e declarou 0.9, o maior dos
seus dois valores.

```
ana@lab:~/triage$ pl show runs/v9.jsonl t35
│ {"category": "other", "urgency": "low", "summary": "Compliments the shop and its service.", "confidence": 0.0}
stop: stop, tokens in 290, out 35, 4.2 s
```

Um bilhete de agradecimento, rotulado `other`, certo, e declarado com **0.0**. Uma confiança zero
numa resposta certa é ou um modelo que nunca tem certeza sobre elogios ou um modelo que leu o campo
como outra coisa, o quanto a mensagem é um problema, talvez. A execução não diz qual, e é esse o
ponto: o campo é um número que o modelo escreveu, e o que ele quer dizer é o que o modelo quis dizer.

Um erro confiante é uma anedota. Se os números declarados querem dizer alguma coisa é uma pergunta
sobre as setenta respostas de uma vez, e a próxima seção a faz.
