---
title: Locals, e dizer uma coisa uma vez só
version: 1
---

Todo recurso da loja deveria levar as mesmas três tags, `Project`, `Owner` e `Environment`, e um
nome montado a partir do ambiente. Escritas à mão em cada recurso, as três cópias concordam no dia
em que são digitadas e se separam na primeira edição que alguém fizer em só duas delas. **Um valor
local dá nome a uma expressão uma vez**, e todo o resto se refere ao nome:

```hcl
locals {
  name = "shop-${var.environment}"

  common_tags = {
    Project     = "shop"
    Owner       = var.owner
    Environment = var.environment
  }
}
```

O bloco é `locals`, no plural, e guarda quantos nomes você quiser; a referência é `local.name`, no
singular. Essa diferença é um erro de digitação que todo mundo comete uma vez. Um local pode usar
qualquer expressão, inclusive outros locals, variáveis e atributos de recursos, e o Terraform
descobre a ordem pelas referências, como faz com os recursos.

As sub-redes agora leem tudo de outro lugar: a faixa do `cidrsubnet`, a zona da variável, as tags
do local, combinadas com um `Name` próprio:

```hcl
resource "aws_subnet" "a" {
  vpc_id                  = aws_vpc.shop.id
  cidr_block              = cidrsubnet(var.network.cidr, 8, 1)
  availability_zone       = var.network.azs[0]
  map_public_ip_on_launch = var.network.public
  tags                    = merge(local.common_tags, { Name = "${local.name}-a" })
}

resource "aws_subnet" "c" {
  vpc_id                  = aws_vpc.shop.id
  cidr_block              = cidrsubnet(var.network.cidr, 8, 2)
  availability_zone       = var.network.azs[1]
  map_public_ip_on_launch = var.network.public
  tags                    = merge(local.common_tags, { Name = "${local.name}-c" })
}
```

A VPC do `main.tf` recebe o mesmo tratamento, e as tags agora vêm de um lugar só em todos os
arquivos:

```
ana@laptop:~/shop$ grep -n "tags" *.tf
locals.tf:4:  common_tags = {
main.tf:20:  tags                 = merge(local.common_tags, { Name = local.name })
network.tf:6:  tags                    = merge(local.common_tags, { Name = "${local.name}-a" })
network.tf:14:  tags                    = merge(local.common_tags, { Name = "${local.name}-c" })
```

Aplicado no moto, o plan mostra cada valor calculado. Eis a primeira sub-rede, cortada depois das
tags:

```
ana@laptop:~/shop$ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_subnet.a will be created
  + resource "aws_subnet" "a" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "sa-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.20.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "sa-east-1"
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "shop-dev-a"
          + "Owner"       = "ana"
          + "Project"     = "shop"
        }
```

E o fim da execução:

```
Plan: 3 to add, 0 to change, 0 to destroy.
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 1s [id=vpc-1421f4c581e114d46]
aws_subnet.c: Creating...
aws_subnet.a: Creating...
aws_subnet.c: Creation complete after 0s [id=subnet-719532a052c2db8ea]
aws_subnet.a: Creation complete after 0s [id=subnet-e30146a6aa7865aaf]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Três recursos, e nenhuma tag ou faixa deles foi digitada duas vezes. `shop-dev-a` veio de
`"${local.name}-a"`, que veio de `var.environment`; mude o ambiente e todo nome e toda tag vão
junto.

## Um local não é uma variável

Os dois se parecem de dentro do arquivo, já que ambos são um nome com um valor, e são diferentes
de fora. **Uma variável é uma entrada**: quem roda o Terraform pode defini-la, com `-var`, um
arquivo `.tfvars` ou uma variável de ambiente `TF_VAR_`, como a aula 2 mostrou. **Um local é
interno**, e ninguém de fora da configuração alcança:

```
ana@laptop:~/shop$ terraform plan -var name=shop-test
╷
│ Error: Value for undeclared variable
│ 
│ A variable named "name" was assigned on the command line, but the root
│ module does not declare a variable of that name. To use this value, add a
│ "variable" block to the configuration.
╵
```

Isso decide qual usar. Se o valor é uma escolha que quem roda o Terraform deve poder fazer, o
ambiente ou a faixa da rede, é uma variável. Se ele é derivado de outros valores, ou é um fato que
não deve ser sobrescrito, como a tag que diz a que projeto um recurso pertence, é um local.
Transformá-lo em variável "por via das dúvidas" convida alguém a pôr outra coisa em `Project` pela
linha de comando um dia.

**Não embrulhe todo literal num local.** `local.vpc_cidr = "10.20.0.0/16"`, usado uma vez, só
acrescenta um salto para quem lê. Um local merece o lugar quando é usado mais de uma vez, ou quando
o nome dele diz algo que a expressão não diz, como `common_tags` diz. A aula 16 mostra outro
caminho para as mesmas tags, o `default_tags` do provider, que as aplica a todo recurso que o
provider cria.
