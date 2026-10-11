---
title: Quanto pesa uma venda em disco
version: 1
---

**O tamanho de uma mensagem não é o tamanho do JSON dela.** Um broker guarda mensagens em lotes, e
cada registro carrega a chave, um offset, um timestamp e alguns bytes de enquadramento; cada lote
carrega um cabeçalho próprio; e ao lado do arquivo de log ficam dois arquivos de índice. Chutar a
partir do conteúdo acerta a ordem de grandeza e erra a conta, então meça: escreva um número conhecido
de vendas num tópico vazio e divida o tamanho que o Kafka informa pela contagem.

## Cem mil vendas

Um tópico de uma partição, para que o tópico inteiro seja um diretório, e cem mil vendas dos caixas
da lição 1, mandadas tão rápido quanto o Kafka aceita:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic bytes --partitions 1
Created topic bytes.
ubuntu@stream:~/work$ python tills.py --topic bytes --count 100000 --rate 0
sent 100000 sales to bytes, the last one at 13:39:21
```

Uma venda, como o consumidor a imprime, contada em bytes pelo `wc -c` (a contagem inclui a quebra de
linha no fim):

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic bytes --from-beginning --max-messages 1 2>/dev/null | wc -c
123
```

## O que o broker diz

`kafka-log-dirs.sh --describe` pergunta a cada broker quanto disco cada partição usa, e responde
numa linha de JSON depois de duas linhas sobre o que está fazendo:

```
ubuntu@stream:~/work$ kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list bytes
Querying brokers for log directories information
Received log directory information from brokers 1
{"brokers":[{"broker":1,"logDirs":[{"partitions":[{"partition":"bytes-0","size":13526603,"offsetLag":0,"isFuture":false}],"error":null,"logDir":"/home/ubuntu/kafka-data/node1/log"}]}],"version":1}
```

`size` são os bytes dos segmentos de log da partição, 13 526 603 aqui, e `offsetLag` é quanto uma
réplica está atrás do líder, o que num nó só é sempre zero. O `jq` tira o tamanho e o divide pelo
número de vendas:

```
ubuntu@stream:~/work$ kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list bytes | grep '^{' | jq '.brokers[0].logDirs[0].partitions[0].size / 100000'
135.26603
```

**Esse é o número a usar: cerca de 135 bytes em disco por venda, sem compressão.** A primeira venda
tem 122 bytes de JSON mais a quebra de linha que o `wc` contou; o resto é a chave, `natal` ou
`joao-pessoa`, e os campos do próprio registro e do lote. E ainda é uma cópia só: o fator de
replicação o multiplica depois.

## O diretório em si

A mesma partição, vista como arquivos:

```
ubuntu@stream:~/work$ ls -l ~/kafka-data/node1/log/bytes-0
total 13228
-rw-r--r-- 1 ubuntu ubuntu 10485760 Oct 10 17:11 00000000000000000000.index
-rw-r--r-- 1 ubuntu ubuntu 13526603 Oct 10 17:11 00000000000000000000.log
-rw-r--r-- 1 ubuntu ubuntu 10485756 Oct 10 17:11 00000000000000000000.timeindex
-rw-r--r-- 1 ubuntu ubuntu        8 Oct 10 17:11 leader-epoch-checkpoint
-rw-r--r-- 1 ubuntu ubuntu       43 Oct 10 17:11 partition.metadata
```

O arquivo `.log` é o segmento, os bytes que o `kafka-log-dirs.sh` contou. `.index` e `.timeindex`
mapeiam offsets e timestamps para posições dentro dele, que é como o reset por datetime da lição 16
achou seus offsets; eles são criados já no tamanho pré-alocado, os 10 485 760 bytes que o `ls`
mostra, e aparados quando o segmento fecha, então o tamanho deles num segmento ativo diz pouco. O
`kafka-log-dirs.sh` não os conta. A lição 3 abriu esses arquivos com o `kafka-dump-log.sh`; aqui o
ponto é só que **o `size` a multiplicar é o do arquivo `.log`**, que é exatamente o que a ferramenta
informou.

Dois cuidados antes de o número entrar na aritmética. **Ele depende do lote**: os caixas mandaram tão
rápido quanto podiam, então o produtor juntou muitas vendas por lote, e um produtor que manda uma
venda a cada poucos segundos paga um cabeçalho de lote por venda. E **ele depende da mensagem**:
acrescente um campo à venda e o número muda. Meça de novo quando a mensagem mudar, o que numa
plataforma real quer dizer quando o esquema dela mudar (lição 6).
