---
title: Um consumidor, e o laço em que ele vive
version: 1
---

**Um consumidor pede mensagens; o Kafka nunca as empurra.** O programa chama `poll` num laço, e cada
chamada devolve a próxima mensagem de uma das partições que ele recebeu, ou nada se nenhuma chegou
dentro do timeout. Todo o resto que um consumidor faz, entrar num grupo, receber partições e registrar
até onde leu, acontece dentro dessas chamadas, então um consumidor que para de chamar `poll` deixa de
ser consumidor, como a lição 16 mostra.

Todo consumidor deste curso pertence a um **consumer group**, nomeado pelo `group.id`. O grupo é para
quem o Kafka guarda a posição de leitura, e entre quem ele divide as partições, que é a próxima seção.
Salve isto como `~/work/consumer.py`:

@@PTEX@@

Rode-o no seu segundo shell. Ele lê as dez vendas da seção anterior e espera por mais; pare-o com
Ctrl+C quando tiver lido:

@@fence@@

A primeira linha é a atribuição: sozinho no grupo `stock`, o `c1` recebeu as três partições. Depois,
as dez vendas, numa ordem que vale a pena ler. **Dentro de cada partição elas estão em ordem de
offset**: as duas vendas do Recife da partição 2, depois as quatro da partição 1, depois as quatro da
partição 0. Entre partições não há ordem nenhuma; o cliente por acaso buscou a partição 2 primeiro, e
a venda `oli-000001` de Olinda, a primeira produzida, saiu em oitavo. A promessa da lição 2 era ordem
por chave, e foi exatamente isso que chegou.

O Ctrl+C encerrou o laço, e o `close` devolveu as partições, que é a linha `revoked`. Ele também
registrou até onde o `c1` tinha lido. Pergunte ao Kafka o que ele sabe do grupo:

@@fence@@

O grupo não tem membros agora, e o Kafka ainda se lembra dele. Para cada partição, **`CURRENT-OFFSET` é
o offset que o grupo vai ler em seguida**, `LOG-END-OFFSET` é o offset que a próxima mensagem produzida
vai receber, e **`LAG`** é a diferença: mensagens escritas e ainda não lidas por este grupo. Os três
são 0, porque o `c1` leu tudo. O grupo continua em 4, 4 e 2, então o `c1` iniciado de novo não teria
nada para ler até chegarem mais vendas.

## Onde um grupo novo começa

Um grupo que nunca fez commit de um offset não tem de onde continuar, e o **`auto.offset.reset`**
decide: `earliest` começa no início de cada partição, e `latest`, o padrão, começa no fim, então o
grupo só vê mensagens produzidas depois que entrou. O console consumer da lição 1 começava no fim pelo
mesmo motivo. O `consumer.py` configura `earliest`, então um nome de grupo novo lê tudo o que existe,
e as próximas seções contam com isso.
