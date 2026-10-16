---
title: O control plane, e o que a AWS roda pelo preço dele
version: 1
---

"Kubernetes gerenciado" soa como Kubernetes que outra pessoa roda, inteiro. **O EKS gerencia uma
metade: o control plane.** O API server, o etcd onde fica o estado do cluster, o scheduler e os
controllers rodam numa conta da AWS, espalhados por três Availability Zones, corrigidos e mantidos
disponíveis pela AWS. As máquinas onde os seus pods rodam, o software de que essas máquinas
precisam e a decisão de ir para uma versão nova do Kubernetes são seus. Esta lição é sobre a linha
entre as duas metades, e as três seções depois desta são a metade do seu lado.

## Um cluster é uma role e duas subnets

O EKS age na sua conta em nome do cluster: põe interfaces de rede nas suas subnets e lê o que
precisa saber delas. Ele faz isso como uma role do IAM que confia no serviço, o padrão que a lição
9 de `aws-foundations` apresentou. A trust policy, salva como `eks-cluster-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "eks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name eks-cluster --assume-role-policy-document file://eks-cluster-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/eks-cluster"
```

Na AWS a role também carrega a managed policy `AmazonEKSClusterPolicy`, que é o que deixa o EKS
administrar essas interfaces de rede. O cluster precisa de **pelo menos duas subnets, em zonas
diferentes**, o que a referência da API da AWS declara como requisito. A VPC padrão do moto tem uma
subnet por zona de São Paulo, e o segundo comando guarda as duas primeiras numa variável:

```
ana@laptop:~/aws$ aws ec2 describe-subnets --query 'Subnets[].[SubnetId,AvailabilityZone,CidrBlock]' --output text
subnet-0d907af99bed87115	sa-east-1a	172.31.0.0/20
subnet-669c66a4048b76897	sa-east-1b	172.31.16.0/20
subnet-8803a7cf9bab445e3	sa-east-1c	172.31.32.0/20
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ',')
```

Depois, o cluster. O `--query` mantém quatro campos de uma resposta que é quase toda um
certificado:

```
ana@laptop:~/aws$ aws eks create-cluster --name shop --kubernetes-version 1.35 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=$SUBNETS --query 'cluster.{status: status, version: version, endpoint: endpoint, oidc: identity.oidc.issuer}'
{
    "status": "ACTIVE",
    "version": "1.35",
    "endpoint": "https://9nTAPRX5t1c0ke4JAps5.Aop.sa-east-1.eks.amazonaws.com/",
    "oidc": "https://oidc.eks.sa-east-1.amazonaws.com/id/Dc9oQpztiq"
}
```

**`ACTIVE` na hora é coisa do moto.** Na AWS um cluster novo fica `CREATING` por vários minutos
enquanto o control plane é montado, e um script que cria um espera com
`aws eks wait cluster-active` antes de fazer qualquer outra coisa. O endpoint é um nome que o moto
inventou, e nada responde nele. Na AWS ele é o endereço do API server, alcançado por um Network Load
Balancer, e por padrão é público, então um notebook com credenciais o alcança.
`--resources-vpc-config endpointPrivateAccess=true` acrescenta um caminho privado de dentro da VPC,
e `endpointPublicAccess=false` tira o público.

