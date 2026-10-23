---
title: Como as revisões dão errado
version: 1
---

**A maioria das revisões que falham falha por motivos sociais, e não técnicos**: as pessoas erradas,
o momento errado, o propósito errado. Cinco padrões são comuns o bastante para ganhar nome.

## O carimbo

A revisão acontece depois que o design foi construído, ou depois que o contrato foi assinado, e todo
mundo na sala sabe que nada vai mudar. Ela produz *aprovado* e mais nada. **O remédio é o momento**:
revisar antes do compromisso, como disse a primeira seção desta aula, ou dizer com honestidade que é
uma retrospectiva e tratá-la como tal.

## O portão

A revisão é um obstáculo que todo time precisa transpor, conduzido por pessoas que não respondem pelo
resultado. Os times aprendem a apresentar designs que passam em vez de designs que funcionam, e a
evitar a revisão quando conseguem. O conselho de arquitetura da aula 8 corre o risco de virar isso;
**o remédio é que as respostas dos revisores sejam previsíveis a partir de princípios escritos**, como
aquela aula disse, e que a revisão encontre problemas para o time, e não sobre ele.

## A torre de marfim

Os revisores não viram o sistema rodar e o julgam contra uma imagem que têm na cabeça. Os achados
deles são sobre padrões, e não sobre cenários, e o time não consegue agir sobre eles. A aula 17 de
`architecture-role` deu nome a esse antipadrão para arquitetos em geral. **O remédio são os
cenários**: todo achado ligado a um, para que um achado que ninguém consegue ligar a um cenário seja
reconhecido como preferência.

## Bikeshedding

A revisão passa uma hora no nome de um endpoint e cinco minutos no failover do banco de dados,
porque todo mundo tem opinião sobre nomes e poucos têm sobre failover. O termo vem do exemplo de C.
Northcote Parkinson de um comitê que aprova uma usina rapidamente e discute longamente o bicicletário.
**O remédio é a árvore de utilidade**: o tempo vai primeiro para os cenários (H, H), por pauta.

## A voz que falta

A revisão inclui arquitetos e engenheiros e ninguém de operações, suporte ou do negócio, então os
cenários são os cenários dos arquitetos. O passo 7 do ATAM existe por causa disso. Na Carcará, o
cenário mais importante da revisão do São João veio de uma atendente de rodoviária. **O remédio é
convidar as pessoas que convivem com o sistema**, nem que seja por uma hora, nem que seja para uma
revisão leve.

## Uma revisão da revisão

Depois de cada revisão, Tainá faz duas perguntas ao time: *alguma coisa que encontramos mudou o que
vocês fizeram?* e *havia algo que devíamos ter olhado e não olhamos?* As respostas decidem se a
próxima revisão vai ser mais longa, mais curta ou diferente, que é a regra da aula 11 aplicada mais
uma vez: **uma prática que não é conferida vira um ritual**.
