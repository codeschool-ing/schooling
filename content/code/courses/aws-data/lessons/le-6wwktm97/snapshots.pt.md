---
title: Snapshots manuais, os backups que ninguém apaga por você
version: 1
---

**Um snapshot manual é uma cópia do volume que o RDS guarda até você apagá-la.** Os backups automáticos
pertencem à instância: saem quando o período de retenção passa por eles e, por padrão, vão embora quando a
instância vai. Um snapshot manual pertence à conta. Ele sobrevive à instância de onde foi tirado, pode ser
copiado para outra região ou compartilhado com outra conta, e é como um banco é guardado por mais de 35
dias: antes de uma migração arriscada, no fim de um ano fiscal ou antes de a instância ser apagada.

**Não é um ponto no tempo que dá para mover.** Um snapshot guarda o volume num momento e nada depois dele;
não há log ao lado para reaplicar. Então um snapshot responde "o banco como era antes da migração", e a
recuperação para um ponto no tempo responde "o banco como era às 14:32". Eles são guardados por motivos
diferentes e custam o mesmo, o preço de backup de 0,095 por GiB-mês além da franquia. O primeiro snapshot de
um volume é uma cópia inteira e os seguintes guardam só os blocos que mudaram, então um snapshot diário de um
banco que muda pouco custa pouco.

## Tirado, guardado, restaurado

A instância da lição 6 mais uma vez, num moto vazio, e um snapshot antes de entrar no ar o novo esquema de
pedidos da Quitanda:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query DBInstance.DBInstanceStatus
"available"
ana@laptop:~/aws$ aws rds describe-db-snapshots --db-instance-identifier quitanda-orders --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotType]' --output text
rds:quitanda-orders-2026-10-16-16-08	automated
ana@laptop:~/aws$ aws rds create-db-snapshot --db-instance-identifier quitanda-orders --db-snapshot-identifier quitanda-orders-before-v2 --query 'DBSnapshot.[DBSnapshotIdentifier,SnapshotType,Status]' --output text
quitanda-orders-before-v2	manual	available
```

**O snapshot automático já estava lá**, com o nome que o RDS dá pela instância e pelo minuto, e o manual fica
ao lado dele com um nome que uma pessoa escolheu. A diferença aparece quando a instância é apagada:

```
ana@laptop:~/aws$ aws rds delete-db-instance --db-instance-identifier quitanda-orders --skip-final-snapshot --query DBInstance.DBInstanceStatus
"deleting"
ana@laptop:~/aws$ aws rds describe-db-snapshots --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotType]' --output text
quitanda-orders-before-v2	manual
```

**O automático foi junto com a instância; o manual ficou.** Esse também é o comportamento documentado da
AWS: apagar uma instância apaga os backups automáticos dela, a menos que você peça para mantê-los, e nunca
toca nos snapshots manuais. Restaurar tem o mesmo formato de uma restauração para um ponto no tempo, uma
instância nova com um endpoint novo:

```
ana@laptop:~/aws$ aws rds restore-db-instance-from-db-snapshot --db-instance-identifier quitanda-orders-v1 --db-snapshot-identifier quitanda-orders-before-v2 --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,Endpoint.Address]' --output text
available	quitanda-orders-v1.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
```

**Na AWS, `delete-db-instance` se recusa a rodar até você indicar um snapshot final com
`--final-db-snapshot-identifier` ou dizer `--skip-final-snapshot` em voz alta**, como fez a exclusão acima. O
moto não insiste, e apagar a cópia restaurada do jeito que alguém arrumando a casa faria mostra isso:

```
ana@laptop:~/aws$ aws rds delete-db-instance --db-instance-identifier quitanda-orders-v1 --query DBInstance.DBInstanceStatus
"deleting"
```

**Na AWS esse comando é um erro; no moto ele apagou a instância sem snapshot nenhum dela.** Então o hábito
precisa vir de você: indique um snapshot final toda vez, a menos que o banco seja um que você ficaria feliz em
perder.

## Os dois jeitos de dar errado

**Snapshots guardados para sempre.** Nada expira um snapshot manual, então um time que tira um antes de cada
release e não apaga nenhum tem, dois anos depois, algumas centenas deles, cada um cobrado todo mês. Uma tag
dizendo por que e até quando, e alguém que leia as tags, sai mais barato que uma linha misteriosa na conta.

**Snapshots nunca restaurados.** Um snapshot que nunca foi restaurado é uma esperança, não um backup.
Restaurar um numa instância nova, rodar algumas consultas nela e apagar a instância é trabalho de uma tarde e
custa algumas horas de instância; é o único teste que prova que o snapshot tem o que todo mundo supõe que ele
tem. O moto não consegue rodar esse teste, porque não guarda dado nenhum, e é a observação certa para fechar
as evidências desta lição: cada restauração aqui produziu um status e um endereço, e nenhuma produziu uma
linha.
