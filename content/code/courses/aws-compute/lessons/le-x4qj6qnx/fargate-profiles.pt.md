---
title: Fargate profiles, um pod por máquina
version: 1
---

O palpite comum sobre o EKS no Fargate é um node group de máquinas grandes e invisíveis que a AWS
reparte entre os seus pods. **Cada pod roda sozinho, numa pequena máquina virtual própria,
dimensionada para aquele pod e iniciada para ele.** O Kubernetes a vê como um node, com o nome do
endereço dele, que guarda exatamente um pod e desaparece junto. Não há node para corrigir, escalar
ou pagar enquanto está vazio, e quais pods vão para lá é decidido por um **Fargate profile**.

A lição 9 apresentou o Fargate com o ECS. As máquinas são as mesmas; o que muda é que o Kubernetes
as pede, um pod por vez.

## A pod execution role

A máquina que o Fargate inicia precisa baixar a imagem do pod e se registrar no cluster como node,
e faz as duas coisas como uma role que confia no serviço do Fargate para o EKS. O cluster `shop` e a
role dele são os da lição 11, criados de novo no moto vazio desta lição. A trust policy, como
`eks-fargate-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "eks-fargate-pods.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name eks-fargate-pods --assume-role-policy-document file://eks-fargate-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/eks-fargate-pods"
```

Na AWS a role carrega a managed policy `AmazonEKSFargatePodExecutionRolePolicy`, que permite baixar
a imagem do ECR. **É a role da máquina, e não a do pod**: o que o programa dentro do pod pode fazer
na AWS é uma role própria, e a lição 13 dá uma a ele.

## Um profile é um conjunto de seletores

```
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ' ')
ana@laptop:~/aws$ aws eks create-fargate-profile --cluster-name shop --fargate-profile-name batch --pod-execution-role-arn arn:aws:iam::123456789012:role/eks-fargate-pods --subnets $SUBNETS --selectors 'namespace=reports,labels={compute=fargate}' namespace=jobs
{
    "fargateProfile": {
        "fargateProfileName": "batch",
        "fargateProfileArn": "arn:aws:eks:sa-east-1:123456789012:fargateprofile/shop/batch/ec9bf9b6-871b-4e81-b159-82e09548f58c",
        "clusterName": "shop",
        "createdAt": "2026-10-16T13:50:27.165000-03:00",
        "podExecutionRoleArn": "arn:aws:iam::123456789012:role/eks-fargate-pods",
        "subnets": [
            "subnet-dca5f8059ad9521e6",
            "subnet-0c3c8eb9dad5738a3"
        ],
        "selectors": [
            {
                "namespace": "reports",
                "labels": {
                    "compute": "fargate"
                }
            },
            {
                "namespace": "jobs"
            }
        ],
        "status": "ACTIVE",
        "tags": {}
    }
}
```

Um seletor é um namespace e, opcionalmente, rótulos. **Um pod vai para o Fargate se casar com
qualquer seletor de qualquer profile**, e ele casa com um seletor quando está naquele namespace e
carrega todos os rótulos que o seletor cita. Então, com este profile:

- um pod em `jobs` roda no Fargate, sejam quais forem os rótulos dele;
- um pod em `reports` roda no Fargate só se carregar `compute: fargate`;
- um pod em qualquer outro namespace vai para os nodes de um node group, como na lição 11.

A decisão é tomada quando o pod é criado. O EKS põe o próprio scheduler no comando de todo pod que um
profile seleciona, e um pod que já existe não se move quando um profile aparece.

**O moto aceitou as subnets da VPC padrão, e a AWS não aceitaria.** A referência da API da AWS diz
que um pod no Fargate não recebe endereço público, então só subnets privadas, sem rota para um
internet gateway, são aceitas num profile. As subnets da VPC padrão são públicas. Na AWS estas
seriam as subnets privadas da lição 16 de `aws-foundations`, e os pods chegariam à internet pelo NAT
gateway dela. O moto também aceita mais seletores do que a AWS permite:

```
ana@laptop:~/aws$ aws eks create-fargate-profile --cluster-name shop --fargate-profile-name many --pod-execution-role-arn arn:aws:iam::123456789012:role/eks-fargate-pods --subnets $SUBNETS --selectors namespace=a namespace=b namespace=c namespace=d namespace=e namespace=f --query 'length(fargateProfile.selectors)'
6
ana@laptop:~/aws$ aws eks delete-fargate-profile --cluster-name shop --fargate-profile-name many --query fargateProfile.fargateProfileName
"many"
```

