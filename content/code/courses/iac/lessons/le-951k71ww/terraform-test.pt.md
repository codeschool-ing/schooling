---
title: terraform test, e um run que só faz o plan
version: 2
---

O `terraform test` vem embutido no Terraform desde a 1.6. **Ele lê arquivos terminados em
`.tftest.hcl`, escritos no mesmo HCL do módulo, e roda cada bloco `run` como um plan ou um apply
contra um state só dele**, nunca o state de um deploy de verdade. Cada `run` traz afirmações, e o
comando informa quais se sustentaram. Não há nada para instalar nem uma segunda linguagem para
aprender.

O primeiro arquivo de teste da Ana, `tests/plan.tftest.hcl`, faz o plan do módulo com os valores
reais da loja e faz duas perguntas:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name = "shop"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { cidr = "10.20.1.0/24", az = "sa-east-1a" }
    c = { cidr = "10.20.2.0/24", az = "sa-east-1c" }
  }
}

run "one_subnet_per_entry" {
  command = plan

  assert {
    condition     = length(aws_subnet.this) == 2
    error_message = "Expected one subnet per entry in var.subnets."
  }

  assert {
    condition     = aws_subnet.this["c"].availability_zone == "sa-east-1c"
    error_message = "Subnet c is not in sa-east-1c."
  }
}

run "names_carry_the_prefix" {
  command = plan

  variables {
    name = "shop-dev"
  }

  assert {
    condition     = aws_subnet.this["a"].tags.Name == "shop-dev-a"
    error_message = "Subnet a is called ${aws_subnet.this["a"].tags.Name}."
  }
}
```

Leia de cima para baixo. **O bloco `provider` configura a AWS para o teste**, porque um módulo deixa
isso para quem o chama, e num teste quem chama é o arquivo. **O bloco `variables` dá a todos os
runs as mesmas entradas**, e um bloco `variables` dentro de um `run` as sobrescreve só para aquele
run, que é como `names_carry_the_prefix` testa um segundo nome sem repetir as sub-redes. **`command
= plan` para cada run depois do plan**: nada é criado, e as afirmações são avaliadas contra o plano
que o Terraform faria.

Um `assert` é uma `condition` e uma `error_message`, o mesmo par de uma regra de validação. Dentro
dele você se refere aos recursos do módulo pelos endereços, `aws_subnet.this["c"]`, e aos outputs
como `output.vpc_id`. A mensagem é um template, então pode dizer o que encontrou:

```
ana@laptop:~/shop/modules/network$ terraform test
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... pass
  run "names_carry_the_prefix"... pass
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

Cada arquivo é preparado, seus runs vão em ordem, e o arquivo é desmontado. Para um arquivo que só
fez plan não há nada a destruir, mas a linha aparece do mesmo jeito.

## Um teste que se paga

Um mês depois, um colega decide que as sub-redes deviam dizer o que são, e muda uma tag no
`main.tf`. A mudança é razoável, e ela renomeia todas as sub-redes que o módulo já criou. O
comando do colega foi:

```sh
sed -i 's/Name = "${var.name}-${each.key}"/Name = "${var.name}-subnet-${each.key}"/' main.tf
```

O teste percebe:

```
ana@laptop:~/shop/modules/network$ grep -n "Name =" main.tf
8:  tags                 = { Name = var.name }
17:  tags              = { Name = "${var.name}-subnet-${each.key}" }
ana@laptop:~/shop/modules/network$ terraform test
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... pass
  run "names_carry_the_prefix"... fail
╷
│ Error: Test assertion failed
│ 
│   on tests/plan.tftest.hcl line 36, in run "names_carry_the_prefix":
│   36:     condition     = aws_subnet.this["a"].tags.Name == "shop-dev-a"
│     ├────────────────
│     │ Diff:
│     │ --- actual
│     │ +++ expected
│     │ - "shop-dev-subnet-a"
│     │ + "shop-dev-a"
│ 
│ 
│ Subnet a is called shop-dev-subnet-a.
╵
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... fail

Failure! 1 passed, 1 failed.
```

**A falha nomeia o run, o arquivo, a linha e a condição**, depois mostra um diff dos dois lados, e
depois imprime a mensagem da Ana com o nome real dentro. Qualquer coisa que ache sub-redes pela tag
`Name`, como fazem os data sources da aula 5, teria deixado de achá-las, e ninguém precisou lembrar
disso; o teste lembrou. Se a mudança está certa ainda é uma decisão de uma pessoa. O teste garantiu
que seja uma decisão e não um acidente.

Até essa decisão ser tomada, a Ana devolve a tag ao que era:

```sh
sed -i 's/Name = "${var.name}-subnet-${each.key}"/Name = "${var.name}-${each.key}"/' main.tf
```

## O que um plan não sabe responder

Um plan sabe o que você escreveu e o que a AWS já tem. Ele não sabe os ids que a AWS vai inventar.
A Ana tenta afirmar, num plan, que uma sub-rede cai na própria VPC do módulo, num arquivo só para
isso, `tests/link.tftest.hcl`:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  command = plan

  assert {
    condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
    error_message = "Subnet a is not in the module's VPC."
  }
}
```

```
ana@laptop:~/shop/modules/network$ terraform test -filter=tests/link.tftest.hcl
tests/link.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... fail
╷
│ Error: Unknown condition value
│ 
│   on tests/link.tftest.hcl line 15, in run "subnet_is_in_the_vpc":
│   15:     condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
│     ├────────────────
│     │ aws_subnet.this["a"].vpc_id is a string
│     │ aws_vpc.this.id is a string
│ 
│ Condition expression could not be evaluated at this time. This means you
│ have executed a `run` block with `command = plan` and one of the values
│ your condition depended on is not known until after the plan has been
│ applied. Either remove this value from your condition, or execute an
│ `apply` command from this `run` block. Alternatively, if there is an
│ override for this value, you can make it available during the plan phase by
│ setting `override_during = plan` in the `override_` block.
╵
tests/link.tftest.hcl... tearing down
tests/link.tftest.hcl... fail

Failure! 0 passed, 1 failed.
```

Os dois lados são strings que o Terraform ainda não conhece, então a condição não pode ser
avaliada, e o Terraform se recusa a chamar isso de aprovado. A mensagem aponta as saídas: tirar o
valor, fazer apply no run, ou fornecer o valor você mesmo com um override. **Uma afirmação num plan
só pode ser sobre o que se sabe na hora do plan**: os valores que você passou e o que é calculado só
a partir deles. A próxima seção responde a esta pergunta sem a AWS, e a última responde com a AWS. O arquivo só
existia para mostrar o erro, então a Ana o apaga, `rm tests/link.tftest.hcl`.

`terraform test` sem argumentos roda todos os arquivos de teste em `tests/` e no próprio diretório
do módulo, em ordem alfabética. `-filter=tests/link.tftest.hcl` roda um arquivo, como acima, e
`-verbose` imprime o plano ou o state de cada run à medida que roda.
