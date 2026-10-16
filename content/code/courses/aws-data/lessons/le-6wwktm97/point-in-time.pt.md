---
title: Backups automáticos e recuperação para um ponto no tempo
version: 1
---

**Os backups automáticos do RDS são um snapshot diário e um log contínuo, e juntos eles reconstroem o banco
como ele estava em qualquer segundo do período de retenção.** Uma vez por dia, na janela de backup, o RDS
tira um snapshot do volume. Entre um snapshot e outro, ele copia o log de transações do engine para o S3 a
cada cinco minutos. Para restaurar para as 14:32:10 de terça, o RDS pega o último snapshot antes desse
momento e reaplica o log até ele. Isso é a **recuperação para um ponto no tempo**, e é a resposta ao erro
que uma réplica copia fielmente: o `DELETE` sem `WHERE`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Sete dias de backups automáticos, de 10 a 16 de outubro. Um snapshot por dia na janela de backup e, por baixo, um log de transações contínuo copiado para o S3 a cada cinco minutos. O último horário restaurável fica alguns minutos antes de agora. Uma restauração para terça, 13 de outubro, às 14:32 pega o snapshot daquele dia e reaplica o log até 14:32, e o resultado é uma instância nova, quitanda-orders-restored, com endpoint próprio, ao lado da original, que não muda.\" data-fig=\"l07-pitr\"><defs><marker id=\"arr-l07-pitr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">snapshots</text><rect x=\"88.0\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"103.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"170.9\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.9\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11</text><rect x=\"253.7\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"268.7\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12</text><rect x=\"336.6\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"351.6\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13</text><rect x=\"419.4\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"434.4\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14</text><rect x=\"502.3\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"517.3\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15</text><rect x=\"585.1\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.1\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">16</text><text x=\"20.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">log de transações, para o S3 a cada cinco minutos</text><rect x=\"70.0\" y=\"110.0\" width=\"570.0\" height=\"10.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"70.0\" y1=\"140.0\" x2=\"660.0\" y2=\"140.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"70.0\" y1=\"132.0\" x2=\"70.0\" y2=\"148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"70.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">7 dias atrás</text><line x1=\"660.0\" y1=\"104.0\" x2=\"660.0\" y2=\"148.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><text x=\"660.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">agora</text><line x1=\"640.0\" y1=\"104.0\" x2=\"640.0\" y2=\"126.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></line><text x=\"636.0\" y=\"176.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">LatestRestorableTime</text><line x1=\"386.6\" y1=\"52.0\" x2=\"386.6\" y2=\"148.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></line><text x=\"392.6\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ter 13 out, 14:32</text><line x1=\"386.6\" y1=\"150.0\" x2=\"386.6\" y2=\"205.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#arr-l07-pitr)\"></line><rect x=\"236.6\" y=\"212.0\" width=\"300.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"386.6\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda-orders-restored</text><text x=\"386.6\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma instância nova, com endpoint novo</text></svg>", "caption": "Uma restauração reaplica o log sobre o snapshot do dia, até o segundo pedido, e cria com isso uma instância nova.", "same": ["snapshots"]}
```

**A retenção vai de 1 a 35 dias**, e 0 desliga os backups automáticos, e com eles a recuperação para um
ponto no tempo e, como disse a seção anterior, as réplicas de leitura. O momento mais recente para o qual
dá para restaurar é um campo da instância, `LatestRestorableTime`, que a AWS documenta como costumando
ficar dentro dos últimos cinco minutos: o log precisa ter chegado ao S3.

## No moto

A instância da lição 6 num moto vazio, com sete dias de retenção:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query 'DBInstance.[BackupRetentionPeriod,PreferredBackupWindow]' --output text
7	13:14-13:44
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].[InstanceCreateTime,LatestRestorableTime]' --output text
2026-10-16T16:08:45.120830+00:00	2026-10-16T16:08:45.983711+00:00
```

