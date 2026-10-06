---
title: Uma pequena parte do tráfego real primeiro
version: 1
---

Um release **canário** manda uma pequena parte do tráfego da produção para a versão nova, compara com
o resto e aumenta a parte só enquanto a comparação continua limpa. O nome vem dos pássaros que os
mineiros levavam para debaixo da terra: um pássaro passando mal avisava antes de o ar fazer mal a
mais alguém.

O laboratório não precisa de nada novo para isso. O mesmo roteador, os mesmos dois lados: os pesos só
deixam de ser tudo ou nada. A green ainda roda o 1.6.0, o release com o erro. Desta vez ela recebe
uma requisição em dez:

```
ana@laptop:~/shipquote$ sed -i 's/"blue": 100, "green": 0/"blue": 90, "green": 10/' ~/envs/routes.json && cat ~/envs/routes.json
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 90, "green": 10}}
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 1000
backend    requests errors    rate
blue            898      0    0.0%
green           102      2    2.0%
```

De mil requisições, o blue atendeu 898 e a green 102. O blue não teve erros; a green teve 2. O bug
que alcançou todos os clientes na troca do blue-green aqui alcançou mais ou menos um cliente em dez,
e só um em vinte desses: **duas requisições falhas em vez de setenta e sete**. Esse estrago menor é o
que o canário vende.

## Passos

Um canário raramente pula de 10% para tudo. Ele avança em passos, por exemplo 5%, 25%, 50% e 100%, e
em cada passo espera o bastante para julgar antes de seguir. Duas coisas mudam a cada passo:

- a parte de clientes que encontraria um bug cresce, então um erro custa mais quanto mais tarde for
  achado;
- a quantidade de evidência cresce também, então um bug raro fica visível.

Os primeiros passos são pequenos porque ainda não se sabe nada. Os passos seguintes são maiores
porque um release que sobreviveu aos anteriores ganhou alguma confiança.

## O que o canário precisa e o blue-green não

- **Um jeito de separar os dois lados nas medições.** Aqui o roteador escreve `X-Served-By` em toda
  resposta e o `load.py` conta por ele. Na produção isso é um rótulo em toda métrica, dizendo que
  versão a produziu.
- **Tráfego.** Um canário a 10% de um serviço quieto é um canário que não vê nada durante uma hora.
  As duas próximas seções tratam do que medir, e de quanto basta.
