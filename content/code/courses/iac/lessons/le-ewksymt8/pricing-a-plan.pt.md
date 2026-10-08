---
title: Pondo preço num plano antes do apply
version: 2
---

A imagem de sempre é que o custo chega na fatura, um mês depois da mudança que o causou, e é assunto
de outro departamento. **Um plano já traz a maior parte da resposta.** Ele nomeia cada recurso que
vai existir e, para os recursos vendidos por hora, nomeia o atributo que define o preço: o tipo de uma
instância, o tamanho de um disco, o simples fato de um NAT gateway existir. Junte isso a uma lista de
preços e o mês fica conhecido antes do `apply`.

Aqui estão a rede da loja e os dois servidores web, no `~/shop`. O `main.tf` é o bloco `terraform` e
`provider` simples da aula 2:

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
```

O `network.tf` guarda a rede:

```hcl
resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-public-a" }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-private-c" }
}

resource "aws_internet_gateway" "shop" {
  vpc_id = aws_vpc.shop.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

# lets the private subnet reach the internet without being reachable from it
resource "aws_nat_gateway" "shop" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.shop]
}
```

e o `web.tf`, os dois servidores:

```hcl
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-1e749f67"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private_c.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "web-${count.index}" }
}
```

A Ana guarda o diretório no Git, com um `.gitignore` de `.terraform/`, `*.tfstate*` e `tfplan`. Depois
do `terraform init` ela faz o commit de tudo, inclusive o `price.py` mais abaixo, como *the shop:
network and two web servers*. O plano cria oito coisas:

```
ana@laptop:~/shop$ terraform plan -no-color -out tfplan | grep -E "will be created|Plan:"
  # aws_eip.nat will be created
  # aws_instance.web[0] will be created
  # aws_instance.web[1] will be created
  # aws_internet_gateway.shop will be created
  # aws_nat_gateway.shop will be created
  # aws_subnet.private_c will be created
  # aws_subnet.public_a will be created
  # aws_vpc.shop will be created
Plan: 8 to add, 0 to change, 0 to destroy.
```

A aula 9 mostrou o mesmo plano em JSON, que é a forma que um programa consegue ler. O tipo da
instância já está lá, como um valor comum, antes de qualquer coisa ser criada:

```
ana@laptop:~/shop$ terraform show -json tfplan | jq -c '.resource_changes[] | select(.type == "aws_instance") | [.address, .change.actions[0], .change.after.instance_type]'
["aws_instance.web[0]","create","t3.medium"]
["aws_instance.web[1]","create","t3.medium"]
```

## Os preços, e de onde eles vêm

**Os preços estão escritos no script, e não consultados quando ele roda.** A lista de preços da AWS é
um download que muda, então os preços abaixo são linhas da planilha de preços do curso de nuvem, o
`prices.py`, copiadas da coluna `sa-east-1` do jeito que aquele curso as imprime: os preços públicos de
tabela da AWS, em USD, sem impostos, nas versões de oferta que ele fixa, `AmazonEC2` 20260925174521 e
`AmazonVPC` 20260917190528. A aula 10 do curso de nuvem explica como essa planilha é lida e por que uma
versão fixada imprime os mesmos números no ano que vem. O que esta aula faz é a conta, e por isso a
sua execução dela imprime os valores desta página.

O `price.py`, salvo no `~/shop`, lê um plano na entrada padrão, põe preço nos quatro tipos de recurso para os quais tem
uma linha e conta um mês como 730 horas, a convenção do curso de nuvem:

```python
#!/usr/bin/env python3
"""What a plan adds to the monthly bill, at list price.

    terraform show -json tfplan | python3 price.py
"""
import json
import sys

HOURS = 730  # an average month: 8,760 hours a year over 12

# sa-east-1, USD, from the cloud course's prices.py
# (offers AmazonEC2 20260925174521 and AmazonVPC 20260917190528)
INSTANCE_PER_HOUR = {"t3.micro": 0.01680, "t3.medium": 0.06720, "m7i.large": 0.16065}
NAT_PER_HOUR = 0.0930
IPV4_PER_HOUR = 0.0050
GP3_PER_GB_MONTH = 0.1520


def monthly(kind, v):
    """USD a month for one resource, or None if the sheet has no line for it."""
    if kind == "aws_instance":
        disk = sum(d["volume_size"] for d in v["root_block_device"])
        return INSTANCE_PER_HOUR[v["instance_type"]] * HOURS + disk * GP3_PER_GB_MONTH
    if kind == "aws_nat_gateway":
        return NAT_PER_HOUR * HOURS
    if kind == "aws_eip":
        return IPV4_PER_HOUR * HOURS
    return None


total, unpriced = 0.0, []
for rc in json.load(sys.stdin)["resource_changes"]:
    actions = rc["change"]["actions"]
    if actions in (["no-op"], ["read"]):
        continue
    before, after = (rc["change"][k] for k in ("before", "after"))
    old = monthly(rc["type"], before) if before else 0.0
    new = monthly(rc["type"], after) if after else 0.0
    if old is None or new is None:
        unpriced.append(rc["address"])
        continue
    total += new - old
    print(f"{rc['address']:22} {'/'.join(actions):8} {old:8.2f} -> {new:8.2f}")
print(f"{'change per month, USD':41} {total:+8.2f}")
if unpriced:
    print("no line on the sheet:", ", ".join(unpriced))
```

Para um update, ele calcula o preço do recurso antes e depois e imprime a diferença, e é por isso que
lê tanto `before` quanto `after`. **Um recurso sem linha na planilha é listado, nunca descartado**,
porque um total que pulasse algo em silêncio pareceria completo.

```
ana@laptop:~/shop$ terraform show -json tfplan | python3 price.py
aws_eip.nat            create       0.00 ->     3.65
aws_instance.web[0]    create       0.00 ->    52.10
aws_instance.web[1]    create       0.00 ->    52.10
aws_nat_gateway.shop   create       0.00 ->    67.89
change per month, USD                      +175.73
no line on the sheet: aws_internet_gateway.shop, aws_subnet.private_c, aws_subnet.public_a, aws_vpc.shop
```

Antes de um único recurso existir, o plano vale **175.73 USD por mês** a preço de tabela. A surpresa é
a ordem. O NAT gateway, uma linha no `network.tf` com um comentário em cima, custa 67.89, mais do que
qualquer um dos servidores web, com 52.10. Os 52.10 de cada servidor são as horas dele mais o disco de
20 GB; o endereço que o gateway segura soma 3.65. A VPC, as sub-redes e o internet gateway não têm
linha, porque a AWS não cobra por eles por hora.

A Ana aplica o plano salvo, `terraform apply -auto-approve tfplan`, para que a rede exista no resto da
aula.

## O que um plano não consegue precificar

O total é um piso. **Um plano sabe o que vai existir, não quanto vai ser usado.** A planilha do curso de
nuvem tem uma segunda linha para o NAT gateway, 0.0930 USD por GB que ele processa, e nenhum plano diz
quantos gigabytes os servidores web vão buscar. O mesmo vale para os dados enviados para a internet,
as requisições ao S3 e as invocações de uma função Lambda. Faltam também descontos, compromissos e
impostos, porque pertencem à conta e não à configuração.

Ainda assim, a estimativa é útil exatamente no lugar que interessa a este curso: a revisão. Tudo o que
uma mudança acrescenta por hora fica visível antes do apply, e a próxima seção põe esse número onde
quem revisa lê.
