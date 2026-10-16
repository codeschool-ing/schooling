---
title: Réplicas, endpoints e um failover que não move dado nenhum
version: 1
---

**Uma réplica do Aurora é um segundo engine lendo o mesmo volume, então nunca lhe falta dado.** Ela não é
uma cópia mantida em sincronia, como as réplicas de leitura da lição 7. Não tem armazenamento próprio; lê os
protection groups que o writer grava, e o fluxo de log do writer chega a ela só para atualizar as páginas
que ela tem na memória. A AWS documenta o atraso de uma réplica do Aurora como ficando em geral bem abaixo
de 100 milissegundos, contra os segundos que uma réplica RDS ocupada pode ficar para trás. O número é da AWS,
não deste laboratório.

Isso muda o que é um failover. **Promover uma réplica do Aurora não copia nem reaplica nada**: os dados já
estão onde a réplica consegue lê-los, então ela só precisa começar a aceitar escritas, e o cluster endpoint
passa para ela. A AWS documenta o serviço como voltando em geral em cerca de trinta segundos quando há uma
réplica para receber o failover. Um cluster sem réplica precisa ligar uma instância nova contra o volume, o
que a AWS documenta como levando em geral menos de dez minutos, e essa diferença é a razão mais forte para
rodar uma réplica mesmo quando nada lê dela.

## Failover no moto

O cluster da seção anterior, com o writer em `sa-east-1a` e a réplica em `sa-east-1b`:

```
ana@laptop:~/aws$ aws rds failover-db-cluster --db-cluster-identifier quitanda-aurora --target-db-instance-identifier quitanda-aurora-2 --query 'DBCluster.DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter]' --output text
quitanda-aurora-1	False
quitanda-aurora-2	True
```

**O writer mudou, o primeiro failover deste curso que o moto mostra de algum jeito.** Ele trocou a marcação
entre os dois membros. Na AWS, o mesmo comando é como se ensaia um failover: o cluster endpoint passa para
`quitanda-aurora-2`, as conexões com o writer antigo caem e a aplicação se reconecta ao mesmo nome,
exatamente como com a instância Multi-AZ da lição 7. O moto muda a marcação e mais nada, porque não há mais
nada; quanto tempo a *sua* aplicação leva para perceber e se reconectar continua sendo um número que só uma
conta de verdade dá.

## Quatro tipos de endpoint

| endpoint | aponta para | serve para |
|---|---|---|
| cluster, `quitanda-aurora.cluster-…` | o writer, qualquer que seja a instância agora | escritas, e leituras que precisam vê-las |
| reader, `quitanda-aurora.cluster-ro-…` | as réplicas, com as conexões distribuídas | leituras que podem estar alguns milissegundos velhas |
| custom | uma lista de instâncias que você escolhe | um grupo de réplicas separado para um trabalho |
| instância, `quitanda-aurora-1.…` | uma instância, sempre | diagnosticar aquela instância, nunca uma aplicação |

**Um custom endpoint é como a Quitanda mantém os analistas longe da réplica de que a loja lê.** Duas réplicas
atendem o site pelo reader endpoint; uma terceira, maior, é indicada num custom endpoint que a ferramenta de
relatórios usa, e assim um relatório pesado não deixa o checkout de ninguém lento. O moto não escreveu essa
ação:

```
ana@laptop:~/aws$ aws rds create-db-cluster-endpoint --db-cluster-identifier quitanda-aurora --db-cluster-endpoint-identifier quitanda-reports --endpoint-type READER --static-members quitanda-aurora-1

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

O terminal do moto diz o que falta, `NotImplementedError: The create_db_cluster_endpoint action has not been
implemented`. Na AWS o comando devolve o endereço do endpoint e os membros que ele atende; isso não foi
rodado.

## Quinze, e não mais

**Um cluster aceita até quinze réplicas**, como a AWS documenta, dezesseis instâncias com o writer. O moto não
conta:

```
ana@laptop:~/aws$ for i in $(seq 3 17); do aws rds create-db-instance --db-instance-identifier quitanda-aurora-$i --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --query DBInstance.DBInstanceStatus --output text; done | sort | uniq -c
     15 available
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'length(DBClusters[0].DBClusterMembers)'
17
```

**Dezessete membros, quinze deles acabados de criar, cada um respondendo `available`.** Na AWS a décima sexta
instância seria a última aceita e a décima sétima seria recusada. Uma réplica é cobrada como uma instância da
classe dela, e nenhuma acrescenta armazenamento, porque há um volume só.

## Entre regiões: Global Database

**Um Aurora Global Database é um cluster primário e clusters secundários em outras regiões**, e a replicação
é feita pela camada de armazenamento e não pelo engine: o volume envia as mudanças para o volume da outra
região, e a AWS documenta o atraso como ficando em geral abaixo de um segundo. Os clusters secundários
respondem leituras perto de quem as faz, e um deles pode ser promovido para receber escritas se a região
primária for perdida, que é o desastre que a réplica entre regiões da lição 7 respondia mais devagar. A
transferência entre regiões é cobrada, como o bloco de transferência da lição 7 mostrou, e as instâncias e o
armazenamento da região secundária são cobrados pelos preços daquela região. Nada disso foi rodado aqui, e a
replicação que isso representa é exatamente a parte de que o moto não tem modelo.
