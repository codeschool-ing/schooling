---
title: Por que avaliar uma amostra
version: 2
---

Uma regra não custa nada, então a aula 8 a rodou em toda resposta. Um juiz é uma chamada de modelo por
resposta por critério, com a resposta, a pergunta e todas as fontes no prompt. Rodá-lo em tudo é
possível, e esta aula faz isso uma vez, para ter a semana inteira contra a qual comparar as amostras:

```
ana@dev:~/obs$ python grade_sample.py uniform --share 1.0
uniform: 275 of 275 replies graded for relevance in 25.6 min, 0 verdicts unreadable
  2026.09.4    58/134  pass  43.3%   95% between 35.2% and 51.7%
  2026.10.1    48/141  pass  34.0%   95% between 26.7% and 42.2%
```

Na semana inteira, **o juiz aprovou 43,3% das respostas em relevância na versão antiga, e 34,0% na
nova.** São números baixos, e parte do motivo é o juiz, não as respostas. Ele reprovou cada uma das 88
recusas, inclusive as que respondem a perguntas que os documentos não respondem, em que a recusa é a
resposta certa: a rubrica pergunta se uma resposta trata da pergunta, e não diz nada sobre o que uma
recusa faz. E reprovou respostas claramente certas, como "shipping is free on orders over R$ 40" para a
pergunta "when is shipping free". A aula 10 põe números em quanto se pode confiar neste juiz. Aqui a
pergunta é quanto custa avaliar e quanto disso é preciso, e essas respostas não dependem de o juiz ser
bom.

Levou **25,6 minutos** do processador desta máquina para avaliar 275 respostas num critério, uns cinco
segundos e meio cada, uma de cada vez. A última seção põe preço nisso; a versão curta é que cada
julgamento custou mais que a resposta que julgou.

Então a pergunta passa a ser: **quão poucas respostas dá para avaliar e ainda ter um número que valha a
pena?** Duas coisas decidem. Quais respostas são escolhidas decide se o número é **não enviesado**, uma
estimativa da semana e não de algum canto dela. Quantas decide quão **certo** ele é. As duas seções
seguintes tratam de uma cada.

Há uma terceira razão para amostrar que não tem nada a ver com dinheiro. O juiz lê o que os clientes
digitaram. Cada resposta que ele avalia é mais uma cópia de uma conversa mandada a mais um modelo, e as
regras da aula 2 valem para ela: uma amostra é menos texto em menos lugares.
