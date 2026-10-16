---
title: Kafka: tópicos, partições, offsets e grupos
version: 1
---

O Kafka foi escrito no LinkedIn por volta de 2010 para mover dados de atividade entre sistemas numa
escala que uma fila não aguentava, publicado como código aberto em 2011, e entregue à Apache Software Foundation. O modelo dele tem quatro
palavras, e cada uma é uma consequência do log.

| palavra | o que é |
| --- | --- |
| **tópico** | um log com nome, como `orders` |
| **partição** | um dos pedaços em que um tópico é dividido; cada partição é um log próprio, num broker de cada vez |
| **offset** | a posição de uma mensagem dentro da partição, começando em 0 |
| **grupo de consumidores** | um conjunto de consumidores que dividem as partições de um tópico, com um offset guardado por partição para o grupo |

## Partições são a unidade de tudo

Um tópico com uma partição pode ser lido por um consumidor de um grupo de cada vez, porque uma partição é
lida em ordem por um leitor. **Para ler mais rápido, um tópico precisa de mais partições**, e os
consumidores de um grupo as dividem: três partições, dois consumidores, um deles fica com duas. Um quarto
consumidor num grupo de três partições não tem o que fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um tópico chamado orders dividido em três partições. As mensagens aparecem com as suas chaves: toda mensagem com chave ana vai para a partição 1, na ordem em que foi escrita; bruno e carla dividem a partição 2. A partição 0 está vazia. Dois consumidores de um grupo dividem as partições entre si.\"><defs><marker id=\"l6-partitions-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">tópico orders</text><rect x=\"30\" y=\"50\" width=\"460\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partição 0</text><rect x=\"30\" y=\"112\" width=\"460\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partição 1</text><rect x=\"150\" y=\"120\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ana: pedido 1</text><rect x=\"260\" y=\"120\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ana: pedido 3</text><rect x=\"30\" y=\"174\" width=\"460\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partição 2</text><rect x=\"150\" y=\"182\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">bruno: pedido 2</text><rect x=\"260\" y=\"182\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">carla: pedido 4</text><rect x=\"370\" y=\"182\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">bruno: pedido 5</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">consumidor 1</text><rect x=\"560\" y=\"160\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">consumidor 2</text><path d=\"M492 74 L558 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-partitions-ah-phosphor)\"></path><path d=\"M492 136 L558 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-partitions-ah-phosphor)\"></path><path d=\"M492 198 L558 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-partitions-ah-phosphor)\"></path><text x=\"360\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma chave, uma partição, em ordem</text></svg>", "caption": "A chave decide a partição, então toda mensagem de um cliente cai numa partição, em ordem. Entre partições não há ordem nenhuma."}
```

**Para que partição uma mensagem vai é decidido pela chave dela.** O produtor calcula um hash da chave e o
resultado escolhe a partição, então toda mensagem com a chave `ana` cai na mesma partição, na ordem em
que foi escrita. Mensagens sem chave são espalhadas pelas partições. A promessa de ordem do Kafka é
exatamente esta e nada mais: **ordem dentro de uma partição, nenhuma entre partições**. A aula 7 desmonta
essa promessa, porque "os eventos de um pedido chegam em ordem" depende inteiramente de escolher a chave
certa.

## Grupos leem de forma independente

Cada grupo de consumidores guarda o seu offset para cada partição, no próprio Kafka. O grupo `email` e o
grupo `warehouse` leem o mesmo tópico sem saber um do outro, cada um na sua posição, e nenhum tira nada do
outro. É o equivalente, no log, da fila por serviço do RabbitMQ, e tem uma propriedade que uma fila não
tem: um grupo criado no mês que vem pode começar da mensagem mais antiga ainda retida e ler a história
inteira.

## O que o Kafka não faz

O Kafka não roteia por conteúdo: não há ligações nem padrões, só tópicos, e um consumidor que quer parte
das mensagens de um tópico lê todas e pula o resto. Ele não apaga uma mensagem porque ela foi lida. E não
acompanha a entrega de cada mensagem: acompanha offsets, então "esta mensagem falhou, tente de novo
depois" é algo que o consumidor precisa arranjar, em geral com um tópico separado para retentativas,
onde o RabbitMQ simplesmente entregaria de novo.
