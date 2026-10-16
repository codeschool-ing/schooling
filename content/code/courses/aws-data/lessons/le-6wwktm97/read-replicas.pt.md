---
title: Réplicas de leitura, as cópias que correm atrás
version: 1
---

**Uma réplica de leitura é uma instância separada que reaplica as mudanças do primário depois de elas
serem confirmadas.** Ela tem endpoint próprio, responde consultas e está sempre um pouco atrás: o primário
confirma, responde à aplicação e só então envia a mudança para a réplica, que a aplica quando ela chega.
Esse intervalo é o **atraso da réplica**, e é a única propriedade de uma réplica em torno da qual todo uso
dela precisa ser projetado.

**A ideia errada é que uma réplica é um backup, ou um standby.** Ela não é nenhum dos dois. Um `DELETE`
sem `WHERE` no primário é reaplicado na réplica um instante depois, fielmente, então a réplica não protege
nada contra um erro; é para isso que servem os backups da próxima seção. E como a replicação é
assíncrona, uma réplica pode estar sem as últimas transações quando o primário morre, então promovê-la é
uma decisão de aceitar essa perda. O Multi-AZ, síncrono, não perde nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma escrita, no tempo da esquerda para a direita, em quatro faixas: a aplicação, o primário em sa-east-1a, o standby Multi-AZ em sa-east-1b e uma réplica de leitura. A aplicação envia COMMIT; o primário grava no standby, o standby confirma, e só então o primário responde OK. Depois do OK, o primário envia a mudança para a réplica de leitura, que a aplica mais tarde. O intervalo entre o OK e a réplica aplicar a mudança é o atraso da réplica.\" data-fig=\"l07-sync\"><defs><marker id=\"arr-l07-sync\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aplicação</text><line x1=\"170.0\" y1=\"50.0\" x2=\"700.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primário, sa-east-1a</text><line x1=\"170.0\" y1=\"105.0\" x2=\"700.0\" y2=\"105.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">standby, sa-east-1b</text><line x1=\"170.0\" y1=\"160.0\" x2=\"700.0\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20.0\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">réplica de leitura</text><line x1=\"170.0\" y1=\"215.0\" x2=\"700.0\" y2=\"215.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"190.0\" y1=\"50.0\" x2=\"228.0\" y2=\"101.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"200.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"240.0\" y1=\"105.0\" x2=\"278.0\" y2=\"156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><line x1=\"290.0\" y1=\"160.0\" x2=\"328.0\" y2=\"109.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><line x1=\"340.0\" y1=\"105.0\" x2=\"378.0\" y2=\"54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"392.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OK</text><text x=\"285.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">síncrono: o OK espera</text><line x1=\"420.0\" y1=\"105.0\" x2=\"588.0\" y2=\"211.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"505.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">assíncrono: enviado depois do OK</text><circle cx=\"596.0\" cy=\"215.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"610.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aplicado</text><line x1=\"384.0\" y1=\"240.0\" x2=\"384.0\" y2=\"252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"596.0\" y1=\"240.0\" x2=\"596.0\" y2=\"252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"384.0\" y1=\"246.0\" x2=\"596.0\" y2=\"246.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"490.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atraso da réplica</text><line x1=\"384.0\" y1=\"54.0\" x2=\"384.0\" y2=\"240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 2\"></line><text x=\"690.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "O Multi-AZ espera o standby antes de dizer OK; a réplica de leitura só fica sabendo da escrita depois.", "same": ["standby, sa-east-1b"]}
```

## Para que serve uma réplica

**Leituras que podem estar um instante velhas.** Os analistas da Quitanda rodam relatórios às nove da
manhã que leem um mês de pedidos. No primário, esses relatórios disputam com os checkouts da loja o mesmo
cache e o mesmo disco. Numa réplica, não disputam com ninguém. Um relatório dois segundos atrás da loja vai
bem. Um cliente que faz um pedido e depois vê "nenhum pedido ainda" na página que lê uma réplica não vai, e
é por isso que a página em que um cliente acabou de escrever lê do primário.

**Até 15 réplicas por primário para PostgreSQL, MySQL e MariaDB**, como a AWS documenta, cada uma cobrada
como uma instância da sua classe, com armazenamento próprio. Uma réplica pode ter uma classe menor que a do
primário, mas uma pequena demais para acompanhar as escritas do primário fica mais para trás a cada hora,
e o atraso cresce em vez de oscilar.

A instância da lição 6, recriada num moto vazio sem a rede dela, e uma réplica para os relatórios:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query DBInstance.DBInstanceStatus
"available"
ana@laptop:~/aws$ aws rds create-db-instance-read-replica --db-instance-identifier quitanda-orders-reports --source-db-instance-identifier quitanda-orders --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,ReadReplicaSourceDBInstanceIdentifier,Endpoint.Address]' --output text
available	quitanda-orders	quitanda-orders-reports.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'
[
    "quitanda-orders-reports"
]
```

## O atraso que o moto não consegue ter

