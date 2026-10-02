---
title: As camadas de um teste, e quanto custa cada uma
version: 1
---

A maioria das pessoas chega acreditando que código de infraestrutura não dá para testar de
verdade: o único jeito de saber se uma configuração funciona é aplicá-la numa conta de
desenvolvimento e olhar. **Esse é um teste, o mais lento e o mais caro de cinco**, e ele acha o
erro por último, depois que tudo o que é mais barato teve a chance de achá-lo antes. Uma suíte de
testes para Terraform é uma escada. Cada degrau precisa de mais do que o de cima e acha algo que o
de cima não enxerga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Cinco verificações numa tabela, a mais barata no topo. terraform fmt não precisa de nada e acha formatação. terraform validate precisa dos providers instalados e acha nomes, argumentos e referências errados. Um scanner, aula 14, não precisa de nada e acha o que o código expõe. Um run de teste com command = plan precisa de uma API que responda, ou de um mock, e acha o que o plano faria com valores dados. Um run com command = apply precisa de uma conta, aqui o moto, e acha o que a AWS aceita e devolve. Uma seta ao lado diz que cada degrau é mais lento, mais caro e mais perto da AWS.\"><defs><marker id=\"ly-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"150.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">verificação</text><text x=\"345.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">precisa de</text><text x=\"555.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">acha</text><rect x=\"60\" y=\"44\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">terraform fmt</text><text x=\"345.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada</text><text x=\"555.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">formatação</text><rect x=\"60\" y=\"100\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">terraform validate</text><text x=\"345.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os providers instalados</text><text x=\"555.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nomes, argumentos, referências</text><rect x=\"60\" y=\"156\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um scanner (aula 14)</text><text x=\"345.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada</text><text x=\"555.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o código expõe</text><rect x=\"60\" y=\"212\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">command = plan</text><text x=\"345.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma API que responda, ou um mock</text><text x=\"555.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o plano faz com esses valores</text><rect x=\"60\" y=\"268\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">command = apply</text><text x=\"345.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma conta (aqui, o moto)</text><text x=\"555.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que a AWS aceita e devolve</text><path d=\"M30 48 L30 312\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah-amber)\"></path><text x=\"30.0\" y=\"322.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">mais lento, mais caro, mais perto da AWS</text></svg>", "caption": "Cada verificação acha o que as de cima não acham, e custa mais para rodar."}
```

**`terraform fmt`** confere só a formatação dos arquivos, e não precisa de nada. Ele tem lugar na
suíte porque um pull request que reformata quarenta linhas para mudar uma esconde essa uma.

**`terraform validate`** lê todos os arquivos do diretório e os confere contra eles mesmos e contra
os schemas dos providers: que todo argumento existe, que toda referência aponta para algo
declarado, que todo tipo encaixa. Ele precisa dos providers instalados e de mais nada. Nem
credenciais, nem API, nem valores para as variáveis. Essa é a força dele, e é também tudo o que ele
deixa passar.

**Um scanner**, assunto da aula 14, lê os mesmos arquivos procurando o que eles expõem: um bucket
aberto para o mundo, a porta 22 aberta para `0.0.0.0/0`. É uma regra sobre o código, escrita por
outra pessoa, e aparece aqui só para você saber onde ela fica.

**Um run de teste com `command = plan`** dá valores ao módulo e faz afirmações sobre o plano que o
Terraform faria com eles: quantas sub-redes, em quais zonas, com quais nomes. Ele não cria nada,
então pode rodar a cada commit. Precisa de um provider que responda perguntas durante o plan, que é
a AWS, o moto neste curso, ou um mock que responda no lugar dela.

**Um run de teste com `command = apply`** constrói a coisa, faz afirmações sobre o que voltou e a
destrói. É o único degrau que descobre se a AWS aceita o que o plano propôs, e numa conta real é o
único degrau que custa dinheiro.

## O módulo testado

O módulo que esta aula testa é pequeno de propósito. A aula 10 é sobre escrever módulos; esta
precisa só de algo com entradas, uma ou duas regras e recursos cuja forma depende dos valores. O
módulo `network` da Ana recebe um nome, uma faixa e um mapa de sub-redes:

```hcl
variable "name" {
  type        = string
  description = "Prefix for every Name tag."
}

variable "cidr" {
  type        = string
  description = "The VPC's range, such as 10.20.0.0/16."

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be an IPv4 range such as 10.20.0.0/16."
  }
}

variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "One subnet per key: its range and its availability zone."
}
```

```hcl
data "aws_availability_zones" "here" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.name}-${each.key}" }

  lifecycle {
    precondition {
      condition     = contains(data.aws_availability_zones.here.names, each.value.az)
      error_message = "Zone ${each.value.az} is not one this region offers."
    }
  }
}
```

A `precondition` lê de um data source as zonas que a região de fato oferece, então uma sub-rede
numa zona que não existe é recusada antes de qualquer coisa ser criada. A aula 3 apresentou os dois
tipos de regra; aqui eles importam porque são coisas em que um teste pode mirar. O `versions.tf`
exige Terraform 1.9 ou mais novo e o provider da AWS, e o `outputs.tf` devolve o id da VPC e um
mapa com os ids das sub-redes.

No fim da aula o módulo tem quatro arquivos de teste e um módulo auxiliar, todos em `tests/`, que é
onde o `terraform test` procura por padrão:

```
ana@laptop:~/shop/modules/network$ tree
.
├── main.tf
├── outputs.tf
├── tests
│   ├── aws
│   │   └── main.tf
│   ├── e2e.tftest.hcl
│   ├── plan.tftest.hcl
│   ├── rules.tftest.hcl
│   └── unit.tftest.hcl
├── variables.tf
└── versions.tf

3 directories, 9 files
```

**A maior parte dos testes fica na ponta barata.** Dos oito runs da suíte pronta, quatro não
precisam da AWS para nada, dois fazem perguntas à AWS durante um plan e dois fazem apply contra
ela. Essa proporção é o sentido da escada: pegar o erro no degrau mais barato de subir, e guardar o
apply para as poucas perguntas que só a AWS sabe responder.
