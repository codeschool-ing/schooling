---
title: Onde o Kafka Streams guarda o estado
version: 1
---

As contagens vivem dentro da aplicação, e a aplicação é um processo que pode morrer. **O Kafka
Streams guarda cada contagem duas vezes: num store local na máquina, pela velocidade, e num tópico
do Kafka, pela segurança.** Uma cópia que começa numa máquina sem store local o reconstrói lendo
esse tópico. Os tópicos são criados pela biblioteca, com o nome da aplicação, e são a primeira coisa
a olhar:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --list
__consumer_offsets
sales
sales-per-book
sales-per-shop
sales-per-shop-KSTREAM-AGGREGATE-STATE-STORE-0000000001-changelog
sales-per-shop-KSTREAM-AGGREGATE-STATE-STORE-0000000006-changelog
sales-per-shop-KSTREAM-AGGREGATE-STATE-STORE-0000000006-repartition
```

Dois deles são os tópicos de saída que o programa nomeou. Os outros três ninguém nomeou:

| tópico | para que serve |
|---|---|
| `…-STATE-STORE-0000000001-changelog` | cada mudança da contagem por loja, para o store poder ser reconstruído |
| `…-STATE-STORE-0000000006-changelog` | o mesmo para a contagem por livro |
| `…-STATE-STORE-0000000006-repartition` | as vendas de novo, com o livro como chave em vez da loja |

Os tópicos de **changelog** são a cópia de segurança. Eles são compactados, como a lição 3
descreveu: o Kafka guarda o último registro por chave, então um changelog guarda uma contagem por
loja por mais tempo que a aplicação rode.

O tópico de **repartição** é o preço do `groupBy`. Uma contagem por livro precisa de todas as vendas
de `bk-03` num mesmo lugar, e as vendas chegam com a loja como chave, espalhadas por três
partições. Então a biblioteca escreve cada venda de volta no Kafka com o livro como chave, o que
manda todas as vendas de um livro para uma mesma partição do tópico novo (lição 3), e a contagem lê
de lá. **Escolher uma chave nova custa uma escrita e uma leitura a mais de cada registro**, e por
isso o `groupByKey` é preferido sempre que a chave já está certa. Os números nos nomes são as
posições dos passos na topologia, e é por eles que uma mudança na topologia pode renomear um store e
deixar o tópico antigo órfão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A topologia do SalesPerShop, em duas partes. A parte 0 lê o tópico sales, com a loja como chave. A contagem por loja não precisa de chave nova, então é contada na hora num store local, cujas mudanças vão para um tópico de changelog e para o tópico de saída sales-per-shop. Para a contagem por livro, a parte 0 escreve cada venda de novo num tópico de repartição, com o livro como chave. A parte 1 lê esse tópico e conta por livro num segundo store, com o seu próprio changelog, e escreve em sales-per-book. Cada parte roda como três tarefas, uma por partição.\" data-fig=\"l13-topology\"><defs><marker id=\"l13-topology-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-topology-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-topology-ah-2105\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales</text><text x=\"65.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">chave: loja</text><rect x=\"150\" y=\"20\" width=\"250\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parte 0: tarefas 0_0, 0_1, 0_2</text><rect x=\"170\" y=\"50\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">groupByKey, count</text><rect x=\"170\" y=\"106\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">groupBy livro</text><path d=\"M 112 82 L 166 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><path d=\"M 112 92 L 166 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><rect x=\"300\" y=\"50\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">store: por loja</text><path d=\"M 292 67 L 297 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"50\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales-per-shop</text><path d=\"M 392 67 L 446 67\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-2105)\"></path><rect x=\"590\" y=\"10\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…-changelog</text><path d=\"M 370 50 Q 420 20 586 27\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-83)\"></path><rect x=\"175\" y=\"190\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…-repartition</text><text x=\"250.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">chave: livro</text><path d=\"M 230 142 L 240 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><rect x=\"400\" y=\"180\" width=\"250\" height=\"80\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"525\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parte 1: tarefas 1_0, 1_1, 1_2</text><rect x=\"415\" y=\"192\" width=\"70\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">count</text><rect x=\"495\" y=\"192\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">store: por livro</text><path d=\"M 327 207 L 411 207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><rect x=\"590\" y=\"120\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales-per-book</text><path d=\"M 587 200 L 640 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-2105)\"></path><path d=\"M 587 215 L 662 215 L 662 250\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"668\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">changelog</text></svg>", "caption": "Uma chave nova custa uma volta pelo Kafka: o tópico de repartição é onde as vendas são reorganizadas por livro.", "same": ["groupByKey, count", "count", "changelog"]}
```

