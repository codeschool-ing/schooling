---
title: Regras de validação, preconditions e checks
version: 1
---

Um tipo diz que formato um valor tem. **Uma regra de validação diz quais valores desse formato
são aceitáveis**, e faz isso no próprio bloco da variável, com uma mensagem de erro que você
escreve. O Terraform tem quatro lugares para uma regra assim, e eles diferem em quando rodam e no
que acontece quando uma falha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três momentos de uma execução, da esquerda para a direita: os valores chegam, o plan, o apply. Quando os valores chegam, roda a validation da variável, e a falha dela é um erro antes de qualquer plan. Durante o plan, roda a precondition, que falha como erro; a postcondition roda se o valor já for conhecido; o bloco check roda e só avisa. Durante o apply, a postcondition cujo valor era desconhecido roda depois que a mudança foi feita, e o check roda de novo e avisa.\"><defs><marker id=\"ru-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">os valores chegam</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><path d=\"M212 52 L266 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ru-ah-wire)\"></path><path d=\"M452 52 L506 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ru-ah-wire)\"></path><text x=\"120.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">validation</text><text x=\"120.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">erro: nada é planejado</text><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">precondition</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">erro, antes do recurso</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">postcondition</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">erro, se o valor é conhecido</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">check</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um aviso; o plan segue</text><text x=\"600.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">postcondition</text><text x=\"600.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">erro, depois da mudança</text><text x=\"600.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">check</text><text x=\"600.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um aviso, de novo</text></svg>", "caption": "Onde cada tipo de regra é conferido. Só o bloco check deixa a execução seguir.", "same": ["plan", "apply"]}
```

## Validation, na variável

As variáveis da Ana ganham uma regra cada:

```hcl
variable "environment" {
  type        = string
  default     = "dev"
  description = "dev or prod."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment is dev or prod; the shop has no other."
  }
}

