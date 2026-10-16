---
title: Node groups, e as máquinas que são suas
version: 1
---

Um cluster EKS novo não tem nodes. As pessoas esperam que ele chegue com alguns, já que um cluster
Kubernetes num notebook chega, e o primeiro pod que criam fica em `Pending` sem lugar para rodar.
**As máquinas são uma decisão separada, tomada na sua conta e cobrada pelos preços do EC2.** Há
quatro jeitos de tomá-la: um managed node group, um grupo de instâncias self-managed, o Fargate e o
Karpenter. Esta seção trata dos dois primeiros, e a lição 12 dos outros dois.

## A role dos nodes

Todo node chama a AWS: para entrar no cluster, para baixar imagens do ECR e para dar aos pods
endereços na VPC. Ele faz isso como uma role que o EC2 pode assumir, então a trust policy cita
`ec2.amazonaws.com`. O arquivo `eks-node-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name eks-node --assume-role-policy-document file://eks-node-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/eks-node"
ana@laptop:~/aws$ aws iam attach-role-policy --role-name eks-node --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the AttachRolePolicy operation: Policy arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy does not exist or is not attachable.
```

A AWS documenta três managed policies para essa role: `AmazonEKSWorkerNodePolicy` para entrar no
cluster, `AmazonEC2ContainerRegistryReadOnly` para baixar do ECR, que é o repositório da lição 10
visto do outro lado, e `AmazonEKS_CNI_Policy` para o plugin de rede da próxima seção. **O moto não
carrega essas três policies**, então prender a primeira falha aqui com `NoSuchEntity` e funciona na
AWS. Nada abaixo depende disso, porque o moto não avalia policy nenhuma de qualquer jeito.

## Um managed node group

Um managed node group é um Auto Scaling group que o EKS cria e cuida. Ele escolhe a imagem, lança as
instâncias e as coloca no cluster. Quando você pede uma versão nova, ele as substitui um lote por
vez.

```
ana@laptop:~/aws$ aws eks create-nodegroup --cluster-name shop --nodegroup-name general --node-role arn:aws:iam::123456789012:role/eks-node --subnets ${SUBNETS/,/ } --instance-types m7g.large --ami-type AL2023_ARM_64_STANDARD --scaling-config minSize=2,maxSize=6,desiredSize=3 --update-config maxUnavailable=1 --labels role=general
{
    "nodegroup": {
        "nodegroupName": "general",
        "nodegroupArn": "arn:aws:eks:sa-east-1:123456789012:nodegroup/shop/general/81031e92-98fd-4871-8837-769815e73c44",
        "clusterName": "shop",
        "version": "1.19",
        "releaseVersion": "1.19.8-20210414",
        "createdAt": "2026-10-16T13:37:35.899000-03:00",
        "modifiedAt": "2026-10-16T13:37:35.899000-03:00",
        "status": "ACTIVE",
        "capacityType": "ON_DEMAND",
        "scalingConfig": {
            "minSize": 2,
            "maxSize": 6,
            "desiredSize": 3
        },
        "instanceTypes": [
            "m7g.large"
        ],
        "subnets": [
            "subnet-0d907af99bed87115",
            "subnet-669c66a4048b76897"
        ],
        "remoteAccess": {
            "ec2SshKey": "eksKeypair"
        },
        "amiType": "AL2023_ARM_64_STANDARD",
        "nodeRole": "arn:aws:iam::123456789012:role/eks-node",
        "labels": {
            "role": "general"
        },
        "taints": [],
        "resources": {
            "autoScalingGroups": [
                {
                    "name": "eks-81031e92-98fd-4871-8837-769815e73c44"
                }
            ],
            "remoteAccessSecurityGroup": "sg-r8ylvhzzz2m3o9ipy"
        },
        "diskSize": 20,
        "health": {
            "issues": []
        },
        "tags": {}
    }
}
```

O pedido é a parte a ler. `--scaling-config` são os três números do grupo da lição 4: nunca menos
de 2 nodes, nunca mais de 6, e 3 agora. `--update-config maxUnavailable=1` diz que um update de
versão pode tirar um node de serviço por vez. `--ami-type AL2023_ARM_64_STANDARD` é o Amazon Linux
2023 para Arm, que é o que uma `m7g.large` precisa, e `--labels` põe `role=general` em todo node,
para que um pod peça para ser agendado ali.

**A resposta é do moto em quatro lugares**, e vale conhecer cada um:

- **`version` é `1.19` e `releaseVersion` é de 2021**, num cluster da versão 1.35. São valores
  fixos do moto. A referência da API da AWS diz que um node group só é criado na versão do
  Kubernetes do próprio cluster, com a imagem mais recente lançada para ela.
