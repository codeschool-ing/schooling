---
title: Uma instância, criada no moto
version: 1
---

**Uma instância RDS é um servidor de banco de dados: uma máquina da classe que você escolhe, um volume
do tamanho que você escolhe, um engine em cima e um endereço.** Ela mora numa VPC, nas sub-redes que
você indica, atrás de um security group que você escreve. A rede é assunto do `aws-foundations`,
lições 16 e 18; aqui ela são as poucas linhas de que um banco precisa, montadas no moto do jeito que
seriam montadas numa conta de verdade. O moto está rodando no terminal dele, e as quatro linhas de
"O seu laboratório, em resumo" da lição 1 estão digitadas neste.

## A rede em volta dela

Uma VPC, duas sub-redes privadas em duas zonas e dois security groups: um para os servidores da
aplicação e um para o banco, que deixa entrar a porta do PostgreSQL vinda do primeiro e de mais nada:

```sh
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
SUBNET_A=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
SUBNET_B=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.2.0/24 \
  --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
APP_SG=$(aws ec2 create-security-group --group-name quitanda-app \
  --description "Quitanda application servers" --vpc-id "$VPC" --query GroupId --output text)
DB_SG=$(aws ec2 create-security-group --group-name quitanda-db \
  --description "PostgreSQL, from the application servers only" --vpc-id "$VPC" \
  --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$DB_SG" --protocol tcp --port 5432 \
  --source-group "$APP_SG" > /dev/null
```

**A regra nomeia um grupo, não um endereço.** Qualquer servidor do `quitanda-app` alcança a porta 5432,
os dois de hoje e os cinco do mês que vem, e nenhum endereço da internet alcança, porque nenhuma regra
menciona um. Esse é todo o modelo de segurança da rede da instância, e ele é escrito antes de a
instância existir.

Mais duas coisas de que a instância precisa antes de ser criada:

```
ana@laptop:~/aws$ aws rds create-db-subnet-group --db-subnet-group-name quitanda-db --db-subnet-group-description "Quitanda databases, two zones" --subnet-ids $SUBNET_A $SUBNET_B --query "DBSubnetGroup.Subnets[].[SubnetIdentifier,SubnetAvailabilityZone.Name]" --output text
subnet-fe68b8049644ef062	sa-east-1a
subnet-75abdea2d54a47e07	sa-east-1b
ana@laptop:~/aws$ aws rds create-db-parameter-group --db-parameter-group-name quitanda-pg16 --db-parameter-group-family postgres16 --description "Quitanda orders, PostgreSQL 16" --query DBParameterGroup.DBParameterGroupArn
"arn:aws:rds:sa-east-1:123456789012:pg:quitanda-pg16"
```

**Um DB subnet group é a lista de sub-redes em que o RDS pode colocar a instância**, e a AWS exige que
ele cubra pelo menos duas zonas mesmo para uma instância que vive numa só. A segunda zona é onde vai
ficar o standby da lição 7 quando a instância virar Multi-AZ, então o lugar dele fica reservado agora.
O parameter group é o arquivo de configuração do engine, que você não pode editar diretamente; a
seção seguinte é sobre ele, e ele é criado vazio aqui para que a instância já o nomeie na criação.

## A instância

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --db-subnet-group-name quitanda-db --vpc-security-group-ids $DB_SG --db-parameter-group-name quitanda-pg16 --backup-retention-period 7 --no-publicly-accessible --query "DBInstance.[DBInstanceStatus,Endpoint.Address,Endpoint.Port,AvailabilityZone,StorageType]" --output text
available	quitanda-orders.aaaaaaaaaa.sa-east-1.rds.amazonaws.com	5432	sa-east-1a	gp3
```

Cada flag é uma decisão que alguém teria de tomar numa conta de verdade:

| flag | o que ela decide |
|---|---|
| `--engine postgres --engine-version 16` | o engine e a versão principal; o RDS escolhe a secundária |
| `--db-instance-class db.m7g.large` | a máquina: 2 vCPU e 8 GiB de memória, processador Graviton (`g`) |
| `--storage-type gp3 --allocated-storage 100` | um volume SSD de uso geral de 100 GiB |
| `--manage-master-user-password` | o RDS gera a senha e a guarda no Secrets Manager |
| `--no-publicly-accessible` | sem endereço público, então a instância só é alcançável dentro da VPC |
| `--backup-retention-period 7` | sete dias de backups automáticos, de onde a lição 7 restaura |

**A senha nunca passou pelo terminal.** `--master-user-password` também existe, e ele põe a senha no
histórico do shell, na lista de processos enquanto o comando roda e em qualquer script para onde o
comando for copiado. Com `--manage-master-user-password`, o RDS cria um segredo e o rotaciona, e a
aplicação o lê do Secrets Manager com uma role que tem permissão para isso; ninguém digita a senha.

**A classe são três letras e um tamanho.** `db.t4g` é burstable: barata, com créditos de CPU que acabam
sob carga contínua, o que serve para desenvolvimento e para uma loja que fica quieta a maior parte do
dia. `db.m7g` é de uso geral, quatro GiB de memória por vCPU. `db.r7g` é otimizada para memória, oito GiB
por vCPU, para o banco cujo conjunto de trabalho precisa caber na memória. Trocar de classe depois é um
`modify-db-instance` e um reinício, então a primeira escolha é um ponto de partida, não uma sentença.

**O gp3 dá uma linha de base que não depende do tamanho**: 3.000 IOPS e 125 MiB/s abaixo de 400 GiB e,
para a maioria dos engines, 12.000 IOPS e 500 MiB/s a partir de 400 GiB, segundo a documentação da
AWS; mais de qualquer um dos dois pode ser comprado por cima. O gp2, mais antigo, amarrava a velocidade
ao tamanho, três IOPS por GiB, e é por isso que se provisionavam terabytes desnecessários para ter a
velocidade necessária.

## Disponível, e nada ali

```
ana@laptop:~/aws$ date -u +%Y-%m-%dT%H:%M:%S
2026-10-16T15:51:24
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query "DBInstances[0].[DBInstanceStatus,InstanceCreateTime,MasterUserSecret.SecretStatus]" --output text
available	2026-10-16T15:51:24.477955+00:00	active
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-banana --engine postgres --engine-version 16 --db-instance-class db.banana.huge --allocated-storage 100 --master-username quitanda --manage-master-user-password --query "DBInstance.[DBInstanceClass,DBInstanceStatus]" --output text
db.banana.huge	available
```

**`available` no mesmo segundo da criação, e o segredo já `active`.** Na AWS a instância passa por
`creating` e `backing-up` e leva minutos para chegar a `available`, porque uma máquina está sendo
ligada, um volume conectado, um engine inicializado e um primeiro backup feito. Isso não foi rodado
aqui. O moto guardou um registro com os campos preenchidos, e o endpoint dentro dele é um nome que
nenhum servidor de DNS tem: não há PostgreSQL atrás de `quitanda-orders.aaaaaaaaaa.sa-east-1.rds.amazonaws.com`,
na porta 5432 ou em qualquer outra, e nada neste curso se conecta a ele.

**O último comando pediu uma `db.banana.huge`, e o moto criou uma.** A AWS confere a classe contra as
oferecidas para aquele engine, versão e região, e recusa uma classe que não existe. O moto confere se
o engine é um de que ele já ouviu falar, como a seção anterior mostrou, e pouco mais. O que este
laboratório ensina sobre o RDS é o formato das requisições e das respostas; se uma requisição daria
certo na AWS é pergunta para a documentação da AWS, e toda lição que depende dessa diferença diz isso.
