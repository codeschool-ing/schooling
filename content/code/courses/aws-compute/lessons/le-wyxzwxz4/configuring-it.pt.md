---
title: Pondo uma função numa VPC, contra o moto
version: 1
---

Ligar uma função a uma VPC é uma opção do `create-function`, e ela nomeia duas coisas: **as subnets
em que ficam as interfaces de rede da função, e os security groups que elas carregam.** Todo o
resto decorre dessas duas listas, e quase tudo o que dá errado dá errado numa delas. Esta seção
monta a menor rede que mostra o padrão, uma função que vai falar com um banco PostgreSQL em subnets
privadas, e depois lê o que o moto fez disso.

## A rede

A VPC, duas subnets privadas em duas zonas e dois security groups: um para a função e um para o
banco. As lições 16 e 18 de `aws-foundations` explicam cada um deles; aqui eles são só o chão em que
a função pisa. As variáveis de shell guardam os ids que o moto inventa, para os comandos seguintes
poderem usá-los:

```
ana@laptop:~/aws$ VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ A=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ B=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ FN=$(aws ec2 create-security-group --vpc-id $VPC --group-name orders-fn --description "the function" --query GroupId --output text)
ana@laptop:~/aws$ DB=$(aws ec2 create-security-group --vpc-id $VPC --group-name orders-db --description "the database" --query GroupId --output text)
ana@laptop:~/aws$ echo $VPC $A $B $FN $DB
vpc-8c3e928502e59b35a subnet-dfadb89736d4aa1a9 subnet-2703629957a6494c1 sg-3e0f3ea4cf6cf0f8a sg-f697fa39575f20885
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $DB --protocol tcp --port 5432 --source-group $FN --query "SecurityGroupRules[].{Port: FromPort, From: ReferencedGroupInfo.GroupId}"
[
    {
        "Port": 5432,
        "From": "sg-3e0f3ea4cf6cf0f8a"
    }
]
```

O último comando é a regra que importa. **O security group do banco admite a porta 5432 a partir do
security group da função, pelo id, e de nada mais.** Nenhuma faixa de endereços é citada, então a
regra continua valendo quantas interfaces de rede a função vier a ter, e quaisquer que sejam os
endereços delas. O grupo da própria função não precisa de regra de entrada nenhuma, porque nada se
conecta a uma função Lambda pela rede: as requisições chegam a ela pelo próprio serviço do Lambda.

Duas subnets em duas zonas não é enfeite. O Lambda põe os ambientes na subnet da lista que ele
escolher, e uma função listada numa subnet só para quando aquela zona para. A AWS recomenda pelo
menos duas zonas para toda função numa VPC.

## A role precisa de permissões de EC2

Uma função numa VPC precisa de uma role de execução que possa gerenciar interfaces de rede, porque o
Lambda as cria e as apaga na sua conta com a autoridade dessa role. A AWS oferece uma política
gerenciada para isso, a `AWSLambdaVPCAccessExecutionRole`, mas o moto 5.2.3 não a traz, então a
política é escrita aqui. Salve-a como `~/aws/vpc-access.json`:

```schooling-example
{"language": "json", "file": "vpc-access.json", "parts": [{"code": "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n", "note": "Uma política de identidade, presa à role. Ela não nomeia principal: a role a que está presa é o principal."}, {"code": "    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"ec2:CreateNetworkInterface\",\n        \"ec2:DescribeNetworkInterfaces\",\n        \"ec2:DescribeSubnets\",\n        \"ec2:DeleteNetworkInterface\",\n        \"ec2:AssignPrivateIpAddresses\",\n        \"ec2:UnassignPrivateIpAddresses\"\n      ],\n      \"Resource\": \"*\"\n    },\n", "note": "O que o Lambda faz na sua VPC em nome da função: criar as interfaces de rede, encontrá-las e encontrar as subnets de novo, dar endereços a elas e apagá-las quando não forem mais necessárias. O `Resource` é `*` porque as interfaces ainda não existem quando a política é escrita."}, {"code": "    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"logs:CreateLogGroup\",\n        \"logs:CreateLogStream\",\n        \"logs:PutLogEvents\"\n      ],\n      \"Resource\": \"*\"\n    }\n", "note": "Os logs da própria função, de que toda role de Lambda precisa, esteja ela numa VPC ou não."}, {"code": "  ]\n}\n"}]}
```

A política de confiança é a mesma da role da lição 16, e as permissões entram como uma política
inline:

```
ana@laptop:~/aws$ aws iam create-role --role-name orders-vpc-role --query Role.Arn --output text --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
arn:aws:iam::123456789012:role/orders-vpc-role
ana@laptop:~/aws$ aws iam put-role-policy --role-name orders-vpc-role --policy-name vpc-access --policy-document file://vpc-access.json
ana@laptop:~/aws$ aws iam list-role-policies --role-name orders-vpc-role
{
    "PolicyNames": [
        "vpc-access"
    ]
}
```

Na AWS, deixar essas permissões de fora é recusado na hora: o `create-function` falha com uma
`InvalidParameterValueException` dizendo que a role de execução não tem permissão para chamar
`CreateNetworkInterface` no EC2. O moto não avalia a role, então aceitaria a função de qualquer
jeito; as permissões estão aqui porque a AWS as confere, e não porque o moto confira.

## A função

Qualquer handler serve, porque nada nesta lição o invoca. Este é o handler vazio da lição 17, em
`~/aws/bare/app.py`:

```python
# bare/app.py
def handler(event, context):
    return {"ok": True}
```

```
ana@laptop:~/aws$ zip -j orders.zip bare/app.py
  adding: app.py (stored 0%)
ana@laptop:~/aws$ aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-vpc-role --zip-file fileb://orders.zip --vpc-config SubnetIds=$A,$B,SecurityGroupIds=$FN --query VpcConfig
{
    "SubnetIds": [
        "subnet-dfadb89736d4aa1a9",
        "subnet-2703629957a6494c1"
    ],
    "SecurityGroupIds": [
        "sg-3e0f3ea4cf6cf0f8a"
    ],
    "VpcId": "vpc-123abc"
}
```

As subnets e o security group voltaram como foram dados. **O `VpcId` não**: o moto responde
`vpc-123abc`, um valor fixo de enfeite, em vez da `$VPC` a que as subnets pertencem. A AWS descobre a
VPC a partir das subnets e a devolve. Esse é o primeiro sinal de quão pouco o moto confere aqui, e o
próximo é mais claro. Uma subnet e um security group que não existem:

```
ana@laptop:~/aws$ aws lambda create-function --function-name ghost --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-vpc-role --zip-file fileb://orders.zip --vpc-config SubnetIds=subnet-0000000000000000a,SecurityGroupIds=sg-0000000000000000a --query "{Name: FunctionName, State: State}"
{
    "Name": "ghost",
    "State": "Active"
}
```

O moto criou a função. A AWS a recusa, porque procura as subnets e o grupo antes de fazer qualquer
outra coisa. **Uma configuração de VPC que funciona contra o moto provou a sintaxe e nada sobre a
rede**, que é a mesma lição da reserva de 2000 da lição 16.

## Tirando de novo

Uma função sai da VPC recebendo duas listas vazias, e na AWS ela volta a alcançar a internet como
qualquer função fora de uma VPC:

```
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name orders --vpc-config SubnetIds=[],SecurityGroupIds=[] --query VpcConfig
{
    "SubnetIds": [],
    "SecurityGroupIds": []
}
```

O que a AWS faz com as interfaces de rede quando uma função entra ou sai, e por que isso já custou
segundos em todo cold start, é a próxima seção.
