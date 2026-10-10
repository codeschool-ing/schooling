---
title: Os custos de cada economia
version: 2
---

Uma economia que muda o prompt é uma mudança como qualquer outra. Ela passa pela trava da aula 14,
e **um prompt mais barato tem de dizer o que custou em respostas além do que economiza**. Os exemplos
que a última seção tirou são o caso a olhar.

## O que o prompt mais barato quebrou

```
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/v3.jsonl
runs/v4.jsonl            passes 20/40
runs/v3.jsonl            passes 28/40
fixed 9, broken 1
broken: t01
sign test on the 10 that changed: p = 0.021
```

Vinte aprovações contra vinte e oito. Ir do `v4` de volta para o `v3` consertou nove mensagens e
quebrou uma, então tirar os exemplos quebrou nove e consertou uma, e um teste do sinal de 0.021 diz
que uma divisão tão desequilibrada é improvável por acaso. Isto é o que o prompt mais barato faz com
as verificações:

```
ana@lab:~/triage$ pl check runs/v4.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     32     8
urgency      20    20
all          20    20
```

O formato se manteve: uma resposta em quarenta não é JSON válido, como com o `v3`. **O que os
exemplos estavam pagando é o julgamento**: as categorias caíram de 35 para 32 e as urgências de 28
para 20. Um terço do custo por oito mensagens a menos, no saldo, em quarenta é uma troca que alguém
tem de fazer sabendo. Se uma urgência errada custa mais que 40.837,5 centavos por milhão de chamadas
é uma pergunta sobre a equipe de suporte, não sobre o prompt, e só quem sabe quanto custa uma
mensagem mal classificada consegue responder. O que o harness pode fazer é garantir que essa pessoa
esteja olhando para os dois números.

## p95, não a média

O prompt mais barato também é mais rápido:

```
ana@lab:~/triage$ python3 stats.py runs/v4.jsonl
runs/v4.jsonl, 40 calls
  tokens in    mean  121.2   total   4846
  tokens out   mean   28.8   total   1153   max 38
  seconds      p50   3.6   p95   4.5   total  145.9
```

Uma mediana de 3,6 segundos contra 4,1, um p95 de 4,5 contra 5,0. Repare que o `stats.py` não imprime
média nenhuma dos segundos. Uma média mistura as chamadas rápidas com as lentas num número que
nenhuma chamada teve. **Quem espera sente as chamadas lentas**, e uma em vinte delas espera pelo menos
o p95. A média pode cair enquanto o p95 sobe, e aí o cliente médio fica melhor no papel enquanto os
azarados esperam mais.

A cauda importa mais quando chamadas se combinam. Um pipeline que faz três chamadas em fila espera a
soma, e um que as faz lado a lado espera a mais lenta das três. *The Tail at Scale* (Dean e Barroso,
2013) fez esse argumento para grandes serviços web: quando uma requisição se espalha por muitos
servidores, a resposta lenta rara de cada um vira uma comum para o todo. Numa máquina só, com um
modelo carregado, a cauda deste laboratório é curta; a cauda de um serviço compartilhado é definida
pelo tráfego dele, e só medindo o seu você vai saber onde ela está.

## Uma ordem para cortar

1. **Tire o que não rende nada.** O log da aula 14 achou commits que custaram tokens e não mexeram
   nota nenhuma no conjunto em que rodaram. Antes de cortar um, descubra para que ele servia; se nada
   o mede, essa economia só precisa de uma verificação de que nada quebrou.
2. **Encurte a saída**, que é a alavanca maior tanto em tempo quanto em dinheiro, e confira a nota.
3. **Depois troque respostas por dinheiro**, um prompt menor ou um modelo mais barato, com as
   mensagens quebradas nomeadas e alguém decidindo, por escrito, que elas valem a pena. O registro de
   decisão da aula 15 é o lugar dessa frase.
