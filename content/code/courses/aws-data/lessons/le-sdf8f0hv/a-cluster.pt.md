---
title: Um cluster e as instâncias dele, no moto
version: 1
---

**Um banco Aurora é primeiro um cluster e depois instâncias.** O cluster é dono do volume, dos backups, da
versão do engine, do usuário mestre e dos endpoints. As instâncias são as máquinas que rodam o engine contra
esse volume, e o cluster pode existir sem nenhuma delas, guardando dados que ninguém consegue consultar.
Então criar um são dois tipos de comando: um `create-db-cluster`, e depois um `create-db-instance` por
máquina, cada um indicando o cluster. O moto está rodando no terminal dele, e as quatro linhas de "O seu
laboratório, em resumo" da lição 1 estão digitadas neste.

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query 'DBCluster.[Status,Endpoint,ReaderEndpoint]'
[
    "creating",
    "quitanda-aurora.cluster-icnvtdkhgjyf.sa-east-1.rds.amazonaws.com",
    "quitanda-aurora.cluster-ro-icnvtdkhgjyf.sa-east-1.rds.amazonaws.com"
]
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].Status'
"available"
```

**Dois endereços antes de existir uma única máquina.** O primeiro é o **cluster endpoint**, que aponta sempre
para o writer. O segundo, com `cluster-ro` no nome, é o **reader endpoint**, que distribui as conexões entre
as réplicas. Não foi dado tamanho nem tipo de armazenamento: um volume Aurora não tem tamanho para escolher,
e cresce com os dados. O status diz `creating`, a primeira vez neste curso em que o moto não respondeu
`available` de cara; perguntado de novo um instante depois, está `available`. Na AWS o cluster leva minutos
para chegar lá, e mesmo então não tem onde rodar.

Depois as máquinas. Uma em cada uma de duas zonas, para que perder uma zona deixe uma:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-aurora-1 --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --availability-zone sa-east-1a --query 'DBInstance.[DBInstanceStatus,AvailabilityZone,Endpoint.Address]' --output text
available	sa-east-1a	quitanda-aurora-1.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-aurora-2 --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --availability-zone sa-east-1b --query 'DBInstance.[DBInstanceStatus,AvailabilityZone,Endpoint.Address]' --output text
available	sa-east-1b	quitanda-aurora-2.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter,PromotionTier]' --output text
quitanda-aurora-1	True	1
quitanda-aurora-2	False	1
```

**A primeira instância de um cluster vira o writer**, e todas as seguintes réplicas, porque o Aurora tem
exatamente um writer por cluster. Cada instância também tem endpoint próprio, que serve para diagnosticar
aquela máquina e não para uma aplicação, que deve usar os dois do cluster. O **promotion tier** decide qual
réplica vira o writer quando o writer falha: o tier mais baixo primeiro, de 0 a 15, com a instância maior
desempatando. As duas estão no padrão, 1, aqui.

## O que o moto diz sobre o armazenamento

```
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].[StorageType,AllocatedStorage]' --output text
gp2	1
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-aurora-1 --query 'DBInstances[0].[StorageType,AllocatedStorage]' --output text
aurora	1
```

**`gp2` para o cluster está errado**, e é a linha mais instrutiva desta lição. gp2 é um tipo de volume EBS,
do tipo que a instância da lição 6 tinha, e um cluster Aurora não tem volume EBS; não existe tipo de
armazenamento que um cluster Aurora possa informar que seja um disco. O `aurora` da instância é a palavra
certa, e o armazenamento alocado de 1 é um marcador: na AWS, as instâncias Aurora informam o armazenamento
como propriedade do cluster, que cresce sozinho. O moto responde com campos emprestados do modelo dele de uma
instância comum, e eles parecem tão plausíveis quanto os verdadeiros.

A outra configuração de armazenamento, I/O-Optimized, é um valor de `--storage-type`, e o moto não a aceita:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-aurora-io --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --storage-type aurora-iopt1

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**Um 500 de novo**, e o terminal do moto imprime o motivo: `KeyError: 'aurora-iopt1'`. O moto procura o tipo
de armazenamento numa tabela de tamanhos padrão de volumes EBS, o mesmo modelo de antes, e os valores do
Aurora não estão nela. Na AWS o comando cria um cluster cujo armazenamento é cobrado do jeito I/O-Optimized;
a última seção desta lição é o que isso significa para a conta, e isso não foi rodado.

**Leia todas as transcrições de Aurora desta lição do mesmo jeito.** O moto guarda o formato de um cluster:
os endpoints, os membros, qual é o writer. Nada abaixo do engine, que é a parte do Aurora que o diferencia, é
modelado, e às vezes ele preenche o vazio com uma resposta que pertence a outro serviço.
