---
title: Quanto tempo uma lápide precisa viver
version: 1
---

Uma lápide não pode viver para sempre: uma tabela que apaga tanto quanto grava cresceria sem fim, e
toda leitura passaria por marcadores de linhas apagadas anos atrás. Também não pode ser descartada
assim que é gravada. **O trabalho inteiro dela é chegar a toda réplica que ainda guarda o valor antigo,
e algumas dessas réplicas podem estar fora quando o delete acontece.** `gc_grace_seconds` é a
configuração da tabela que diz por quanto tempo o Cassandra mantém uma lápide antes de a compactação
poder jogá-la fora, e o padrão, que o `DESCRIBE TABLE` mostrou antes nesta aula, é `864000`: dez dias.

## O que acontece no fim do período de carência

A compactação junta SSTables e grava só o que ainda é necessário. Uma lápide mais nova que
`gc_grace_seconds` é copiada para a SSTable nova, junto com o fato de que ela encobre os dados por
baixo. **Uma lápide mais velha que `gc_grace_seconds` pode ser expurgada**: quando a compactação a junta
com os dados que ela apagou, as duas coisas são descartadas, e a SSTable nova não guarda nenhuma. A
partir daí o nó não tem registro de que a linha existiu, nem de que foi apagada.

Num nó que viu o delete, tudo bem. É um problema para uma réplica que não viu.

## Por que o período de carência tem a ver com repair

Imagine as três réplicas de uma partição. Um delete em `QUORUM` chega a duas enquanto a terceira está
fora. As duas gravam lápides; a terceira guarda a linha antiga. Três coisas podem levar o delete até a
terceira réplica quando ela voltar, e a aula 19 trata das três:

- **hinted handoff**: o coordenador guardou o delete para o nó ausente e o reenvia quando o nó volta,
  mas só se o nó ficou fora menos que `max_hint_window`, três horas por padrão;
- **read repair**: uma leitura que por acaso pergunta àquela réplica e a outra percebe que diferem e
  corrige a mais velha;
- **repair**: o comando `nodetool repair`, que compara todas as réplicas de cada intervalo e copia o
  que falta.

Os dois primeiros são esforço possível. Hints expiram; uma linha que ninguém lê nunca passa por read
repair. **O repair é o único com garantia de visitar toda partição**, e ele só consegue levar uma lápide
que ainda existe. Daí a regra:

> Toda réplica de toda tabela precisa passar por repair ao menos uma vez a cada `gc_grace_seconds`.

Rode repair em todo nó dentro de dez dias e um delete perdido sempre chega à réplica atrasada
enquanto a lápide ainda está lá para ser copiada. Deixe um nó passar disso, ou ficar fora mais que
isso, e a lápide pode ser expurgada nos nós que a viram enquanto a cópia velha ainda espera em outro
lugar. A próxima seção faz isso acontecer.

## Mudando o número

`gc_grace_seconds` é por tabela, definido com `WITH gc_grace_seconds = …` no `CREATE TABLE` ou no
`ALTER TABLE`. Encurtá-lo faz as lápides irem embora antes, o que ajuda uma tabela que apaga muito, e
**aperta o prazo do repair exatamente na mesma medida**. Equipes o baixam para alguns dias só quando
seus repairs terminam, com segurança, com mais frequência que isso. Pôr `0` é razoável numa tabela da
qual nunca se apaga nem se atualiza no lugar, e perigoso em qualquer outra.

Duas configurações relacionadas existem e vale reconhecê-las pelo nome. Uma linha gravada com tempo de
vida (`USING TTL`) vira lápide quando expira, e essa lápide segue o mesmo período de carência. E num
nó que ficou fora **mais que `gc_grace_seconds`**, o conselho operacional padrão é não religá-lo como
está, mas apagá-lo e deixá-lo entrar de novo como um nó novo, porque os dados dele podem guardar linhas
cujos deletes todos os outros já esqueceram.
