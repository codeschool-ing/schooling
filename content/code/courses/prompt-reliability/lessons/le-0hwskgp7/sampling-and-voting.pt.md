---
title: Amostrar e votar
version: 1
---

O outro jeito de ter vários votantes é perguntar a um prompt várias vezes com temperatura acima de
0, para que cada resposta seja uma amostra nova. É a forma que a autoconsistência assume, e **neste
laboratório ela se sai pior do que não votar**:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
350 calls, prompt fbc4c9b1, written to runs/s5.jsonl
ana@lab:~/triage$ pl vote runs/s5.jsonl
runs/s5.jsonl              229/350 right
majority of the samples    52/70 right
unanimous on 27 cases, a tie on 6
```

Cinco amostras de cada uma das setenta mensagens, 350 chamadas. Cada amostra sozinha acertou 229
vezes em 350, cerca de 65%. A votação das cinco por mensagem acertou **52 de 70**. O mesmo prompt
com temperatura 0, na execução da seção anterior, acertou 56.

Veja o que a amostragem fez com uma mensagem que a temperatura 0 acertava:

```
ana@lab:~/triage$ pl show runs/s5.jsonl t37 --sample 0
│ {
│   "category": "other",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."
│ }
stop: end, tokens in 128, out 46
ana@lab:~/triage$ pl show runs/s5.jsonl t37 --sample 1
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."
│ }
stop: end, tokens in 128, out 46
```

`t37` é um pedido atrasado, rotulado delivery. Duas amostras, dois rótulos errados diferentes.

## Por que a votação perdeu

No substituto, a temperatura 0 escolhe o rótulo de maior pontuação. Acima de 0, ele sorteia um
rótulo, com o de maior pontuação como o sorteio mais provável e os outros possíveis; o
`promptlab/sample.py` mostra como. Então cada amostra é a resposta da temperatura 0 com **erros
acrescentados em volta**, e uma votação de amostras é uma tentativa de tirar esses erros de novo. O
máximo que ela recupera é o rótulo que o sorteio favorece, que é o rótulo que a temperatura 0 já
dava, salvo empates.

Com cinco amostras ela nem sempre recupera nem isso. Numa mensagem em que o rótulo favorecido sai
menos da metade das vezes, a conta da primeira seção roda ao contrário e a maioria cai em outro
lugar. Seis das setenta votações empataram, e o `pl vote` desempata ficando com a primeira amostra.
**A amostragem acrescentou erros e a votação tirou a maioria deles**, e a maioria é menos que todos.

Há uma armadilha no jeito como isso é relatado. Comparada a uma amostra só com temperatura 0,8,
cerca de 65% de acerto, a votação parece um ganho. Comparada à resposta que você teria sem amostrar,
é uma perda. **Compare sempre um ensemble com a melhor chamada única**, e não com um dos próprios
membros.

## De onde vem a autoconsistência

Os ganhos que tornaram a técnica conhecida foram reais, e vieram de outro tipo de tarefa.
*Self-Consistency Improves Chain of Thought Reasoning in Language Models* (Wang e outros, 2022)
amostrava várias cadeias de raciocínio para o mesmo problema, entre eles questões de aritmética e de
senso comum, e tirava a maioria das respostas finais. O argumento era que um problema tem muitos
jeitos de raciocinar até a resposta certa, e que cadeias erradas tendem a se espalhar por respostas
erradas diferentes, então a certa junta mais votos.

Uma classificação de uma palavra não tem cadeia. A amostra é a resposta, há um único caminho até
ela, e as amostras compartilham todos os motivos que o prompt dá ao modelo para pender para um lado.
Antes de pagar por uma votação de amostras, pergunte se a sua tarefa tem **muitos caminhos
diferentes até uma resposta**. Se não tiver, meça contra a temperatura 0 primeiro, como acima.
