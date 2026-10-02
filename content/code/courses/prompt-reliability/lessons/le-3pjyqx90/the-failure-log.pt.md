---
title: O registro de falhas
version: 1
---

Um registro de decisão explica uma escolha. Um registro de falhas explica um acidente: cada vez que o
prompt é pego fazendo algo errado, uma entrada dizendo o que aconteceu e o que agora impede que
aconteça de novo. A prática é mais antiga que os prompts. O livro *Site Reliability Engineering* do
Google (2016) dedica um capítulo, *Postmortem Culture: Learning from Failure*, a escrevê-los sem
culpados, e **a ideia vale do mesmo jeito: a entrada é sobre o sistema, não sobre quem fez a
edição**.

## Os números da entrada

A regressão da aula 14 é um exemplo pronto. Os números vêm do `pl log`, e a evidência vem da execução
da versão quebrada que a seção anterior já fez:

```
ana@lab:~/triage$ pl log
commit   date        all tokens  subject
8ec39c2  2026-08-03  0/40   2366  First triage prompt
90a013e  2026-08-04 24/40   4734  Ask for JSON, name the fields and list the labels
f361c0a  2026-08-05 36/40  11036  Add three examples of the answer
9683448  2026-08-07 36/40  11636  Ask for the JSON object and nothing else
931c548  2026-08-10 36/40  13356  Put the message in tags and say it is data
c8470c9  2026-08-11 36/40  13356  Escape the message so it cannot close its own tags
31a6a59  2026-08-14  0/40   9739  Make the examples easier to read
03e1151  2026-08-17 36/40  13356  Put the examples back in JSON
ana@lab:~/triage$ pl check runs/plain.jsonl
check      pass  fail
json          0    40
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
ana@lab:~/triage$ pl show runs/plain.jsonl t04
│ account, high: wants the express delivery charge back
stop: end, tokens in 233, out 10
```

## A entrada

```localised
F-0001  Nenhuma resposta saía mais em JSON          2026-08-14 a 2026-08-17

Mudança      31a6a59 "Make the examples easier to read"
Mensagem     t04 "I can't log in. The password reset email never comes."
             e todas as outras: 0/40 em dev, 36/40 antes
Resposta     account, high: wants the express delivery charge back
Pego por     json, a primeira verificação: 0 de 40 passaram. Nenhuma
             execução registrada antes da correção; a barreira da aula 14
             teria rodado no mesmo dia
Correção     03e1151 devolveu os exemplos em JSON (decisão 0001)
Teste novo   nenhum: dev já reprova isso na primeira verificação. No
             lugar: a barreira, que roda dev a cada mudança
Custo        9739 tokens em dev contra 13356; mais barato, e inútil
```

Cinco linhas carregam o peso.

- *Mensagem* e *Resposta* são a evidência, citada em vez de descrita. Uma resposta real diz
  mais a um leitor que uma frase sobre respostas, e `t04` mostra duas coisas de uma vez: a forma
  copiada do exemplo e o resumo do primeiro exemplo colado numa mensagem sobre senha.
- *Pego por* nomeia a verificação, ou a verificação que teria pegado. Quando a resposta é *nenhuma
  teria pegado*, essa linha é a mais importante do registro, porque é um buraco nos testes.
- *Correção* nomeia um commit, para que a entrada e a história apontem uma para a outra.
- *Teste novo* é o que mantém a correção de pé.

## A linha que mais importa

Esta falha é incomum num ponto: o conjunto de teste já a pegava, e o que faltava era alguém rodá-lo.
A maioria das falhas é do outro tipo. Um cliente escreve algo que ninguém imaginou, a resposta sai
errada, e alguém percebe na fila de atendimento. **A correção não termina enquanto essa mensagem,
limpa de nomes e números, não for um caso num conjunto de teste**, com a resposta que uma pessoa
decidiu ser a certa. Sem isso a barreira não tem em que falhar, e a mesma falha pode voltar com a
próxima mudança e passar em todas as verificações.

Leia uma dúzia de entradas juntas e elas mostram padrões que nenhuma mostra sozinha. Se três delas
terminassem em *puxada para o rótulo do primeiro exemplo*, como `t37` terminaria, o registro estaria
dizendo algo sobre como o prompt é construído, não sobre três mensagens.
