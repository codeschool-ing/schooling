---
title: Testar que uma regra recusa o que deve
version: 2
---

O módulo tem duas regras: `cidr` precisa ser uma faixa com máscara, e a zona de uma sub-rede precisa
ser uma que a região oferece. As duas foram escritas para o dia em que alguém passar o valor errado,
e **uma regra que ninguém viu recusar nada é uma regra que ninguém sabe se funciona**. Um run que dá
a ela um valor ruim normalmente falharia, que é o contrário do que um teste deve informar.
`expect_failures` inverte isso. O `tests/rules.tftest.hcl` da Ana:

```hcl
mock_provider "aws" {}

override_data {
  target = data.aws_availability_zones.here
  values = {
    names = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  }
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "cidr_without_a_mask" {
  command = plan

  variables {
    cidr = "10.20.0.0"
  }

  expect_failures = [var.cidr]
}

run "zone_from_another_region" {
  command = plan

  variables {
    subnets = { a = { cidr = "10.20.1.0/24", az = "us-east-1a" } }
  }

  expect_failures = [aws_subnet.this]
}
```

`expect_failures` lista os objetos que precisam falhar neste run: uma variável, pelos blocos
`validation` dela, ou um recurso, pelas preconditions e postconditions. **O run passa quando esses
objetos falham**, e falha se um deles deixar o valor passar. O arquivo usa o mesmo mock e o mesmo
override do teste unitário, então também não precisa da AWS:

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... pass
  run "zone_from_another_region"... pass
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

Dois aprovados, cada um uma recusa que aconteceu onde devia. `cidr_without_a_mask` para na
variável, antes de qualquer recurso entrar no plano. `zone_from_another_region` chega até a
sub-rede, cuja precondition procura `us-east-1a` na lista de zonas de São Paulo do override e não
encontra.

## Quando a regra quebra

Regras são afrouxadas como qualquer código: alguém precisa de um valor que a regra recusa e
simplifica a condição. Aqui a regra de `cidr` é reduzida a "dígitos, pontos e barras", que ainda
parece uma faixa. A edição, no `variables.tf`:

```sh
sed -i 's|condition     = can(cidrnetmask(var.cidr))|condition     = can(regex("^[0-9./]+$", var.cidr))|' variables.tf
```

```
ana@laptop:~/shop/modules/network$ grep -n "condition" variables.tf
11:    condition     = can(regex("^[0-9./]+$", var.cidr))
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... fail
╷
│ Error: expected cidr_block to contain a valid Value, got: 10.20.0.0 with err: invalid CIDR address: 10.20.0.0
│ 
│   with aws_vpc.this,
│   on main.tf line 6, in resource "aws_vpc" "this":
│    6:   cidr_block           = var.cidr
│ 
╵
╷
│ Error: Missing expected failure
│ 
│   on tests/rules.tftest.hcl line 23, in run "cidr_without_a_mask":
│   23:   expect_failures = [var.cidr]
│ 
│ The checkable object, var.cidr, was expected to report an error but did
│ not.
╵
  run "zone_from_another_region"... skip
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... fail

Failure! 0 passed, 1 failed, 1 skipped.
```

Leia os dois erros na ordem, porque o primeiro é uma armadilha. **`10.20.0.0` continuou sendo
recusado, só que não pela regra da Ana**: a verificação do próprio provider da AWS sobre
`cidr_block` o pegou, e essa verificação roda também sob um mock, porque pertence ao schema do
provider e não à API dele. Um teste que só perguntasse "este run falhou?" teria passado e declarado
a regra saudável.

`expect_failures` fez uma pergunta mais estreita, `var.cidr` falhou?, e a resposta foi não. Então o
run falha com `Missing expected failure`, nomeando o objeto que deixou o valor passar. A diferença
importa além deste módulo: uma regra existe para falhar cedo, na variável, com a frase que você
escreveu para quem digitou o valor. A mensagem do provider chega depois e fala de `cidr_block`, algo
que quem chama o módulo nunca escreveu.

**O run seguinte a um run que falhou é pulado**, como `zone_from_another_region` foi aqui. Os runs
de um arquivo vão em ordem e compartilham um state, e o Terraform não segue adiante depois de uma
falha, então uma regra quebrada pode esconder se a próxima ainda funciona até a primeira ser
consertada. A Ana devolve a regra ao que era:

```sh
sed -i 's|condition     = can(regex("^\[0-9./\]+$", var.cidr))|condition     = can(cidrnetmask(var.cidr))|' variables.tf
```

## O que testar assim

Toda `validation`, `precondition` e `postcondition` de um módulo merece um run com um valor que ela
precisa recusar. Escolha o valor que uma pessoa real digitaria, como `10.20.0.0`, em vez de algo
absurdo: uma regra que recusa bobagem e aceita o quase certo é o jeito comum de essas regras
falharem. Um valor ruim por run, como neste arquivo, deixa cada recusa atribuível a uma regra só. Um
bloco `check` é diferente: ele só avisa, como a aula 3 mostrou, então a falha dele nunca para um
plan e é uma base fraca para um teste.
