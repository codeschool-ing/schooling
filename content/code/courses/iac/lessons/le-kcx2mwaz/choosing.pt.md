---
title: Escolher entre count e for_each
version: 1
---

Os dois argumentos fazem cópias, e qualquer um pode ser torcido para fazer o trabalho do outro. A
pergunta que decide entre eles é **o que identifica uma cópia**. Se nada identifica, porque as
cópias são intercambiáveis ou há no máximo uma, o `count` é a ferramenta mais simples. Se cada
cópia é uma coisa específica da qual outra coisa depende, ela precisa de um nome, e isso é o
`for_each`.

| situação | use | por quê |
| --- | --- | --- |
| um resource que existe ou não, por uma flag | `count = var.x ? 1 : 0` | zero ou uma cópia; leia com `one(...[*])` |
| um número fixo de cópias a que ninguém se refere uma a uma | `count` | o índice nunca é uma identidade |
| cópias que têm, cada uma, um papel: sub-redes, buckets, usuários | `for_each` sobre um map | remover uma toca uma |
| uma lista de strings únicas e estáveis | `for_each = toset(...)` | as strings viram as chaves |
| blocos repetidos dentro de um resource | `dynamic` | só quando não existe um resource separado |
| o mesmo resource em outra região ou conta | `provider` com um alias | ou `region`, só para a região |

`count` e `for_each` não podem aparecer juntos no mesmo bloco, e um `count` sobre uma lista de
coisas com nome é o caso de que desconfiar: é o problema do índice esperando alguém editar a lista.

## As chaves precisam ser conhecidas durante o plan

Há uma regra que a tabela não mostra, e ela pega todo mundo uma vez. **O Terraform monta os
endereços durante o plan, então as chaves de um `for_each`, e o número de um `count`, precisam ser
conhecidos antes de qualquer coisa ser criada.** Em `~/shop/routes`, a Ana associa cada sub-rede a
uma route table, e usa os ids das sub-redes como chaves das associações:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "routes" {
  cidr_block = "10.40.0.0/16"
}

resource "aws_subnet" "app" {
  for_each = { web = "10.40.1.0/24", db = "10.40.3.0/24" }

  vpc_id     = aws_vpc.routes.id
  cidr_block = each.value
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.routes.id
}

resource "aws_route_table_association" "app" {
  for_each = toset(values(aws_subnet.app)[*].id)

  subnet_id      = each.value
  route_table_id = aws_route_table.app.id
}
```

```
Plan: 4 to add, 0 to change, 0 to destroy.
╷
│ Error: Invalid for_each argument
│ 
│   on main.tf line 21, in resource "aws_route_table_association" "app":
│   21:   for_each = toset(values(aws_subnet.app)[*].id)
│     ├────────────────
│     │ aws_subnet.app is object with 2 attributes
│ 
│ The "for_each" set includes values derived from resource attributes that
│ cannot be determined until apply, and so Terraform cannot determine the
│ full set of keys that will identify the instances of this resource.
│ 
│ When working with unknown values in for_each, it's better to use a map
│ value where the keys are defined statically in your configuration and where
│ only the values contain apply-time results.
│ 
│ Alternatively, you could use the -target planning option to first apply
│ only the resources that the for_each value depends on, and then apply a
│ second time to fully converge.
╵
```

O plano chegou até a VPC, as sub-redes e a route table, e parou nas associações. O id de uma
sub-rede é inventado pela AWS quando a sub-rede é criada, então neste plano ele é desconhecido, e
um set de strings desconhecidas não consegue nomear nada. Repare que o problema não é o valor: a
associação só precisa do id quando é criada, e o Terraform espera por isso sem reclamar. **O
problema é usar um valor da hora do apply como chave.**

O próprio conselho do erro é a correção. Percorra algo cujas chaves estão no arquivo, e tire o
valor da hora do apply de `each.value`. O próprio `aws_subnet.app` é um map das chaves que a Ana
escreveu, `web` e `db`, para as sub-redes:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "routes" {
  cidr_block = "10.40.0.0/16"
}

resource "aws_subnet" "app" {
  for_each = { web = "10.40.1.0/24", db = "10.40.3.0/24" }

  vpc_id     = aws_vpc.routes.id
  cidr_block = each.value
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.routes.id
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}
```

```
ana@laptop:~/shop/routes$ terraform plan -no-color | grep -E "^  # |^Plan"
  # aws_route_table.app will be created
  # aws_route_table_association.app["db"] will be created
  # aws_route_table_association.app["web"] will be created
  # aws_subnet.app["db"] will be created
  # aws_subnet.app["web"] will be created
  # aws_vpc.routes will be created
Plan: 6 to add, 0 to change, 0 to destroy.
```

As associações agora são `["db"]` e `["web"]`, com o nome de sub-redes que ela escolheu, e não de
ids que ninguém viu ainda. A outra saída que o erro menciona, `-target`, aplica parte da
configuração primeiro; a aula 9 explica por que isso é uma ferramenta de emergência e não um
desenho.

## Os meta-argumentos que esta aula não usou

`count`, `for_each` e `provider` são três dos argumentos que o Terraform lê em todo resource,
qualquer que seja o tipo. Mais dois são da mesma família. `depends_on` acrescenta uma ordem que as
referências não mostram, e `lifecycle` muda como um resource é substituído, protegido ou deixado
divergir. Os dois decidem o que acontece com um resource ao longo do tempo, e não quantos há, e a
aula 6 trata deles.
