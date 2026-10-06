---
title: Uma rubrica com as respostas escritas nela
version: 1
---

As discordâncias da versão 1 não eram erros a corrigir; eram perguntas que a rubrica não tinha
respondido. A Ana e o Bruno passaram por elas juntos e escreveram as respostas na versão 2:

```
ana@lab:~/obs$ cat data/rubrics/relevance-v2.md
# Relevance, version 2

Read the customer's question and the assistant's reply. Relevance asks only
whether the reply is about what was asked. Whether it is true is faithfulness,
and whether it is the right answer is correctness: grade neither here.

- pass: the reply gives what the question asks for, even among other
  sentences.
  e.g. "Above what order value is standard delivery free?" answered with a
  sentence on express delivery and then "standard ... free on orders over 40".
- pass: the reply is the agreed refusal, "I could not find that in our
  documents." It answers the question by saying there is no answer here.
  Whether it should have refused is correctness.
- fail: the reply is about the question's subject and does not give what was
  asked for.
  e.g. "How much is express delivery?" answered with "Express delivery is not
  free at any order value."
- fail: the reply answers a different question, even one that shares the
  question's words.
  e.g. "Above what order value is standard delivery free?" answered with
  "Express delivery is not free at any order value."

When the reply gives a condition from which the answer follows, and the customer
would have to work it out, write that down beside the label: it is the case this
version does not settle.
```

Três coisas mudaram, e cada uma é uma técnica que vale reaproveitar.

- **O critério diz o que ele não é.** Fidelidade e correção são nomeadas e postas de lado, para que
  quem avalia e nota uma resposta errada não a reprove por relevância. Isso decide a recusa: uma recusa
  é sobre a pergunta, e se devia ter sido uma recusa é correção, que a aula 8 mediu contra os fatos.
- **Toda regra tem um exemplo.** Uma **âncora** é uma resposta real com o seu veredicto, e resolve numa
  linha o que um parágrafo de definição deixaria em aberto. As âncoras aqui são as próprias respostas
  em que as pessoas discordaram.
- **A rubrica diz o que ela não resolve.** O último parágrafo nomeia o caso para o qual a equipe não
  conseguiu combinar uma regra, e pede a quem avalia que o marque em vez de adivinhar.

As mesmas sessenta respostas, rotuladas de novo pela versão 2:

```
ana@lab:~/obs$ python agree.py relevance-v2/ana relevance-v2/bruno
60 replies; rows relevance-v2/ana, columns relevance-v2/bruno
          pass  fail
  pass      51     2
  fail       0     7
agreement 96.7%   by chance 76.8%   kappa 0.86
apart on 2: 0 refusals, 2 other replies
  e05 2026.09.4  pass / fail  An e-book can be refunded within 14 days of purchase if yo
  e05 2026.10.1  pass / fail  An e-book can be refunded within 14 days of purchase if yo
```

**Kappa de 0,86, e duas discordâncias restantes**, as duas na mesma resposta: e05, o e-book baixado
ontem, em cada versão. É o caso que o último parágrafo da rubrica descreve. A Ana aprovou, porque a
resposta decorre do que ela diz; o Bruno reprovou, porque um cliente não deveria ter de deduzi-la. Eles
conversaram e combinaram aprovar, e esse veredicto é o terceiro conjunto de rótulos,
`relevance-v2/agreed`. Resolver por conversa os casos que restam, e guardar o resultado como um
conjunto próprio, chama-se **adjudicação**.

## Do que uma referência precisa

Os rótulos combinados agora podem medir um juiz, porque se apoiam numa rubrica que duas pessoas leem
do mesmo jeito. Três propriedades tornaram isso possível, e elas são a lista de conferência de qualquer
conjunto de rótulos de referência:

1. **Cada rótulo nomeia a resposta por um id estável** e a rubrica pela sua versão.
2. **A concordância entre as pessoas foi medida**, e é alta o bastante para os rótulos significarem
   alguma coisa.
3. **As discordâncias que restaram foram resolvidas e guardadas** como um conjunto próprio, para que os
   rótulos individuais continuem sendo o que cada pessoa disse.

Duas pessoas em sessenta respostas é a menor versão disso que ainda mede alguma coisa. Uma equipe que
rotula com regularidade dá a uma pessoa nova algumas dezenas de respostas já combinadas, confere o kappa
dela contra a referência antes de confiar nos seus rótulos, e repete uma pequena sobreposição entre
avaliadores a cada rodada, porque as pessoas mudam de critério à medida que a rubrica fica familiar.
