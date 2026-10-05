---
title: A mesma pergunta, duas vezes
version: 1
---

Um programa rodado duas vezes com a mesma entrada dá a mesma saída. Um modelo pode não dar, e uma
avaliação que rodou cada caso uma vez mediu um sorteio de algo que varia.

De onde vem a variação é a configuração de **temperatura** que o `prompt-engineering` trata: acima
de zero, o modelo sorteia entre os próximos tokens prováveis em vez de pegar sempre o mais provável, então o
mesmo prompt pode produzir respostas diferentes. Em zero a maioria dos provedores chega perto de
repetível, embora nem todos garantam.

## Com temperatura 0

O `evalkit` manda temperatura 0 a menos que alguém diga outra coisa. A ana roda o standin-small de
novo nos mesmos casos e compara as respostas com as da primeira execução:

```
ana@desk:~/desk$ python lab/evalkit.py run triage runs/again.jsonl 0 standin-small && diff <(cut -d, -f4,5 runs/again.jsonl) <(grep standin-small runs/triage.jsonl | cut -d, -f4,5) && echo same answers
same answers
```

Idênticas, caso a caso.

## Com temperatura 1

Depois duas vezes com temperatura 1, a configuração que alguns aplicativos deixam ligada para
rascunhos:

```
ana@desk:~/desk$ python lab/evalkit.py run triage runs/hot-a.jsonl 1 standin-small; python lab/evalkit.py run triage runs/hot-b.jsonl 1 standin-small
```

```
ana@desk:~/desk$ python lab/evalkit.py report runs/hot-a.jsonl; python lab/evalkit.py report runs/hot-b.jsonl | tail -1
model           strict   loose     loose, 95%  p50 s  $ per 1k
standin-small    32/40   34/40     71% to  93%   0.21    0.0167
standin-small    30/40   32/40     65% to  90%   0.21    0.0167
```

Mesmo modelo, mesmos casos, mesmo prompt: **34 numa vez e 32 na outra**. A diferença entre as duas
execuções são dois casos:

```
ana@desk:~/desk$ diff <(cut -d, -f3,4 runs/hot-a.jsonl) <(cut -d, -f3,4 runs/hot-b.jsonl)
10c10
<  "case": "c10", "answer": "other"
---
>  "case": "c10", "answer": "refund"
17c17
<  "case": "c17", "answer": "refund"
---
>  "case": "c17", "answer": "order-status"
```

O c10, um pedido de nota fiscal, foi `other` numa execução e `refund` na outra. O c17, um reembolso
ainda não recebido, foi `refund` e depois `order-status`. São os dois casos instáveis do substituto,
escritos pelo curso para se comportarem assim; um modelo real com temperatura 1 varia nos casos que
ficam perto das fronteiras dele, e você descobre quais rodando mais de uma vez.

## O que resulta

- **Classifique e extraia com temperatura 0.** Há uma resposta certa; variedade é só ruído.
- **Onde a temperatura precisa ficar alta**, como pode ser no rascunho, rode cada caso várias vezes
  e relate a variação, não uma nota. "32 a 34 em duas execuções" é uma afirmação verdadeira; "34"
  sozinho não é.
- **Uma diferença entre dois modelos menor que a variação de um modelo entre execuções não é uma
  diferença.** Dois casos separaram estas execuções de um modelo só. É metade dos quatro casos que
  separaram o standin-large do standin-small na seção 06, mais um motivo para aquela comparação ter
  sido chamada de sugestiva.
