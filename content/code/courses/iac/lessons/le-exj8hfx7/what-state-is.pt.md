---
title: O que o arquivo de estado guarda
version: 1
---

A aula 1 terminou com uma promessa: o Terraform só consegue comparar o que sabe ler, então precisa
lembrar qual VPC real corresponde a qual linha do arquivo. Esta aula é sobre essa memória. Aqui está
de novo a rede da loja, uma VPC, uma sub-rede e o security group `web` com a sua única regra HTTPS:

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

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

A Ana aplica, e três recursos passam a existir:

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 8
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 2s [id=vpc-10f2b2857589fd959]
aws_security_group.web: Creating...
aws_subnet.a: Creating...
aws_subnet.a: Creation complete after 0s [id=subnet-1849baa846a6631fa]
aws_security_group.web: Creation complete after 0s [id=sg-3bb7d165786e44657]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

**Apareceu ao lado do `main.tf` um arquivo que ela nunca escreveu.** Ele se chama
`terraform.tfstate`, e o Terraform o grava toda vez que muda alguma coisa:

```
ana@laptop:~/shop$ ls -a
.
..
.terraform
.terraform.lock.hcl
main.tf
terraform.tfstate
```

É JSON, então o `jq` consegue ler. O começo do arquivo diz o que ele é:

```
ana@laptop:~/shop$ jq "{version, terraform_version, serial, lineage}" terraform.tfstate
{
  "version": 4,
  "terraform_version": "1.16.4",
  "serial": 4,
  "lineage": "7d110614-d17a-9483-3aa9-392bbcba59d2"
}
```

`version` é o formato do próprio arquivo, não de algo dentro dele. `terraform_version` é o Terraform
que o gravou por último. `serial` sobe de um em um a cada gravação, então, de duas cópias, a de
serial maior é a mais nova. `lineage` é um id aleatório dado ao estado quando ele foi criado e
mantido em todos os seriais seguintes: dois arquivos com lineages diferentes não são duas versões de
uma história, são duas histórias, e o Terraform se recusa a gravar uma por cima da outra. Você vai
ver esses dois números fazendo o seu trabalho em "protecting".

Abaixo do cabeçalho está a parte que importa, uma entrada por recurso:

```
ana@laptop:~/shop$ jq -c ".resources[] | {type, name, id: .instances[0].attributes.id}" terraform.tfstate
{"type":"aws_security_group","name":"web","id":"sg-3bb7d165786e44657"}
{"type":"aws_subnet","name":"a","id":"subnet-1849baa846a6631fa"}
{"type":"aws_vpc","name":"shop","id":"vpc-10f2b2857589fd959"}
```

**Esse é o mapeamento.** À esquerda, um endereço que só existe na configuração: `aws_vpc.shop` é um
tipo e um nome que a Ana escolheu. À direita, um id que só existe na AWS: a conta o inventou durante
o apply, e nada no `main.tf` poderia contê-lo. O estado é o único lugar onde os dois se encontram.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três colunas. À esquerda, a configuração main.tf com três endereços: aws_vpc.shop, aws_subnet.a e aws_security_group.web. No meio, o estado, terraform.tfstate, que junta cada endereço a um id. À direita, a conta AWS, onde a VPC, a sub-rede e o security group existem com ids que a AWS inventou. Só o estado contém o endereço e o id ao mesmo tempo.\"><rect x=\"20\" y=\"20\" width=\"200\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a configuração</text><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">main.tf</text><rect x=\"260\" y=\"20\" width=\"200\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o estado</text><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">terraform.tfstate</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a conta</text><text x=\"600.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AWS (moto)</text><rect x=\"30\" y=\"80\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_vpc.shop</text><rect x=\"270\" y=\"80\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">aws_vpc.shop  →  vpc-…</text><rect x=\"510\" y=\"80\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">vpc-…</text><rect x=\"30\" y=\"125\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.a</text><rect x=\"270\" y=\"125\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">aws_subnet.a  →  subnet-…</text><rect x=\"510\" y=\"125\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">subnet-…</text><rect x=\"30\" y=\"170\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_security_group.web</text><rect x=\"270\" y=\"170\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">aws_security_group.web  →  sg-…</text><rect x=\"510\" y=\"170\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">sg-…</text><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o único lugar onde um endereço encontra um id</text></svg>", "caption": "O estado é a junção: um endereço que só a configuração tem, ao lado de um id que só a AWS tem."}
```

Por que o Terraform não procura a VPC pela tag `Name`, em vez disso? Porque uma tag não é uma
identidade. A aula 1 já criou duas VPCs chamadas `shop` com a mesma faixa, e a AWS aceitou as duas.
Uma busca por nome encontra zero, uma ou várias, e o Terraform teria de adivinhar qual delas é *a*
`aws_vpc.shop`. Com o id anotado não há o que adivinhar: no plan seguinte ele pede à AWS exatamente
aquele objeto e compara o que volta com o arquivo.

Cada entrada guarda mais do que um id. É uma cópia de todos os atributos que o provider devolveu,
inclusive os que a AWS calculou, e uma lista daquilo de que o recurso dependia:

```
ana@laptop:~/shop$ jq ".resources[] | select(.name == \"web\") | .instances[0] | {arn: .attributes.arn, owner_id: .attributes.owner_id, dependencies}" terraform.tfstate
{
  "arn": "arn:aws:ec2:sa-east-1:123456789012:security-group/sg-3bb7d165786e44657",
  "owner_id": "123456789012",
  "dependencies": [
    "aws_vpc.shop"
  ]
}
```

A lista `dependencies` está ali para o dia em que a configuração já não disser nada. Apague o
`main.tf` inteiro e o Terraform ainda sabe, só pelo estado, que o security group tem de sair antes da
VPC onde ele vive. A cópia dos atributos é o que permite a um plan mostrar `~ update in-place` com o
valor antigo ao lado do novo, e é também por isso que o estado é **sensível**: o que quer que um
provider devolva vai parar nele, e a aula 12 encontra lá uma senha em texto puro.

Então são três coisas, e todo comando desta aula serve para mantê-las de acordo: **a configuração**
diz o que deveria existir, **a conta real** tem o que de fato existe, e **o estado** diz qual objeto
real responde por qual endereço. Perca o terceiro, e os outros dois não podem mais ser comparados.