variable "network" {
  type = object({
    cidr   = string
    azs    = list(string)
    public = optional(bool, false)
  })
  default = {
    cidr = "10.20.0.0/16"
    azs  = ["sa-east-1a", "sa-east-1c"]
  }

  validation {
    condition     = can(cidrsubnet(var.network.cidr, 8, 2))
    error_message = "The network needs a CIDR range with room for /24 subnets, such as 10.20.0.0/16."
  }
}
```

Um bloco `validation` guarda uma `condition`, uma expressão que precisa dar `true`, e uma
`error_message` para quando não der. Uma variável pode ter várias. A condição de `network` é o
formato com `can` da seção de funções: pergunta se o `cidrsubnet` conseguiria cortar o segundo
`/24` da faixa, e trata qualquer erro como "não". Eis as duas recusando:

```
ana@laptop:~/shop$ terraform plan -var environment=staging

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│     ├────────────────
│     │ var.environment is "staging"
│ 
│ The environment is dev or prod; the shop has no other.
│ 
│ This was checked by the validation rule at variables.tf:6,3-13.
╵
```

```
ana@laptop:~/shop$ terraform plan -var 'network={ cidr = "10.20.0.0/26", azs = ["sa-east-1a", "sa-east-1c"] }'
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on variables.tf line 12:
│   12: variable "network" {
│     ├────────────────
│     │ var.network.cidr is "10.20.0.0/26"
│ 
│ The network needs a CIDR range with room for /24 subnets, such as
│ 10.20.0.0/16.
│ 
│ This was checked by the validation rule at variables.tf:23,3-13.
╵
```

**Nada foi planejado em nenhuma das execuções.** A mensagem é a frase que a Ana escreveu, abaixo de
uma linha dizendo que valor a quebrou, e assim quem digitou `staging` fica sabendo o que
a loja aceita, em palavras, antes que qualquer coisa seja planejada ou mudada. Um `/26` é uma faixa
válida e passa pelo tipo, e mesmo assim não tem espaço para sub-redes `/24`; a regra diz isso.
Desde o Terraform 1.9 uma condição pode se referir a outras variáveis além da sua.

## Preconditions e postconditions, num recurso

Algumas regras tratam de um valor que nenhuma variável sozinha guarda. O bucket de arquivos da loja
tem o nome montado a partir de três pedaços, e o S3 recusa um nome de bucket com mais de 63
caracteres:

```hcl
locals {
  bucket = "${local.name}-assets-${var.owner}"
}

resource "aws_s3_bucket" "assets" {
  bucket = local.bucket

  lifecycle {
    precondition {
      condition     = length(local.bucket) <= 63
      error_message = "Bucket names stop at 63 characters; ${local.bucket} has ${length(local.bucket)}."
    }
    postcondition {
      condition     = self.region == "sa-east-1"
      error_message = "The shop's files stay in São Paulo."
    }
  }
}
```

Uma **precondition** fica no bloco `lifecycle` de um recurso e é conferida antes de o Terraform
planejar esse recurso. Uma **postcondition** é conferida contra o recurso como ele vai ficar, ou
como voltou, e se refere a ele como `self`. Aqui a precondition guarda o nome, e a postcondition
confere que o bucket ficou em São Paulo. Com um owner longo o bastante para estourar o nome:

```
ana@laptop:~/shop$ terraform plan -var owner=ana-and-everybody-else-on-the-platform-team-of-the-shop
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]
aws_subnet.c: Refreshing state... [id=subnet-719532a052c2db8ea]
aws_subnet.a: Refreshing state... [id=subnet-e30146a6aa7865aaf]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform planned the following actions, but then encountered a problem:
```

O Terraform planejou as atualizações de tags que o owner longo causa nos outros três recursos, e
então:

```
Plan: 0 to add, 3 to change, 0 to destroy.
╷
│ Error: Resource precondition failed
│ 
│   on bucket.tf line 10, in resource "aws_s3_bucket" "assets":
│   10:       condition     = length(local.bucket) <= 63
│     ├────────────────
│     │ local.bucket is "shop-dev-assets-ana-and-everybody-else-on-the-platform-team-of-the-shop"
│ 
│ Bucket names stop at 63 characters;
│ shop-dev-assets-ana-and-everybody-else-on-the-platform-team-of-the-shop has
│ 71.
╵
```

O erro cita o nome e o tamanho dele, 71, porque a própria mensagem é um template. **O plan falhou,
então nada foi aplicado**, nem as atualizações de tags. Sem a precondition, o mesmo nome teria
chegado ao S3 na hora do apply, depois de as outras mudanças já terem sido feitas.

Uma postcondition cujo valor é conhecido durante o plan é conferida ali, como esta região. Quando o
valor só existe depois da mudança, o Terraform confere depois de fazer a mudança, e uma falha
nesse momento é um erro com o recurso já criado ou alterado. É o preço de uma regra sobre algo que
só a AWS sabe dizer.

## Blocos check, que só avisam

Um bloco `check` fica sozinho, fora de qualquer recurso, e **uma asserção que falha é um aviso, não
um erro**:

```hcl
check "two_zones" {
  assert {
    condition     = length(distinct(var.network.azs)) >= 2
    error_message = "With one zone, the shop goes down with that zone."
  }
}
```

Com a mesma zona duas vezes, o plan segue em frente:

```
ana@laptop:~/shop$ terraform plan -var 'network={ cidr = "10.20.0.0/16", azs = ["sa-east-1a", "sa-east-1a"] }'
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]
aws_s3_bucket.assets: Refreshing state... [id=shop-dev-assets-ana]
aws_subnet.c: Refreshing state... [id=subnet-719532a052c2db8ea]
aws_subnet.a: Refreshing state... [id=subnet-e30146a6aa7865aaf]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_subnet.c must be replaced
-/+ resource "aws_subnet" "c" {
      ~ arn                                            = "arn:aws:ec2:sa-east-1:123456789012:subnet/subnet-719532a052c2db8ea" -> (known after apply)
      ~ availability_zone                              = "sa-east-1c" -> "sa-east-1a" # forces replacement
```

```
Plan: 1 to add, 0 to change, 1 to destroy.
╷
│ Warning: Check block assertion failed
│ 
│   on checks.tf line 3, in check "two_zones":
│    3:     condition     = length(distinct(var.network.azs)) >= 2
│     ├────────────────
│     │ var.network.azs is list of string with 2 elements
│ 
│ With one zone, the shop goes down with that zone.
╵
```

O plan substituiria a sub-rede `c` na zona `sa-east-1a`, e o check disse o que achava disso e
deixou seguir. É a ferramenta certa para algo que vale saber e não vale parar; uma regra que
precisa valer pertence a uma validation ou a uma precondition. A aula 13 testa regras como estas de
propósito, alimentando-as com valores que devem falhar.
