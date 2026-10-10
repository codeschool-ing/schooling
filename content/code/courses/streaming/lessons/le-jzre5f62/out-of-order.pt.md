---
title: Fora de ordem, e por quanto
version: 1
---

**Um stream chega na ordem de chegada. A ordem dos eventos é algo que você reconstrói, se precisar,
e só até certo ponto.** A suposição comum vai no sentido contrário: que os registros chegam na ordem
em que as coisas aconteceram, tirando um ou outro tropeço. Medido, o tropeço acaba sendo uma parte
considerável dos dados, com um formato que importa mais do que o tamanho.

Fora de ordem tem um sentido preciso aqui. Uma venda está fora de ordem quando, no momento em que
chega, uma venda que aconteceu **depois** já foi vista. O quanto ela está fora de ordem é a distância
entre o seu próprio tempo do evento e o maior tempo do evento visto antes dela. Vale guardar esse
segundo número, porque a lição 11 constrói o watermark a partir dele.

## Medindo

O tópico `late` tem uma partição, então os registros voltam exatamente na ordem em que chegaram.
Três ferramentas encadeadas fazem a medição. O consumidor de console imprime as vendas, o `jq`
transforma cada `at` em segundos desde 1970, e o `awk` guarda o maior tempo do evento que já viu
(`seen`) e, para cada venda, o quanto ela está atrás dele:

@@fence@@

Dois detalhes deixam o passo do `jq` honesto. Todo `at` destas vendas tem o mesmo deslocamento,
`-03:00`, então os primeiros dezenove caracteres se comparam corretamente como se fossem UTC, e o
`fromdate` só lê UTC. Duas vendas com deslocamentos diferentes precisariam ter o deslocamento
aplicado, que é um passo que um pipeline de verdade não pode pular.

**68 de 360 vendas chegaram fora de ordem: quase uma em cada cinco.** Não são as 38 de Natal. Trinta
delas estavam de alguns segundos a um minuto e meio atrás: vendas comuns de todas as lojas que por
acaso levaram 40 ou 95 segundos no caminho enquanto uma venda posterior de outra loja levou um.
Ninguém chamaria essas de atrasadas. É o que uma rede faz.

## Duas populações

Ordenadas, as 68 distâncias caem em dois grupos, com muito pouco entre eles:

| atrás por | vendas | o que são |
|---|---|---|
| até 92 segundos | 30 | entregas lentas, de todas as lojas |
| de 14 minutos a 3 horas e 23 minutos | 38 | as vendas retidas de Natal, todas chegando às 14:00 |

Os dois grupos pedem tratamentos diferentes, e boa parte do projeto de um processador de stream é
decidir qual tratamento cada um recebe. Uma espera de dois minutos poria o primeiro grupo de volta
em ordem, ao custo de todo resultado chegar dois minutos atrasado. Nenhuma espera que alguém
aceitasse poria o segundo grupo em ordem: esperar por Natal é segurar todos os resultados do dia até
quatro horas depois do fato, que é o batch noturno de novo com passos a mais.

**Então "quão fora de ordem está o meu stream?" não tem uma resposta só.** Tem uma distribuição, e a
pergunta que importa é onde traçar uma linha nela: as vendas antes da linha são tratadas como se
estivessem em ordem, e as que passam dela são tratadas como atrasadas. A lição 11 traça essa linha e
a chama de limite de um watermark; a seção dela sobre escolher o limite mede essa distribuição a
partir dos dados, como você acabou de fazer.

## O que uma partição esconde

Tudo isso foi medido numa partição só, onde a ordem de chegada é uma coisa única e legível. Um tópico
com três partições tem três ordens de chegada, uma em cada, e nenhuma ordem entre elas: a lição 3
mostra que um consumidor que lê várias partições as intercala do jeito que as buscas voltarem. Fora
de ordem entre partições é, portanto, o estado normal, não um defeito, e é por isso que um
processador que se importa com o tempo do evento mantém a noção de "até onde o tempo chegou" **por
partição**, ponto ao qual a lição 11 volta.
