---
title: Atualizado no lugar, ou substituído
version: 1
---

Uma primeira imagem comum do Terraform é que editar uma linha edita a coisa. Mude a faixa da
sub-rede no arquivo e o Terraform muda a faixa da sub-rede na AWS. **Às vezes é isso que acontece,
e às vezes o Terraform destrói o recurso e constrói um novo no lugar**, com id novo, endereço novo
e nada do conteúdo do antigo. Qual das duas coisas ele vai fazer é decidido pelo provider,
argumento por argumento, e o plan conta antes de qualquer coisa se mexer.

Esta aula trabalha numa configuração pequena em `~/shop/app`: a VPC da loja, uma sub-rede e a
instância `web`. A Ana já aplicou uma vez, em silêncio, e fez commit no git:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.a.id
  tags          = { Name = "web" }
}
```

Os ids de AMI são duas das imagens de exemplo que vêm com o moto, um Ubuntu mais antigo e um mais
novo. São os mesmos em toda execução do laboratório, então podem ser citados; os ids `vpc-…` e
`i-…` dos plans abaixo são inventados de novo a cada vez.

## Uma mudança que a AWS faz no lugar

A primeira edição renomeia a sub-rede. Uma tag é metadado que a AWS consegue reescrever num recurso
em funcionamento, então o plan diz `~`, **update in-place**:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 12d07df..4158f47 100644
--- a/main.tf
+++ b/main.tf
@@ -20,7 +20,7 @@ resource "aws_subnet" "a" {
   vpc_id            = aws_vpc.shop.id
   cidr_block        = "10.20.1.0/24"
   availability_zone = "sa-east-1a"
-  tags              = { Name = "shop-a" }
+  tags              = { Name = "shop-public-a" }
 }
 
 resource "aws_instance" "web" {
ana@laptop:~/shop/app$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-620a9a42c64d1b9c4]
aws_subnet.a: Refreshing state... [id=subnet-47e7ab7e19d97ade4]
aws_instance.web: Refreshing state... [id=i-f60bc6ad037ef6535]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_subnet.a will be updated in-place
  ~ resource "aws_subnet" "a" {
        id                                             = "subnet-47e7ab7e19d97ade4"
      ~ tags                                           = {
          ~ "Name" = "shop-a" -> "shop-public-a"
        }
      ~ tags_all                                       = {
          ~ "Name" = "shop-a" -> "shop-public-a"
        }
        # (20 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

O id na segunda linha do recurso é o mesmo antes e depois, e o resumo conta uma mudança e nada
adicionado ou destruído. Esse é o tipo barato de mudança.

## Uma mudança que força uma substituição

A edição seguinte passa a `web` para a imagem mais nova. Uma instância não troca o disco de onde deu
boot enquanto roda, então o provider marca `ami` como um argumento que não pode ser atualizado. O
plan completo é longo, quase todo ele atributos virando `(known after apply)`, então desta vez o
`grep` fica só com as linhas que decidem alguma coisa:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 4158f47..1b1c85a 100644
--- a/main.tf
+++ b/main.tf
@@ -24,7 +24,7 @@ resource "aws_subnet" "a" {
 }
 
 resource "aws_instance" "web" {
-  ami           = "ami-1e749f67"
+  ami           = "ami-785db401"
   instance_type = "t3.micro"
   subnet_id     = aws_subnet.a.id
   tags          = { Name = "web" }
ana@laptop:~/shop/app$ terraform plan | grep -E "replace|Plan:"
-/+ destroy and then create replacement
  # aws_instance.web must be replaced
      ~ ami                                  = "ami-1e749f67" -> "ami-785db401" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

**`-/+` é uma substituição, e `# forces replacement` aponta o argumento responsável.** Esse
comentário é a linha mais útil de um plan longo: responde o *porquê* antes de você rolar a tela. O
resumo diz `1 to add, 0 to change, 1 to destroy`, que é como uma substituição é contada.

## Uma substituição que se espalha

Uma substituição dá ao recurso novo um id novo, e tudo o que referencia o id antigo tem de ir
junto. A Ana tenta mudar a faixa da sub-rede:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 4158f47..a4ba35f 100644
--- a/main.tf
+++ b/main.tf
@@ -18,7 +18,7 @@ resource "aws_vpc" "shop" {
 
 resource "aws_subnet" "a" {
   vpc_id            = aws_vpc.shop.id
-  cidr_block        = "10.20.1.0/24"
+  cidr_block        = "10.20.3.0/24"
   availability_zone = "sa-east-1a"
   tags              = { Name = "shop-public-a" }
 }
ana@laptop:~/shop/app$ terraform plan | grep -E "replace|Plan:"
-/+ destroy and then create replacement
  # aws_instance.web must be replaced
      ~ subnet_id                            = "subnet-47e7ab7e19d97ade4" -> (known after apply) # forces replacement
  # aws_subnet.a must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.20.3.0/24" # forces replacement
Plan: 2 to add, 0 to change, 2 to destroy.
```

Uma linha editada, duas substituições. A faixa da sub-rede não muda no lugar, então a sub-rede é
substituída; o id novo dela é `(known after apply)`, e uma instância também não muda de sub-rede,
então `subnet_id` força a instância a sair junto. **O comentário na instância aponta para
`subnet_id`, não para nada que a Ana digitou**, e é esse o formato a vigiar numa revisão: uma
substituição cuja causa está dois recursos adiante.

Quem decide entre no lugar e substituição é a API da nuvem, do jeito que o provider a modela. Tags,
o tipo de uma instância e as regras de um security group têm chamadas de atualização; uma AMI, a
faixa de uma sub-rede, o nome de um bucket e a descrição de um security group não têm. Você não
precisa decorar a lista. Precisa ler `-/+` e `# forces replacement` toda vez que aparecerem, porque
uma instância substituída perde o que havia no disco dela, e a aula 9 constrói uma verificação que
reprova um pipeline exatamente por isso.