O issuer `oidc` é o provedor de identidade do próprio cluster, um por cluster. A lição 13 o entrega
ao IAM para que um pod assuma uma role sem chave guardada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Duas caixas. À esquerda, uma conta que a AWS administra, com o control plane: o API server e o etcd em três Availability Zones atrás de um Network Load Balancer, cobrados a 0,10 USD por hora. À direita, a sua VPC: interfaces de rede que o EKS põe nas suas subnets, e os node groups, Auto Scaling groups de instâncias EC2 que rodam os seus pods e os add-ons, cobrados pelo preço do EC2.\"><defs><marker id=\"eks-cp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"12\" width=\"330\" height=\"306\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">uma conta que a AWS administra</text><rect x=\"28\" y=\"50\" width=\"96\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">zona a</text><rect x=\"36\" y=\"80\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"36\" y=\"112\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"132\" y=\"50\" width=\"96\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">zona b</text><rect x=\"140\" y=\"80\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"140\" y=\"112\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"236\" y=\"50\" width=\"96\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">zona c</text><rect x=\"244\" y=\"80\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"244\" y=\"112\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"28\" y=\"164\" width=\"304\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"180\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Network Load Balancer: o endpoint</text><text x=\"180\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">0,10 USD por hora, rode o que rodar</text><rect x=\"372\" y=\"12\" width=\"336\" height=\"306\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"386\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a sua conta e a sua VPC</text><rect x=\"388\" y=\"50\" width=\"304\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">interfaces de rede que o EKS põe nas suas subnets</text><rect x=\"388\" y=\"130\" width=\"304\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">um node group: um Auto Scaling group</text><rect x=\"404\" y=\"166\" width=\"80\" height=\"64\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"444\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pods</text><rect x=\"500\" y=\"166\" width=\"80\" height=\"64\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pods</text><rect x=\"596\" y=\"166\" width=\"80\" height=\"64\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"636\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"636\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pods</text><text x=\"540\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os seus pods, e os add-ons</text><text x=\"540\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o preço do EC2 por node</text><path d=\"M388 200 L334 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#eks-cp-ah)\"></path><text x=\"358\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o kubelet se registra</text><path d=\"M342 66 L386 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#eks-cp-ah)\"></path><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">exec, logs</text></svg>", "caption": "A linha que o EKS traça. Tudo à esquerda é da AWS para rodar, corrigir e manter disponível, por um preço por hora. Tudo à direita está na sua conta: os nodes, o que roda neles e quanto custam.", "same": ["API server", "exec, logs"]}
```

## Como o kubectl entra

O `kubectl` lê um arquivo kubeconfig, e a linha de comando da AWS escreve um. `--kubeconfig` o
mantém no diretório de trabalho em vez de `~/.kube/config`:

```
ana@laptop:~/aws$ aws eks update-kubeconfig --name shop --kubeconfig ./kubeconfig
Added new context arn:aws:eks:sa-east-1:123456789012:cluster/shop to /home/ana/aws/kubeconfig
ana@laptop:~/aws$ sed -n '/^users:/,$p' kubeconfig
users:
- name: arn:aws:eks:sa-east-1:123456789012:cluster/shop
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --region
      - sa-east-1
      - eks
      - get-token
      - --cluster-name
      - shop
      - --output
      - json
      command: aws
```

Não há senha nele. **O usuário é um comando**: cada vez que o `kubectl` precisa se autenticar, ele
roda `aws eks get-token`, e o token que esse comando imprime é a parte interessante:

```
ana@laptop:~/aws$ aws eks get-token --cluster-name shop --query status.token --output text | cut -d. -f1
k8s-aws-v1

ana@laptop:~/aws$ aws eks get-token --cluster-name shop --query status.token --output text | cut -c12- | base64 -d 2>/dev/null | cut -d'&' -f1-2
http://localhost:4567/?Action=GetCallerIdentity&Version=2011-06-15
```

Depois do prefixo `k8s-aws-v1`, o token é um pedido pré-assinado ao `GetCallerIdentity` do STS,
codificado em base64. O API server envia esse pedido ao STS, e o STS responde com a identidade que
o assinou. **Um usuário do Kubernetes no EKS é um principal do IAM**, então quem consegue assinar
como a role alcança o cluster, e ninguém mais. Aqui o pedido aponta para `localhost:4567`, porque o
`AWS_ENDPOINT_URL` manda tudo para o moto; na AWS é o endereço do próprio STS.

O que esse principal pode fazer dentro do cluster é outra permissão. As access entries do EKS ligam
um principal do IAM a permissões do Kubernetes, e o moto não as implementa. **Nada da parte do
`kubectl` foi rodado**, nem poderia: o moto guarda um registro do cluster e não roda Kubernetes
nenhum por trás dele, então não há API server para o `kubectl` conversar.

## Quanto custa o control plane

A tabela de preços da lição 1, publicada em 16 de outubro de 2026, tem duas linhas para ele:

```
ana@laptop:~/aws$ python3 prices.py containers | grep -A3 "EKS and ECR"
EKS and ECR
  EKS cluster, standard support                      0.1  per hour
  EKS extended support, on top of that               0.5  per hour
  ECR storage                                        0.1  per GB-month
```

**Um cluster custa 0,10 USD por hora rode o que rodar**, vazio ou cheio, o que dá 73 USD num mês de
730 horas antes de existir um único node. É pouco perto dos nodes de um cluster movimentado e muito
perto dos nodes de um cluster parado. Um time que dá a cada um dos seus dez desenvolvedores um
cluster próprio paga 730 USD por mês só de control planes, e é por isso que clusters compartilhados,
com um namespace por desenvolvedor, são a resposta comum. A segunda linha, o suporte estendido,
pertence à seção sobre upgrades.
