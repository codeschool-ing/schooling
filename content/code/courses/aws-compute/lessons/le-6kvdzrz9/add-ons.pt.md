---
title: Add-ons, o software de que todo node precisa
version: 1
---

Um control plane e três nodes ainda não são um cluster onde um pod consegue viver. Um pod precisa de
um endereço, os Services precisam de regras em todo node que levem o tráfego ao pod certo, e nomes
como `orders.default.svc` precisam de um servidor DNS. **Nada disso está no control plane.** Três
programas fazem isso, e eles rodam nos seus nodes, ao lado dos seus pods:

| add-on | o que faz | como roda |
|---|---|---|
| `vpc-cni` | dá a cada pod um endereço da VPC | um pod em cada node, como um DaemonSet chamado `aws-node` |
| `kube-proxy` | escreve as regras que fazem o endereço de um Service chegar aos pods | um pod em cada node |
| `coredns` | responde ao DNS dos nomes de dentro do cluster | um Deployment, dois pods por padrão |

Quando um cluster é criado pela API, o EKS instala esses três sozinho, como objetos comuns do
Kubernetes. A referência da API da AWS os chama de add-ons de rede padrão e diz que
`--no-bootstrap-self-managed-addons` os deixa de fora, para um time que traz o próprio plugin de
rede. Mais dois são comuns o bastante para nomear: o `aws-ebs-csi-driver`, que transforma um pedido
de volume do Kubernetes num volume EBS da lição 3, e o `eks-pod-identity-agent`, que a lição 13 usa.

## Managed add-ons, que o moto não tem

Instalados desse jeito, os três são seus para atualizar com `kubectl`, e achar a versão que serve
para uma versão do Kubernetes também é com você. **Como EKS add-ons**, a AWS publica quais versões
de cada um funcionam com qual versão do Kubernetes, e os instala e atualiza pela API do EKS. Essa
API é a parte do EKS que o moto 5.2.3 não implementa:

```
ana@laptop:~/aws$ aws eks list-addons --cluster-name shop

aws: [ERROR]: An error occurred (404) when calling the ListAddons operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

Toda chamada de add-on responde esse 404, então o que segue vem da documentação da AWS e **não foi
rodado**. Na AWS, estas são as três chamadas:

```sh
aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version 1.35 \
  --query 'addons[0].addonVersions[0].addonVersion'
aws eks create-addon --cluster-name shop --addon-name vpc-cni --resolve-conflicts OVERWRITE
aws eks update-addon --cluster-name shop --addon-name vpc-cni --addon-version <the version above>
```

A primeira pergunta quais versões existem para a 1.35. A segunda assume a cópia que já está no
cluster, e `--resolve-conflicts` diz o que fazer onde a cópia em execução foi configurada diferente
dos padrões do EKS. `OVERWRITE` troca esses valores pelos do EKS, e `NONE` não muda nada e deixa a
chamada falhar quando eles diferem. `PRESERVE` mantém os seus valores, e a AWS documenta que ele se
comporta diferente num update. **Um EKS add-on continua mudando só quando você pede**: a AWS publica
as versões, e escolher uma é trabalho do dono do cluster, que a próxima seção põe num calendário.

## O que o plugin de rede decide: quantos pods cabem num node

O `vpc-cni` dá a cada pod um endereço de verdade na VPC, tirado das interfaces de rede do node dele.
Então o número de pods que um node comporta é definido pelo tipo de instância, por dois números que
o EC2 publica para cada tipo, e o moto carrega o catálogo da AWS com eles:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types t3.medium m7g.large c7g.xlarge --query 'InstanceTypes[].[InstanceType,NetworkInfo.MaximumNetworkInterfaces,NetworkInfo.Ipv4AddressesPerInterface]' --output text
c7g.xlarge	4	15
m7g.large	3	10
t3.medium	3	6
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types t3.medium m7g.large c7g.xlarge --query 'InstanceTypes[].[InstanceType,NetworkInfo.MaximumNetworkInterfaces,NetworkInfo.Ipv4AddressesPerInterface]' --output text | awk '{ print $1, $2 * ($3 - 1) + 2 }'
c7g.xlarge 58
m7g.large 29
t3.medium 17
```

O segundo comando aplica a fórmula que a AWS documenta para a configuração padrão: **interfaces ×
(endereços por interface − 1) + 2.** Cada interface guarda um endereço para si, e os dois somados no
fim são pods que usam o endereço do próprio node, como o `kube-proxy` e o próprio `aws-node`. Uma
`m7g.large` comporta 29 pods por menos que cada um peça, e uma `t3.medium` 17. Um cluster de
instâncias pequenas cheio de pods pequenos fica sem endereços muito antes de ficar sem processador.

Duas coisas mudam esse limite, ambas descritas pela AWS e nenhuma rodada aqui. Uma é o **prefix
delegation**, em que o `vpc-cni` põe um bloco de 16 endereços em cada vaga de uma interface onde
antes ia um endereço. A outra é a própria subnet, cujo tamanho limita quantos pods o cluster
inteiro consegue endereçar.

## Os add-ons também chamam a AWS

O `vpc-cni` cria interfaces de rede e o `aws-ebs-csi-driver` cria volumes, então os dois precisam de
permissões do IAM. Pô-las na role dos nodes funciona e dá a todo pod do node as mesmas permissões do
plugin. O lugar melhor é uma role só para o add-on, que o EKS prende à service account dele, e esse
mecanismo é a lição 13 inteira.
