---
title: Medir o juiz
version: 1
---

Um juiz é um classificador. Ele lê duas respostas e devolve um rótulo, `a` ou `b`, então **é medido
do jeito que o prompt de triagem foi: contra rótulos que uma pessoa anotou antes.**

```
ana@lab:~/triage$ pl judge cases/pairs.jsonl
j01  human b  judge a
j02  human b  judge b
j03  human a  judge a
j04  human a  judge a
j05  human b  judge b
j06  human a  judge a
j07  human b  judge a
j08  human a  judge a
j09  human b  judge b
j10  human a  judge a
j11  human b  judge a
j12  human a  judge a
j13  human b  judge a
j14  human b  judge b
j15  human a  judge b
j16  human a  judge b

agrees with the human on 10 of 16
Cohen's kappa 0.25
```

Dez de dezesseis concordam com a pessoa, 62,5%. Parece a maioria, e é menos do que parece.

## Concordância além do acaso

Com duas respostas possíveis, um juiz que jogasse uma moeda concordaria com a pessoa mais ou menos
metade das vezes. A concordância bruta não diz quanto dos 62,5% é essa metade. **O kappa de Cohen
mede a concordância além do acaso**, uma estatística que Jacob Cohen publicou em 1960 para exatamente
isto: dois avaliadores classificando os mesmos itens em categorias.

Ele precisa de dois números. A concordância observada é 10 de 16, 0,625. A concordância esperada
pelo acaso vem da frequência com que cada avaliador usa cada resposta:

```
ana@lab:~/triage$ grep -c '"human": "a"' cases/pairs.jsonl
8
```

A pessoa escolheu `a` em 8 pares de 16, e o juiz escolheu `a` em 10. Se os dois respondessem de forma
independente nessas taxas, diriam os dois `a` com probabilidade 8/16 × 10/16 = 0,3125, e os dois `b`
com probabilidade 8/16 × 6/16 = 0,1875. Então concordariam 0,5 das vezes por acaso.

O kappa é quanto a concordância observada se afastou do acaso, como fração de quanto poderia ter se
afastado: (0,625 − 0,5) / (1 − 0,5) = 0,25. **Um kappa de 0 é um juiz que concorda com as pessoas
exatamente com a frequência que o acaso daria, e 1 é concordância perfeita.** A escala mais citada, de Landis e Koch
em 1977, chama de razoável a faixa de 0,21 a 0,40. Este juiz classifica pares um pouco melhor que uma
moeda.

## Calibre antes de confiar

Esse número é o que um juiz precisa mostrar antes que alguém dependa dele: uma amostra da tarefa
real, rotulada por pessoas que não viram a resposta do juiz, e a concordância dele com elas corrigida
pelo acaso. Dezesseis pares é o menor conjunto que deixa a aritmética visível, e o aviso da aula 11
vale inteiro: um par move a concordância em seis pontos. Um juiz que você pretende usar em milhares
de respostas merece algumas centenas de pares rotulados antes.
