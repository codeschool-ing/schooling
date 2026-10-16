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

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic stock --partitions 1 --config cleanup.policy=compact --config segment.ms=5000 --config min.cleanable.dirty.ratio=0.01
Created topic stock.
ubuntu@stream:~/work$ python keys.py stock bk-01=4 bk-02=7 bk-03=2 bk-01=3 bk-02=6 bk-01=2 bk-03=-
bk-01        partition 0  offset 0
bk-02        partition 0  offset 1
bk-03        partition 0  offset 2
bk-01        partition 0  offset 3
bk-02        partition 0  offset 4
bk-01        partition 0  offset 5
bk-03        partition 0  offset 6
```

O último par, `bk-03=-`, é uma mensagem com a chave `bk-03` e valor nenhum, que a próxima seção
explica. Sete mensagens, offsets 0 a 6, todas no segmento ativo.

Espere mais de cinco segundos, para que esse segmento fique velho o bastante para fechar, e mande mais
uma mensagem. O segmento é fechado quando a próxima mensagem chega, então esta começa um segmento
ativo novo:

```
ubuntu@stream:~/work$ python keys.py stock bk-04=9
bk-04        partition 0  offset 7
```

Dê alguns segundos ao cleaner; quando não tem nada para fazer ele olha de novo a cada quinze
(`log.cleaner.backoff.ms`). Depois leia o tópico desde o começo:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic stock --from-beginning --max-messages 4 --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Offset:4	bk-02	6
Offset:5	bk-01	2
Offset:6	bk-03	null
Offset:7	bk-04	9
Processed a total of 4 messages
```

Sobraram quatro mensagens, e elas são o último valor de cada chave: `bk-02` é 6, `bk-01` é 2, `bk-03`
tem o seu tombstone, impresso como `null`, e `bk-04` é 9, ainda sozinha no segmento ativo. `bk-01=4`,
`bk-01=3`, `bk-02=7` e `bk-03=2` sumiram, **e as sobreviventes mantiveram os seus offsets**: o tópico
agora começa no offset 4, e os offsets 0 a 3 faltam para sempre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O tópico stock antes e depois da compactação. Antes: oito mensagens nos offsets 0 a 7, bk-01 = 4, bk-02 = 7, bk-03 = 2, bk-01 = 3, bk-02 = 6, bk-01 = 2, um tombstone para bk-03, e bk-04 = 9 no segmento ativo. Depois: só restam os offsets 4, 5, 6 e 7, o último valor de cada chave e o tombstone, com os offsets originais, então os offsets 0 a 3 viram um buraco.\" data-fig=\"l3-compaction\"><text x=\"20\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">antes</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">depois</text><text x=\"56\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">offset</text><rect x=\"90\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"125\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=4</text><rect x=\"90\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"125\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><rect x=\"168\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"203\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"203\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-02=7</text><rect x=\"168\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"203\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><rect x=\"246\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"281\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"281\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-03=2</text><rect x=\"246\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"281\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><rect x=\"324\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"359\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=3</text><rect x=\"324\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"359\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><rect x=\"402\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"437\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-02=6</text><rect x=\"402\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"437\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-02=6</text><rect x=\"480\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"515\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=2</text><rect x=\"480\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"515\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=2</text><rect x=\"558\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"593\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"593\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">bk-03=null</text><rect x=\"558\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"593\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"593\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">bk-03=null</text><rect x=\"636\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"671\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"671\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-04=9</text><rect x=\"636\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"671\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"671\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-04=9</text><line x1=\"632\" y1=\"30\" x2=\"632\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"359.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segmento fechado</text><text x=\"671\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segmento ativo</text><text x=\"593\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">tombstone</text></svg>", "caption": "A compactação guarda a última mensagem de cada chave, no offset em que foi escrita; o segmento ativo fica intocado.", "same": ["tombstone", "offset"]}
```

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