**Na AWS, o atraso é uma métrica**, `ReplicaLag` no CloudWatch, em segundos, e a réplica informa o estado
da replicação em `StatusInfos`. Um alarme na primeira é como um time descobre que a importação noturna está
ultrapassando a réplica antes que os analistas descubram:

```
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders-reports --query 'DBInstances[0].StatusInfos'
null
ana@laptop:~/aws$ aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name ReplicaLag --dimensions Name=DBInstanceIdentifier,Value=quitanda-orders-reports --start-time 2026-10-16T00:00:00Z --end-time 2026-10-17T00:00:00Z --period 60 --statistics Maximum
{
    "Label": "ReplicaLag",
    "Datapoints": []
}
```

**Nada nas duas respostas, porque nada está replicando.** O moto não guarda dado nenhum em nenhuma das
instâncias, então não há atraso para medir nem estado para informar; na AWS o `StatusInfos` traria uma
entrada `read replication` com o status dela, e a métrica um ponto por minuto. O atraso da figura acima foi
desenhado a partir de como a replicação assíncrona funciona, não deste laboratório.

## Promoção

**Promover uma réplica corta o vínculo e a torna uma instância independente, que aceita escrita.** É assim
que uma réplica vira o novo primário depois de um desastre que o standby Multi-AZ não cobria, e assim que
uma cópia da produção vira um banco próprio para o ensaio de uma migração. Não pode ser desfeito: a
instância promovida não segue mais nada, e o primário antigo não aprende a segui-la.

```
ana@laptop:~/aws$ aws rds promote-read-replica --db-instance-identifier quitanda-orders-reports --query 'DBInstance.[DBInstanceStatus,ReadReplicaSourceDBInstanceIdentifier]' --output text
available	quitanda-orders
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'
[
    "quitanda-orders-reports"
]
```

**Na AWS, a instância promovida não teria mais origem, e a lista de réplicas do primário estaria vazia.** O
moto não marcou nada: a instância promovida ainda diz `quitanda-orders` como origem, e a origem ainda a
lista. O comando é aceito e o significado dele não é modelado, que é o padrão desta lição inteira.

## Em outra região

**Uma réplica pode morar em outra região**, para um desastre que derruba São Paulo ou para ler perto de
clientes em outro continente. A requisição é feita na região de destino e indica a origem pelo ARN:

```
ana@laptop:~/aws$ aws rds create-db-instance-read-replica --db-instance-identifier quitanda-orders-dr --source-db-instance-identifier arn:aws:rds:sa-east-1:123456789012:db:quitanda-orders --region us-east-1 --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceArn,AvailabilityZone]' --output text
arn:aws:rds:us-east-1:123456789012:db:quitanda-orders-dr	sa-east-1a
```

**O ARN diz `us-east-1` e a zona diz `sa-east-1a`**, uma réplica na Virgínia sentada numa zona de São
Paulo. O moto montou o nome para uma região e copiou a posição da outra; na AWS a zona seria uma das da
Virgínia. E na AWS a cópia custa um dinheiro que uma réplica na mesma região não custa: o tráfego de
replicação sai de São Paulo, e o bloco de transferência dá o preço:

```
ana@laptop:~/aws$ python3 prices.py transfer
AWS public price list, sa-east-1, USD, excluding tax

Data transfer out of sa-east-1, USD per GB
  to the internet, first 10 TB                          0.15000  GB
  to the internet, next 40 TB                           0.13800  GB
  to the internet, next 100 TB                          0.12600  GB
  to the internet, over 150 TB                          0.11400  GB
  between zones, each direction                         0.01000  GB
  to us-east-1                                          0.13800  GB
  to CloudFront                                         0.00000  GB
  in from the internet                                  0.00000  GB
```

**0,138 por GB para us-east-1.** O que atravessa é o write-ahead log do primário, tudo o que ele escreve, não
o tamanho do banco. Um primário que escreve 300 GB de log num mês paga 300 × 0,138 = 41,40 pela
transferência, além da instância e do armazenamento da réplica na Virgínia, que têm preço pela lista da
Virgínia e não por esta tabela. Dentro de uma região, a AWS não documenta cobrança pelo tráfego de
replicação entre um primário e as réplicas dele.

## Uma condição que o moto não confere

**Na AWS, uma réplica só pode ser criada de uma instância com backups automáticos ligados**, um período de
retenção de pelo menos um dia, porque a réplica é construída a partir de um backup e do log do primário. O
moto não confere:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-scratch --engine postgres --engine-version 16 --db-instance-class db.t4g.micro --allocated-storage 20 --master-username quitanda --manage-master-user-password --backup-retention-period 0 --query DBInstance.BackupRetentionPeriod
0
ana@laptop:~/aws$ aws rds create-db-instance-read-replica --db-instance-identifier quitanda-scratch-copy --source-db-instance-identifier quitanda-scratch --query DBInstance.DBInstanceStatus
"available"
```

O primeiro comando desligou os backups e o segundo criou uma réplica mesmo assim. Na AWS o segundo é
recusado. A próxima seção é o que são esses backups.
