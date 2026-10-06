---
title: Por que avaliar uma amostra
version: 1
---

Uma regra não custa nada, então a aula 8 rodou-a em toda resposta. Um juiz é uma chamada de modelo por
resposta por critério, com a resposta, a pergunta e todas as fontes no prompt. Rodá-lo em tudo é
possível, e esta aula faz isso uma vez, para ter a verdade contra a qual comparar as amostras:

```
ana@lab:~/obs$ python grade_sample.py uniform --share 1.0
uniform: 1221 of 1221 replies graded for relevance
  2026.09.4   604/789  pass  76.6%   95% between 73.5% and 79.4%
  2026.10.1   269/432  pass  62.3%   95% between 57.6% and 66.7%
```

Na semana inteira, **o judge-1 aprovou 76,6% das respostas em relevância na versão antiga, e 62,3% na
nova**. É o número que uma equipe quer, e os intervalos ao lado são estreitos porque quase oitocentas e
quatrocentas respostas entraram neles.

Foram precisas 1.221 chamadas ao juiz para obtê-lo. A última seção desta aula põe preço nelas; a versão
curta é que avaliar toda resposta num critério custa cerca de um quarto do que custou servi-la, e cada
critério acrescenta outro quarto. Uma equipe que avalia tudo em três critérios quase dobra a conta do
seu assistente.

Então a pergunta passa a ser: **quão poucas respostas dá para avaliar e ainda ter um número que valha a
pena?** Duas coisas decidem. Quais respostas são escolhidas decide se o número é **não enviesado**, uma
estimativa da semana e não de algum canto dela. Quantas decide quão **certo** ele é. As duas seções
seguintes tratam de uma cada.

Há uma terceira razão para amostrar que não tem nada a ver com dinheiro. O juiz lê o que os clientes
digitaram. Cada resposta que ele avalia é mais uma cópia de uma conversa mandada a mais um modelo, e as
regras da aula 2 valem para ela: uma amostra é menos texto em menos lugares.
