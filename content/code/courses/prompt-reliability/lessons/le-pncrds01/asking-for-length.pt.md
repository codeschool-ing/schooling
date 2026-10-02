---
title: Pedir uma resposta mais curta
version: 1
---

O jeito de conseguir uma resposta mais curta é pedi-la no prompt, onde o modelo lê.
`prompts/v4-words.txt` é o `v4-only-json.txt` com uma linha trocada:

```
ana@lab:~/triage$ diff prompts/v4-only-json.txt prompts/v4-words.txt
6c6
< - "summary": one sentence saying what the customer needs
---
> - "summary": what the customer needs, in under 12 words
ana@lab:~/triage$ pl run prompts/v4-words.txt cases/dev.jsonl --out runs/words.jsonl
40 calls, prompt d6ee7191, written to runs/words.jsonl
ana@lab:~/triage$ pl show runs/v4.jsonl t37
│ {
│   "category": "delivery",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."
│ }
stop: end, tokens in 101, out 46
ana@lab:~/triage$ pl show runs/words.jsonl t37
│ {
│   "category": "delivery",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says…"
│ }
stop: end, tokens in 103, out 39
```

No substituto a regra é tosca: ele acha o número e corta o resumo nessa quantidade de palavras, com
reticências. Conte e verá que ficaram doze, quando *under 12* permitia onze, porque ele lê o número e
não a palavra antes dele. Um modelo de linguagem escreveria mais vezes uma frase diferente e mais curta
do que cortaria uma longa, e também erraria um limite de palavras de vez em quando. **Um tamanho que
você pede é um tamanho que você confere**, do mesmo jeito que confere um rótulo.

Só que a resposta continua sendo JSON, e é essa a diferença que importa aqui. O pedido mudou o que
foi escrito, e a chave de fechamento fazia parte do que foi escrito. **Pedir dá forma à resposta; o
limite só a corta.**

## Quanto mais curta

```
ana@lab:~/triage$ pl latency runs/v4.jsonl
calls 40
p50 1170 ms   p95 1324 ms   max 1473 ms
output tokens: mean 38.0, max 50
ana@lab:~/triage$ pl latency runs/words.jsonl
calls 40
p50 1136 ms   p95 1255 ms   max 1323 ms
output tokens: mean 36.8, max 48
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/words.jsonl --answers
40 cases, same answer 40, different answer 0
```

O `pl latency` mostra os tempos de resposta que o substituto calcula e, na última linha, os tokens de
saída da execução. A média foi de 38.0 para 36.8, pouco mais de um token por resposta, e a resposta
mais longa de 50 para 48. É pouco, e a figura de *Tokens, não palavras* diz por quê: o resumo é a
única parte da resposta que pode encolher, e muitos resumos já tinham menos de doze palavras.
`--answers` compara o que cada resposta disse, e não se ela passou: as quarenta categorias saíram
iguais, então a mudança mexeu no tamanho e em mais nada.

## Você precisa dos dois

Um pedido não substitui o limite. Este é o prompt mais curto sob o mesmo limite de trinta:

```
ana@lab:~/triage$ pl run prompts/v4-words.txt cases/dev.jsonl --set max_tokens=30 --out runs/words30.jsonl
40 calls, prompt d6ee7191, written to runs/words30.jsonl
ana@lab:~/triage$ pl check runs/words30.jsonl
check      pass  fail
json          1    39
fields        1    39
labels        1    39
category      1    39
urgency       1    39
all           1    39
```

Uma aprovação em quarenta, igual a antes. Doze palavras de resumo dentro da moldura ainda passam de
trinta tokens, e uma resposta que obedece ao pedido à risca continua sendo cortada por um limite
abaixo dele. **Peça o tamanho que você quer e ponha o limite bem acima.** O pedido decide o tamanho
da resposta; o limite existe para a resposta que ignora o pedido.
