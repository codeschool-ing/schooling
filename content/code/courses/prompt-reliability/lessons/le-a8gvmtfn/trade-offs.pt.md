---
title: Os custos de cada economia
version: 1
---

Uma economia que muda o prompt é uma mudança como qualquer outra. Ela passa pela barreira da aula
14, e **a pergunta não é só se ficou mais barato, mas quanto custou em respostas**. Os exemplos que a
seção anterior tirou são um bom caso, porque os números sozinhos não decidem.

## O que o prompt mais barato quebrou

```
ana@lab:~/triage$ pl compare runs/v3.jsonl runs/v4.jsonl
runs/v3.jsonl            passes 36/40
runs/v4.jsonl            passes 34/40
fixed 1, broken 3, still passing 33, still failing 3
broken: t08 t19 t22
sign test on the 4 that changed: p = 0.625
ana@lab:~/triage$ pl check runs/v4.jsonl --failures | tail -n 6
t08    json      not JSON
t14    urgency   normal, expected low
t19    json      not JSON
t22    json      not JSON
t24    urgency   low, expected normal
t28    urgency   normal, expected low
```

Trinta e quatro aprovações contra trinta e seis, uma mensagem corrigida e três quebradas, e um teste
do sinal de 0,625. Esse valor p não diz que os prompts são igualmente bons. **Ausência de evidência
de diferença não é evidência de ausência de diferença**: com quatro mensagens mudadas, o teste do
sinal não chegaria abaixo de 0,125 nem se as quatro tivessem ido para o mesmo lado. Quarenta
mensagens são poucas para distinguir esses dois prompts pela contagem.

Então leia o que quebrou. `t08`, `t19` e `t22` não são JSON: sem exemplo, o substituto volta aos
hábitos de uma frase na frente ou de um bloco de código em volta da resposta, que a aula 1 mostrou.
Uma urgência errada ainda encaminha a mensagem, devagar; **uma resposta que não se analisa não
encaminha nada**. Três em quarenta são 7,5%, e se essa taxa se mantivesse num milhão de chamadas
seriam umas 75.000 mensagens que um programa não conseguiria ler, cada uma pedindo uma nova tentativa,
que custa outra chamada, ou uma pessoa. A economia é real e a conta que vem com ela também, e só
quem sabe quanto custa uma mensagem perdida consegue pôr uma contra a outra. O que a bancada pode
fazer é garantir que essa pessoa esteja olhando para as duas.

## p95, não a média

O prompt mais barato também é mais rápido:

```
ana@lab:~/triage$ pl latency runs/v4.jsonl
calls 40
p50 1170 ms   p95 1324 ms   max 1473 ms
output tokens: mean 38.0, max 50
```

Uma mediana de 1170 ms contra 1230, um p95 de 1324 contra 1341. Repare que o `pl latency` não
imprime média nenhuma. Uma média mistura as chamadas rápidas com as lentas num número que nenhuma
chamada teve. **Quem espera sente as chamadas lentas**, e uma em cada vinte espera pelo menos o p95. A
média pode cair enquanto o p95 sobe, e aí o cliente médio fica melhor no papel enquanto os azarados
esperam mais.

A cauda pesa mais quando as chamadas se combinam. Um pipeline que faz três chamadas em sequência
espera a soma, e um que as faz lado a lado espera a mais lenta das três. *The Tail at Scale* (Dean e
Barroso, 2013) fez esse argumento para grandes serviços web: quando um pedido se espalha por muitos
servidores, a resposta lenta e rara de cada um vira uma resposta comum para o todo. No substituto a
variação para em 150 ms, então a cauda é curta e arrumada. A cauda de um serviço real é definida pelo
tráfego dele, não por um número de curso, e só medir o seu vai dizer onde ela está.

## Uma ordem para cortar

1. **Tire o que não rende nada.** O log da aula 14 achou uma instrução que custava 15 tokens por
   chamada e não mexia na nota de nenhum dos dois conjuntos em que rodou. Essa economia não pede
   troca nenhuma, só uma verificação de que nada quebrou.
2. **Encurte a saída**, que é a alavanca maior tanto no tempo quanto no dinheiro, e confira a nota.
3. **Depois troque respostas por dinheiro**, um prompt menor ou um modelo mais barato, com as
   mensagens quebradas nomeadas e alguém decidindo, por escrito, que elas valem a pena. O registro de
   decisão da aula 15 é o lugar dessa frase.
