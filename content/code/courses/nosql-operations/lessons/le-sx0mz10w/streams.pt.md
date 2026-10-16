---
title: Streams, eventos que esperam uma confirmação
version: 1
---

A lista da seção sobre listas e sets perdeu uma tarefa porque retirá-la a apagou. **Um stream nunca
apaga uma entrada porque alguém a leu.** É um log só de acréscimo, de entradas com um id e alguns
campos cada, e quem lê guarda a sua posição nele em vez de consumi-lo. Um **grupo de consumidores**
reparte as entradas entre workers e lembra quais cada worker recebeu e ainda não confirmou, então uma
tarefa que um worker pegou e nunca terminou continua lá para ser achada.

## Três pedidos, dois workers

A loja acrescenta um evento ao stream `orders` a cada pedido feito. Os workers da equipe de expedição
formam um grupo chamado `shipping` e leem dele:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> XADD orders * order 1001 customer ana total_cents 34990
"1791617490336-0"
127.0.0.1:6379> XADD orders * order 1002 customer bruno total_cents 18900
"1791617490337-0"
127.0.0.1:6379> XADD orders * order 1003 customer carla total_cents 149900
"1791617490337-1"
127.0.0.1:6379> XLEN orders
(integer) 3
127.0.0.1:6379> XGROUP CREATE orders shipping 0
OK
127.0.0.1:6379> XREADGROUP GROUP shipping worker-1 COUNT 2 STREAMS orders >
1) 1) "orders"
   2) 1) 1) "1791617490336-0"
         2) 1) "order"
            2) "1001"
            3) "customer"
            4) "ana"
            5) "total_cents"
            6) "34990"
      2) 1) "1791617490337-0"
         2) 1) "order"
            2) "1002"
            3) "customer"
            4) "bruno"
            5) "total_cents"
            6) "18900"
127.0.0.1:6379> XREADGROUP GROUP shipping worker-2 COUNT 2 STREAMS orders >
1) 1) "orders"
   2) 1) 1) "1791617490337-1"
         2) 1) "order"
            2) "1003"
            3) "customer"
            4) "carla"
            5) "total_cents"
            6) "149900"
```

`XADD orders *` acrescentou uma entrada e deixou o Redis escolher o id: a hora em milissegundos, um
traço e um número de sequência para entradas no mesmo milissegundo, e é por isso que duas delas
terminam em `-0` e `-1`. Os ids só crescem, então o stream fica na ordem em que os eventos chegaram.

`XGROUP CREATE orders shipping 0` criou o grupo no começo do stream, então ele verá as três entradas
que já estão lá; `$` no lugar de `0` o teria começado no fim, só com eventos novos. No `XREADGROUP`, o
`>` quer dizer "entradas que este grupo ainda não entregou a ninguém". O `worker-1` pediu duas e
recebeu os pedidos 1001 e 1002; o `worker-2` pediu duas e recebeu a única que sobrava, a 1003. **Cada
entrada foi para exatamente um worker do grupo.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 310\" role=\"img\" aria-label=\"O stream orders desenhado como três entradas em fila, dos pedidos 1001, 1002 e 1003, a mais antiga à esquerda. Abaixo, dois grupos de consumidores. A posição do grupo shipping fica depois da entrada 1003, porque ele já entregou as três; a sua lista de pendentes guarda 1001 e 1002, entregues ao worker-1 e não confirmadas, enquanto 1003 foi confirmada pelo worker-2. A posição do grupo billing fica antes da primeira entrada, com atraso de três, e nada pendente.\"><defs><marker id=\"l12stream-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12stream-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stream</text><text x=\"70\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><rect x=\"60\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pedido 1001</text><text x=\"145.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…-0</text><rect x=\"250\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pedido 1002</text><text x=\"335.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…-0</text><rect x=\"440\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"525.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pedido 1003</text><text x=\"525.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…-1</text><line x1=\"625\" y1=\"65\" x2=\"680\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12stream-ah-paper-dim)\" stroke-dasharray=\"4 3\"></line><text x=\"652\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">novas entradas</text><rect x=\"20\" y=\"130\" width=\"400\" height=\"150\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grupo</text><text x=\"72\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shipping</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">posição: depois de 1003, atraso 0</text><path d=\"M 420 140 L 616 140 L 616 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12stream-ah-phosphor)\"></path><rect x=\"40\" y=\"190\" width=\"170\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pendentes</text><text x=\"125.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1001 → worker-1</text><text x=\"125.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1002 → worker-1</text><rect x=\"230\" y=\"190\" width=\"170\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confirmada</text><text x=\"315.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1003 ← worker-2</text><text x=\"315.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">saiu da lista de pendentes</text><rect x=\"440\" y=\"160\" width=\"240\" height=\"120\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"450\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grupo</text><text x=\"492\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">billing</text><text x=\"450\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">posição: antes de 1001, atraso 3</text><text x=\"450\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nada pendente</text><path d=\"M 560 280 L 560 298 L 8 298 L 8 65 L 56 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12stream-ah-paper-dim)\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "Um stream, dois grupos. Cada grupo tem a sua posição no stream e a sua lista de entradas entregues e ainda não confirmadas; as entradas continuam no stream de qualquer jeito.", "same": ["stream"]}
```

