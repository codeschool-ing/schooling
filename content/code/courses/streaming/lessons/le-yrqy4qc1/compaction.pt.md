---
title: Compactação, o valor mais recente de cada chave
version: 1
---

**Um tópico compactado guarda, para cada chave, pelo menos a última mensagem escrita com aquela
chave, e pode jogar fora as mais antigas.** A retenção por tempo ou tamanho esquece o passado por
atacado; a compactação esquece só o que foi sobrescrito. É a tabela da lição 2 feita em disco: um
stream de mudanças, dobrado até o valor mais recente por chave, e ainda legível como log.

Isso combina com um tópico cujas mensagens são **estado, e não eventos**: o estoque atual de cada
livro, o endereço atual de cada cliente. Ninguém precisa do estoque como estava na terça, mas um
leitor novo precisa do estoque atual de cada livro, e um tópico compactado lhe dá isso lendo a partir
do offset 0. Não combina com `sales`, em que cada mensagem é um fato separado e as antigas não são
substituídas pelas novas.

## Vendo funcionar

O cleaner, a thread do broker que compacta, é cauteloso por padrão: deixa um log em paz até metade
dele ser valores sobrescritos, e nunca toca no segmento ativo. Por isso este tópico fecha segmentos
depois de cinco segundos e é limpo assim que 1% dele está sujo, o que um tópico de verdade não faria.
Crie-o, e mande o estoque de três livros, mudando, com o `keys.py` do começo desta lição:

@@fence@@

O último par, `bk-03=-`, é uma mensagem com a chave `bk-03` e valor nenhum, que a próxima seção
explica. Sete mensagens, offsets 0 a 6, todas no segmento ativo.

Espere mais de cinco segundos, para que esse segmento fique velho o bastante para fechar, e mande mais
uma mensagem. O segmento é fechado quando a próxima mensagem chega, então esta começa um segmento
ativo novo:

@@fence@@

Dê alguns segundos ao cleaner; quando não tem nada para fazer ele olha de novo a cada quinze
(`log.cleaner.backoff.ms`). Depois leia o tópico desde o começo:

@@fence@@

Sobraram quatro mensagens, e elas são o último valor de cada chave: `bk-02` é 6, `bk-01` é 2, `bk-03`
tem o seu tombstone, impresso como `null`, e `bk-04` é 9, ainda sozinha no segmento ativo. `bk-01=4`,
`bk-01=3`, `bk-02=7` e `bk-03=2` sumiram, **e as sobreviventes mantiveram os seus offsets**: o tópico
agora começa no offset 4, e os offsets 0 a 3 faltam para sempre.

@@fig:l3-compaction@@

## Tombstones

Uma mensagem com chave e sem valor é um **tombstone**: ela diz *esta chave foi apagada*. A
compactação guarda o próprio tombstone por `delete.retention.ms`, um dia por padrão, para que um
leitor no meio do log veja a remoção em vez de perdê-la, e depois remove o tombstone também. Daí em
diante a chave simplesmente não existe, como se nunca tivesse sido escrita.

Duas coisas decorrem disso que o pessoal erra. **A compactação não é imediata**: até o cleaner rodar,
um leitor desde o offset 0 vê todos os valores antigos, então um leitor de um tópico compactado ainda
precisa fazer o fold, e ficar com o último valor de cada chave, como o `balance.py` fez. E **a
compactação mantém os offsets**: as mensagens que sobram ficam com os offsets em que foram escritas,
então uma partição compactada tem buracos nos offsets, e um leitor não pode supor que o offset *n* + 1
vem depois do *n*. A lição 14 reencontra tópicos compactados, em que as linhas de um banco chegam como
mensagens com a chave primária como chave e uma linha apagada vira um tombstone.
