---
title: Enxugando um prompt
version: 2
---

Cortar um prompt parece mais arriscado do que acrescentar, porque cada linha foi posta ali por
alguém por algum motivo. **Três regras deixam o corte seguro**, e a terceira é a que precisa de uma
medição.

- Uma instrução por decisão. O tamanho do resumo é uma decisão, e as linhas 4 e 16 do
  `v2-long.txt` a tomam cada uma. Decida para que serve o resumo e diga isso.
- Diga uma vez. Uma linha repetida acrescenta tokens e mais nada, e as maiúsculas põem uma regra
  acima das vizinhas, quer alguém tenha querido isso ou não.
- Apague o que o modelo já faz de qualquer jeito, e saiba disso por uma contagem e não por um
  palpite.

Aplicado ao `v2-long.txt`, a persona sai, já que ser prestativo e simpático não decide nada num
objeto JSON. O resumo vira uma frase, porque a equipe percorre a fila. A regra repetida sai, e a
regra contra campos extras também: a lista de campos já nomeia três, e na aula 1 toda resposta ao
`v2-json.txt` que era JSON válido tinha exatamente esses três. O que sobra é o `v2-json.txt`, o
prompt de onde a aula 1 partiu.

## Medindo que nada se perdeu

Um corte é uma mudança, então é medido como uma. As duas execuções estão no disco desde a primeira
seção:

```
ana@lab:~/triage$ pl check runs/long.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     33     7
urgency      21    19
all          21    19
ana@lab:~/triage$ pl check runs/v2.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      21    19
all          21    19
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl
runs/long.jsonl          passes 21/40
runs/v2.jsonl            passes 21/40
fixed 0, broken 0
sign test on the 0 that changed: p = 1.000
```

Vinte e um contra vinte e um, e **nenhuma mensagem mudou de resultado**: as mesmas vinte e uma
passam com os dois prompts. Os 97 tokens a mais por chamada do prompt longo não compraram nada que
uma verificação consiga ver. As verificações falham em lugares diferentes, porém. Com o prompt
longo toda resposta era JSON válido e sete falharam na categoria; com o curto, uma não era JSON
válido e nove falharam na categoria. O `--answers` compara a categoria que cada resposta deu, lida
sem o embrulho:

```
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl --answers
40 cases, same answer 37, different answer 3
  t36    billing -> account
  t38    delivery -> None
  t39    account -> delivery
```

Três respostas mudaram, e nenhuma mudou um veredicto. O `t38` é a resposta da aula 1 cujo resumo
quebrou num apóstrofo, então não tem resposta para comparar; `t36` e `t39` estavam erradas com um
prompt e erradas de outro jeito com o outro. **O corte manteve todas as aprovações e economizou 97
tokens por chamada.**

## O que o conjunto de teste não consegue dizer

O `v2-json.txt` também deixou cair a linha 13, a regra contra pôr o nome do cliente no resumo. Nada
acima diz se isso foi seguro, porque **nenhuma mensagem do `cases/dev.jsonl` contém um nome**. Uma
regra que protege contra algo que o conjunto de teste nunca mostra não pode ser julgada por esse
conjunto de teste, em nenhuma direção: a contagem seria a mesma com a regra ou sem ela. O mesmo vale
para a regra contra inventar coisas, que nenhuma verificação mede.

Então a terceira regra do corte vem com uma condição. Apague o que o modelo já faz de qualquer
jeito **quando um caso do conjunto de teste o teria pegado deixando de fazer**. Onde não há esse
caso, mantenha a linha ou escreva o caso primeiro. A aula 11 trata de montar conjuntos de teste que
cubram o que as regras do prompt existem para impedir.
