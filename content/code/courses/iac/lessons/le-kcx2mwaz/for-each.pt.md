---
title: for_each, e cópias com nome
version: 1
---

O `for_each` faz cópias como o `count`, com uma diferença que decide todo o resto: **cada cópia é
nomeada por uma chave que você escolheu**, não numerada pela posição. Remova uma chave e só sai a
cópia com essa chave, porque o nome de nenhuma outra cópia dependia dela.

A Ana experimenta primeiro num diretório de rascunho, com uma VPC só dele, para que a rede da loja
não faça parte do experimento. As faixas agora são um map de um nome para uma faixa:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variable "subnets" {
  type = map(string)
  default = {
    web = "10.20.1.0/24"
    app = "10.20.2.0/24"
    db  = "10.20.3.0/24"
  }
}

resource "aws_vpc" "scratch" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "scratch" }
}

resource "aws_subnet" "app" {
  for_each = var.subnets

  vpc_id     = aws_vpc.scratch.id
  cidr_block = each.value
  tags       = { Name = "scratch-${each.key}" }
}
```

O `for_each` aceita um **map** ou um **set de strings**. Num map, cada cópia vê dois valores:
`each.key`, o nome à esquerda, e `each.value`, a faixa à direita. Aqui a chave vai para a tag
`Name` e o valor para `cidr_block`. Num set há uma coisa só por elemento, e `each.key` e
`each.value` são a mesma string.

O apply cria quatro recursos, e os endereços carregam as chaves:

```
Plan: 4 to add, 0 to change, 0 to destroy.
aws_vpc.scratch: Creating...
aws_vpc.scratch: Creation complete after 1s [id=vpc-aa3637c237d354dc1]
aws_subnet.app["web"]: Creating...
aws_subnet.app["app"]: Creating...
aws_subnet.app["db"]: Creating...
aws_subnet.app["web"]: Creation complete after 0s [id=subnet-26d3b5fe2878535e6]
aws_subnet.app["app"]: Creation complete after 0s [id=subnet-d8208f30f1c769002]
aws_subnet.app["db"]: Creation complete after 0s [id=subnet-a247c432631647404]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

O state os lista sob essas chaves. Ele os ordena alfabeticamente, o que dá uma pista de como o
Terraform pensa neles: uma coleção consultada por nome, sem primeiro nem último.

```
ana@laptop:~/shop/scratch$ terraform state list
aws_subnet.app["app"]
aws_subnet.app["db"]
aws_subnet.app["web"]
aws_vpc.scratch
```

## A mesma remoção, de novo

Agora o experimento da seção anterior. A sub-rede do meio sai, desta vez deixando a chave dela
fora do map:

```hcl
subnets = {
  web = "10.20.1.0/24"
  db  = "10.20.3.0/24"
}
```

```
Terraform will perform the following actions:

  # aws_subnet.app["app"] will be destroyed
  # (because key ["app"] is not in for_each map)
```
```
Plan: 0 to add, 0 to change, 1 to destroy.
```

**Uma sub-rede destruída, mais nada tocado.** `web` e `db` mantêm seus endereços, então mantêm seus
ids, e o que tiver sido colocado nelas fica intacto. O motivo no plano é o equivalente, no
`for_each`, do que o `count` deu: a chave `"app"` não está mais no map. Acrescentar uma chave depois
cria uma sub-rede, e a ordem em que as chaves estão escritas no arquivo não faz diferença nenhuma.

Depois do plano a Ana apaga o `terraform.tfvars` e destrói a cópia de rascunho, que já cumpriu seu
papel.

## Uma lista não basta

O `for_each` recusa uma lista, mesmo uma lista de strings, e o motivo é a razão de ele existir. Uma
lista é ordenada e pode ter o mesmo valor duas vezes, então seus elementos não têm nome além da
posição, e posição é exatamente o que o `for_each` existe para evitar. Aqui está uma lista escrita
direto no argumento:

```
ana@laptop:~/shop/try$ terraform plan
╷
│ Error: Invalid for_each argument
│ 
│   on main.tf line 6, in resource "aws_vpc" "try":
│    6:   for_each   = ["10.30.0.0/16", "10.31.0.0/16"]
│ 
│ The given "for_each" argument value is unsuitable: the "for_each" argument
│ must be a map, or set of strings, and you have provided a value of type
│ tuple.
╵
```

O erro a chama de tuple, que é o que uma lista escrita entre colchetes é antes de o Terraform
convertê-la. Um `toset(...)` em volta seria aceito: as próprias strings viram as chaves, duplicatas
viram uma só, e a ordem se perde. Isso vai bem quando cada string é um nome estável e único, como
uma faixa ou o nome de um bucket. Quando os elementos são objetos com vários atributos, monte um
map cujas chaves sejam os nomes que você quer ver nos endereços; as expressões `for` da aula 3
fazem isso numa linha.

Uma boa chave é uma que você ficaria contente de ver num plano daqui a um ano. `"web"` diz para que
serve a sub-rede. Uma chave montada a partir de algo que muda, como uma descrição, traz de volta o
problema do índice com outra cara, porque mudar a chave é mudar o endereço.
