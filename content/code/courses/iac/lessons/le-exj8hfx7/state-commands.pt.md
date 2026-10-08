---
title: Ler e editar o estado com terraform state
version: 2
---

De volta ao diretório da própria Ana, com o estado que conhece os três recursos. O JSON pode ser
lido com o `jq`, como duas seções atrás, e nunca deve ser editado num editor de texto: uma vírgula
fora do lugar e o Terraform não consegue carregá-lo, e um campo mudado à mão é uma mentira em que o
próximo plan acredita. **`terraform state` é o conjunto de subcomandos para olhar o estado e
mudá-lo com segurança.**

`list` imprime todos os endereços que o estado guarda:

```
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.a
aws_vpc.shop
```

`show` imprime um deles, cada atributo como o estado o registrou, na mesma sintaxe de uma
configuração:

```
ana@laptop:~/shop$ terraform state show aws_subnet.a
# aws_subnet.a:
resource "aws_subnet" "a" {
    arn                                            = "arn:aws:ec2:sa-east-1:123456789012:subnet/subnet-1849baa846a6631fa"
    assign_ipv6_address_on_creation                = false
    availability_zone                              = "sa-east-1a"
    availability_zone_id                           = "sae1-az1"
    cidr_block                                     = "10.20.1.0/24"
    customer_owned_ipv4_pool                       = null
    enable_dns64                                   = false
    enable_lni_at_device_index                     = 0
    enable_resource_name_dns_a_record_on_launch    = false
    enable_resource_name_dns_aaaa_record_on_launch = false
    id                                             = "subnet-1849baa846a6631fa"
    ipv6_cidr_block                                = null
    ipv6_cidr_block_association_id                 = null
    ipv6_native                                    = false
    map_customer_owned_ip_on_launch                = false
    map_public_ip_on_launch                        = false
    outpost_arn                                    = null
    owner_id                                       = "123456789012"
    private_dns_hostname_type_on_launch            = "ip-name"
    region                                         = "sa-east-1"
    tags                                           = {
        "Name" = "shop-a"
    }
    tags_all                                       = {
        "Name" = "shop-a"
    }
    vpc_id                                         = "vpc-10f2b2857589fd959"
}
```

Todo valor ali veio da AWS durante o último apply ou refresh. Muitos deles, `ipv6_native` ou
`private_dns_hostname_type_on_launch`, nem aparecem no `main.tf`: o provider preenche os valores
padrão e o estado os guarda, e é assim que um plan posterior percebe quando um deles muda.

## Renomear: `state mv`

A Ana decide que `a` é um nome ruim para uma sub-rede que vai ganhar irmãs, e quer
`aws_subnet.public_a`. Renomear só no arquivo pareceria ao Terraform um recurso apagado e outro, sem
relação, adicionado. O `state mv` renomeia o endereço no estado, e o `-dry-run` diz o que faria sem
fazer:

```
ana@laptop:~/shop$ terraform state mv -dry-run aws_subnet.a aws_subnet.public_a
Would move "aws_subnet.a" to "aws_subnet.public_a"
ana@laptop:~/shop$ terraform state mv aws_subnet.a aws_subnet.public_a
Move "aws_subnet.a" to "aws_subnet.public_a"
Successfully moved 1 object(s).
```

O estado mudou e o arquivo não, e esse é o meio do caminho perigoso. Um plan agora:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_subnet.a will be created
  # aws_subnet.public_a will be destroyed
  # (because aws_subnet.public_a is not in configuration)
Plan: 1 to add, 0 to change, 1 to destroy.
```

Leia como o Terraform lê. O estado tem um `public_a` que o arquivo não menciona, então ele seria
destruído; o arquivo tem um `a` que o estado não conhece, então ele seria criado. **Um destroy e um
create da mesma sub-rede**, só porque as duas metades discordam de um nome. A Ana faz o arquivo
concordar:

```
ana@laptop:~/shop$ sed -i 's/"aws_subnet" "a"/"aws_subnet" "public_a"/' main.tf
ana@laptop:~/shop$ grep aws_subnet main.tf
resource "aws_subnet" "public_a" {
ana@laptop:~/shop$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`, e a sub-rede manteve o id. O bloco `moved` da aula 4 faz esse mesmo rename de dentro da
configuração, onde um revisor o vê e toda cópia do estado o recebe no plan seguinte. O `state mv` é a
ferramenta manual para quando não há tempo para isso, e ele muda um estado, numa máquina.

## Esquecer: `state rm`

O `state rm` tira um endereço do estado **sem tocar no recurso real**. É assim que se diz ao
Terraform para parar de gerenciar alguma coisa:

```
ana@laptop:~/shop$ terraform state rm aws_subnet.public_a
Removed aws_subnet.public_a
Successfully removed 1 resource instance(s).
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_subnet.public_a will be created
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/shop$ aws ec2 describe-subnets --filters Name=tag:Name,Values=shop-a --query "Subnets[].[SubnetId,CidrBlock]" --output text
subnet-1849baa846a6631fa	10.20.1.0/24
```

A sub-rede continua na AWS; o Terraform a esqueceu, e o plan quer criar uma. É o acidente da
seção anterior de novo, para um recurso só. O bloco `removed` da aula 6 é o jeito revisável de parar
de gerenciar algo; o `state rm` é o imediato.

## Os backups

Num estado local, todo `state mv` e todo `state rm` primeiro gravam o estado como estava num arquivo
de backup, com o momento em segundos Unix no nome. Há um do `mv` e um do `rm`, e a Ana copia o mais
novo de volta por cima do estado:

```
ana@laptop:~/shop$ ls terraform.tfstate*
terraform.tfstate
terraform.tfstate.1790913034.backup
terraform.tfstate.1790913055.backup
ana@laptop:~/shop$ cp "$(ls -t terraform.tfstate.*.backup | head -n 1)" terraform.tfstate
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.public_a
aws_vpc.shop
ana@laptop:~/shop$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

O `public_a` voltou, e o plan está limpo. **Isso funcionou porque o backup estava no mesmo
diretório**, que é o mesmo motivo pelo qual ele sumiria junto com o laptop. Duas seções adiante, o backend põe o
estado num lugar onde a história dele sobrevive, e a aula 8 mostra o `terraform import`, que traz um
recurso real de volta à gerência sem backup nenhum.

A Ana faz commit do `main.tf` com o bloco renomeado, para que o arquivo no Git também diga
`public_a`; as próximas seções o clonam.
