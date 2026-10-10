---
title: Cassandra, pelo nodetool
version: 1
---

O problema do Cassandra raramente chega como erro. **Chega como latência nos percentis altos, como
trabalho enfileirado dentro de um nó, e como leituras que fazem muito mais trabalho do que as linhas
que devolvem**, e um nó nesse estado ainda responde a toda consulta. O `nodetool` é a janela para
tudo isso, e cinco dos seus comandos carregam quase tudo o que um operador lê. Um nó basta para
vê-los, então esta seção usa o contêiner `cassandra` da aula 1 em vez do cluster de três nós das
aulas 16 a 19.

```sh
docker rm -f redis redis-replica
docker start cassandra
until docker exec cassandra cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
```

Se o contêiner da aula 1 sumiu, a linha `docker run` dela, com as duas configurações `-e`, cria um
novo.

## `nodetool status`: o primeiro comando, sempre

```
ana@vm:~$ docker exec cassandra nodetool status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  172.18.0.2  124.48 KiB  16      100.0%            bd4227b0-b32f-4436-af79-8b01b4bfc7cf  rack1

```

**Duas letras por nó, e qualquer coisa diferente de `UN` é notícia**: `U` ou `D` para no ar ou fora,
como o gossip deste nó enxerga, depois `N`, `L`, `J` ou `M` para normal, saindo, entrando ou se
movendo. Num cluster, uma linha `DN` é um nó que os outros não alcançam, e toda escrita destinada a
ele vira um hint (aula 19). `Load` são os dados em disco; cargas muito diferentes em nós que possuem
fatias iguais são uma chave de partição que espalha os dados de forma desigual (aula 16).

## Uma tabela que lê mal de propósito

A cesta da loja: uma partição por cliente, uma linha por item. A Ana põe 2.000 cabos USB-C e tira
1.990 deles, o padrão de fila contra o qual a aula 18 alerta; o Bruno guarda 50.000 mouses, uma
partição muito maior que as outras; três clientes ficam com sensatos 20 itens cada.

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> CREATE TABLE shop.basket (customer text, item int, sku text, PRIMARY KEY (customer, item));
cqlsh> exit
```

As linhas são geradas como um arquivo CSV na VM e copiadas para o contêiner:

```sh
{ seq 1 2000 | sed 's/.*/ana@example.com,&,CB-012/'
  seq 1 50000 | sed 's/.*/bruno@example.com,&,MS-204/'
  for c in carla diego elisa; do seq 1 20 | sed "s/.*/$c@example.com,&,KB-101/"; done
} > basket.csv
docker cp basket.csv cassandra:/basket.csv
```

O `COPY ... FROM` é o carregador em massa do `cqlsh`. Ele imprime uma linha de progresso enquanto
anda, e o `tail -1` fica com o resumo:

```
ana@vm:~$ docker exec cassandra cqlsh -e "COPY shop.basket (customer, item, sku) FROM '/basket.csv'" | tail -1
52060 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 1.339 seconds (0 skipped).
```

Depois, 1.990 deletes, um por cabo retirado, gerados do mesmo jeito e passados ao `cqlsh` pela
entrada:

```sh
seq 1 1990 | sed "s/.*/DELETE FROM shop.basket WHERE customer = 'ana@example.com' AND item = &;/" > emptied.cql
docker exec -i cassandra cqlsh < emptied.cql
```

```
ana@vm:~$ wc -l basket.csv emptied.cql
  52060 basket.csv
   1990 emptied.cql
  54050 total
