---
title: count, e cópias numeradas a partir de zero
version: 1
---

A rede da loja precisa de três sub-redes que só diferem na faixa de endereços. A primeira ideia da
maioria das pessoas são três blocos `resource`, copiados e editados, e isso funciona até o dia em
que forem doze. **O `count` transforma um bloco em quantos recursos você pedir.** Ele é um
**meta-argumento**: o próprio Terraform o lê, antes de o provider ver qualquer coisa, então ele
significa o mesmo num `aws_subnet`, num `random_id` ou em qualquer outro tipo de resource.

A configuração da Ana mantém os blocos `terraform` e `provider` da aula 2 em `versions.tf`. Tudo de
que esta seção trata está em `main.tf`:

```hcl
variable "subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "public" {
  type    = bool
  default = true
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "app" {
  count = length(var.subnets)

  vpc_id     = aws_vpc.shop.id
  cidr_block = var.subnets[count.index]
  tags       = { Project = "shop" }
}

resource "aws_internet_gateway" "shop" {
  count = var.public ? 1 : 0

  vpc_id = aws_vpc.shop.id
}
```

`count = length(var.subnets)` pede três sub-redes. Dentro do bloco, `count.index` é o número da
cópia sendo construída, **começando em zero**, então `var.subnets[count.index]` entrega à primeira
cópia a primeira faixa, à segunda cópia a segunda, e assim por diante. Cada cópia ganha um endereço
próprio, que é o endereço do resource com o índice entre colchetes. Dá para vê-los no apply,
enquanto o Terraform cria cada uma:

```
Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + gateway = (known after apply)
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 1s [id=vpc-ef185f8eeea2f754c]
aws_internet_gateway.shop[0]: Creating...
aws_subnet.app[1]: Creating...
aws_subnet.app[0]: Creating...
aws_subnet.app[2]: Creating...
aws_subnet.app[0]: Creation complete after 1s [id=subnet-9485478c607d4a202]
aws_subnet.app[2]: Creation complete after 1s [id=subnet-151a62e4e9c8c6cb4]
aws_subnet.app[1]: Creation complete after 1s [id=subnet-a4a6adb3ebc89f9b9]
aws_internet_gateway.shop[0]: Creation complete after 1s [id=igw-d64e0925c422c6e13]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

gateway = "igw-d64e0925c422c6e13"
```

Três blocos, cinco recursos: a VPC, três sub-redes e o gateway. O state os guarda sob esses
endereços, e o `terraform console`, que a aula 3 usa para expressões, consegue ler qualquer um
deles de volta:

```
ana@laptop:~/shop/network$ terraform state list
aws_internet_gateway.shop[0]
aws_subnet.app[0]
aws_subnet.app[1]
aws_subnet.app[2]
aws_vpc.shop
ana@laptop:~/shop/network$ echo "aws_subnet.app[1].cidr_block" | terraform console
"10.20.2.0/24"
```

`aws_subnet.app[1]` é uma sub-rede. `aws_subnet.app` sozinho são as três, como uma lista, e essa
diferença importa assim que você escreve uma referência.

## count como liga-desliga

O internet gateway usa o `count` para outro trabalho. `var.public ? 1 : 0` dá uma cópia ou nenhuma,
que é o jeito comum de tornar um resource opcional: uma rede pública ganha um gateway, uma privada
não. O bloco fica no arquivo nos dois casos, e uma variável decide.

**O problema é tudo o que aponta para o resource opcional.** O `outputs.tf` lê o id do gateway como
`aws_internet_gateway.shop[0].id`, o que vai bem enquanto existe uma cópia zero. Peça uma rede
privada e veja o que acontece:

```
Terraform planned the following actions, but then encountered a problem:

  # aws_internet_gateway.shop[0] will be destroyed
  # (because index [0] is out of range for count)
  - resource "aws_internet_gateway" "shop" {
      - arn      = "arn:aws:ec2:sa-east-1:123456789012:internet-gateway/igw-d64e0925c422c6e13" -> null
      - id       = "igw-d64e0925c422c6e13" -> null
      - owner_id = "123456789012" -> null
      - region   = "sa-east-1" -> null
      - tags     = {} -> null
      - tags_all = {} -> null
      - vpc_id   = "vpc-ef185f8eeea2f754c" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.
╷
│ Error: Invalid index
│ 
│   on outputs.tf line 2, in output "gateway":
│    2:   value = aws_internet_gateway.shop[0].id
│     ├────────────────
│     │ aws_internet_gateway.shop is empty tuple
│ 
│ The given key does not identify an element in this collection value: the
│ collection has no elements.
╵
```

O Terraform montou o plano, destruindo o gateway, e então falhou no output, porque
`aws_internet_gateway.shop` agora é uma lista vazia e `[0]` não aponta para nada. Nada foi
alterado: um apply teria parado no mesmo erro antes de tocar em qualquer coisa. A correção é uma
referência que aguenta o zero:

```hcl
output "gateway" {
  value = one(aws_internet_gateway.shop[*].id)
}
```

`[*]` é o splat da aula 3, uma lista com o id de cada cópia, com um elemento ou nenhum. O `one()`
transforma essa lista no seu único elemento, ou em `null` quando ela está vazia, e recusa uma lista
de dois. O mesmo plano agora passa, e diz também o que vai acontecer com o output:

```
Plan: 0 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  - gateway = "igw-d64e0925c422c6e13" -> null
```

**Dois limites para guardar.** O `count` precisa ser um número que o Terraform conheça enquanto
planeja, antes de qualquer coisa ser criada; a última seção desta aula mostra o que acontece
quando não é. E o índice é a identidade da cópia: `aws_subnet.app[2]` é o que estiver em terceiro
lugar na lista hoje. A próxima seção mostra quanto isso custa.
