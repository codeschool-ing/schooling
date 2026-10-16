---
title: Um workload, com preço em três stores
version: 1
---

**A tela "meus pedidos" do aplicativo da Quitanda é um workload de formato claro**: um cliente a
abre, e o aplicativo mostra os pedidos recentes dele, do mais novo ao mais antigo. Ela é lida por uma
chave, o cliente, e uma faixa sob ela, as datas dos pedidos. Ponha números nela antes de escolher:

| | |
|---|---|
| consultas | 100.000 por dia, 3.000.000 por mês |
| cada consulta devolve | até dez pedidos, menos de 4 KB ao todo |
| pedidos novos | 20.000 por dia, 600.000 por mês, cada um com menos de 1 KB |
| dados guardados | 50 GB |
| latência | a tela abre em bem menos de um segundo |

Os preços dos três stores que esta seção compara vêm da tabela, com o S3 e o Redshift ao lado, que as
outras seções desta lição citam:

```
ana@laptop:~/aws$ python3 prices.py s3 dynamodb aurora redshift athena
AWS public price list, sa-east-1, USD, excluding tax

S3 storage, USD per GB-month
  Standard, first 50 TB                                 0.04050  GB-month
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Standard-IA                                           0.02210  GB-month
  One Zone-IA                                           0.01770  GB-month
  Glacier Instant Retrieval                             0.00830  GB-month
  Glacier Flexible Retrieval                            0.00765  GB-month
  Glacier Deep Archive                                  0.00320  GB-month

S3 requests, USD per 1,000
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
  Standard-IA: GET                                      0.00100  per 1,000
  Glacier Instant Retrieval: GET                        0.01000  per 1,000
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month

S3 retrieval, USD per GB
  Standard-IA                                           0.01000  GB
  Glacier Instant Retrieval                             0.03000  GB
  Glacier Flexible, expedited                           0.04200  GB
  Glacier Flexible, standard                            0.01400  GB
  Deep Archive, standard                                0.02800  GB
  Deep Archive, bulk                                    0.00800  GB

DynamoDB, USD
  on demand, per million write request units            0.93750  million
  on demand, per million read request units             0.18750  million
  provisioned, per WCU-hour                            0.000975  WCU-hour
  provisioned, per RCU-hour                            0.000195  RCU-hour
  storage beyond 25 GB                                  0.37500  GB-month
  storage, Standard-IA table class                      0.15000  GB-month
  streams, per million read requests beyond free        0.30000  million
  point-in-time recovery                                0.30000  GB-month

Aurora PostgreSQL, USD
  db.r7g.large, Standard, per hour                      0.43884  hour
  db.r7g.large, I/O-Optimized, per hour                 0.57081  hour
  storage, Standard                                     0.19000  GB-month
  storage, I/O-Optimized                                0.42800  GB-month
  I/O, Standard, per million requests                   0.28000  million
  Serverless v2, per ACU-hour                           0.25000  ACU-hour

Redshift, USD
  ra3.large, per node-hour                              0.86600  hour
  ra3.xlplus, per node-hour                             1.73100  hour
  ra3.4xlarge, per node-hour                            5.19500  hour
  managed storage                                       0.04300  GB-month
  Serverless, per RPU-hour                              0.59760  RPU-hour
  Spectrum, per TB scanned                              5.00000  TB

Athena, USD
  SQL queries, per TB scanned                           9.00000  TB
```

## DynamoDB

**A chave de partição da tabela é o cliente e a chave de ordenação, a data do pedido**, o desenho que
a lição 9 ensinou, então uma consulta é um `Query` que lê menos de 4 KB: uma unidade de requisição de
leitura quando fortemente consistente. Um pedido novo é uma escrita de menos de 1 KB: uma unidade de
requisição de escrita.

| sob demanda, um mês | conta | USD |
|---|---|---|
| leituras | 3,000,000 × 0.18750 ÷ 1,000,000 | 0.56 |
| escritas | 600,000 × 0.93750 ÷ 1,000,000 | 0.56 |
| armazenamento além de 25 GB | (50 − 25) × 0.37500 | 9.38 |
| **total** | | **10.50** |

**Dez dólares e meio por mês, e o armazenamento é nove deles.** As requisições saem baratas porque
cada uma toca uma chave, que é o padrão de acesso para o qual o DynamoDB tem preço.

## Aurora PostgreSQL

**O mesmo workload como uma tabela com índice no cliente e na data** é uma consulta indexada por
abertura de tela, servida em milissegundos a partir da memória depois que o conjunto de trabalho
aquece. O preço é a instância, seja qual for o número de consultas.

| Standard, um mês | conta | USD |
|---|---|---|
| uma db.r7g.large | 0.43884 × 730 | 320.35 |
| armazenamento | 50 × 0.19000 | 9.50 |
| I/O, se 30 milhões de leituras por mês escaparem do cache | 30 × 0.28000 | 8.40 |
| **total** | | **338.25** |

**Trinta e duas vezes a conta do DynamoDB, para um workload que usa uma lasca da máquina**, e um
escritor sem standby, que a lição 7 não aceitaria para nada de que o negócio dependa. Mas a comparação
tem uma segunda metade. **Se os pedidos da Quitanda já moram no Aurora**, como a seção anterior
decidiu, a tela "meus pedidos" é mais uma consulta numa máquina que já está paga, e o custo marginal
dela é quase nada. O store mais barato para um workload muitas vezes é o que já está rodando para o
workload ao lado.

## Athena

**O Athena é o store que não deveria estar nesta comparação**, e pôr preço nele mostra por quê. Cada
abertura de tela seria uma consulta, e o Athena cobra toda consulta por pelo menos 10 MB varridos, por
pouco que ela leia.

| um mês | conta | USD |
|---|---|---|
| 3.000.000 consultas no mínimo de 10 MB | 3,000,000 × 10 MB = 30 TB × 9.00 | 270.00 |

**270.00 por mês no mínimo, e cada consulta leva segundos**, porque uma consulta é planejada,
enfileirada e rodada sobre arquivos antes de responder. Um cliente não espera segundos por uma tela.
Só o preço teria deixado o Athena com cara de perto do Aurora; a segunda pergunta, a latência, o exclui
antes de o preço ser lido, que é a ordem que a primeira seção desta lição exigiu.

## O que os três números dizem

| store | um mês | o que diz |
|---|---|---|
| DynamoDB | 10.50 | o padrão de acesso é aquele para o qual ele foi feito |
| Aurora | 338.25 sozinho, quase zero ao lado dos pedidos | a instância é o preço, e ela pode já estar paga |
| Athena | 270.00 no mínimo, e lento demais | um motor de lake usado como banco de dados |

**Nem o DynamoDB nem o Aurora é "a resposta" só por esses números.** Uma equipe começando do zero poria
"meus pedidos" no DynamoDB; uma equipe cujos pedidos já estão no Aurora acrescentaria um índice e não
pagaria nada a mais. Os dois estão certos para a sua situação, e os dois leem os mesmos três números.
