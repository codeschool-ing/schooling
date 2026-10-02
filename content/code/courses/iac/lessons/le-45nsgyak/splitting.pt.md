---
title: Dividir a loja em rede e aplicação
version: 1
---

Uma divisão tem duas metades, e o pessoal costuma fazer só a primeira. **Os arquivos se movem fácil;
o estado é o que precisa ir junto com eles.** Copie os blocos da rede para um diretório novo, rode
`apply` lá, e o Terraform vê três recursos de que nunca ouviu falar e cria mais três: uma segunda VPC
ao lado da primeira, exatamente o acidente da aula 7. Então a ordem é: escrever as configurações
novas, mover as entradas do estado para elas, e provar com um plan em cada uma que nada vai mudar.

## As duas configurações

A rede ganha um diretório só dela, com a VPC e as duas sub-redes, copiadas do `main.tf` sem mudar um
caractere, já que os endereços precisam continuar os mesmos:

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
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}
```

Os outputs são novos. São o que a rede oferece ao resto da empresa, e a próxima seção é sobre eles:

```hcl
output "vpc_id" {
  description = "The shop's VPC."
  value       = aws_vpc.shop.id
}

output "vpc_cidr" {
  description = "The VPC's address range."
  value       = aws_vpc.shop.cidr_block
}

output "public_subnet_ids" {
  description = "One public subnet per availability zone."
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}
```

O backend é o bucket da aula 7, sob uma **key nova**:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "network/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

O `main.tf` e o `backend.tf` antigos vão para `app/`, com o git guardando o histórico deles. Os
blocos da rede saem do `main.tf`, e o security group encontra a VPC com um data source pela tag, a
ferramenta da aula 5, como primeira ponte:

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

data "aws_vpc" "shop" {
  tags = { Name = "shop" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

A aplicação fica no mesmo bucket e também ganha uma key própria:

```
ana@laptop:~/shop/app$ git diff backend.tf
diff --git a/app/backend.tf b/app/backend.tf
index 8a9b10f..9782b2e 100644
--- a/app/backend.tf
+++ b/app/backend.tf
@@ -1,7 +1,7 @@
 terraform {
   backend "s3" {
     bucket       = "shop-tfstate-123456789012"
-    key          = "shop/terraform.tfstate"
+    key          = "app/terraform.tfstate"
     region       = "sa-east-1"
     encrypt      = true
     use_lockfile = true
```

```
ana@laptop:~/shop$ tree --noreport -I .terraform
.
├── app
│   ├── backend.tf
│   └── main.tf
└── network
    ├── backend.tf
    ├── main.tf
    └── outputs.tf
```

## Mover as entradas

O `terraform state mv` da aula 7 move uma entrada dentro de um estado. Com `-state` e `-state-out`
ele move uma entrada entre dois **arquivos locais**, e esse é o truque: baixar o estado remoto,
cortá-lo em dois no disco, e empurrar cada metade para a key nova. A cópia é um download simples do
objeto:

```
ana@laptop:~/shop$ mkdir split && cd split
ana@laptop:~/shop/split$ aws s3 cp --no-progress s3://shop-tfstate-123456789012/shop/terraform.tfstate shop.tfstate
download: s3://shop-tfstate-123456789012/shop/terraform.tfstate to ./shop.tfstate
```

Depois as três entradas da rede saem de `shop.tfstate` para um `network.tfstate` novo, mantendo os
endereços:

```
ana@laptop:~/shop/split$ terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_vpc.shop aws_vpc.shop
Move "aws_vpc.shop" to "aws_vpc.shop"
Successfully moved 1 object(s).
ana@laptop:~/shop/split$ terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_a aws_subnet.public_a
Move "aws_subnet.public_a" to "aws_subnet.public_a"
Successfully moved 1 object(s).
ana@laptop:~/shop/split$ terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_c aws_subnet.public_c
Move "aws_subnet.public_c" to "aws_subnet.public_c"
Successfully moved 1 object(s).
ana@laptop:~/shop/split$ terraform state list -state=shop.tfstate
aws_s3_bucket.assets
aws_s3_bucket.logs
aws_security_group.web
ana@laptop:~/shop/split$ terraform state list -state=network.tfstate
aws_subnet.public_a
aws_subnet.public_c
aws_vpc.shop
```

Cada metade é empurrada para a key nova com `terraform state push`, do próprio diretório, e cada uma
é conferida com um plan antes de qualquer outra coisa. A rede primeiro:

```
ana@laptop:~/shop/network$ terraform state push ../split/network.tfstate
ana@laptop:~/shop/network$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-644904a24046c8bab]
aws_subnet.public_c: Refreshing state... [id=subnet-0bf2cbc4f593b157b]
aws_subnet.public_a: Refreshing state... [id=subnet-2fc7f0dc6fb32b7e4]

Changes to Outputs:
  + public_subnet_ids = [
      + "subnet-2fc7f0dc6fb32b7e4",
      + "subnet-0bf2cbc4f593b157b",
    ]
  + vpc_cidr          = "10.20.0.0/16"
  + vpc_id            = "vpc-644904a24046c8bab"

You can apply this plan to save these new output values to the Terraform
```

**Nenhum recurso muda, só outputs.** Os três recursos são reconhecidos pelos ids, e os outputs são
novidade para um estado que nunca os teve, então o Terraform se oferece para registrá-los; a próxima
seção aplica isso. A aplicação:

```
ana@laptop:~/shop/app$ terraform state push ../split/shop.tfstate
ana@laptop:~/shop/app$ terraform plan
data.aws_vpc.shop: Reading...
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
data.aws_vpc.shop: Read complete after 0s [id=vpc-644904a24046c8bab]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`, e três recursos consultados em vez de seis. A divisão está feita, e a key antiga sai:

```
ana@laptop:~/shop/app$ aws s3 rm s3://shop-tfstate-123456789012/shop/terraform.tfstate
delete: s3://shop-tfstate-123456789012/shop/terraform.tfstate
ana@laptop:~/shop/app$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:09:13       6517 app/terraform.tfstate
2026-10-02 07:09:06       6150 network/terraform.tfstate
ana@laptop:~/shop/app$ rm -r ../split
```

O diretório `split` guardava duas cópias completas de estado no disco da Ana, e vai embora junto.

## O checkout antigo

Ainda há um jeito de desfazer tudo isso, e ele está no notebook de um colega. Um checkout de antes
da divisão ainda tem o `main.tf` grande e ainda aponta para `shop/terraform.tfstate`, que não existe
mais:

```
ana@laptop:~/shop-old$ git log --oneline -1
9089f02 the shop, in one state
ana@laptop:~/shop-old$ terraform plan -no-color | grep -E "^Plan"
Plan: 6 to add, 0 to change, 0 to destroy.
```

**Seis a adicionar**: a loja inteira de novo, a rede duplicada da aula 7. O estado está vazio para
essa key, então para a configuração antiga nada existe. O versionamento do bucket ainda guarda o
objeto apagado, e é assim que você se recuperaria do erro, mas a defesa é evitá-lo. Faça a divisão
quando ninguém mais estiver aplicando, faça o merge como uma mudança só, e avise todo mundo que roda
Terraform na loja para dar pull antes de planejar.

Esse foi o caminho rápido, e ele tem um custo: ninguém revisou os comandos `state mv`, e nada no
repositório registra que eles rodaram. Duas seções adiante, o mesmo tipo de movimento é feito de
dentro das configurações, onde um pull request o mostra.
