---
title: Um diretório por ambiente
version: 2
---

O outro layout comum tira a escolha do ambiente de um arquivo escondido e a põe no caminho. **Cada
ambiente é um diretório próprio, uma pequena configuração raiz com a sua key de backend, e os dois
chamam os mesmos módulos.** A Ana desmonta os workspaces em `~/shop`, destruindo cada um antes
de apagá-lo:

```sh
terraform workspace select prod
terraform destroy -var-file=prod.tfvars -auto-approve | tail -n 1
terraform workspace select dev
terraform destroy -var-file=dev.tfvars -auto-approve | tail -n 1
terraform workspace select default
terraform workspace delete prod
terraform workspace delete dev
```

Depois começa um repositório, `~/shop-infra`, organizado assim:

```
ana@laptop:~/shop-infra$ tree --noreport
.
├── envs
│   ├── dev
│   │   ├── backend.tf
│   │   └── main.tf
│   └── prod
│       ├── backend.tf
│       └── main.tf
└── modules
    ├── network
    │   └── main.tf
    └── web
        └── main.tf
```

Os dois módulos guardam o que o `main.tf` guardava antes, dividido em dois: `network` é a VPC e as
sub-redes, e `web` é o security group. Escrever módulos, com entradas e saídas, é a aula 10; aqui eles
só precisam existir. O módulo de rede, `modules/network/main.tf`, é a configuração de antes, com as
variáveis e um output para o id da VPC:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "cidr" {
  type = string
}

variable "azs" {
  type = list(string)
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

output "vpc_id" {
  value = aws_vpc.shop.id
}
```

O módulo web, `modules/web/main.tf`, é o security group, com o id da VPC como entrada:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = var.vpc_id
  tags        = { Project = "shop", Environment = var.environment, Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

O diretório de um ambiente é um bloco de backend e um arquivo que chama os módulos com os valores
daquele ambiente. Os de prod são `envs/prod/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "envs/prod/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

e `envs/prod/main.tf`:

```hcl
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source      = "../../modules/network"
  environment = "prod"
  cidr        = "10.20.0.0/16"
  azs         = ["sa-east-1a", "sa-east-1c"]
}

module "web" {
  source      = "../../modules/web"
  environment = "prod"
  vpc_id      = module.network.vpc_id
}
```

Os dois arquivos de dev são iguais, com a key e os valores de dev, `envs/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "envs/dev/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

e `envs/dev/main.tf`:

```hcl
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source      = "../../modules/network"
  environment = "dev"
  cidr        = "10.21.0.0/16"
  azs         = ["sa-east-1a"]
}

module "web" {
  source      = "../../modules/web"
  environment = "dev"
  vpc_id      = module.network.vpc_id
}
```

Os valores ficam escritos direto nas chamadas de módulo, então não há `.tfvars` para passar nem flag
para esquecer. **O diretório é o ambiente**: para planejar prod você fica em `envs/prod`, e o prompt
diz isso. É nisto que os dois diretórios realmente diferem:

```
ana@laptop:~/shop-infra$ diff -r envs/dev envs/prod
diff -r envs/dev/backend.tf envs/prod/backend.tf
4c4
<     key          = "envs/dev/terraform.tfstate"
---
>     key          = "envs/prod/terraform.tfstate"
diff -r envs/dev/main.tf envs/prod/main.tf
7,9c7,9
<   environment = "dev"
<   cidr        = "10.21.0.0/16"
<   azs         = ["sa-east-1a"]
---
>   environment = "prod"
>   cidr        = "10.20.0.0/16"
>   azs         = ["sa-east-1a", "sa-east-1c"]
14c14
<   environment = "dev"
---
>   environment = "prod"
```

Quatro linhas de valores em cada um, e a key do backend. A key precisa ser escrita em cada cópia porque, como a
aula 7 mostrou, um bloco de backend não pode usar variáveis.

O `.gitignore` do repositório é o de `~/shop` com uma linha a mais, para o diretório em que o
Terragrunt trabalha, que a próxima seção explica:

```
.terraform/
*.tfstate
*.tfstate.*
.terragrunt-cache/
```

A Ana faz o commit do repositório como está:

```sh
git init -q && git add . && git commit -qm "one directory per environment"
```

Cada diretório é inicializado e aplicado sozinho, sem argumento nenhum:

```
ana@laptop:~/shop-infra/envs/dev$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
ana@laptop:~/shop-infra/envs/prod$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
ana@laptop:~/shop-infra/envs/prod$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 12:15:15       6446 envs/dev/terraform.tfstate
2026-10-02 12:15:25       8588 envs/prod/terraform.tfstate
2026-10-02 12:13:21        181 shop/terraform.tfstate
```

Dois objetos de estado, cada um sob uma key que diz o que ele é, e o plan de cada ambiente lê só o
seu. O prompt dessa captura é o único lugar onde o ambiente aparece, e basta. Se prod mora em outra
conta da AWS, o diretório também é o lugar natural para dizer quais credenciais usar, pelo bloco do
provider ou pelo pipeline que roda nele; um workspace não tem onde pendurar isso.

## O que as cópias custam

**Tudo o que os dois diretórios compartilham está escrito duas vezes**: o bloco do provider, o bloco
de backend tirando a key, as chamadas de módulo tirando os valores. Com dois ambientes isso é
tolerável. Cinco ambientes em três regiões, cada um com uma rede, um banco e uma aplicação em estados
separados, dão quarenta e cinco blocos de backend que diferem numa string. No dia em que alguém
muda o nome do bucket, são quarenta e cinco edições.

Os módulos compartilhados são a outra metade, e cortam para os dois lados. Uma mudança em
`modules/network` chega a todos os ambientes de uma vez. A Ana acrescenta uma tag `Owner` às tags do
módulo e planeja os dois:

```
ana@laptop:~/shop-infra$ sed -i 's/tags = { Project = "shop", Environment = var.environment }/tags = { Project = "shop", Environment = var.environment, Owner = "ana" }/' modules/network/main.tf
ana@laptop:~/shop-infra/envs/dev$ terraform plan -no-color | grep -E "^(No changes|Plan:)"
Plan: 0 to add, 2 to change, 0 to destroy.
ana@laptop:~/shop-infra/envs/prod$ terraform plan -no-color | grep -E "^(No changes|Plan:)"
Plan: 0 to add, 3 to change, 0 to destroy.
```

Dev mudaria dois recursos e prod três, a partir de uma edição. É o que você quer para uma correção, e
não para uma mudança que você pretendia testar em dev por uma semana antes. O jeito usual de segurar prod é entregar o módulo a ele por versão em vez de por caminho, `?ref=v1.2.0` numa origem
git, e mover cada ambiente para a versão nova quando ele estiver pronto. A aula 10 trata de origens e
versões de módulos. A tag era só um experimento, então a Ana devolve o módulo ao que estava no
commit, com `git checkout modules/network/main.tf`.

**As cópias também podem divergir de propósito**, e às vezes esse é o ponto. O diretório de prod pode
ter um recurso que dev não tem, um cofre de backup por exemplo, sem um único `count` ou condicional no
código compartilhado. Com workspaces, toda diferença entre ambientes precisa ser expressa pelos
valores de uma configuração só.

Antes que a próxima seção construa os mesmos dois ambientes de novo com o Terragrunt, a Ana
destrói estes dois:

```sh
cd ~/shop-infra/envs/dev && terraform destroy -auto-approve
cd ~/shop-infra/envs/prod && terraform destroy -auto-approve
cd ~/shop-infra
```

A repetição é o assunto da próxima seção. O Terragrunt existe principalmente para removê-la.
