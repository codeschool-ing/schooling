---
title: O Multi-AZ DB cluster, dois standbys que você lê
version: 1
---

**Um Multi-AZ DB cluster são três instâncias em três zonas, e duas delas respondem consultas.** É a mais
nova das duas implantações Multi-AZ do RDS, para PostgreSQL e MySQL, e corrige a queixa que se faz da
primeira: um standby que custa uma instância inteira e não faz nada até o dia em que é necessário. No
cluster, um **writer** recebe as escritas e dois **readers** nas outras duas zonas as recebem dele, e os
readers atendem leituras enquanto esperam.

| | instância Multi-AZ | Multi-AZ DB cluster |
|---|---|---|
| instâncias | 2: primário e standby | 3: um writer, dois readers |
| zonas | 2 | 3 |
| as cópias respondem leituras | não | sim, por um reader endpoint |
| replicação | síncrona para o standby | semissíncrona: um commit espera um dos dois readers |
| failover, como a AWS documenta | costuma levar de 60 a 120 segundos | costuma levar menos de 35 segundos |
| engines | todos os do RDS | PostgreSQL e MySQL |

**O semissíncrono é a troca.** Um commit volta quando o writer e pelo menos um reader têm a transação,
então o commit não espera o mais lento dos dois, e um reader que fica para trás não atrasa toda escrita.
O reader que confirmou tem toda transação confirmada, e é isso que torna seguro fazer failover para ele.
O outro pode estar um instante atrás, então uma consulta mandada ao reader endpoint pode ver dados um pouco
mais velhos que os do writer, a mesma ressalva das réplicas de leitura da próxima seção, só que medida
numa unidade muito menor.

**O cluster tem dois endereços**, um writer endpoint e um reader endpoint. O writer endpoint aponta
sempre para a instância que é o writer agora, então um failover é de novo uma mudança de DNS por trás de
um nome que não muda. O reader endpoint distribui as conexões entre os readers. Uma aplicação que quer os
dois divide o tráfego: escritas, e leituras que precisam ver as próprias escritas, vão para o primeiro;
relatórios e painéis, para o segundo.

## No moto

Um Multi-AZ DB cluster é criado com `create-db-cluster`, o comando que a lição 8 usa para o Aurora, e um
engine que não é Aurora. As três instâncias dele levam uma classe da lista que o cluster aceita, como
`db.m6gd.large`, e o armazenamento é `io1`, `io2` ou `gp3`, segundo a documentação da AWS:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-orders --engine postgres --engine-version 16 --db-cluster-instance-class db.m6gd.large --storage-type io2 --allocated-storage 100 --iops 3000 --master-username quitanda --manage-master-user-password --query 'DBCluster.[Status,MultiAZ,Endpoint,ReaderEndpoint]' --output text
creating	False	quitanda-orders.cluster-peijid1n1e4k.sa-east-1.rds.amazonaws.com	quitanda-orders.cluster-ro-peijid1n1e4k.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-orders --query 'DBClusters[0].[Status,MultiAZ,length(DBClusterMembers)]' --output text
available	False	0
```

**O moto criou um cluster com dois endpoints e nenhuma instância**, e diz que ele não é Multi-AZ. Na AWS
este comando cria três instâncias em três zonas e informa `MultiAZ` como `True`; o `length` dos membros
seria 3, e cada um apareceria com a indicação de ser ou não o writer. O moto conhece o comando, guarda o
registro e inventa os dois endereços no formato certo, e para por aí. Nada da replicação, dos readers ou
do failover pode ser praticado aqui, e esta seção é ensinada a partir da documentação da AWS, como diz a
tabela.

## Qual dos dois, e quanto custa

**Para um banco PostgreSQL ou MySQL novo que precisa de standby, o cluster costuma ser a compra melhor**:
faz failover mais rápido, e as cópias trabalham. A instância Multi-AZ continua sendo a única opção para
Oracle, SQL Server, MariaDB e Db2, e para uma versão ou uma classe de instância que o cluster não oferece.

O cluster é cobrado como três instâncias da classe dele, mais o armazenamento e os IOPS provisionados. A
tabela de preços deste curso não imprime nem as classes `db.m6gd` nem o armazenamento `io2`, então esta
seção não cita total. O formato da conta são três máquinas onde a instância Multi-AZ tem duas, contra duas
máquinas que respondem consultas onde a instância Multi-AZ tem uma.
