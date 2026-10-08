---
title: Nenhum resultado, dois resultados e uma lista vazia
version: 2
---

Um bloco de recurso que falha para no apply. **Uma data source que falha para o plan**, e o plan
inteiro junto, porque nada que se refira à resposta pode ser calculado sem ela. Uma busca pode dar
errado de três jeitos, e só dois deles fazem barulho.

**Nenhum resultado.** A VPC que a Ana pediu não existe, porque a tag dela é `shop`, não `shop-prod`.
Um segundo diretório, `~/shop/probe`, guarda configurações pequenas para experimentar isso. O
`versions.tf` dele fica igual o tempo todo:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

O primeiro `main.tf` pede o nome errado:

```hcl
provider "aws" {
  region = "sa-east-1"
}

data "aws_vpc" "prod" {
  tags = {
    Name = "shop-prod"
  }
}
```

```
ana@laptop:~/shop/probe$ terraform plan
data.aws_vpc.prod: Reading...

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: no matching EC2 VPC found
│ 
│   with data.aws_vpc.prod,
│   on main.tf line 5, in data "aws_vpc" "prod":
│    5: data "aws_vpc" "prod" {
│ 
╵
```

**Dois resultados, numa data source que devolve um.** Uma data source no singular (`aws_vpc`,
`aws_ami`, `aws_subnet`) precisa achar exatamente uma coisa, e se recusa a escolher entre duas. Peça
todas as imagens `shop-web-*` sem `most_recent`, agora que o time de imagens publicou duas, num
`main.tf` novo:

```hcl
provider "aws" {
  region = "sa-east-1"
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["shop-web-*"]
  }
}
```

```
ana@laptop:~/shop/probe$ terraform plan
data.aws_ami.web: Reading...

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Your query returned more than one result. Please try a more specific search criteria, or set `most_recent` attribute to true.
│ 
│   with data.aws_ami.web,
│   on main.tf line 5, in data "aws_ami" "web":
│    5: data "aws_ami" "web" {
│ 
╵
```

O erro é o resultado útil. Uma busca que pegasse uma de duas ao acaso faria o deploy de coisas
diferentes em dias diferentes, e ninguém veria por quê.

**Nenhum resultado, numa data source que devolve uma lista.** As do plural (`aws_subnets`,
`aws_vpcs`, `aws_availability_zones`) respondem com uma lista, e uma lista vazia é uma resposta
perfeitamente válida:

```hcl
provider "aws" {
  region = "sa-east-1"
}

data "aws_subnets" "private" {
  tags = {
    Tier = "private"
  }
}

output "private_subnets" {
  value = data.aws_subnets.private.ids
}
```

```
ana@laptop:~/shop/probe$ terraform apply -auto-approve
data.aws_subnets.private: Reading...
data.aws_subnets.private: Read complete after 0s [id=sa-east-1]

Changes to Outputs:
  + private_subnets = []

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

private_subnets = tolist([])
```

Nenhum erro, nenhum aviso. Não há sub-redes privadas, e a configuração segue em frente com zero
delas. Um security group com uma lista vazia de origens, ou um grupo de autoscaling posto em sub-rede
nenhuma, é exatamente o tipo de engano que passa no apply em silêncio. Quando uma lista vazia está
errada, diga isso: uma `precondition` ou um bloco `check` da aula 3 pode recusá-la com uma mensagem
sua.

**O resultado que quebra depois** é o que dói, porque a configuração não mudou. O time de rede monta
uma cópia de staging da rede e copia as tags junto com todo o resto. Fazendo o papel dele mais uma
vez, de qualquer diretório:

```sh
aws ec2 create-vpc --cidr-block 10.30.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop},{Key=Environment,Value=staging},{Key=Owner,Value=network}]'
```

Agora duas VPCs respondem à tag:

```
ana@laptop:~/shop/app$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[CidrBlock,Tags[?Key==\`Environment\`]|[0].Value]" --output text
10.20.0.0/16	prod
10.30.0.0/16	staging
```

A configuração da Ana, intocada desde o último plan limpo, agora para:

```
ana@laptop:~/shop/app$ terraform plan
data.local_file.office: Reading...
data.local_file.office: Read complete after 0s [id=d31eb9db97a1f63a12b9d3ed7b67d80fde5b4ab8]
data.aws_ami.web: Reading...
data.aws_vpc.shop: Reading...
data.aws_region.current: Reading...
data.aws_caller_identity.current: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-123456789012]
data.aws_ami.web: Read complete after 0s [id=ami-737937c26a362335e]
data.aws_iam_policy_document.assets: Reading...
data.aws_iam_policy_document.assets: Read complete after 0s [id=2993801947]
aws_s3_bucket_policy.assets: Refreshing state... [id=shop-assets-123456789012]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: multiple EC2 VPCs matched; use additional constraints to reduce matches to a single EC2 VPC
│ 
│   with data.aws_vpc.shop,
│   on network.tf line 1, in data "aws_vpc" "shop":
│    1: data "aws_vpc" "shop" {
│ 
╵
```

A busca estava certa no dia em que ela a escreveu. **A consulta de uma data source é um contrato com
quem é dono daquilo que ela procura**, e esse contrato nunca foi escrito: "existe uma VPC com a tag
`shop`" era verdade por acaso. A correção é pedir o que ela quer dizer, a rede de produção, no
`network.tf`:

```hcl
data "aws_vpc" "shop" {
  tags = {
    Name        = "shop"
    Environment = "prod"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shop.id]
  }
  tags = {
    Tier = "public"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_cidr" {
  value = data.aws_vpc.shop.cidr_block
}

output "public_subnets" {
  value = length(data.aws_subnets.public.ids)
}
```

```
No changes. Your infrastructure matches the configuration.
```

Tags são um contrato fraco, porque qualquer um pode copiá-las. Dois hábitos o deixam mais forte.
Combine as tags com o outro time, como uma interface que eles prometem manter única, em vez de
adivinhá-las pelo console. E quando o outro lado também é uma configuração do Terraform, leia os
**outputs** dela, que ela publica de propósito: isso é o `terraform_remote_state`, e a aula 8 o usa
para ligar a configuração da rede à da aplicação.
