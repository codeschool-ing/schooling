---
title: O que quebra um cache
version: 1
---

**Qualquer mudança no prefixo quebra todos os blocos a partir do que mudou.** No substituto é assim
que os blocos são identificados: a chave de cada bloco é um hash dele e de todos os blocos anteriores,
então um bloco só bate se o prompt inteiro até o fim dele bater. Caches reais também casam um
prefixo, e a consequência é a mesma.

O `v17-message-first` era o caso extremo, um primeiro bloco diferente em cada chamada. Edições comuns
fazem a mesma coisa de forma mais discreta:

- Uma palavra mudada no guia torna novo todo bloco daquela palavra em diante. As chamadas seguintes
  gravam tudo de novo, e só então começam a ler.
- Um exemplo novo inserido perto do topo desloca todos os tokens depois dele, então todos os
  blocos seguintes mudam mesmo que o texto deles não tenha mudado.
- Uma data, o nome de um cliente ou o número de um chamado no começo, *"Today is 14 August.
  Customer: Maria Souza."*, varia a cada chamada exatamente como a mensagem, e custa ao cache tudo o
  que vem depois.

Então deixe no fim o que varia, e mude a parte fixa de propósito e raramente, sabendo que cada mudança
é paga uma vez em gravações.

## O cache não pode mudar as respostas

Um cache deveria mudar custo e tempo e nada mais. **Verifique isso em vez de supor**, do mesmo jeito
que qualquer mudança é verificada:

```
ana@lab:~/triage$ pl compare runs/plain.jsonl runs/static.jsonl
runs/plain.jsonl         passes 32/40
runs/static.jsonl        passes 32/40
fixed 0, broken 0, still passing 32, still failing 8
sign test on the 0 that changed: p = 1.000
```

Nada corrigido, nada quebrado: o mesmo template com o cache ligado deu o mesmo resultado em cada
mensagem. No substituto a resposta é calculada antes de o cache ser consultado, então isso estava
garantido; com um provedor real, é a verificação que avisaria se não estivesse.

## Reordenar não é uma configuração do cache

Levar a mensagem para a frente é diferente. Isso muda o texto que o modelo lê, então é um prompt novo,
e as respostas podem mudar por motivos que nada têm a ver com o cache:

```
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl
runs/static.jsonl        passes 32/40
runs/first.jsonl         passes 34/40
fixed 5, broken 3, still passing 29, still failing 3
broken: t18 t26 t40
sign test on the 8 that changed: p = 0.727
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl --answers
40 cases, same answer 40, different answer 0
ana@lab:~/triage$ pl check runs/static.jsonl
check      pass  fail
json         35     5
fields       35     5
labels       35     5
category     35     5
urgency      32     8
all          32     8
ana@lab:~/triage$ pl check runs/first.jsonl
check      pass  fail
json         37     3
fields       37     3
labels       37     3
category     37     3
urgency      34     6
all          34     6
```

Trinta e quatro contra trinta e duas, cinco corrigidas e três quebradas, e um teste do sinal de 0,727
que não consegue distinguir os dois. O `--answers` compara a categoria, e as quarenta concordam. As
verificações põem toda a diferença em `json`: cinco respostas falharam nela com o guia primeiro e três
com a mensagem primeiro, e as falhas de urgência depois dela são três em cada. Aqui está uma das três
que quebraram:

```
ana@lab:~/triage$ pl show runs/static.jsonl t18
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "Two pages are missing from chapter 3."
│ }
stop: end, tokens in 250, out 32
ana@lab:~/triage$ pl show runs/first.jsonl t18
│ ```json
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "Two pages are missing from chapter 3."
│ }
│ ```
stop: end, tokens in 250, out 39
```

A mesma resposta, embrulhada num bloco de código. No substituto, os hábitos de formatação da aula 1
caem em mensagens escolhidas por um hash do prompt inteiro, então **reordenar um prompt os leva para
outras mensagens** na mesma taxa. Um modelo real reage à ordem por motivos próprios, e é por isso que
uma reordenação feita para o cache passa pela barreira da aula 14 como qualquer outra mudança no
texto.
