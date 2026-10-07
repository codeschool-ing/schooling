---
title: Descrever o resultado em vez dos passos
version: 1
---

De volta à terceira pergunta da rede feita à mão: o que acontece se a Ana rodar o `network.sh` de novo? Ela
descobre no dia em que alguém pede para ela "garantir que a rede está configurada", e faz o óbvio:

```
ana@laptop:~/shop$ sh network.sh
created vpc-1ce5b143bd4c0c7c9, subnet-1eec27a2a90b91dd5 and sg-073d775b8001602b6
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-1dc5b2f02877661dd	10.20.0.0/16
vpc-1ce5b143bd4c0c7c9	10.20.0.0/16
```

**Duas VPCs, as duas chamadas `shop`, as duas com a mesma faixa.** O script fez exatamente o que
diz. Cada linha dele é uma instrução de criar, e a AWS cria de bom grado uma segunda rede ao lado da
primeira. Um script assim é **imperativo**: ele lista os passos, e rodar os passos de novo os
repete.

Dá para tornar o script seguro de repetir, e dá muito trabalho. Antes de cada criação ele teria de
perguntar se a coisa já existe, e então decidir o que fazer quando ela existe *mas é diferente*:
uma VPC com outra faixa, um security group com uma regra a mais. Cada um desses ramos é código que
alguém escreve, testa e erra.

Uma descrição **declarativa** inverte o problema. Ela não diz o que fazer; diz o que deveria
existir, e deixa os passos para um programa. Aqui está a mesma VPC, descrita para o Terraform, que a
aula 2 desmonta linha por linha:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop-tf" }
}
```

Num diretório novo o Terraform precisa antes de `terraform init`, que baixa o provider da AWS e que
a aula 2 lê linha por linha. Depois, o primeiro `terraform apply` não encontra essa VPC e a cria.
Veja as últimas linhas:

```
Plan: 1 to add, 0 to change, 0 to destroy.
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 0s [id=vpc-72a78e48826631670]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

O segundo compara a descrição com o que existe, acha os dois iguais e não faz nada:

```
ana@laptop:~/shop-tf$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-72a78e48826631670]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

E continua existindo exatamente uma:

```
ana@laptop:~/shop-tf$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-tf --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-72a78e48826631670	10.20.0.0/16
```

Essa propriedade tem um nome que você vai encontrar em todas as aulas deste curso:
**idempotência**. Uma operação é idempotente quando fazê-la duas vezes deixa o mundo como fazê-la uma
vez deixou. O `network.sh` não é; o `terraform apply` é, porque nunca roda um passo às cegas. Ele lê,
compara, e então faz só a diferença.

**Declarativo tem um preço.** O Terraform só consegue comparar o que sabe ler, então
precisa lembrar qual VPC real pertence a qual linha do arquivo. Essa memória é o **estado**, e as
aulas 7 e 8 tratam do que acontece quando ele se perde, é compartilhado ou está errado. O script não
precisava de memória porque nunca perguntava nada.
