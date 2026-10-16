---
title: Multi-AZ, um standby que você não lê
version: 1
---

**Uma instância Multi-AZ são duas instâncias em duas zonas, uma das quais você nunca vê.** O primário
recebe toda leitura e toda escrita. O standby, em outra zona, recebe toda escrita de forma síncrona: uma
transação só é confirmada quando está nos dois volumes. Se o primário falha, o RDS aponta o endereço da
instância para o standby, e a aplicação se reconecta ao mesmo nome e encontra os mesmos dados. O standby
não é uma réplica que você consulta, e não deixa nada mais rápido. É um seguro, e custa o que a
instância custa.

**A ideia errada é que o Multi-AZ serve para escalar.** Não serve: o standby não aceita conexões, então
um banco lento numa instância é exatamente tão lento numa Multi-AZ, e um pouco mais lento para confirmar,
porque todo commit agora espera uma segunda zona responder. Ele serve para o dia em que uma zona fica sem
energia, um host falha ou o RDS aplica patch no sistema operacional. A AWS documenta que nesses casos o
failover é automático e costuma terminar em 60 a 120 segundos. Esse tempo é da AWS, não deste
laboratório; nada no moto faz failover, como mostra a segunda metade desta seção.

## O que acontece num failover

Na AWS, na ordem que a documentação dá, o primário para de responder, ou o RDS decide mudar. O standby,
que já tem toda transação confirmada, é promovido. O nome DNS da instância,
`quitanda-orders.….rds.amazonaws.com`, passa a apontar para o endereço do standby, e um novo standby é
construído na zona onde estava o primário antigo. **O endereço não muda. O que está atrás dele muda.**

Então o trabalho do lado da aplicação é se reconectar. Toda conexão aberta com o primário antigo cai, as
transações em andamento são desfeitas, e o cliente precisa abrir conexões novas para o mesmo nome. Um
driver que tenta de novo vai bem. Uma aplicação que resolveu o nome uma vez ao subir e guardou o endereço
para sempre continua batendo numa máquina que já não existe. É por isso que a AWS recomenda um cache de
DNS de menos de um minuto para clientes do RDS, e por isso o padrão do runtime do Java, que pode guardar
para sempre, é o culpado de sempre.

## No moto

O moto está rodando no terminal dele, e as quatro linhas de "O seu laboratório, em resumo" da lição 1
estão digitadas neste. A instância é a da lição 6, sem a rede em volta, de que esta lição não precisa, e
com uma flag a mais:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --multi-az --query 'DBInstance.[DBInstanceStatus,MultiAZ,AvailabilityZone,SecondaryAvailabilityZone]' --output text
available	True	sa-east-1a	None
```

**`MultiAZ` é `True`, e `SecondaryAvailabilityZone` é `None`.** Na AWS esse campo diz a zona do standby,
`sa-east-1b` ou `sa-east-1c`, porque há um standby e ele está em algum lugar. O moto registra a flag e não
constrói nada. Forçar um failover, que na AWS é o jeito de ensaiar um, mostra a mesma coisa pelo outro
lado:

```
ana@laptop:~/aws$ aws rds reboot-db-instance --db-instance-identifier quitanda-orders --force-failover --query 'DBInstance.[DBInstanceStatus,AvailabilityZone]' --output text
available	sa-east-1a
ana@laptop:~/aws$ aws rds describe-events --source-type db-instance --source-identifier quitanda-orders --query 'Events[].Message'
[
    "DB instance created",
    "Backing up DB instance",
    "Finished DB instance backup"
]
```

**O reboot foi aceito, a zona não mudou, e os eventos da instância dizem que nada aconteceu.** Na AWS, um
reboot com failover leva o primário para a zona do standby, então o segundo campo mostraria a outra zona
depois, e os eventos da instância registrariam o início e o fim do failover. Ensaiar isso numa conta de
verdade antes do dia em que for preciso é o único jeito de saber quanto tempo a *sua* aplicação leva para
se reconectar, que é o número que importa, e é um número que o moto não consegue produzir.

## Quanto custa

O bloco RDS da tabela de preços tem as duas linhas, porque uma instância Multi-AZ tem preço de implantação
própria:

```
ana@laptop:~/aws$ python3 prices.py rds
AWS public price list, sa-east-1, USD, excluding tax

RDS, USD per hour
  PostgreSQL, db.m7g.large, Single-AZ                   0.22100  hour
  MySQL, db.m7g.large, Single-AZ                        0.22100  hour
  MariaDB, db.m7g.large, Single-AZ                      0.22100  hour
  PostgreSQL, db.m7g.large, Multi-AZ                    0.44200  hour
  PostgreSQL, db.t4g.micro, Single-AZ                   0.03400  hour
  SQL Server Standard, db.m6i.large, licence in         1.08700  hour

RDS storage and backup, USD per GB-month
  gp3, Single-AZ                                        0.21900  GB-month
  gp3, Multi-AZ                                         0.43800  GB-month
  backup beyond the free allowance                      0.09500  GB-month
```

**Tudo dobra.** A instância é 0,442 por hora contra 0,221, e o armazenamento 0,438 por GiB-mês contra
0,219, porque há uma segunda máquina e um segundo volume. Para a `db.m7g.large` da Quitanda com 100 GiB,
a conta da lição 6 dá 366,46 por mês contra 183,23. A diferença é 183,23 por mês, ou 2.198,76 por ano, e
se vale a pena pagá-la é uma pergunta sobre a loja, não sobre o banco: quanto custa à Quitanda uma hora
sem pedidos numa sexta à noite?
