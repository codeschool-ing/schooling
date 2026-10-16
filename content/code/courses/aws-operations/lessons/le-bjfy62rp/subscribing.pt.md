---
title: Assinando, num laboratório em que não custa nada
version: 1
---

**Leia isto primeiro: numa conta real, o comando desta seção compromete a organização da conta com 3.000
USD por mês por um ano, e não pode ser cancelado.** No moto, é uma linha na memória. Essa diferença é o
motivo de este curso ser praticado no moto, e o motivo desta seção existir: ver o que é a assinatura, como
dados, sem pagar por ela.

O que proteger é o balanceador da loja, feito como na lição 15, em `~/aws/shield`:

```sh
mkdir -p ~/aws/shield && cd ~/aws/shield
VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
A=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
B=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop --subnets $A $B --query 'LoadBalancers[0].DNSName' --output text
```

## Antes, e depois

Uma conta só com o Shield Standard não tem assinatura a descrever:

```
ana@laptop:~/aws/shield$ LB=$(aws elbv2 describe-load-balancers --names shop --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws/shield$ aws shield describe-subscription

aws: [ERROR]: An error occurred (ResourceNotFoundException) when calling the DescribeSubscription operation: The subscription does not exist.
```

Depois, o comando, que no moto não cobra nada:

```
ana@laptop:~/aws/shield$ aws shield create-subscription
ana@laptop:~/aws/shield$ aws shield describe-subscription --query 'Subscription.[StartTime,EndTime,TimeCommitmentInSeconds,AutoRenew]' --output text
2026-10-16T16:19:00	2027-10-16T16:19:00	31536000	ENABLED
```

A segunda linha são os termos da assinatura. Começa agora, termina em um ano, o compromisso é de
**31.536.000 segundos**, que são 365 dias, e ela **se renova sozinha** a menos que alguém desligue isso.
Com uma assinatura, um recurso é protegido ao ser nomeado:

```
ana@laptop:~/aws/shield$ aws shield create-protection --name shop-alb --resource-arn $LB
{
    "ProtectionId": "94c399d2-bd42-40f5-a501-2d086bdf60c2"
}
ana@laptop:~/aws/shield$ aws shield list-protections --query 'Protections[].[Name,ResourceArn]' --output text
shop-alb	arn:aws:elasticloadbalancing:sa-east-1:123456789012:loadbalancer/app/shop/9c657181d428d45b
```

Uma proteção é por recurso, e a assinatura permite um número delas por tipo. Na AWS, cada balanceador,
distribuição ou endereço protegido também começa a pagar a linha de transferência de dados da última
seção. O moto aceitou uma proteção aqui; ele também aceita uma antes de existir qualquer assinatura, o que
a AWS não faz.

## O que não dá para fazer, no laboratório ou fora dele

```
ana@laptop:~/aws/shield$ aws shield delete-subscription 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the DeleteSubscription operation (reached max retries: 2): <!doctype html>
ana@laptop:~/aws/shield$ aws shield list-attacks 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the ListAttacks operation (reached max retries: 2): <!doctype html>
```

Os dois são 500 do moto, e representam coisas diferentes na AWS. `list-attacks` funciona lá, e é como uma
equipe vê os ataques que o Shield detectou nos seus recursos protegidos, com início, fim e vetores; o moto
não guarda ataques. `delete-subscription` é o que importa: **a AWS não deixa uma assinatura ser cancelada
durante o seu ano**. O que pode mudar é a renovação, com `update-subscription --auto-renew DISABLED`, para
ela acabar no fim do ano em vez de continuar. O jeito de experimentar o Shield Advanced é este laboratório,
ou uma organização que já decidiu comprá-lo.
