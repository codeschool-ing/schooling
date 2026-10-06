---
title: Um cache semântico
version: 1
---

Um cache semântico casa perguntas pelo sentido: gera o embedding de cada pergunta nova, acha a guardada
mais próxima, e serve aquela resposta se a similaridade passar de um limite. "how long does a refund take"
e "refund timing after return" são uma pergunta só, e um cache exato guarda duas respostas para elas.

O `semantic.py` reproduz a semana por um cache semântico em seis limites, e usa o assunto de que cada
pergunta foi gerada para contar os acertos que serviram a resposta de outra pergunta:

```
ana@lab:~/rag$ python semantic.py
threshold  misses  hits  wrong
     0.95      38   462      0
     0.90      35   465      0
     0.85      32   468      0
     0.80      27   473      0
     0.75      24   476     25
     0.70      21   479     25
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Barras para seis limites de um cache semântico sobre as 500 perguntas da semana. As chamadas ao modelo caem de 38 em 0,95 para 27 em 0,80 sem nenhuma resposta errada; em 0,75 caem para 24 e 25 respostas saem erradas; em 0,70, 21 chamadas e 25 erradas.\"><path d=\"M70 240 L540 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 240 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M65 240.0 L70 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M65 190.0 L70 190.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M65 140.0 L70 140.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M65 90.0 L70 90.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><rect x=\"88.0\" y=\"50.0\" width=\"20\" height=\"190.0\" fill=\"var(--phosphor)\"></rect><text x=\"110.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,95</text><rect x=\"166.0\" y=\"65.0\" width=\"20\" height=\"175.0\" fill=\"var(--phosphor)\"></rect><text x=\"188.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,90</text><rect x=\"244.0\" y=\"80.0\" width=\"20\" height=\"160.0\" fill=\"var(--phosphor)\"></rect><text x=\"266.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,85</text><rect x=\"322.0\" y=\"105.0\" width=\"20\" height=\"135.0\" fill=\"var(--phosphor)\"></rect><text x=\"344.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,80</text><rect x=\"400.0\" y=\"120.0\" width=\"20\" height=\"120.0\" fill=\"var(--phosphor)\"></rect><rect x=\"424.0\" y=\"115.0\" width=\"20\" height=\"125.0\" fill=\"var(--amber)\"></rect><text x=\"422.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,75</text><rect x=\"478.0\" y=\"135.0\" width=\"20\" height=\"105.0\" fill=\"var(--phosphor)\"></rect><rect x=\"502.0\" y=\"115.0\" width=\"20\" height=\"125.0\" fill=\"var(--amber)\"></rect><text x=\"500.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,70</text><text x=\"305.0\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">limite de similaridade do cache</text><rect x=\"566\" y=\"54\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"584\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chamadas ao modelo</text><rect x=\"566\" y=\"78\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"584\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">respostas erradas</text></svg>", "caption": "Baixar o limite poupa chamadas devagar e de repente quebra: de 0,80 para 0,75 o cache poupa mais três chamadas e serve a 25 clientes a resposta de outra pergunta."}
```

De 0,95 até 0,80, **as falhas caem de 38 para 27 sem nenhuma resposta errada**: onze chamadas ao modelo
poupadas em relação ao cache exato. Em **0,75, mais três chamadas são poupadas e 25 respostas saem
erradas**, todas de um cliente perguntando sobre um tipo de cancelamento e recebendo a resposta sobre o
outro:

```
ana@lab:~/rag$ python near.py
0.867  'Can I cancel a pre-order?'  'Can I cancel my order?'
0.872  'how do I cancel a pre-order'  'how do I cancel an order'
0.774  'how long does a refund take'  'refund timing after return'
```

"Can I cancel a pre-order?" e "Can I cancel my order?" têm similaridade 0,867, mais próximas que duas
redações honestas da pergunta de reembolso, com 0,774, e têm respostas diferentes. **A similaridade entre
perguntas mede o quanto as palavras e os assuntos se parecem, e não se elas têm a mesma resposta.** Um
limite alto o bastante para separar os dois cancelamentos é alto demais para juntar as redações do
reembolso, e esse conflito está nas perguntas, não no modelo.

Três consequências para quem acrescenta um:

- **O limite é escolhido num registro rotulado**, do jeito que a aula 8 escolheu o piso, e conferido em
  perguntas que não serviram para escolhê-lo. O 0,80 que funciona aqui é um número sobre estas quarenta
  redações.
- **A margem é estreita e invisível.** Entre 0,80 e 0,75 nada piorou aos poucos; quebrou. Um cache que
  serve respostas erradas não produz erro nem reclamação até um cliente agir com base numa delas.
- **O ganho é a diferença para o cache exato**, onze chamadas de 486 aqui, e não a diferença para nenhum
  cache. A maior parte do que um cache semântico parece poupar, um cache exato já poupa sem resposta
  errada nenhuma.
