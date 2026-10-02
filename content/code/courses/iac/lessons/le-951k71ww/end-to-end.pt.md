---
title: Uma execução ponta a ponta, contra o moto
version: 1
---

Tudo até aqui perguntou ao Terraform o que ele faria. **Um teste ponta a ponta faz**: ele aplica o
módulo, pergunta à AWS o que existe agora e destrói tudo de novo. É o degrau mais lento e o único
que consegue descobrir se a AWS concorda com o plano. A própria ajuda do Terraform diz com todas as
letras para que serve o comando:

```
ana@laptop:~/shop/modules/network$ terraform test -h
Usage: terraform [global options] test [options]

  Executes automated integration tests against the current Terraform
  configuration.

  Terraform will search for .tftest.hcl files within the current configuration
  and testing directories. Terraform will then execute the testing run blocks
  within any testing files in order, and verify conditional checks and
  assertions against the created infrastructure.

  This command creates real infrastructure and will attempt to clean up the
  testing infrastructure on completion. Monitor the output carefully to ensure
  this cleanup process is successful.
```

Neste curso, a "infraestrutura real" é o moto, então nada abaixo foi cobrado. Numa conta real, cada
execução deste arquivo cria uma VPC e duas sub-redes, e custa o que elas custam enquanto existem.

## Construir, e depois perguntar à AWS

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name = "shop-e2e"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { cidr = "10.20.1.0/24", az = "sa-east-1a" }
    c = { cidr = "10.20.2.0/24", az = "sa-east-1c" }
  }
}

run "build" {
  command = apply

  assert {
    condition     = alltrue([for s in aws_subnet.this : s.vpc_id == aws_vpc.this.id])
    error_message = "A subnet landed outside the module's VPC."
  }
}

run "aws_agrees" {
  module {
    source = "./tests/aws"
  }

  variables {
    vpc_id = run.build.vpc_id
  }

  assert {
    condition     = data.aws_vpc.built.cidr_block == "10.20.0.0/16"
    error_message = "AWS reports the VPC as ${data.aws_vpc.built.cidr_block}."
  }

  assert {
    condition     = length(data.aws_subnets.built.ids) == 2
    error_message = "AWS reports ${length(data.aws_subnets.built.ids)} subnets in the VPC."
  }
}
```

`build` aplica o módulo e confere que toda sub-rede está na VPC do módulo, a afirmação que falhou
num plan, agora avaliada contra ids que a AWS de fato devolveu. Mas isso ainda é o Terraform
corrigindo a própria prova, já que os valores vêm do que o Terraform registrou. **`aws_agrees`
pergunta à AWS**, por meio de um módulo auxiliar: o bloco `module` de um run troca o módulo testado
por outro, aqui um diretório de data sources que leem a VPC de volta pelo id.

```hcl
# A helper module for the tests: it reads the VPC back from AWS.
variable "vpc_id" {
  type = string
}

data "aws_vpc" "built" {
  id = var.vpc_id
}

data "aws_subnets" "built" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
```

O id passa de um run para outro como `run.build.vpc_id`, o output de um run anterior, que é como um
run entrega um valor ao próximo. Um módulo auxiliar é um módulo como outro qualquer, então o
`terraform init` precisa instalá-lo antes de o teste poder usá-lo:

```
ana@laptop:~/shop/modules/network$ terraform init
Initializing the backend...

Initializing modules...
- test.tests.e2e.aws_agrees in tests/aws

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.67.0

```

```
ana@laptop:~/shop/modules/network$ terraform test -filter=tests/e2e.tftest.hcl
tests/e2e.tftest.hcl... in progress
  run "build"... pass
  run "aws_agrees"... pass
tests/e2e.tftest.hcl... tearing down
tests/e2e.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um arquivo de teste ponta a ponta, da esquerda para a direita. O run chamado build aplica o módulo e cria uma VPC e duas sub-redes na AWS, aqui o moto. O run chamado aws_agrees usa um módulo auxiliar cujos data sources leem de volta da AWS a VPC e suas sub-redes. Depois o teste faz a limpeza e destrói o que o build criou.\"><defs><marker id=\"ee-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ee-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ee-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run \"build\"</text><text x=\"125.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aplica o módulo</text><rect x=\"265\" y=\"30\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run \"aws_agrees\"</text><text x=\"360.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um módulo auxiliar lê</text><rect x=\"500\" y=\"30\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">limpeza</text><text x=\"595.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">destrói na ordem inversa</text><path d=\"M222 65 L262 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-wire)\"></path><path d=\"M457 65 L497 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-wire)\"></path><rect x=\"30\" y=\"180\" width=\"660\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AWS (no laboratório, o moto)</text><path d=\"M125 102 L125 177\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-phosphor)\"></path><text x=\"135.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">cria uma VPC, duas sub-redes</text><path d=\"M360 177 L360 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-phosphor)\"></path><text x=\"370.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">lê de volta</text><path d=\"M595 102 L595 177\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-amber)\"></path><text x=\"585.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">destrói</text></svg>", "caption": "Um teste ponta a ponta constrói a coisa real, pergunta à AWS sobre ela e a remove."}
```

`tearing down` é onde o Terraform destruiu os recursos do arquivo, na ordem inversa da criação. Depois
do run, a AWS guarda só a VPC padrão que o moto cria em toda região, como a AWS faz:

```
ana@laptop:~/shop/modules/network$ aws ec2 describe-vpcs --query "Vpcs[].[CidrBlock,IsDefault]" --output text
172.31.0.0/16	True
```

## O que só um apply encontra

Eis o caso que os degraus anteriores não pegavam. Uma sub-rede `10.30.1.0/24` numa VPC
`10.20.0.0/16` é uma faixa válida, numa zona real, do tipo certo. O `validate` não tem valores para
olhar, o plan não tem motivo para objetar e um mock aceita qualquer coisa. A AWS recusa:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name    = "shop-range"
  cidr    = "10.20.0.0/16"
  subnets = { b = { cidr = "10.30.1.0/24", az = "sa-east-1a" } }
}

run "plan_accepts_it" {
  command = plan
}

run "apply_refuses_it" {
  command = apply
}
```

