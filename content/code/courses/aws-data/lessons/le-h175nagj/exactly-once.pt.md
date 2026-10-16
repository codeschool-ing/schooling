---
title: Ordem, duplicados e o exatamente uma vez do Kafka
version: 1
---

**Ordem e duplicados são problemas separados, e resolver um não resolve o outro.** Um consumidor pode
ver todo registro exatamente uma vez na ordem errada, ou na ordem certa duas vezes. As ferramentas
também são diferentes, e uma delas é mais barata que a tabela de deduplicação, no único caso em que
se aplica.

## O número de sequência como marca d'água

**Dentro de um shard, um reprocessamento relê os registros na mesma ordem com os mesmos números de
sequência.** Então um consumidor que guarda o maior número de sequência que já aplicou, por shard, na
mesma escrita que o efeito, pode pular qualquer registro igual ou abaixo dele. Isso é exatamente um reprocessamento, e custa um número por shard em vez de um item por evento. É o checkpoint levado para
dentro do destino. **Ele pega os duplicados do consumidor e não os do produtor**, porque o retry de um
produtor é um registro novo com um número de sequência maior, como a segunda seção mostrou com os
números 1 e 2. Um stream com produtores que tentam de novo ainda precisa da chave de idempotência; a
marca d'água é a metade mais barata para o outro tipo.

**E a ordem precisa de um campo próprio.** Quando os eventos do mesmo pedido podem chegar fora de
ordem, depois de um retry ou através de um reshard, o evento leva uma versão ou um horário dado pelo produtor. O destino só aplica uma escrita se ela for mais nova que o que ele guarda: uma escrita
condicional sobre a versão, o mesmo mecanismo de `ConditionExpression` da deduplicação, comparando um
número em vez de testar existência.

## O produtor idempotente do Kafka

**O Kafka remove os duplicados do produtor no broker**, o que o Kinesis não faz. Com
`enable.idempotence=true`, o padrão desde o Kafka 3.0, cada produtor recebe um id do broker e numera
todo registro que manda para cada partição. Quando um retry chega com um número que a partição já
escreveu, o broker o confirma sem escrevê-lo de novo, e um número fora de sequência é recusado. Então
o caso da segunda seção, uma confirmação perdida e um reenvio, escreve o registro uma vez. Isso cobre
uma sessão do produtor e os retries dela; um produtor que reinicia e manda de novo os registros a
partir da própria origem é uma sessão nova, e esses são registros novos.

## As transações do Kafka

**Uma transação faz do trabalho e do checkpoint uma escrita atômica só, desde que os dois estejam no
Kafka.** Um consumidor que lê de um tópico e escreve em outro pode, com um `transactional.id`, escrever
os registros de saída e confirmar os offsets de entrada numa transação só. Ou as saídas e os offsets novos ficam visíveis juntos, ou nenhum fica. Consumidores depois dele que leem com
`isolation.level=read_committed` só veem transações confirmadas. Esse é o exatamente uma vez do
Kafka, e o Kafka Streams o usa com uma configuração.

**Ele para na borda do Kafka.** No momento em que o trabalho sai do Kafka, uma linha no DynamoDB, um
objeto no S3, uma cobrança num cartão, a escrita externa não está na transação, e uma queda entre ela e
a confirmação a repete. É de novo a frase da primeira seção desta lição: exatamente uma vez é de ponta
a ponta ou nada, e a ponta é onde quer que o efeito caia. Nada disso foi rodado, já que um broker só
com ferramentas de console não consegue mostrá-lo; o comportamento vem da documentação do Kafka. O
que foi rodado, o reprocessamento das duas seções anteriores, é o que um pipeline faz nessa borda,
leia ele o stream que for.

| duplicado vindo de | pego por |
|---|---|
| um retry do produtor, Kinesis | uma chave de idempotência nos dados |
| um retry do produtor, Kafka | o produtor idempotente, no broker |
| um reprocessamento do consumidor | uma chave de idempotência, ou uma marca d'água de número de sequência por shard |
| um retry do Firehose ou da Lambda | um destino idempotente, ou uma deduplicação quando o lago é compactado |
| um ler-processar-escrever dentro do Kafka | as transações do Kafka |
