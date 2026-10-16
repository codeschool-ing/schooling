---
title: O que fica difícil entre shards
version: 1
---

Dentro de um shard, tudo continua sendo um banco: transações, joins, restrições de unicidade, um
`count(*)` que está certo. **Entre shards, cada uma dessas coisas vira trabalho do programa**, e
algumas ficam impossíveis de fazer barato. Estas são as que mordem primeiro.

## Perguntas sobre tudo

Uma consulta sem chave de shard é mandada para todo shard, e as respostas são juntadas. Isso se
chama **espalhar e recolher** (*scatter-gather*), e o roteador da última seção fez isso para os três
shows mais vendidos. Os custos:

- **Ela é tão lenta quanto o shard mais lento.** O programa espera todas as respostas, então um
  shard no meio de um backup define o tempo da consulta inteira. A aula 11 volta a isso como
  latência de cauda.
- **Ela não escala.** Com dez shards, toda consulta dessas faz dez consultas de trabalho. Acrescentar
  shards deixa as consultas roteadas mais baratas e estas mais caras.
- **Nem toda resposta se junta.** Um top três se junta: o top três de cada shard contém toda linha
  que poderia estar no top três geral. Uma soma ou uma contagem se juntam somando. Uma **média não
  se junta**: a média de duas médias está errada a menos que os dois shards tenham o mesmo número de
  linhas, então cada shard precisa devolver uma soma e uma contagem. Uma **mediana ou um percentil
  não se juntam de jeito nenhum** a partir de medianas por shard; precisam dos valores, ou de um
  resumo feito para ser juntado, como os histogramas da aula 7.

## Transações

A venda de um ingresso toca um shard. Uma transferência de ingresso de um comprador para outro, se
os compradores fossem a chave de shard, tocaria dois, e **não existe transação comum entre dois
servidores**. Ou as duas mudanças acontecem ou nenhuma, e dois bancos independentes não conseguem
prometer isso sozinhos. As opções são um commit em duas fases, que o PostgreSQL suporta com
`PREPARE TRANSACTION` e que bloqueia os dois shards se o coordenador morrer na hora errada; ou uma
saga, uma sequência de transações locais com um passo de compensação para cada uma, que a aula 14
de `architecture` descreve. As duas são caras o bastante para que **a chave de shard seja escolhida
de modo que as operações comuns fiquem dentro de um shard**.

## Unicidade e ids

`bigserial` dá a cada linha o próximo número de uma sequência, e cada shard tem a sua própria
sequência, então **dois shards distribuem os mesmos ids**. Restrições de unicidade têm o mesmo
problema: cada shard verifica só as próprias linhas, então um nome de usuário que precisa ser único
no sistema todo tem de ser verificado por algo que veja todos os shards, ou ser a própria chave de
shard. A resposta de costume para ids é parar de contar e gerá-los onde a linha nasce: um UUID, ou
um esquema que põe a hora e o número do shard dentro de um número de 64 bits.

## Joins

Um join entre duas tabelas com sharding pela mesma chave, por essa chave, fica dentro de cada shard.
Um join entre tabelas com sharding diferente, ou com uma que não tem sharding, não fica. Tabelas
pequenas de que todo shard precisa, como a lista de casas de show, costumam ser **copiadas para
todo shard** em vez de divididas, para que os joins com elas fiquem locais.