A AWS documenta um limite de **cinco seletores por profile**, e recusa o sexto.

## Um profile não se edita

Um profile não tem operação de update, e a linha de comando diz isso antes de qualquer pedido sair
da máquina:

```
ana@laptop:~/aws$ aws eks update-fargate-profile --cluster-name shop --fargate-profile-name batch

aws: [ERROR]: An error occurred (ParamValidation): argument operation: Found invalid choice 'update-fargate-profile'

Maybe you meant:

  * delete-fargate-profile
  * create-fargate-profile

usage: aws [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  aws help
  aws <command> help
  aws <command> <subcommand> help
ana@laptop:~/aws$ aws eks list-fargate-profiles --cluster-name shop
{
    "fargateProfileNames": [
        "batch"
    ]
}
```

A AWS documenta os profiles como imutáveis. Para mudar um, você cria um profile novo com os seletores
novos, espera ele ficar `ACTIVE` e apaga o antigo. Os pods que já rodam ficam onde estão até serem
criados de novo.

## Quanto custa um pod no Fargate

O Fargate cobra pela vCPU e pela memória da máquina, e **a máquina é dimensionada pelos pedidos do
pod, mais 256 MB** que a AWS documenta como a memória dos componentes do Kubernetes nela: kubelet,
kube-proxy e containerd. O total é então arredondado para cima até a combinação mais próxima do
Fargate, as mesmas que a lição 9 listou:

| vCPU | memória |
|---|---|
| 0.25 | 0,5, 1 ou 2 GB |
| 0.5 | de 1 a 4 GB, de 1 em 1 GB |
| 1 | de 2 a 8 GB, de 1 em 1 GB |
| 2 | de 4 a 16 GB, de 1 em 1 GB |
| 4 | de 8 a 30 GB, de 1 em 1 GB |

Os preços da tabela da lição 1, publicados em 16 de outubro de 2026:

```
ana@laptop:~/aws$ python3 prices.py containers | grep -A5 "^Fargate"
Fargate
  vCPU, x86                                       0.0696  per hour
  memory, x86                                     0.0076  per GB-hour
  vCPU, Arm                                       0.0557  per hour
  memory, Arm                                    0.00612  per GB-hour
  ephemeral storage above 20 GB                 0.000211  per GB-hour
ana@laptop:~/aws$ python3 prices.py ec2 | grep -E 'c7g.large|m7i.2xlarge'
  c7g.large    2 vCPU   4 GiB  EBS only           0.1111  per hour
  m7i.2xlarge  8 vCPU  32 GiB  EBS only           0.6426  per hour
```

Um pod que pede 0,5 vCPU e 1 GiB é dimensionado em 1 GiB mais 256 MB, cerca de 1,25 GB, que
arredonda para **0,5 vCPU e 2 GB**. Nos preços x86 isso dá 0,5 × 0,0696 + 2 × 0,0076 = 0,05 USD por
hora, 36,50 USD num mês de 730 horas, para um pod cujos pedidos sozinhos caberiam na máquina de
0,5 vCPU e 1 GB. **No Fargate você paga pelos pedidos**, então um pod que pede muito mais do que usa
desperdiça dinheiro de um jeito que não desperdiçaria num node compartilhado.

## O que não roda lá

Um pod no Fargate está sozinho na máquina e não tem acesso ao host dela, e a AWS documenta o que
decorre disso:

- **DaemonSets** não rodam: não há node seu onde pôr um. Um agente de log ou de monitoramento vira
  um container sidecar dentro do pod.
- **Containers privilegiados, `hostNetwork` e `hostPort`** são recusados.
- **Sem volumes EBS e sem GPUs.** O EFS, o sistema de arquivos compartilhado da lição 3, pode ser
  montado.
- Um load balancer alcança o pod pelo endereço IP, então o target type dele é `ip`.

Mais um é fácil de perder. O CoreDNS é criado com uma anotação que o mantém em nodes EC2, então um
cluster **sem** node group nenhum não tem onde rodar o DNS até que um profile selecione o
`kube-system` e essa anotação seja removida. O guia da AWS para um cluster só com Fargate traz o
patch. Nada disso foi rodado aqui: o moto guarda o profile e não agenda pod nenhum.
