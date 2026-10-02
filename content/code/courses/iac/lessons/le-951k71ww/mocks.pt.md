---
title: Mock providers, e um teste que não precisa de nuvem
version: 1
---

Um run com `command = plan` não cria nada, e ainda assim conversa com a AWS. O provider confere as
credenciais quando inicia e lê todos os data sources durante o plan. **Então um teste de plan só
está disponível quando a API por trás dele está.** Aponte o laboratório para uma porta onde nada
escuta, e os mesmos dois testes que passaram há pouco nem começam:

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... skip
  run "names_carry_the_prefix"... skip
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... fail
╷
│ Error: Retrieving AWS account details: validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity, exceeded maximum number of attempts, 9, https response error StatusCode: 0, RequestID: , request send failed, Post "http://localhost:4567/": dial tcp 127.0.0.1:4567: connect: connection refused
│ 
│ 
╵

Failure! 0 passed, 0 failed, 2 skipped.
```

`skip`, não `fail`: os runs nem foram tentados, porque o provider não pôde ser configurado. Numa
conta real acontece o mesmo quando as credenciais expiram, quando um pipeline não tem nenhuma ou
quando quem contribui não tem acesso à conta. Um teste que depende de qualquer uma dessas coisas é
um teste que as pessoas param de rodar.

## mock_provider

Desde o Terraform 1.7, um arquivo de teste pode trocar um provider por um mock. **Um mock provider
mantém o schema do provider real e nunca chama a API dele**: todo atributo que um provider real
calcularia, um id ou um ARN, ele inventa. Com o mock, um run pode até fazer `apply`, porque aplicar
num mock não cria nada em lugar nenhum. A Ana escreve o teste que a seção anterior não conseguiu,
com o endpoint ainda apontando para o nada:

```hcl
mock_provider "aws" {}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  assert {
    condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
    error_message = "Subnet a is not in the module's VPC."
  }
}
```

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/unit.tftest.hcl
tests/unit.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... fail
╷
│ Error: Resource precondition failed
│ 
│   on main.tf line 21, in resource "aws_subnet" "this":
│   21:       condition     = contains(data.aws_availability_zones.here.names, each.value.az)
│     ├────────────────
│     │ data.aws_availability_zones.here.names is empty list of string
│     │ each.value.az is "sa-east-1a"
│ 
│ Zone sa-east-1a is not one this region offers.
╵
tests/unit.tftest.hcl... tearing down
tests/unit.tftest.hcl... fail

Failure! 0 passed, 1 failed.
```

Essa falha é a coisa mais útil que um mock faz no primeiro dia, porque mostra a dependência do
módulo em relação ao mundo de fora. A precondition pergunta ao data source quais zonas a região
oferece, e **um mock responde toda lista com uma lista vazia**. Nenhuma zona existe, então nenhuma
sub-rede pode ser criada. O módulo está certo em recusar; o teste é que precisa fornecer o mundo.

## override_data e override_resource

Um override fixa o valor de um data source ou de um recurso, para o arquivo inteiro ou dentro de um
único `run`. A Ana dá às zonas uma resposta de verdade e à VPC um id sobre o qual ela pode fazer
afirmações:

```hcl
mock_provider "aws" {}

override_data {
  target = data.aws_availability_zones.here
  values = {
    names = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  }
}

override_resource {
  target = aws_vpc.this
  values = {
    id = "vpc-0123456789abcdef0"
  }
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  assert {
    condition     = aws_subnet.this["a"].vpc_id == "vpc-0123456789abcdef0"
    error_message = "Subnet a is in ${aws_subnet.this["a"].vpc_id}."
  }

  assert {
    condition     = output.subnet_ids["a"] == aws_subnet.this["a"].id
    error_message = "The output does not carry subnet a's id."
  }
}
```

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/unit.tftest.hcl
tests/unit.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... pass
tests/unit.tftest.hcl... tearing down
tests/unit.tftest.hcl... pass

Success! 1 passed, 0 failed.
```

**Um run, sem rede, e a pergunta da seção anterior respondida**: o `vpc_id` da sub-rede é o id da
VPC, porque o módulo liga um ao outro, e o output carrega o id da sub-rede. Com `-verbose`, o run
imprime o state que o mock produziu, e a sub-rede mostra do que um mock é feito:

```
# aws_subnet.this["a"]:
resource "aws_subnet" "this" {
    arn                                 = "jhm1adza"
    availability_zone                   = "sa-east-1a"
    availability_zone_id                = "403cwd9r"
    cidr_block                          = "10.20.1.0/24"
    id                                  = "l0t3iehz"
    ipv6_cidr_block                     = "kugbyqub"
    ipv6_cidr_block_association_id      = "t4n5woph"
    owner_id                            = "cjw54oll"
    private_dns_hostname_type_on_launch = "fpr535ti"
    region                              = "241ub8wp"
    tags                                = {
        "Name" = "shop-a"
    }
    tags_all                            = {}
    vpc_id                              = "vpc-0123456789abcdef0"
}
```

A zona, a faixa e a tag vieram do módulo. O `vpc_id` veio do override da Ana. Todos os outros
atributos calculados são oito caracteres aleatórios, inclusive `region`, e nenhum se parece com algo
que a AWS devolveria. Outra execução imprime outros.

## O que um mock não sabe dizer

**Um mock prova a lógica do próprio módulo, e nada sobre a AWS.** Ele aceitou uma sub-rede sem
perguntar se a faixa fica dentro da VPC, se a zona existe ou se a conta pode criar sub-redes, porque
nenhuma dessas perguntas chega até ele. As zonas do override são o que a Ana acredita que São Paulo
oferece; se ela estiver errada, o mock erra junto. Essa é a troca: um teste unitário com mock roda
em qualquer lugar, num pipeline sem credenciais e num notebook sem rede, e o preço é que toda
resposta de fora é uma que você mesmo escreveu.

Blocos `mock_resource` e `mock_data` dentro de `mock_provider` definem defaults para todas as
instâncias de um tipo, enquanto um override mira um endereço. Um override também aceita
`override_during = plan`, a opção que o erro anterior sugeria, que torna os valores dele conhecidos
durante um plan além de um apply.
