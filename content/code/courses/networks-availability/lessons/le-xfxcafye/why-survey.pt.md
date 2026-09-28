---
title: Por que fazer site survey, e os três tipos
version: 1
---

O jeito comum de posicionar pontos de acesso é uma regra de área: um a cada tantos metros quadrados, no
meio de cada sala, no alcance que o datasheet promete. **Ela falha porque um prédio não é espaço livre.**
Um poço de elevador de concreto pode custar mais sinal que trinta metros de escritório aberto, e uma
janela de vidro com película, que parece transparente, pode bloquear mais que uma parede de tijolo. A
planta baixa não mostra nenhum dos dois. Um **site survey** troca a regra por medições, feitas antes de o
projeto ser fechado e de novo depois que os APs estão no ar.

Como nas aulas 6 a 9, **este laboratório não tem rádio**, então não há survey para mostrar. O que esta
aula pode fazer é calcular o que um survey mediria, com as mesmas fórmulas que o software de survey usa,
e dizer com clareza quais números são regras práticas.

## Primeiro os requisitos

Um survey mede contra alguma coisa, e essa coisa é escrita antes de alguém percorrer um andar:

- quais aplicações, e portanto quais alvos: e-mail tolera um sinal mais fraco que uma chamada de voz;
- quantos aparelhos ficam ativos ao mesmo tempo, e onde (a conta de capacidade da aula 9);
- **qual é o cliente mais fraco**, porque é ele que decide o projeto: um leitor portátil com antena
  pequena ouve menos, e é menos ouvido, que o notebook com que o survey foi feito;
- quais bandas, e se haverá clientes de 6 GHz.

## Três tipos, e dois ajudantes

| | como funciona | o que mostra | o limite dele |
|---|---|---|---|
| **preditivo** | um software modela os APs sobre a planta, com uma perda para cada parede | um projeto e um orçamento antes de comprar qualquer coisa | só é tão bom quanto os materiais de parede que alguém cadastrou |
| **passivo** | percorrer o andar com um adaptador de survey que escuta todo beacon, de todo AP, seu e dos vizinhos | o sinal, o ruído e os canais que estão de fato no ar | não diz nada sobre o que um usuário conectado recebe |
| **ativo** | percorrer o andar conectado à rede, medindo vazão, perda, atraso e roamings | o que um usuário recebe de fato | exige que a rede já exista |

**O preditivo é o mais barato e o menos certo.** É como a maioria dos projetos começa, e o resultado só é
tão bom quanto os materiais de parede. Uma parede com o rótulo errado, gesso acartonado onde o prédio tem
concreto, muda a borda de uma célula em metros. Passivo e ativo são medições, e precisam de um prédio e,
no caso do ativo, de uma rede.

Dois ajudantes cobrem as lacunas. **Um AP no tripé** (AP on a stick) é um ponto de acesso de verdade
num tripé, posto onde o projeto o coloca, com um survey feito em volta dele para achar onde a célula
termina de fato. É o jeito de resolver uma discussão sobre uma área difícil, um depósito com prateleiras
de metal ou uma ala de hospital, antes de pagar o cabeamento. **Um analisador de espectro** enxerga energia
que nem é Wi-Fi, os micro-ondas e as babás eletrônicas da aula 7, que um adaptador Wi-Fi só percebe como um
canal misteriosamente ocupado.

A sequência de costume é todos eles em ordem: **prever, conferir as paredes duvidosas no local,
instalar, e medir de novo**. O último passo é o mais pulado, e a última seção desta aula diz por que ele
não deveria ser.