- **`remoteAccess` cita um key pair, `eksKeypair`, que o pedido nunca mencionou.** O moto o
  acrescenta; na AWS um node group só tem acesso SSH se você pedir.
- **Não há `updateConfig`** na resposta, embora o pedido tivesse um.
- **`resources.autoScalingGroups` cita um grupo que não existe.** Na AWS esse é o Auto Scaling group
  de verdade, com três instâncias dentro. No moto nada foi lançado:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].AutoScalingGroupName'
[]
ana@laptop:~/aws$ aws ec2 describe-instances --query 'length(Reservations[].Instances[])'
0
```

Mudar o tamanho é uma chamada ao EKS, e não ao Auto Scaling group, porque o grupo é do EKS:

```
ana@laptop:~/aws$ aws eks update-nodegroup-config --cluster-name shop --nodegroup-name general --scaling-config minSize=2,maxSize=8,desiredSize=4 --query update.[type,status]
[
    "ConfigUpdate",
    "Successful"
]
```

Na AWS o update fica `InProgress` por um tempo antes de ficar `Successful`, e as instâncias chegam
como a lição 4 descreveu. A lição 12 é sobre o que muda o `desiredSize` sozinho quando há pods
esperando lugar.

O moto também aceita um grupo que a AWS recusaria, com o mínimo acima do máximo:

```
ana@laptop:~/aws$ aws eks create-nodegroup --cluster-name shop --nodegroup-name wrong --node-role arn:aws:iam::123456789012:role/eks-node --subnets ${SUBNETS/,/ } --scaling-config minSize=5,maxSize=2,desiredSize=9 --query nodegroup.[status,scalingConfig]
[
    "ACTIVE",
    {
        "minSize": 5,
        "maxSize": 2,
        "desiredSize": 9
    }
]
ana@laptop:~/aws$ aws eks delete-nodegroup --cluster-name shop --nodegroup-name wrong --query nodegroup.nodegroupName
"wrong"
```

Isso é um lembrete do limite do laboratório, e não uma funcionalidade: **o moto confere muito menos
que a AWS**, então uma configuração que o moto aceita não foi validada por ninguém.

## Spot, e vários tipos de instância

Um node group pode rodar em capacidade spot, o desconto da lição 6, e se espalhar por vários tipos
de instância do mesmo tamanho, para que a falta de um tipo não impeça o grupo de crescer:

```
ana@laptop:~/aws$ aws eks create-nodegroup --cluster-name shop --nodegroup-name spot --node-role arn:aws:iam::123456789012:role/eks-node --subnets ${SUBNETS/,/ } --capacity-type SPOT --instance-types m7g.large c7g.large r7g.large --scaling-config minSize=0,maxSize=10,desiredSize=2 --query nodegroup.[capacityType,instanceTypes]
[
    "SPOT",
    [
        "m7g.large",
        "c7g.large",
        "r7g.large"
    ]
]
```

O Kubernetes reagenda os pods de um node que o spot toma de volta, o que faz das cargas sem estado
uma boa escolha, e é comum um time manter um grupo sob demanda para o que não pode se mover e um
grupo spot para todo o resto. Os dois grupos são o motivo de o cluster agora se recusar a ser
apagado:

```
ana@laptop:~/aws$ aws eks delete-cluster --name shop

aws: [ERROR]: An error occurred (ResourceInUseException) when calling the DeleteCluster operation: Cluster has nodegroups attached

Additional error details:
clusterName: shop
nodegroupName: general,spot
```

A AWS responde do mesmo jeito: primeiro se apagam os node groups, e o cluster depois.

## Managed ou self-managed

Um grupo self-managed é a lição 4 aplicada ao Kubernetes: o seu launch template, o seu Auto Scaling
group, e um script de bootstrap no user data que põe cada instância no cluster. Nada nele fica
escondido, e nada nele é feito por você.

| | managed node group | grupo self-managed |
|---|---|---|
| quem cria o Auto Scaling group | o EKS | você |
| a imagem | a mais recente do EKS para a versão, ou a sua por um launch template | sua para escolher e corrigir |
| um update de versão | uma chamada; o EKS drena e substitui os nodes em lotes | o seu instance refresh, e a sua drenagem |
| quanto custa | as instâncias EC2, nada a mais | as instâncias EC2 |

**Managed node groups não custam nada além das instâncias**, então o motivo para administrar os
seus é uma necessidade que o tipo gerenciado não atende, como um sistema operacional que o EKS não
oferece, e não dinheiro.
