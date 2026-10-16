---
title: An instance, created in moto
version: 1
---

**An RDS instance is one database server: a machine of a class you choose, a volume of a size you
choose, an engine on it, and an address.** It lives in a VPC, in subnets you name, behind a security
group you write. The network is `aws-foundations`' subject, lessons 16 and 18; here it is the few
lines a database needs, built in moto the way it would be built on a real account. moto is running
in its own terminal and the four lines of lesson 1's "Your lab, in brief" are typed in this one.

## The network around it

A VPC, two private subnets in two zones, and two security groups: one for the application servers
and one for the database, which lets in PostgreSQL's port from the first and from nothing else:

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

**The rule names a group, not an address.** Any server in `quitanda-app` may reach port 5432, today's
two and next month's five, and no address on the internet may, because no rule mentions one. That
is the whole security model of the instance's network, and it is written before the instance exists.

Two more things the instance needs before it can be created:

```
ana@laptop:~/aws$ aws rds create-db-subnet-group --db-subnet-group-name quitanda-db --db-subnet-group-description "Quitanda databases, two zones" --subnet-ids $SUBNET_A $SUBNET_B --query "DBSubnetGroup.Subnets[].[SubnetIdentifier,SubnetAvailabilityZone.Name]" --output text
subnet-fe68b8049644ef062	sa-east-1a
subnet-75abdea2d54a47e07	sa-east-1b
ana@laptop:~/aws$ aws rds create-db-parameter-group --db-parameter-group-name quitanda-pg16 --db-parameter-group-family postgres16 --description "Quitanda orders, PostgreSQL 16" --query DBParameterGroup.DBParameterGroupArn
"arn:aws:rds:sa-east-1:123456789012:pg:quitanda-pg16"
```

**A DB subnet group is the list of subnets RDS may place the instance in**, and AWS requires it to
cover at least two zones even for an instance that lives in one. The second zone is where lesson 7's
standby goes when the instance becomes Multi-AZ, so the room for it is booked now. The parameter group
is the engine's configuration file, which you are not allowed to edit directly; the section after
this one is about it, and it is created empty here so the instance can name it from the start.

## The instance

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --db-subnet-group-name quitanda-db --vpc-security-group-ids $DB_SG --db-parameter-group-name quitanda-pg16 --backup-retention-period 7 --no-publicly-accessible --query "DBInstance.[DBInstanceStatus,Endpoint.Address,Endpoint.Port,AvailabilityZone,StorageType]" --output text
available	quitanda-orders.aaaaaaaaaa.sa-east-1.rds.amazonaws.com	5432	sa-east-1a	gp3
```

Every flag is a decision somebody would have to make on a real account:

| flag | what it decides |
|---|---|
| `--engine postgres --engine-version 16` | the engine and its major version; RDS picks the minor one |
| `--db-instance-class db.m7g.large` | the machine: 2 vCPU and 8 GiB of memory, a Graviton (`g`) processor |
| `--storage-type gp3 --allocated-storage 100` | a 100 GiB general-purpose SSD volume |
| `--manage-master-user-password` | RDS generates the password and keeps it in Secrets Manager |
| `--no-publicly-accessible` | no public address, so the instance is reachable only inside the VPC |
| `--backup-retention-period 7` | seven days of automated backups, which lesson 7 restores from |

**The password never touched the terminal.** `--master-user-password` exists too, and it puts the
password in the shell's history, in the process list while the command runs, and in whatever script
the command is copied into. With `--manage-master-user-password`, RDS creates a secret, rotates it,
and the application reads it from Secrets Manager with a role that is allowed to; nobody types it.

**The class is three letters and a size.** `db.t4g` is burstable: cheap, with CPU credits that run out
under sustained load, which suits development and a shop that is quiet most of the day. `db.m7g` is
general purpose, four GiB of memory per vCPU. `db.r7g` is memory-optimised, eight GiB per vCPU, for
the database whose working set has to fit in memory. Changing class later is one
`modify-db-instance` and a restart, so the first choice is a starting point and not a sentence.

**gp3 gives a baseline that does not depend on the size**: 3,000 IOPS and 125 MiB/s below 400 GiB,
and for most engines 12,000 IOPS and 500 MiB/s from 400 GiB up, per AWS's documentation; more of
either can be bought on top. The older gp2 tied its speed to its size, three IOPS per GiB, which
is why people used to provision terabytes they did not need to get the speed they did.

## Available, and nothing there

```
ana@laptop:~/aws$ date -u +%Y-%m-%dT%H:%M:%S
2026-10-16T15:51:24
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query "DBInstances[0].[DBInstanceStatus,InstanceCreateTime,MasterUserSecret.SecretStatus]" --output text
available	2026-10-16T15:51:24.477955+00:00	active
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-banana --engine postgres --engine-version 16 --db-instance-class db.banana.huge --allocated-storage 100 --master-username quitanda --manage-master-user-password --query "DBInstance.[DBInstanceClass,DBInstanceStatus]" --output text
db.banana.huge	available
```

**`available` on the same second it was created, and the secret already `active`.** On AWS the
instance goes through `creating` and `backing-up` and takes minutes to reach `available`, because
a machine is being started, a volume attached, an engine initialised and a first backup taken. That
was not run here. moto stored a record with the fields filled in, and the endpoint in it is a name
no DNS server holds: there is no PostgreSQL behind `quitanda-orders.aaaaaaaaaa.sa-east-1.rds.amazonaws.com`,
on port 5432 or any other, and nothing in this course connects to it.

**The last command asked for a `db.banana.huge`, and moto made one.** AWS checks the class against the
ones offered for that engine, version and region, and refuses a class that does not exist. moto checks
that the engine is one it has heard of, as the section before showed, and not much else. What this
lab teaches about RDS is the shape of the requests and the answers; whether a request would succeed
on AWS is a question for AWS's documentation, and every lesson that depends on the difference says so.
