---
title: A mesma pergunta, duas vezes
version: 1
---

Um programa rodado duas vezes com a mesma entrada dá a mesma saída. Um modelo pode não dar, e uma
avaliação que rodou cada caso uma vez mediu um sorteio de algo que varia.

De onde vem a variação é a configuração de **temperatura** que o `prompt-engineering` trata: acima
de zero, o modelo sorteia entre os próximos tokens prováveis em vez de pegar sempre o mais provável,
então o mesmo prompt pode produzir respostas diferentes. Em zero a maioria dos provedores chega
perto de repetível, embora nem todos garantam.


## Com temperatura 0

O `evalkit` manda temperatura 0 a menos que lhe digam outra coisa. A ana roda o qwen2.5:3b de novo
nos mesmos casos e compara as respostas com as da primeira execução:

```
ana@desk:~/desk$ python evalkit.py run triage runs/again.jsonl 0 qwen2.5:3b && diff <(cut -d, -f4,5 runs/again.jsonl) <(grep qwen2.5:3b runs/triage.jsonl | cut -d, -f4,5) && echo same answers
same answers
```

Idênticas, caso a caso. Num servidor local sem mais nada rodando, é o que se espera; um provedor
atendendo milhares de requisições ao mesmo tempo pode não se repetir exatamente nem em zero, e rodar
duas vezes é como se descobre.

## Com temperatura 1

Depois duas vezes com temperatura 1, a configuração que alguns aplicativos deixam ligada para
rascunhos:

```
ana@desk:~/desk$ python evalkit.py run triage runs/hot-a.jsonl 1 qwen2.5:3b; python evalkit.py run triage runs/hot-b.jsonl 1 qwen2.5:3b
```

```
ana@desk:~/desk$ python evalkit.py report runs/hot-a.jsonl; python evalkit.py report runs/hot-b.jsonl | tail -1
model         strict   loose     loose, 95%  p50 s  out tok
qwen2.5:3b     29/40   29/40     57% to  84%   0.82      2.8
qwen2.5:3b     30/40   30/40     60% to  86%   0.81      2.7
```

Mesmo modelo, mesmos casos, mesmo prompt: **29 uma vez e 30 na seguinte**. E os totais escondem mais
do que mostram, porque quatro casos mudaram entre as duas execuções:

```
ana@desk:~/desk$ diff <(cut -d, -f3,4 runs/hot-a.jsonl) <(cut -d, -f3,4 runs/hot-b.jsonl)
6c6
<  "case": "c06", "answer": "order-status"
---
>  "case": "c06", "answer": "refund"
10c10
<  "case": "c10", "answer": "refund"
---
>  "case": "c10", "answer": "product-question"
32c32
<  "case": "c32", "answer": "order-status"
---
>  "case": "c32", "answer": "address-change"
39c39
<  "case": "c39", "answer": "order-status"
---
>  "case": "c39", "answer": "other"
```

O c06, o pacote marcado como entregue, foi `order-status` uma vez e `refund` na outra; o c10, a nota
fiscal, foi `refund` e depois `product-question`. O c32 e o c39 foram no sentido contrário: errados
na primeira execução, certos na segunda. **Quatro respostas mudaram e a nota mudou um**, porque duas
mudanças se anularam. Esses são os casos que ficam perto das fronteiras do próprio modelo, e você
descobre quais são rodando mais de uma vez.

## O que resulta

- **Classifique e extraia com temperatura 0.** Há uma resposta certa; variedade é só ruído.
- **Onde a temperatura precisa ficar alta**, como pode ser para rascunhos, rode cada caso várias
  vezes e relate a dispersão, não uma nota. "De 29 a 30 em duas execuções" é uma afirmação
  verdadeira; "30" sozinho não é.
- **Uma diferença entre dois modelos menor que a dispersão de um modelo entre execuções não é uma
  diferença.** Quatro respostas mudaram entre estas duas execuções de um modelo. A comparação da
  seção 06 se apoiou em vinte e um casos em que só um dos dois acertou, e é por isso que ela
  sobrevive a isso, e uma divisão de dois ou três casos não sobreviveria.