```
ana@laptop:~/shop/modules/network$ terraform test -filter=tests/range.tftest.hcl
tests/range.tftest.hcl... in progress
  run "plan_accepts_it"... pass
  run "apply_refuses_it"... fail
╷
│ Error: creating EC2 Subnet: operation error EC2: CreateSubnet, https response error StatusCode: 400, RequestID: qEQGGh8HNnVprVhob3z5gwJyohxQIqEXuYWJ29WOm5bUT5WKwxJp, api error InvalidSubnet.Range: The CIDR '10.30.1.0/24' is invalid.
│ 
│   with aws_subnet.this["b"],
│   on main.tf line 11, in resource "aws_subnet" "this":
│   11: resource "aws_subnet" "this" {
│ 
╵
tests/range.tftest.hcl... tearing down
tests/range.tftest.hcl... fail

Failure! 1 passed, 1 failed.
ana@laptop:~/shop/modules/network$ aws ec2 describe-vpcs --query "Vpcs[].[CidrBlock,IsDefault]" --output text
172.31.0.0/16	True
```

**O plan passou, e o apply dos mesmos valores falhou**, com o código de erro da própria API,
`InvalidSubnet.Range`. Na limpeza, o Terraform destruiu a VPC que o run já tinha criado, e o
`describe-vpcs` não mostra nada sobrando. Essa limpeza é o que o texto de ajuda manda acompanhar:
numa conta real, o que uma limpeza que falhou deixa para trás fica lá, e é cobrado, até alguém
remover.

Uma falha ponta a ponta é cara de encontrar, então a resposta certa é subir esse conhecimento na
escada. A Ana acrescenta a `subnets` uma regra que compara a rede de cada sub-rede com a da VPC;
ela exige Terraform 1.9, porque a condição lê uma segunda variável. Depois acrescenta ao
`rules.tftest.hcl` um run que espera a recusa da regra:

```
ana@laptop:~/shop/modules/network$ tail -n 10 variables.tf
  validation {
    # The subnet's first address, cut to the VPC's prefix, is the VPC's own
    # network address. If var.cidr is itself broken, its rule says so.
    condition = try(alltrue([
      for s in values(var.subnets) :
      cidrhost("${split("/", s.cidr)[0]}/${split("/", var.cidr)[1]}", 0) == cidrhost(var.cidr, 0)
    ]), true)
    error_message = "Every subnet must lie inside the VPC's range, ${var.cidr}."
  }
}
ana@laptop:~/shop/modules/network$ tail -n 9 tests/rules.tftest.hcl
run "subnet_outside_the_vpc" {
  command = plan

  variables {
    subnets = { b = { cidr = "10.30.1.0/24", az = "sa-east-1a" } }
  }

  expect_failures = [var.subnets]
}
```

```
ana@laptop:~/shop/modules/network$ rm tests/range.tftest.hcl
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... pass
  run "zone_from_another_region"... pass
  run "subnet_outside_the_vpc"... pass
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

O arquivo de faixa cumpriu seu papel e sai. O mesmo erro agora falha na variável, com a frase da
Ana, num teste que não precisa da AWS. A suíte inteira, com o arquivo ponta a ponta ainda nela:

```
ana@laptop:~/shop/modules/network$ terraform test
tests/e2e.tftest.hcl... in progress
  run "build"... pass
  run "aws_agrees"... pass
tests/e2e.tftest.hcl... tearing down
tests/e2e.tftest.hcl... pass
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... pass
  run "names_carry_the_prefix"... pass
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... pass
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... pass
  run "zone_from_another_region"... pass
  run "subnet_outside_the_vpc"... pass
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... pass
tests/unit.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... pass
tests/unit.tftest.hcl... tearing down
tests/unit.tftest.hcl... pass

Success! 8 passed, 0 failed.
```

## Terratest, e com que frequência rodar isto

O outro jeito comum de escrever estes testes é o **Terratest**, uma biblioteca em Go da Gruntwork:
um teste em Go roda `terraform apply`, chama o SDK da própria nuvem para inspecionar o resultado e
roda `terraform destroy` numa função adiada. Ele alcança mais longe do que um módulo auxiliar, por
exemplo fazendo uma requisição HTTP a um servidor que acabou de criar, ao preço de uma segunda
linguagem. Ele é citado aqui e não foi rodado neste laboratório.

Seja qual for, rode testes ponta a ponta com menos frequência que o resto: num pull request que
muda o módulo, ou toda noite, numa conta só deles que não guarda mais nada. A aula 15 põe os degraus
baratos em todo commit.
