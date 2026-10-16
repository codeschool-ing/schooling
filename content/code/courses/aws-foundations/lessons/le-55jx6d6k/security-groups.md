---
title: Security groups, stateful and attached to the machine
version: 1
---

**A security group is a list of what may arrive at a network interface, and of what may leave it,
and everything else is refused.** It holds only allows. It is attached to the interface a machine, a
load balancer or a database talks through, not to the subnet. So two machines side by side in one
subnet can have different groups. And it is **stateful**: once it lets a connection in, the replies
to that connection go out without any rule having to say so.

The wrong picture is a firewall at the edge of the subnet that traffic passes on its way in. **A
security group sits on each interface**, so it also judges traffic between two machines in the same
subnet, which no edge ever sees. The filter at the subnet's edge exists too. It is the network ACL
of the next section, and it works differently.

## Starting from lesson 17

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS, and rebuild lessons 16 and 17 with their scripts:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh
zone a: nat-99abbf31f5912eafc in public-a, rtb-2f5b255a96df86cac for app-a and data-a
zone b: nat-de872524ebf250fe5 in public-b, rtb-8a1f0f36b3db1cfbe for app-b and data-b
zone c: nat-c69478fa57a3113fe in public-c, rtb-2725b1ebad62ad346 for app-c and data-c
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
```

The second command keeps the VPC's id in `vpc`, as lessons 16 and 17 did.

## The default group, and a new one

Every VPC is created with a security group called `default`, which lesson 16 counted, and anything
launched without naming a group gets it:

```
ana@laptop:~/aws$ aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc Name=group-name,Values=default --query "SecurityGroups[0].[IpPermissions,IpPermissionsEgress[].IpRanges[].CidrIp]"
[
    [],
    [
        "0.0.0.0/0"
    ]
]
```

moto's default group allows every outbound connection and no inbound one. **AWS's default group has
one inbound rule more.** It allows all traffic from interfaces that carry the same group, so
machines left on the default can all reach one another and nothing else can reach them. That rule
was not seen here, since moto does not create it.

The shop gives each tier a group of its own, named for what it guards: `alb-sg` for the load
balancer that lesson 22 builds, `app-sg` for the application machines and `db-sg` for the database.
**A new group starts with no inbound rule and one outbound rule allowing everything**, which the
last command shows for `db-sg`.

```
ana@laptop:~/aws$ alb=$(aws ec2 create-security-group --vpc-id $vpc --group-name alb-sg --description "shop load balancer" --query GroupId --output text)
ana@laptop:~/aws$ app=$(aws ec2 create-security-group --vpc-id $vpc --group-name app-sg --description "shop application" --query GroupId --output text)
ana@laptop:~/aws$ db=$(aws ec2 create-security-group --vpc-id $vpc --group-name db-sg --description "shop database" --query GroupId --output text)
ana@laptop:~/aws$ echo $alb $app $db
sg-17bcf95982f6b62d7 sg-b38ebe462f6b33d5c sg-021d9b87ab0d8153d
ana@laptop:~/aws$ aws ec2 describe-security-group-rules --filters Name=group-id,Values=$db --query "SecurityGroupRules[].[IsEgress,IpProtocol,CidrIpv4]" --output text
True	-1	0.0.0.0/0
```

## Rules that name a group instead of an address

The load balancer takes HTTPS from anywhere, so its rule names the range `0.0.0.0/0`. The next two
rules do something an address cannot: **the source is another security group**. `app-sg` lets in
port 8080 from any interface that carries `alb-sg`, and `db-sg` lets in PostgreSQL's port 5432 from
any interface that carries `app-sg`.

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $alb --protocol tcp --port 443 --cidr 0.0.0.0/0 --query "SecurityGroupRules[0].[IsEgress,FromPort,CidrIpv4]" --output text
False	443	0.0.0.0/0
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $app --protocol tcp --port 8080 --source-group $alb --query "SecurityGroupRules[0].[IsEgress,FromPort,ReferencedGroupInfo.GroupId]" --output text
False	8080	sg-17bcf95982f6b62d7
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $db --protocol tcp --port 5432 --source-group $app --query "SecurityGroupRules[0].[IsEgress,FromPort,ReferencedGroupInfo.GroupId]" --output text
False	5432	sg-b38ebe462f6b33d5c
ana@laptop:~/aws$ aws ec2 revoke-security-group-egress --group-id $db --protocol all --cidr 0.0.0.0/0
{
    "Return": true
}
```

**A reference survives everything an address does not.** The application machines come and go as the
shop scales, and their addresses change every time. The load balancer adds interfaces in new zones.
A rule naming `alb-sg` keeps meaning "the load balancer" through all of it. A rule naming
`10.20.0.0/20` would keep meaning "whatever happens to have an address in `public-a`". That includes
the NAT gateway and anything somebody launches there next year.

The last command removed `db-sg`'s outbound rule. **A database opens no connection of its own**, so
it needs none. The replies to the application's queries still leave, because the group is stateful.
Removing it means that a database somebody tricks into calling out reaches nothing.

## Reading the rules back

```
ana@laptop:~/aws$ aws ec2 describe-security-group-rules --filters Name=group-id,Values=$alb,$app,$db --query "SecurityGroupRules[].[GroupId,IsEgress,IpProtocol,FromPort,CidrIpv4 || ReferencedGroupInfo.GroupId]" --output text
sg-17bcf95982f6b62d7	True	-1	-1	0.0.0.0/0
sg-17bcf95982f6b62d7	False	tcp	443	0.0.0.0/0
sg-b38ebe462f6b33d5c	True	-1	-1	0.0.0.0/0
sg-b38ebe462f6b33d5c	False	tcp	8080	sg-17bcf95982f6b62d7
sg-021d9b87ab0d8153d	False	tcp	5432	sg-b38ebe462f6b33d5c
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $alb --protocol tcp --port 443 --cidr 0.0.0.0/0

aws: [ERROR]: An error occurred (InvalidPermission.Duplicate) when calling the AuthorizeSecurityGroupIngress operation: The specified rule already exists
```

Each line is one rule with an id of its own, `sgr-…`, which `revoke-security-group-ingress` can name
to remove exactly that rule. The first column is the group, and the last is the source. That is
`0.0.0.0/0` for the load balancer, and for the other two **the id of the group they trust**: the
chain `alb-sg` to `app-sg` to `db-sg` in three lines. The last command adds the same rule twice, and
moto refuses it as AWS does.

**There is no way to write a deny here.** A security group can only allow, so "everybody except
`198.51.100.7`" cannot be said in one. That is the network ACL's job. By default AWS also limits a
group to 60 inbound and 60 outbound rules, and an interface to five groups. Both are quotas that can
be raised, and neither was reached here.
