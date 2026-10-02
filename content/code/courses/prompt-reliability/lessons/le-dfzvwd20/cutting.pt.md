---
title: Enxugando um prompt
version: 1
---

Cortar um prompt parece mais arriscado do que acrescentar, porque cada linha foi posta ali por
alguém, por algum motivo. **Três regras tornam o corte seguro**, e a terceira é a que precisa de
uma medição.

- **Uma instrução por decisão.** O tamanho do resumo é uma decisão, e as linhas 4 e 16 do
  `v2-long.txt` a tomam cada uma por conta própria. Decida para que serve o resumo e diga isso.
- **Diga uma vez só.** Uma linha repetida acrescenta tokens e mais nada, e as maiúsculas põem uma
  regra acima das vizinhas, quer alguém tenha querido isso ou não.
- **Apague o que o modelo já faz sozinho**, e saiba disso por uma contagem, não por um palpite.

Aplicado ao `v2-long.txt`, a persona sai, já que ser prestativo e simpático não decide nada num
objeto JSON. O resumo vira uma frase, porque a equipe percorre a fila de olho. A regra repetida
sai, e a regra contra campos extras também: a lista de campos já nomeia três, e na aula 1 toda
resposta ao `v2-json.txt` que foi analisada tinha exatamente esses três. O que sobra é o prompt de
onde a aula 1 partiu:

```
ana@lab:~/triage$ cat prompts/v2-json.txt
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Message: {{message}}
```

## Medindo que nada se perdeu

Um corte é uma mudança, então é medido como uma. As duas execuções estão no disco desde a primeira
seção:

```
ana@lab:~/triage$ pl check runs/long.jsonl
check      pass  fail
json         21    19
fields       21    19
labels       21    19
category     21    19
urgency      19    21
all          19    21
ana@lab:~/triage$ pl check runs/v2.jsonl
check      pass  fail
json         27    13
fields       27    13
labels       27    13
category     27    13
urgency      24    16
all          24    16
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl
runs/long.jsonl          passes 19/40
runs/v2.jsonl            passes 24/40
fixed 12, broken 7, still passing 12, still failing 9
broken: t08 t09 t15 t16 t20 t27 t39
sign test on the 19 that changed: p = 0.359
ana@lab:~/triage$ pl compare runs/long.jsonl runs/v2.jsonl --answers
40 cases, same answer 40, different answer 0
```

O prompt curto passa em 24 de 40, contra 19. **Isso não é uma vitória, e o teste do sinal diz
isso**: dezenove mensagens mudaram, doze para um lado e sete para o outro, e uma moeda honesta
divide dezenove lançamentos de forma ao menos tão desigual cerca de uma vez em três (p = 0.359). O
que o `--answers` acrescenta é o conteúdo. Ele compara a categoria que cada resposta deu, lida sem o
embrulho, e as quarenta são iguais. O corte manteve todas as respostas e economizou 98 tokens por
chamada.

As mudanças que aconteceram são os hábitos de formatação da aula 1, caindo em mensagens diferentes:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t08
│ Here is the JSON you asked for:
│
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "They ordered the hardback and you sent the paperback."
│ }
stop: end, tokens in 82, out 42
ana@lab:~/triage$ pl show runs/long.jsonl t08
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "They ordered the hardback and you sent the paperback. They'd like to exchange it."
│ }
stop: end, tokens in 180, out 42
```

O prompt curto pôs uma frase antes de `t08` e o longo não. No substituto, quais respostas pegam um
hábito depende do texto exato do prompt, então qualquer edição embaralha essas respostas enquanto a
taxa fica mais ou menos a mesma. **Esse embaralhamento é a cara do ruído neste laboratório**, e é
por isso que a contagem subiu sem que o prompt melhorasse. A aula 3 trata do embrulho em si.

## O que o conjunto de teste não diz

O `v2-json.txt` também largou a linha 13, a regra contra pôr o nome do cliente no resumo. Nada do
que está acima diz se isso foi seguro, porque **nenhuma mensagem de `cases/dev.jsonl` contém um
nome**. Uma regra que protege contra algo que o conjunto de teste nunca mostra não pode ser julgada
por esse conjunto, em nenhum sentido: a contagem teria sido a mesma com a regra ou sem ela. O mesmo
vale para a regra contra inventar coisas, que nenhuma verificação mede.

Então a terceira regra do corte vem com uma condição. Apague o que o modelo já faz sozinho **quando
um caso do conjunto de teste teria flagrado o modelo deixando de fazer**. Onde não houver esse caso,
mantenha a linha ou escreva o caso antes. A aula 11 trata de montar conjuntos de teste que cubram
aquilo que as regras do prompt existem para evitar.
