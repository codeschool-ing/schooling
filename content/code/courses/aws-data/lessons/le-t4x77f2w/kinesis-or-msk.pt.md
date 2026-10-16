---
title: Kinesis ou MSK, para uma carga
version: 1
---

**O Kinesis vende shards e registros; o MSK vende brokers e discos.** Essa diferença no que é cobrado
decide a maior parte da comparação, então a comparação começa pelos preços:

```
ana@laptop:~/aws$ python3 prices.py kinesis msk
AWS public price list, sa-east-1, USD, excluding tax

Kinesis Data Streams, USD
  provisioned, per shard-hour                           0.03000  hour
  provisioned, per million PUT payload units            0.02800  million
  provisioned, extended retention, per shard-hour       0.04000  hour
  on demand, per stream-hour                            0.08000  hour
  on demand, data written                               0.16000  GB
  on demand, data read                                  0.08000  GB

Data Firehose, USD per GB
  ingested, first 500 TB                                0.05800  GB
  format conversion                                     0.03500  GB
  dynamic partitioning                                  0.03100  GB

MSK, USD
  kafka.t3.small, per broker-hour                       0.07360  hour
  kafka.m7g.large, per broker-hour                      0.32530  hour
  kafka.m7g.xlarge, per broker-hour                     0.65030  hour
  broker storage                                        0.19000  GB-month
  Serverless, per cluster-hour                          1.19500  hour
  Serverless, per partition-hour                        0.00240  hour
  Serverless, data in                                   0.16000  GB
ana@laptop:~/aws$ python3 prices.py transfer | grep zones
  between zones, each direction                         0.01000  GB
```

A carga é a que as lições 20 e 21 puseram preço: os eventos de pedido da Quitanda, 20 GB por dia em
registros de cerca de 1 KB, lidos por dois consumidores, guardados por sete dias, num mês de 30 dias e
730 horas.

## O mesmo mês, de três jeitos

| Kinesis, provisionado, 3 shards (lição 20) | conta | USD por mês |
|---|---|---|
| shard-horas | 3 × 730 × 0,03000 | 65,70 |
| PUT payload units | 600 milhões × 0,02800 por milhão | 16,80 |
| sete dias de retenção | 3 × 730 × 0,04000 | 87,60 |
| **total** | | **170,10** |

| MSK, provisionado, 3 × `kafka.m7g.large` em 3 zonas | conta | USD por mês |
|---|---|---|
| broker-horas | 3 × 730 × 0,32530 | 712,41 |
| armazenamento: 7 dias × 20 GB × 3 cópias = 420 GB, provisionados como 200 GB por broker | 600 × 0,19000 | 114,00 |
| clientes atravessando zonas: dois em cada três bytes chegam a uma líder em outra zona | 1.200 GB × 2 × 0,01000 | 24,00 |
| **total** | | **850,41** |

| MSK Serverless | conta | USD por mês |
|---|---|---|
| o cluster | 730 × 1,19500 | 872,35 |
| 3 partições | 3 × 730 × 0,00240 | 5,26 |
| dados que entram | 600 GB × 0,16000 | 96,00 |
| **total das linhas que a tabela imprime** | | **973,61** |

**A linha de zona precisa da conta.** Os produtores escrevem 600 GB por mês e dois consumidores leem
1.200 GB; com as líderes espalhadas por três zonas, dois terços desses 1.800 GB, que dão 1.200 GB,
atravessam uma zona, e a travessia é cobrada em cada sentido. A replicação entre os brokers não é
cobrada, como a seção de replicação disse. **O total do Serverless é um piso**: o MSK Serverless também
cobra dados lidos e dados guardados, e a tabela não imprime nenhuma das duas linhas, então o número
real é maior.

**Neste tamanho o Kinesis é cinco vezes mais barato que o cluster provisionado, e o motivo é a parte
fixa.** Três brokers `m7g.large` custam 712,41 por mês antes de um byte ser escrito, e 20 GB por dia usam
uma fração pequena do que eles aguentam. Um cluster de brokers `kafka.t3.small` levaria isso a
3 × 730 × 0,07360 = 161,18 pelos brokers e 299,18 no total, que é o tamanho de desenvolvimento da AWS e
não um em que se põe produção.

## Onde as linhas se cruzam

Faça a carga crescer e as duas contas crescem de jeitos diferentes. Por GB por dia de tráfego, a partir
das tabelas acima:

| por GB por dia | Kinesis | MSK provisionado |
|---|---|---|
| fixo, seja qual for o tráfego | 0 | 712,41 |
| para cada GB por dia | 170,10 / 20 = 8,51 | (114,00 + 24,00) / 20 = 6,90 |

**Elas se encontram mais ou menos onde 8,51 × v = 712,41 + 6,90 × v, em cerca de 440 GB por dia**,
vinte e duas vezes o volume da Quitanda, e o MSK é o mais barato acima disso, desde que os mesmos três
brokers aguentem a carga. Se aguentam é uma questão de vazão de broker, partições e rede, que o guia de
dimensionamento da AWS para o MSK responde e que este curso não mediu, então leia o cruzamento como
onde começar a olhar e não como um resultado. Mais duas coisas o movem: o armazenamento em camadas
baixa a linha por GB do MSK, e do lado do Kinesis registros juntados vários por payload unit baixam a
linha de PUT.

## O que o preço não decide

| | Kinesis Data Streams | MSK |
|---|---|---|
| ordem | por shard | por partição, e acrescentar partições muda chaves de lugar |
| retenção | de 24 horas a 365 dias, só por idade | por tempo ou tamanho, ilimitada com armazenamento em camadas, ou compactação por chave |
| muitos consumidores | 2 MB por segundo por shard divididos, ou enhanced fan-out por consumidor | cada grupo lê na velocidade do broker, sem cobrança por grupo |
| ecossistema | o da AWS: Firehose, Lambda, a Kinesis Client Library | o do Kafka: qualquer cliente Kafka, Kafka Connect, Kafka Streams, transações |
| operação | sem brokers, um número de shards ou on-demand | tipo e número de brokers, discos, partições, configurações de replicação, atualizações |

**O Kinesis ganha quando a equipe quer um stream e não um sistema**: volume modesto, consumidores da
AWS, ninguém cujo trabalho seja o Kafka. **O MSK ganha quando o próprio Kafka é o requisito**: um
parque existente de clientes e conectores Kafka, uma retenção de meses, tópicos compactados usados
como tabelas, muitos grupos de consumidores, ou as transações da lição 23. E acima de algumas centenas
de GB por dia, se os brokers aguentarem, ganha no preço também.
