---
title: "Clusters e capacidade: onde as tasks caem"
version: 1
---

A palavra cluster sugere um conjunto de máquinas, e no ECS essa é a parte opcional. **Um cluster
do ECS é um nome ao qual tasks e serviços pertencem, mais a capacidade que você tiver dado a ele
para rodá-los.** Criado sozinho, ele não tem capacidade nenhuma:

```
ana@laptop:~/aws$ aws ecs create-cluster --cluster-name shop --query "cluster.[clusterName,status,registeredContainerInstancesCount]" --output text
shop	ACTIVE	0
ana@laptop:~/aws$ AMI=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-ecs-hvm-*-x86_64" --query "sort_by(Images,&Name)[-1].ImageId" --output text)
ana@laptop:~/aws$ aws ec2 describe-images --image-ids "$AMI" --query "Images[0].Name" --output text
al2023-ami-ecs-hvm-2023.0.20260226-kernel-6.1-x86_64
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id "$AMI" --instance-type m7i.large --user-data "#!/bin/bash
echo ECS_CLUSTER=shop >> /etc/ecs/ecs.config" --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ecs register-container-instance --cluster shop --instance-identity-document "{\"instanceId\":\"$ID\",\"availabilityZone\":\"sa-east-1a\"}" --query "containerInstance.[ec2InstanceId,status]" --output text
i-963ce1d38adfdbbb0	ACTIVE
ana@laptop:~/aws$ CI=$(aws ecs list-container-instances --cluster shop --query "containerInstanceArns[0]" --output text)
ana@laptop:~/aws$ aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].remainingResources[?name==\`CPU\`||name==\`MEMORY\`].[name,integerValue]" --output text
CPU	4096
MEMORY	7482
```

O `0` na primeira linha é o número de container instances registradas. O resto do bloco dá uma a
ele, e cada passo é um que acontece na AWS.

## Capacidade EC2: instâncias que entraram

Uma **container instance** é uma instância EC2 comum rodando o agente do ECS, um programa que
conversa com o ECS, inicia e para contêineres pelo Docker e informa o que a instância ainda tem. A
AWS publica AMIs otimizadas para ECS com o agente e o Docker já instalados, e o catálogo do moto
traz os nomes delas, que é como o bloco achou uma.

A instância descobre em que cluster entrar por uma única linha em `/etc/ecs/ecs.config`, escrita
pelo user data no primeiro boot, o mecanismo da aula 7. Sem ela o agente entra num cluster chamado
`default`. A instância também precisa de um instance profile cuja role deixe o agente se registrar
e buscar trabalho; a política gerenciada da AWS para isso é `AmazonEC2ContainerServiceforEC2Role`,
e a aula 10 de `aws-foundations` é onde os instance profiles foram associados.

**Na AWS o próprio agente chama o `register-container-instance`, no momento em que começa.** O moto
não roda agente, então o bloco fez essa chamada à mão, com o documento de identidade que o agente
teria enviado. Isso é encenado; tudo o que vem depois é o que o ECS guarda.

Os recursos que ela informou são do moto: 4.096 unidades de CPU e 7.482 MiB. Uma `m7i.large` tem 2
vCPUs, que o agente registra como 2.048 unidades, e 8 GiB, dos quais ele registra um pouco menos que
tudo, porque o sistema operacional e o agente ficam com uma parte. **A aritmética do posicionamento
é a mesma nos dois casos**: uma task cabe numa instância se o que ela pede é menos do que sobra.

## Uma porta também é recurso

A definição de task fixou o `hostPort` em 8080. Uma task o pegou; uma segunda pediu a mesma porta
na mesma instância:

```
ana@laptop:~/aws$ aws ecs run-task --cluster shop --task-definition web --query "{tasks: length(tasks), failures: failures}"
{
    "tasks": 0,
    "failures": []
}
ana@laptop:~/aws$ aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].remainingResources[?name==\`PORTS\`].stringSetValue[]" --output text
22	2376	2375	51678	51679	8080
```