**A janela de backup é uma meia hora que o moto escolheu**, `13:14-13:44` em UTC, que é meio da manhã em São
Paulo. Na AWS, quando você não escolhe a janela, ela também é escolhida para você, dentro de um bloco de oito horas
por região, e uma empresa cuja hora mais calma é às quatro da manhã a põe ali com
`--preferred-backup-window`. O último horário restaurável fica menos de um segundo depois da criação da
instância: no moto, o log está "no S3" na hora, porque não há log.

## Uma restauração é uma instância nova

**É esta a parte que surpreende as pessoas, no dia em que importa.** Uma restauração para um ponto no tempo
não rebobina a instância. Ela cria uma segunda instância, com um nome que você dá e um endpoint próprio, e
deixa a original exatamente como estava:

```
ana@laptop:~/aws$ aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier quitanda-orders --target-db-instance-identifier quitanda-orders-restored --use-latest-restorable-time --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,Endpoint.Address]' --output text
available	quitanda-orders-restored.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,Endpoint.Address]' --output text
quitanda-orders	quitanda-orders.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
quitanda-orders-restored	quitanda-orders-restored.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
```

**Duas instâncias, dois endereços.** A aplicação continua falando com `quitanda-orders`, com as linhas
apagadas ainda apagadas. A cópia restaurada, `quitanda-orders-restored`, tem os dados como eram, num
endpoint diferente, e até alguém agir, ninguém a usa. O que acontece em seguida é uma decisão, e há duas
comuns. Uma é copiar de volta o que se perdeu: consultar a instância restaurada atrás das linhas apagadas e
inseri-las na original, o que mantém tudo o que foi escrito desde o erro. A outra é trocar: apontar a
aplicação para a instância restaurada, ou renomear as duas para a restaurada ficar com o nome antigo, o que
perde tudo o que foi escrito depois do ponto restaurado.

**Indique a rede e a configuração no comando de restauração**, também. Se elas não forem dadas, a AWS
documenta que a instância restaurada sobe com o security group padrão e o parameter group padrão, o que
quer dizer que os servidores da aplicação podem não conseguir alcançá-la, e o `max_connections` volta à
fórmula. Uma restauração ensaiada uma vez, num dia calmo, com os comandos anotados, é a única que dá certo às
três da manhã.

**Uma restauração leva tempo na AWS**, um volume novo construído a partir de um snapshot e um log reaplicado
nele, e o tempo cresce com o tamanho do banco e com a quantidade de log a reaplicar. Nada disso foi rodado
aqui.

## O que o moto deixa passar

```
ana@laptop:~/aws$ aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier quitanda-orders --target-db-instance-identifier quitanda-orders-october --restore-time 2026-10-01T09:00:00-03:00 --query DBInstance.DBInstanceStatus
"available"
ana@laptop:~/aws$ aws rds modify-db-instance --db-instance-identifier quitanda-orders --backup-retention-period 36 --apply-immediately --query DBInstance.BackupRetentionPeriod
36
```

**Uma restauração para o dia primeiro de outubro foi aceita, para uma instância criada no dia dezesseis.** Na
AWS o horário de restauração precisa cair dentro da janela, entre o primeiro horário restaurável e o
`LatestRestorableTime`, e qualquer outro é recusado. E uma retenção de 36 dias foi aceita, onde o máximo da
AWS é 35. Dois números que o moto poderia ter conferido e não conferiu; numa conta de verdade, o primeiro
erro custa uma restauração que falha e o segundo um comando que falha, e os dois saem mais baratos se
aprendidos aqui.

**Backups além da franquia custam 0,095 por GiB-mês**, como a lição 6 calculou. Sete dias de um banco de 100
GiB que muda devagar ficam perto da franquia de 100 GiB; trinta e cinco dias de um que reescreve uma tabela
grande toda noite passam bem dela, porque todo bloco alterado é guardado pela janela inteira.
