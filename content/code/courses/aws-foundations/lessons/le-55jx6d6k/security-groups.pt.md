---
title: Security groups, com estado e presos à máquina
version: 1
---

**Um security group é uma lista do que pode chegar a uma interface de rede, e do que pode sair dela,
e todo o resto é recusado.** Ele só guarda permissões. Ele fica preso à interface pela qual uma
máquina, um load balancer ou um banco de dados conversa, não à sub-rede. Então duas máquinas lado a
lado numa sub-rede podem ter grupos diferentes. E ele **tem estado** (é stateful): depois que deixa
uma conexão entrar, as respostas dessa conexão saem sem que nenhuma regra precise dizer isso.

A imagem errada é um firewall na borda da sub-rede pelo qual o tráfego passa na entrada. **Um
security group fica em cada interface**, então ele também julga o tráfego entre duas máquinas da
mesma sub-rede, que nenhuma borda vê. O filtro na borda da sub-rede existe também. É a network ACL
da próxima seção, e ela funciona de outro jeito.

## Partindo da lição 17

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia, e reconstrua as lições 16 e 17 com os scripts delas:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh
zone a: nat-99abbf31f5912eafc in public-a, rtb-2f5b255a96df86cac for app-a and data-a
zone b: nat-de872524ebf250fe5 in public-b, rtb-8a1f0f36b3db1cfbe for app-b and data-b
zone c: nat-c69478fa57a3113fe in public-c, rtb-2725b1ebad62ad346 for app-c and data-c
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
```

O segundo comando guarda o id da VPC em `vpc`, como as lições 16 e 17 fizeram.

## O grupo padrão, e um novo

Toda VPC é criada com um security group chamado `default`, que a lição 16 contou, e tudo o que é
lançado sem nomear um grupo fica com ele:

```
ana@laptop:~/aws$ aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc Name=group-name,Values=default --query "SecurityGroups[0].[IpPermissions,IpPermissionsEgress[].IpRanges[].CidrIp]"
[
    [],
    [
        "0.0.0.0/0"
    ]
]
```

O grupo padrão do moto permite toda conexão de saída e nenhuma de entrada. **O grupo padrão da AWS
tem uma regra de entrada a mais.** Ele permite todo tráfego vindo de interfaces que carregam o mesmo
grupo, então máquinas deixadas no padrão se alcançam todas entre si e nada mais as alcança. Essa
regra não apareceu aqui, já que o moto não a cria.

A loja dá a cada camada um grupo próprio, com o nome do que ele guarda: `alb-sg` para o load
balancer que a lição 22 constrói, `app-sg` para as máquinas da aplicação e `db-sg` para o banco de
dados. **Um grupo novo começa sem regra de entrada e com uma regra de saída que permite tudo**, o
que o último comando mostra para o `db-sg`.

```
ana@laptop:~/aws$ alb=$(aws ec2 create-security-group --vpc-id $vpc --group-name alb-sg --description "shop load balancer" --query GroupId --output text)
ana@laptop:~/aws$ app=$(aws ec2 create-security-group --vpc-id $vpc --group-name app-sg --description "shop application" --query GroupId --output text)
ana@laptop:~/aws$ db=$(aws ec2 create-security-group --vpc-id $vpc --group-name db-sg --description "shop database" --query GroupId --output text)
ana@laptop:~/aws$ echo $alb $app $db
sg-17bcf95982f6b62d7 sg-b38ebe462f6b33d5c sg-021d9b87ab0d8153d
ana@laptop:~/aws$ aws ec2 describe-security-group-rules --filters Name=group-id,Values=$db --query "SecurityGroupRules[].[IsEgress,IpProtocol,CidrIpv4]" --output text
True	-1	0.0.0.0/0
```

## Regras que nomeiam um grupo em vez de um endereço

O load balancer recebe HTTPS de qualquer lugar, então a regra dele nomeia o intervalo `0.0.0.0/0`.
As duas regras seguintes fazem algo que um endereço não consegue: **a origem é outro security
group**. O `app-sg` deixa entrar a porta 8080 de qualquer interface que carregue o `alb-sg`, e o
`db-sg` deixa entrar a porta 5432 do PostgreSQL de qualquer interface que carregue o `app-sg`.

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

**Uma referência sobrevive a tudo a que um endereço não sobrevive.** As máquinas da aplicação vêm e
vão conforme a loja escala, e os endereços delas mudam a cada vez. O load balancer acrescenta
interfaces em zonas novas. Uma regra que nomeia `alb-sg` continua significando "o load balancer"
através de tudo isso. Uma regra que nomeasse `10.20.0.0/20` continuaria significando "o que tiver um
endereço em `public-a`". Isso inclui o NAT gateway e qualquer coisa que alguém lance ali no ano que
vem.

O último comando tirou a regra de saída do `db-sg`. **Um banco de dados não abre conexão nenhuma por
conta própria**, então não precisa de uma. As respostas às consultas da aplicação continuam saindo,
porque o grupo tem estado. Tirá-la quer dizer que um banco de dados que alguém engane para chamar
para fora não alcança nada.

## Lendo as regras de volta

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

Cada linha é uma regra com id próprio, `sgr-…`, que o `revoke-security-group-ingress` pode nomear
para tirar exatamente aquela regra. A primeira coluna é o grupo, e a última é a origem. É
`0.0.0.0/0` para o load balancer, e para os outros dois **o id do grupo em que eles confiam**: a
corrente `alb-sg` para `app-sg` para `db-sg` em três linhas. O último comando acrescenta a mesma
regra duas vezes, e o moto a recusa como a AWS recusa.

**Não há como escrever uma negação aqui.** Um security group só sabe permitir, então "todo mundo
menos `198.51.100.7`" não se diz num deles. Isso é trabalho da network ACL. Por padrão a AWS também
limita um grupo a 60 regras de entrada e 60 de saída, e uma interface a cinco grupos. As duas são
cotas que podem ser aumentadas, e nenhuma foi alcançada aqui.