```

Agora leia as cestas, a da Ana duas vezes:

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT count(*) FROM shop.basket WHERE customer = 'ana@example.com';

 count
-------
    10

(1 rows)

Warnings :
Read 10 live rows and 1990 tombstone cells for query SELECT * FROM shop.basket WHERE customer = 'ana@example.com' LIMIT 100 ALLOW FILTERING; token 8413089589345688709 (see tombstone_warn_threshold)

cqlsh> SELECT count(*) FROM shop.basket WHERE customer = 'bruno@example.com';

 count
-------
 50000

(1 rows)
cqlsh> SELECT count(*) FROM shop.basket WHERE customer = 'ana@example.com';

 count
-------
    10

(1 rows)

Warnings :
Read 10 live rows and 1990 tombstone cells for query SELECT * FROM shop.basket WHERE customer = 'ana@example.com' LIMIT 100 ALLOW FILTERING; token 8413089589345688709 (see tombstone_warn_threshold)

cqlsh> exit
ana@vm:~$ docker exec cassandra nodetool flush shop basket
```

**Dez linhas respondidas, 1.990 tombstones lidos para encontrá-las.** O aviso aparece porque a
leitura passou do `tombstone_warn_threshold`, 1.000 por padrão; no `tombstone_failure_threshold`,
100.000, a leitura é recusada. O cliente só vê o aviso se alguém o imprimir, e a maioria dos drivers
não imprime. O nó conta de qualquer jeito, e o `nodetool flush` grava a memtable numa SSTable para
que os tamanhos por partição abaixo tenham algo em disco para medir.

## `tablestats` e `tablehistograms`: a história da própria tabela

O `tablestats` imprime umas quarenta linhas por tabela; estas são as que falam da saúde desta:

```
ana@vm:~$ docker exec cassandra nodetool tablestats shop.basket | grep -E "SSTable count|Number of partitions|Local read latency|Compacted partition|tombstones per slice"
		SSTable count: 1
		Old SSTable count: 0
		Number of partitions (estimate): 5
		Local read latency: 0.163 ms
		Compacted partition minimum bytes: 373
		Compacted partition maximum bytes: 1131752
		Compacted partition mean bytes: 232523
		Average tombstones per slice (last five minutes): 10.137176938369782
		Maximum tombstones per slice (last five minutes): 2299
```

**`Maximum tombstones per slice` é 2.299, e uma slice é uma leitura de uma partição.** A leitura
contou 1.990; o número é 2.299 porque essas estatísticas são mantidas em histogramas de faixas fixas,
e 2.299 é o limite superior da faixa em que 1.990 cai. A média, 10,1, se espalha por todas as
leituras dos últimos cinco minutos, e é por isso que ela esconde o problema e o máximo o mostra. A
aula 18 diz o que fazer com uma tabela que lê assim.

**`Compacted partition maximum bytes` é 1.131.752, contra uma média de 232.523 e um mínimo de
373.** Esse máximo é a partição do Bruno, 50.000 linhas em cerca de um megabyte. Uma partição de um
megabyte não é problema; o número a temer é uma rumo às centenas de megabytes, que toda leitura e
toda compactação dela precisa carregar. Os histogramas dizem o mesmo por percentil:

```
ana@vm:~$ docker exec cassandra nodetool tablehistograms shop basket
shop/basket histograms
Percentile      Read Latency     Write Latency          SSTables    Partition Size        Cell Count
                    (micros)          (micros)                             (bytes)                  
50%                    86.00             72.00              0.00               446                20
75%                   124.00            124.00              0.00             29521                20
95%                   310.00            310.00              0.00           1131752             51012
98%                   535.00           9887.00              0.00           1131752             51012
99%                   924.00          24601.00              0.00           1131752             51012
Min                    21.00              4.00              0.00               373                 9
Max                 14237.00         219342.00              0.00           1131752             51012

```

Metade das partições tem 446 bytes ou menos, e a maior tem 51.012 células pela mesma divisão em
faixas. A coluna `SSTables` é quantas SSTables cada leitura precisou abrir, 0 aqui porque toda
leitura foi atendida pela memtable antes do flush; numa tabela lida depois de muitos flushes, uma
mediana passando de algumas unidades é a compactação ficando para trás.

