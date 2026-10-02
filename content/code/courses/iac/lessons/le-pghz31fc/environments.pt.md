---
title: Dev e prod, e o que os mantém separados
version: 1
---

Um **ambiente** é uma cópia completa da infraestrutura, construída a partir do mesmo código para
outro propósito. A loja tem dois. `dev` é onde a Ana testa uma mudança primeiro, e ele pode ser
pequeno, barato e ficar quebrado por uma tarde. `prod` é o que os clientes acessam, e é maior: duas
zonas de disponibilidade em vez de uma e, numa configuração com máquinas, máquinas maiores e em maior
número. **Mesmo código, valores diferentes.** Até aí todo mundo concorda.

A ideia com que as pessoas chegam é que os valores são a diferença inteira: uma configuração, um
arquivo `.tfvars` por ambiente, e o arquivo certo passado a cada comando. A Ana escreve assim. As
variáveis:

```hcl
variable "environment" {
  description = "Which environment these values are for: dev or prod."
  type        = string
}

variable "cidr" {
  description = "The VPC's address range."
  type        = string
}

variable "azs" {
  description = "The availability zones that get a public subnet."
  type        = list(string)
}
```

A configuração dá nome a tudo a partir de `var.environment` e cria uma sub-rede pública por zona,
com o `for_each` da aula 4 e o `cidrsubnet` da aula 3:

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

locals {
  name = "shop-${var.environment}"
  tags = { Project = "shop", Environment = var.environment }
}

resource "aws_vpc" "shop" {
  cidr_block = var.cidr
  tags       = merge(local.tags, { Name = local.name })
}

resource "aws_subnet" "public" {
  for_each          = { for i, az in var.azs : az => i }
  vpc_id            = aws_vpc.shop.id
  cidr_block        = cidrsubnet(var.cidr, 8, each.value + 1)
  availability_zone = each.key
  tags              = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = merge(local.tags, { Name = "web" })

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

E um arquivo de valores para cada ambiente:

```hcl
environment = "dev"
cidr        = "10.21.0.0/16"
azs         = ["sa-east-1a"]
```

```hcl
environment = "prod"
cidr        = "10.20.0.0/16"
azs         = ["sa-east-1a", "sa-east-1c"]
```

O backend é o bucket S3 da aula 7, com uma key, `shop/terraform.tfstate`. Ela aplica dev:

```
ana@laptop:~/shop$ terraform apply -var-file=dev.tfvars -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Depois pede um plan com os valores de produção, esperando uma segunda rede ao lado da primeira:

```
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars -no-color | grep -E "^  #|# forces|^Plan:"
  # aws_security_group.web must be replaced
      ~ vpc_id                 = "vpc-d6fd53b198fa1e674" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1a"] must be replaced
      ~ cidr_block                                     = "10.21.1.0/24" -> "10.20.1.0/24" # forces replacement
      ~ vpc_id                                         = "vpc-d6fd53b198fa1e674" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1c"] will be created
  # aws_vpc.shop must be replaced
      ~ cidr_block                           = "10.21.0.0/16" -> "10.20.0.0/16" # forces replacement
Plan: 4 to add, 0 to change, 3 to destroy.
```

**O Terraform não vê um segundo ambiente. Ele vê o primeiro, descrito de outro jeito.** O estado
guarda uma VPC, a de dev, e a configuração agora diz que essa VPC deveria ser `10.20.0.0/16`. A faixa
de uma VPC não muda no lugar, então o plan a substitui, e tudo o que está dentro dela junto: três
recursos destruídos, quatro criados. Aplicado, isso não criaria produção. Transformaria dev em
produção, e o próximo apply com `dev.tfvars` o transformaria de volta.

Os valores nunca foram o problema. **O que faz de dois ambientes dois é cada um ter o seu próprio
estado**, de modo que um plan de um nem consiga enxergar os recursos do outro. É desse isolamento que
trata o resto desta aula, e vale dizer o que ele compra antes de ver como:

- um erro em dev, aplicado, estraga dev e mais nada;
- um plan de prod lê o estado de prod e lista só as mudanças de prod;
- cada estado tem a sua trava, então um apply demorado em dev nunca bloqueia uma correção urgente
  em prod.

Há três jeitos comuns de dar a cada ambiente o seu estado, e as próximas seções os tratam um por vez:
**workspaces**, que mantêm um diretório e trocam o estado por baixo dele; **um diretório por
ambiente**, cada um com a sua key de backend; e o **Terragrunt**, uma ferramenta que gera o segundo
arranjo para você. Eles diferem em onde mora a escolha do ambiente, e essa acaba sendo a pergunta que
importa.

O isolamento também tem uma camada abaixo do estado. Dois estados na mesma conta da AWS, acessados
com as mesmas credenciais, estão separados pela contabilidade do Terraform e por mais nada; quem
consegue aplicar dev consegue, com um comando errado, aplicar prod. Muitas organizações põem prod
**numa conta da AWS só dela**, com credenciais que o pipeline de dev não tem. Este curso tem uma conta
emulada, então as aulas não conseguem mostrar essa camada, mas todos os arranjos a seguir funcionam
com ela.

A Ana destrói a rede de dev antes de experimentar o primeiro dos três:

```
ana@laptop:~/shop$ terraform destroy -var-file=dev.tfvars -auto-approve | tail -n 1
Destroy complete! Resources: 3 destroyed.
```
