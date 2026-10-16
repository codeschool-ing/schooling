---
title: Aurora Serverless v2, capacidade que acompanha a carga
version: 1
---

**O Aurora Serverless v2 é uma instância Aurora cujo tamanho muda enquanto ela roda.** Em vez de uma classe
como `db.r7g.large`, a instância é `db.serverless`, e o cluster diz o menor e o maior que ela pode ser, em
**Aurora capacity units**. A AWS documenta uma ACU como cerca de 2 GiB de memória com a CPU e a rede que vêm
junto. O Aurora acompanha a carga e move a instância entre os dois limites em passos de meia ACU, em
segundos, sem reiniciá-la nem derrubar conexão. É cobrada por ACU-hora pela capacidade que teve de fato.

**A ideia errada é que serverless quer dizer barato.** Quer dizer cobrado pelo tamanho que teve a cada
segundo, o que é barato quando o banco fica quieto a maior parte do tempo e caro quando fica ocupado o tempo
todo. O bloco Aurora da tabela de preços diz quão caro:

```
ana@laptop:~/aws$ python3 prices.py aurora
AWS public price list, sa-east-1, USD, excluding tax

Aurora PostgreSQL, USD
  db.r7g.large, Standard, per hour                      0.43884  hour
  db.r7g.large, I/O-Optimized, per hour                 0.57081  hour
  storage, Standard                                     0.19000  GB-month
  storage, I/O-Optimized                                0.42800  GB-month
  I/O, Standard, per million requests                   0.28000  million
  Serverless v2, per ACU-hour                           0.25000  ACU-hour
```

## A conta nas duas pontas

**Com carga constante, o serverless custa cerca de quatro vezes e meia mais.** Uma `db.r7g.large` tem 2 vCPU
e 16 GiB de memória; 16 GiB são 8 ACUs, e 8 × 0,25 = 2,00 por hora contra 0,43884 da instância provisionada,
4,6 vezes. Um banco que precisa de 16 GiB o mês inteiro paga 8 × 0,25 × 730 = 1.460,00 em serverless contra
0,43884 × 730 = 320,35 provisionado.

**Quando a carga quase não existe, custa uma fração.** O cluster de desenvolvimento da Quitanda é usado pelo
time dez horas por dia, vinte e dois dias úteis por mês, 220 horas, e ninguém mexe nele nas outras 510. Com 8
ACUs durante o uso, são 8 × 0,25 × 220 = 440,00 por mês, e o que as horas ociosas custam depende do mínimo:

| mínimo | as 510 horas ociosas | computação no mês |
|---|---|---|
| 0,5 ACU | 0,5 × 0,25 × 510 = 63,75 | 503,75 |
| 0, pausando depois de 15 minutos | nada de computação | 440,00 |

Os dois passam dos 320,35 provisionados, porque dez horas por dia no tamanho cheio já são muitas horas. A
linha em que o serverless ganha com 8 ACUs é 320,35 / 2,00 = 160 horas por mês no tamanho cheio, umas sete
horas e meia por dia útil e nada fora delas. Um cluster ocupado duas horas por dia fica bem abaixo dela; um
ocupado a noite toda, não.

**Um mínimo de 0 é a opção mais nova**: a instância pausa depois de um tempo sem conexões, a cobrança de
computação para, e a primeira conexão depois disso a acorda, o que a AWS documenta como levando segundos e
não milissegundos. O armazenamento é cobrado de qualquer jeito. Essa pausa serve para um cluster de
desenvolvimento ou de teste e não para a loja, onde o primeiro cliente da manhã esperaria por ela. Os limites
que a AWS documenta são um mínimo de 0 ou 0,5 e um máximo de 256 ACUs nas versões recentes do engine, e a
pausa entre 5 minutos e 24 horas de ociosidade.

## No moto

Um cluster de desenvolvimento que pode pausar, e uma instância serverless dentro dele:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-dev --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --serverless-v2-scaling-configuration MinCapacity=0,MaxCapacity=8,SecondsUntilAutoPause=900 --query 'DBCluster.ServerlessV2ScalingConfiguration'
{
    "MinCapacity": 0.0,
    "MaxCapacity": 8.0,
    "SecondsUntilAutoPause": 900
}
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-dev-1 --db-cluster-identifier quitanda-dev --engine aurora-postgresql --db-instance-class db.serverless --query 'DBInstance.[DBInstanceClass,DBInstanceStatus]' --output text
db.serverless	available
```

**A configuração de escala é guardada e a instância fica `available`**, e ela nunca vai escalar, porque não
há carga nem engine para medi-la. O moto guarda os números que recebeu, e guarda quaisquer que sejam:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-backwards --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --serverless-v2-scaling-configuration MinCapacity=300,MaxCapacity=2 --query 'DBCluster.ServerlessV2ScalingConfiguration'
{
    "MinCapacity": 300.0,
    "MaxCapacity": 2.0
}
```

**Um mínimo de 300 e um máximo de 2 foram aceitos**, uma faixa ao contrário e com um mínimo acima de
qualquer coisa que a AWS permite. Na AWS a requisição é recusada. Como com todo número destas três lições, o
moto guarda e não julga; o julgamento é da documentação e, numa conta de verdade, da mensagem de erro.

**Um cluster pode misturar os dois tipos.** Um writer provisionado, dimensionado para a carga constante da
loja, e uma réplica serverless que cresce quando os relatórios da manhã rodam é um formato comum. O promotion
tier importa aqui tanto quanto num failover: a AWS documenta que um reader serverless no tier 0 ou 1 mantém
pelo menos a capacidade do writer, para estar pronto para assumir, enquanto um nos tiers 2 a 15 escala pela
própria carga.
