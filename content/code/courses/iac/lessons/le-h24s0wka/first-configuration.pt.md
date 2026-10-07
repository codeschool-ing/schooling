---
title: Uma configuração é um diretório
version: 2
---

A aula 1 mostrou um arquivo de Terraform e pediu que você confiasse nele. Esta aula o desmonta e
constrói a rede da loja a partir dele, um bloco de cada vez.

Comece pela imagem com que quase todo mundo chega: a de que um arquivo `.tf` é um script, e o
Terraform o executa de cima para baixo. Não é, e ele não executa. **O Terraform lê todos os
arquivos terminados em `.tf` de um diretório como um único documento, e esse diretório se chama
configuração.** Os nomes dos arquivos não significam nada para o Terraform, e a ordem dos blocos
dentro deles também não: mover a VPC para um arquivo chamado `zzz.tf` não muda absolutamente nada.
Subdiretórios não são lidos. Um diretório abaixo deste é uma configuração à parte, que a aula 10
transforma em módulo.

A rede da Ana começa com dois arquivos num diretório novo, `~/shop`. O primeiro, `versions.tf`, diz
do que a configuração precisa antes de poder rodar:

```hcl
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

O bloco `terraform` guarda ajustes do próprio Terraform. `required_version` se recusa a rodar num
Terraform anterior ao 1.10. `required_providers` lista os plugins que a configuração usa, e cada
entrada tem três partes. A chave, `aws`, é o **nome local** que os outros arquivos usam. `source`
diz de onde o plugin vem: `hashicorp/aws` é a forma curta de `registry.terraform.io/hashicorp/aws`.
E `version` limita quais versões são aceitáveis; `~> 6.0` quer dizer qualquer 6.x e nada do 7 em
diante, o que a seção sobre providers desmonta.

O segundo arquivo, `main.tf`, é a rede:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}
```

**Um bloco `provider` configura um plugin; um bloco `resource` pede que uma coisa exista.** O bloco
do provider aqui define um argumento só, a região. As credenciais não estão nele, e não devem
estar nunca: o provider da AWS as procura onde o AWS CLI procura, e neste laboratório isso são as
quatro variáveis `AWS_` que o `iac-env.sh` da aula 1 define, que também o apontam para o moto. É por isso
que este arquivo funcionaria sem mudança numa conta real.

O bloco de recurso leva dois rótulos. `aws_vpc` é o **tipo**, definido pelo provider, e `shop` é o
**nome**, escolhido por você. Juntos formam o endereço `aws_vpc.shop`, que é como o resto da
configuração se refere a esta VPC e como toda mensagem do Terraform a nomeia. Dentro das chaves
ficam os **argumentos**: `cidr_block` e `tags`, cada um um valor que você define. Dois recursos
podem ter o mesmo nome desde que o tipo seja diferente, então `aws_vpc.shop` e um
`aws_s3_bucket.shop` conviveriam lado a lado.

Os nomes dos arquivos seguem uma convenção, não uma regra: `versions.tf` para o bloco
`terraform`, `main.tf` para os recursos, e logo `variables.tf` e `outputs.tf`. Quem abre uma
configuração que nunca viu sabe onde olhar primeiro.

Com os dois arquivos escritos, o passo óbvio é pedir um plano, e o Terraform se recusa:

```
ana@laptop:~/shop$ ls
main.tf
versions.tf
ana@laptop:~/shop$ terraform plan
╷
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are
│ inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/aws: required by this configuration but no version is selected
│ 
│ To make the initial dependency selections that will initialize the
│ dependency lock file, run:
│   terraform init
╵
```

**Nada foi instalado ainda.** Sozinho, o Terraform não sabe nada sobre a AWS. O que é uma VPC,
quais argumentos ela aceita e qual chamada de API a cria, tudo isso mora no provider, um programa
à parte que este diretório ainda não tem. O erro dá o nome do comando que o busca, e esse comando é
a próxima seção.