## Confirmada, pendente e reivindicada

Receber uma entrada não é terminá-la. Um worker que expediu um pedido diz isso com `XACK`, e até lá a
entrada fica na **lista de entradas pendentes** do grupo, com o nome do worker que a tem, há quanto
tempo ela foi entregue e quantas vezes já foi. Aqui o `worker-2` expede o pedido 1003 e o confirma, e
o `worker-1` cai segurando os outros dois:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> XACK orders shipping 1791617490337-1
(integer) 1
127.0.0.1:6379> XPENDING orders shipping
1) (integer) 2
2) "1791617490336-0"
3) "1791617490337-0"
4) 1) 1) "worker-1"
      2) "2"
127.0.0.1:6379> XPENDING orders shipping - + 10
1) 1) "1791617490336-0"
   2) "worker-1"
   3) (integer) 6190
   4) (integer) 1
2) 1) "1791617490337-0"
   2) "worker-1"
   3) (integer) 6190
   4) (integer) 1
127.0.0.1:6379> XAUTOCLAIM orders shipping worker-2 5000 0 COUNT 10
1) "0-0"
2) 1) 1) "1791617490336-0"
      2) 1) "order"
         2) "1001"
         3) "customer"
         4) "ana"
         5) "total_cents"
         6) "34990"
   2) 1) "1791617490337-0"
      2) 1) "order"
         2) "1002"
         3) "customer"
         4) "bruno"
         5) "total_cents"
         6) "18900"
3) (empty array)
127.0.0.1:6379> XPENDING orders shipping - + 10
1) 1) "1791617490336-0"
   2) "worker-2"
   3) (integer) 1
   4) (integer) 2
2) 1) "1791617490337-0"
   2) "worker-2"
   3) (integer) 1
   4) (integer) 2
127.0.0.1:6379> XACK orders shipping 1791617490336-0 1791617490337-0
(integer) 2
127.0.0.1:6379> XLEN orders
(integer) 3
127.0.0.1:6379> XGROUP CREATE orders billing 0
OK
127.0.0.1:6379> XINFO GROUPS orders
1)  1) "name"
    2) "billing"
    3) "consumers"
    4) (integer) 0
    5) "pending"
    6) (integer) 0
    7) "last-delivered-id"
    8) "0-0"
    9) "entries-read"
   10) (nil)
   11) "lag"
   12) (integer) 3
2)  1) "name"
    2) "shipping"
    3) "consumers"
    4) (integer) 2
    5) "pending"
    6) (integer) 0
    7) "last-delivered-id"
    8) "1791617490337-1"
    9) "entries-read"
   10) (integer) 3
   11) "lag"
   12) (integer) 0
```

Leia a sessão em ordem:

1. O `XACK` devolveu `1`: a entrada do pedido 1003 saiu da lista de pendentes.
2. A forma resumida do `XPENDING` informou **2 entradas pendentes, as duas com o `worker-1`**.
3. Seis segundos depois, a forma detalhada mostrou cada uma parada há mais de 6.000 milissegundos,
   entregue uma vez. Nada no Redis vigia esse número: uma entrada cujo worker morreu fica pendente
   para sempre, e nenhum outro worker do grupo a recebe com `>`, porque o grupo já a entregou.
4. `XAUTOCLAIM … worker-2 5000 0` é como ela se destrava: o `worker-2` assumiu toda entrada parada há
   mais de 5.000 ms e as recebeu completas.
5. A lista de pendentes agora diz `worker-2`, o tempo parado recomeçou e o **contador de entregas foi
   para 2**. Um contador que não para de subir é um evento que derruba todo worker que encosta nele.
   Um worker que vê um contador acima de um limite escolhido pela loja move a entrada para um stream
   separado, para uma pessoa olhar, em vez de cair nela de novo.
6. Dois `XACK` depois a lista de pendentes está vazia, e o `XLEN` ainda diz 3. **Confirmar uma entrada
   não a apaga.** Um stream cresce até ser cortado, com `XADD orders MAXLEN ~ 100000 * …` a cada
   acréscimo ou `XTRIM` de tempos em tempos, e um stream que ninguém corta é uma big key que não para
   de crescer.

As duas últimas linhas são o outro motivo de os streams existirem. Um segundo grupo, `billing`, foi
criado no começo do mesmo stream. O `XINFO GROUPS` mostra os dois lado a lado: `shipping` entregou
tudo e o seu atraso (`lag`) é 0; `billing` não entregou nada e o seu atraso é 3. **Cada grupo lê o
stream inteiro no seu próprio ritmo**, então o serviço de cobrança e o de expedição veem todos os
pedidos sem a loja gravar cada evento duas vezes.

## O que um stream não é

Um stream vive na memória de um Redis, como toda chave desta aula. Se as suas entradas sobrevivem a
esse Redis reiniciar é o assunto da aula 13, e se sobrevivem a um failover para uma réplica é o
assunto da aula 15. Nenhuma das respostas é "sempre". Para eventos que o negócio não pode perder,
como um pagamento recebido, um stream no Redis é um jeito rápido de distribuir trabalho, e o registro
oficial continua sendo gravado num lugar feito para guardá-lo.