## `proxyhistograms`: a latência como o cliente a vê

O `tablehistograms` mede o trabalho local numa tabela. O `proxyhistograms` mede o pedido inteiro no
nó que o coordenou, o que num cluster inclui esperar pelas outras réplicas:

```
ana@vm:~$ docker exec cassandra nodetool proxyhistograms
proxy histograms
Percentile       Read Latency      Write Latency      Range Latency   CAS Read Latency  CAS Write Latency View Write Latency
                     (micros)           (micros)           (micros)           (micros)           (micros)           (micros)
50%                    258.00             535.00            6866.00               0.00               0.00               0.00
75%                    372.00            1109.00           14237.00               0.00               0.00               0.00
95%                   1331.00           29521.00           20501.00               0.00               0.00               0.00
98%                   2299.00           61214.00           42510.00               0.00               0.00               0.00
99%                   4768.00          105778.00           42510.00               0.00               0.00               0.00
Min                     61.00             104.00            1332.00               0.00               0.00               0.00
Max                  14237.00          219342.00           42510.00               0.00               0.00               0.00

```

**Leia o percentil 99, nunca a mediana.** As leituras têm mediana de 258 µs e p99 de 4.768 µs,
quase vinte vezes mais; as escritas têm mediana de 535 µs e p99 de 105.778 µs, porque a carga em
massa mandou lotes grandes. A mediana diz como a maioria dos pedidos se sente, e o p99 é o que uma
página em cada cem espera. Esses números são acumulados desde que o nó subiu, então observe-os como
taxa ao longo do tempo, por um exporter, em vez de ler os totais.

## `tpstats` e `compactionstats`: trabalho esperando

```
ana@vm:~$ docker exec cassandra nodetool tpstats | grep -E "^(Pool Name|ReadStage|MutationStage|Native-Transport-Requests|CompactionExecutor|Message type|READ_REQ|MUTATION_REQ) "
Pool Name                      Active Pending Completed Blocked All time blocked
MutationStage                  0      0       2661      0       0               
ReadStage                      0      0       610       0       0               
CompactionExecutor             0      0       58        0       0               
Native-Transport-Requests      0      0       4743      0       0               
Message type                      Dropped     50%      95%      99%      Max
MUTATION_REQ                      0           0.0      0.0      0.0      0.0
READ_REQ                          0           0.0      0.0      0.0      0.0
ana@vm:~$ docker exec cassandra nodetool compactionstats
concurrent compactors            2          
pending tasks                    0          
compactions completed            4          
data compacted                   81003      
compressed data compacted        22194      
compactions aborted              0          
compactions reduced              0          
sstables dropped from compaction 0          
15 minute rate                   0.26/minute
mean rate                        183.75/hour
compaction throughput (MiB/s)    64.0       
```

Cada estágio de um nó é um pool de threads com uma fila na frente. **`Pending` que fica acima de zero
quer dizer que um estágio não dá conta; `Blocked` quer dizer que a fila dele está cheia e o trabalho
está sendo segurado antes.** A segunda tabela é a que mais importa: um `MUTATION_REQ` **descartado**
é uma escrita que esperou mais que seu timeout e foi jogada fora por esta réplica. O cliente pode ter
ouvido que a escrita deu certo, num nível de consistência que outras réplicas satisfizeram, e a cópia
neste nó agora falta até o repair colocá-la de volta (aula 19).

O `pending tasks` do `compactionstats` são as compactações esperando para rodar. Zero, como aqui, é
um nó em dia; um número que cresce hora após hora é um nó escrevendo mais rápido do que consegue
juntar, e as SSTables por leitura e a latência de leitura sobem atrás dele um dia depois.

Tudo aqui é zero porque um nó com esta carga não tem o que enfileirar. Esse é o retrato honesto de
um nó saudável, e o motivo de esses serem os contadores que um alerta observa: ficam em zero até o
dia em que não ficam.