O moto não posicionou nada, não devolveu falha nenhuma e lista a 8080 entre as portas reservadas da
instância. **Na AWS a mesma chamada responde com uma falha cujo motivo é `RESOURCE:PORTS`**, o jeito
do agendador dizer que a única instância com espaço estava com a porta ocupada. Esse é o custo de
uma porta fixa no host: uma cópia por instância, por mais CPU e memória que sobrem. Pôr o `hostPort`
em `0` deixa o Docker escolher uma porta livre para cada task, e o target group de um balanceador
de carga, que o ECS mantém atualizado com a porta de cada task, é como o tráfego ainda acha todas.

## Capacity providers

Registrar instâncias à mão não escala, e decidir que task vai para onde também não. Um **capacity
provider** é uma fonte nomeada de capacidade da qual um cluster pode tirar. Há três tipos:
`FARGATE`, `FARGATE_SPOT` e um que você cria a partir de um grupo de auto scaling de container
instances, montado como a aula 4 monta grupos:

```
ana@laptop:~/aws$ ASG=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ecs-web --query "AutoScalingGroups[0].AutoScalingGroupARN" --output text)
ana@laptop:~/aws$ aws ecs create-capacity-provider --name ecs-web --auto-scaling-group-provider "autoScalingGroupArn=$ASG,managedScaling={status=ENABLED,targetCapacity=90},managedTerminationProtection=DISABLED" --query "capacityProvider.[name,status,autoScalingGroupProvider.managedScaling.targetCapacity]" --output text
ecs-web	ACTIVE	90
ana@laptop:~/aws$ aws ecs put-cluster-capacity-providers --cluster shop --capacity-providers ecs-web FARGATE FARGATE_SPOT --default-capacity-provider-strategy capacityProvider=ecs-web,base=1,weight=1 --query "cluster.[capacityProviders,defaultCapacityProviderStrategy]"
[
    [
        "ecs-web",
        "FARGATE",
        "FARGATE_SPOT"
    ],
    [
        {
            "capacityProvider": "ecs-web",
            "weight": 1,
            "base": 1
        }
    ]
]
```

`managedScaling` com alvo de 90 entrega o tamanho do grupo ao ECS: ele aumenta o grupo quando há
tasks esperando espaço e o diminui quando instâncias ficam ociosas, buscando manter 90% da
capacidade em uso. O moto guarda a configuração e não escala nada.

Uma **capacity provider strategy** diz como um serviço espalha as tasks pelos providers. `base` é
quantas tasks vão para um provider antes de qualquer peso, e `weight` divide o resto. A estratégia
padrão acima põe toda task no grupo EC2, pelo menos uma lá aconteça o que acontecer. Um serviço que
definisse `base=2` no `FARGATE` e pesos 1 no `FARGATE` e 3 no `FARGATE_SPOT` poria as 2 primeiras
tasks no Fargate e depois 1 a cada 4, o resto no Spot. A aula 9 é o Fargate, e a seção dela sobre o
Fargate Spot volta à estratégia.

## Quanto custa

O ECS em si não cobra nada. **Você paga pela capacidade**: no EC2, pelas instâncias, estejam elas
cheias de tasks ou não. Da tabela de preços de 16 de outubro de 2026:

```
ana@laptop:~/aws$ python3 prices.py ec2 | grep -E "m7i.large|m7g.large"
  m7i.large    2 vCPU   8 GiB  EBS only          0.16065  per hour
  m7g.large    2 vCPU   8 GiB  EBS only           0.1301  per hour
```

Uma `m7i.large` rodando como container instance o mês inteiro custa 0,16065 × 730 = 117,27 USD,
tenha ela uma task de um quarto de vCPU ou oito. Essa é a troca que a próxima aula inverte: o
Fargate cobra pelo que cada task reserva, e nada por instância, porque nenhuma é sua.
