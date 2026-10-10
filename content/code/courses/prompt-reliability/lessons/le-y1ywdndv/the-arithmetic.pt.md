---
title: A aritmética
version: 2
---

O cache não muda quantos tokens são lidos, só quanto custa lê-los. Na sua própria máquina o custo é
tempo, e *O que um cache reaproveita*, duas seções antes, dá os dois números que importam: 5009
milissegundos para ler o prompt com nada no cache, e uns 750 com o guia no cache e só a mensagem
nova.

## O que o cache poupou

Por chamada, o prompt com o guia primeiro poupou uns quatro segundos e um quarto de leitura em
cinco. A escrita, uns três segundos por chamada, não mudou nada. Então a chamada inteira foi de uns
oito segundos para uns quatro, e as execuções de quarenta chamadas da última seção dizem o mesmo do
jeito delas:

| | guia primeiro | mensagem primeiro |
|---|---|---|
| tokens numa chamada | 285,1 | 285,1 |
| chamada mediana | 3,8 s | 7,6 s |
| quarenta chamadas | 152,7 s | 286,0 s |

**Metade de cada chamada com a mensagem primeiro foi lendo um guia que o cache já tinha**, numa
posição em que ele não podia ser achado. Quanto maior a parte fixa de um prompt, maior essa fatia: um
prompt com algumas páginas de texto de referência e uma mensagem de uma linha cabe quase inteiro no
cache, ou quase nada.

## E o dinheiro

Um provedor hospedado cobra por token, não por segundo, e os provedores que têm cache cobram um token
lido do cache bem abaixo de um token de entrada comum. Alguns também cobram a mais para escrever um
prefixo no cache da primeira vez. A documentação deles dá os números, e o `cost.py` da aula 16 recebe
um preço por token; para contar um cache você daria a ele um preço para os tokens em cache e outro
para o resto, e a resposta do provedor diz quantos de cada uma chamada usou.

Onde escrever custa a mais, a conta tem uma armadilha: **um prefixo usado uma vez só custa mais com
cache do que sem**. O prompt com a mensagem primeiro pagaria para escrever o prefixo de cada chamada
e nunca leria nenhum de volta. A regra que faz um cache compensar é a que a última seção mediu, um
começo fixo longo e um fim variável curto, e a verificação é a mesma de qualquer outra coisa que custa
dinheiro: rode, leia o que o provedor relata, e compare.