A cópia local fica em disco, no diretório que o programa nomeou, com um subdiretório por tarefa:

```
ubuntu@stream:~/work$ ls ~/streams-state/a/sales-per-shop
0_0
0_1
0_2
1_0
1_1
1_2
kafka-streams-process-metadata
```

`0_0` a `0_2` são as tarefas da primeira parte da topologia, que lê `sales`, e `1_0` a `1_2` as da
segunda, que lê o tópico de repartição. Os stores lá dentro são RocksDB, um banco embutido cujo jar
também veio com o Kafka.

## Uma segunda cópia

**Escalar uma aplicação Kafka Streams é iniciar mais uma cópia dela.** Inicie a cópia `a` de novo
no segundo shell, e depois a cópia `b` num terceiro shell, aberto do mesmo jeito:

```
ubuntu@stream:~/work$ java -cp "$HOME/kafka/libs/*:." SalesPerShop b
state: CREATED -> REBALANCING
state: REBALANCING -> RUNNING
tasks here: [0_1, 1_0, 1_2]
state: RUNNING -> PENDING_SHUTDOWN
state: PENDING_SHUTDOWN -> NOT_RUNNING
```

As duas cópias são membros de um grupo de consumidores, `sales-per-shop`, o id da aplicação, e o
grupo deu as seis tarefas a dois membros:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group sales-per-shop --members

GROUP           CONSUMER-ID                                                                                                      HOST            CLIENT-ID                                                                   #PARTITIONS     
sales-per-shop  sales-per-shop-dabbbf81-17e6-434a-9c35-4fad4428eacd-StreamThread-1-consumer-89e5e53c-7058-41b1-94be-043b5b58b876 /127.0.0.1      sales-per-shop-dabbbf81-17e6-434a-9c35-4fad4428eacd-StreamThread-1-consumer 3               
sales-per-shop  sales-per-shop-a7b61109-432f-48c5-9455-da5f975f2de0-StreamThread-1-consumer-37731bed-72e3-471a-9493-dccc05f6d825 /127.0.0.1      sales-per-shop-a7b61109-432f-48c5-9455-da5f975f2de0-StreamThread-1-consumer 3               
```

Cada membro tem três partições, e as linhas do próprio programa dizem quais tarefas:

```
ubuntu@stream:~/work$ java -cp "$HOME/kafka/libs/*:." SalesPerShop a
state: CREATED -> REBALANCING
state: REBALANCING -> RUNNING
tasks here: [0_0, 0_2, 1_1]
state: RUNNING -> PENDING_SHUTDOWN
state: PENDING_SHUTDOWN -> NOT_RUNNING
```

A cópia `a` ficou com `0_0`, `0_2` e `1_1`, e a cópia `b` com as outras três; a sua divisão pode
ser outra, porque quem decide é o grupo. Nada foi copiado entre elas à mão: uma tarefa que muda para
outra cópia pega a sua contagem do tópico de changelog. Pare as duas cópias com Ctrl+C quando
terminar. Enquanto a cópia `a` rodava sozinha, ela era um processo Java de cerca de 170 MB ao lado do
nó Kafka:

```
ubuntu@stream:~/work$ ps -o pid,rss,comm -u ubuntu --sort=-rss | head -4
  PID   RSS COMMAND
31511 478416 java
30894 429560 java
23783 410488 java
```
