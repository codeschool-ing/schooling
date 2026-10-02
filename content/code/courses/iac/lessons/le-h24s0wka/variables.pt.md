---
title: Variáveis, para os valores que mudam
version: 1
---

Tudo no `main.tf` até aqui é literal. Isso serve para uma rede e dá errado no dia em que a loja
precisa de uma segunda, para produção. **O movimento tentador é copiar o diretório e editar os
números, e ele te dá duas configurações que se afastam uma da outra a cada edição esquecida.** A
alternativa é dar nome aos valores que mudam e deixá-los em aberto. Esses nomes são as **variáveis
de entrada**, declaradas em blocos próprios:

```hcl
variable "environment" {
  description = "Which copy of the shop this is: dev or prod."
  type        = string
}

variable "vpc_cidr" {
  description = "The address range of the shop's VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "https_port" {
  description = "The port the web servers answer on."
  type        = number
  default     = 443
}
```

Cada bloco declara uma entrada. `description` aparece para quem é perguntado pelo valor, e para
quem lê o arquivo. `type` diz que tipo de valor é aceitável: `string` e `number` aqui, e `bool`,
listas, mapas e objetos na aula 3. **Um `default` torna a variável opcional; sem ele, ela é
obrigatória**, então `environment` precisa ser informada toda vez e as outras duas não.

O `main.tf` as usa como `var.NOME`, e como a versão anterior está no commit, o `git diff` mostra
exatamente onde:

```
ana@laptop:~/shop$ git diff main.tf
diff --git a/main.tf b/main.tf
index e565f3e..a597fc0 100644
--- a/main.tf
+++ b/main.tf
@@ -3,10 +3,11 @@ provider "aws" {
 }
 
 resource "aws_vpc" "shop" {
-  cidr_block = "10.20.0.0/16"
+  cidr_block = var.vpc_cidr
 
   tags = {
-    Name = "shop"
+    Name        = "shop"
+    Environment = var.environment
   }
 }
 
@@ -16,7 +17,8 @@ resource "aws_subnet" "web_a" {
   availability_zone = "sa-east-1a"
 
   tags = {
-    Name = "shop-web-a"
+    Name        = "shop-web-a"
+    Environment = var.environment
   }
 }
 
@@ -29,7 +31,7 @@ resource "aws_security_group" "web" {
 resource "aws_vpc_security_group_ingress_rule" "https" {
   security_group_id = aws_security_group.web.id
   ip_protocol       = "tcp"
-  from_port         = 443
-  to_port           = 443
+  from_port         = var.https_port
+  to_port           = var.https_port
   cidr_ipv4         = "0.0.0.0/0"
 }
```

A faixa agora vem de `var.vpc_cidr`, os dois recursos levam uma tag `Environment`, e a porta da
regra é `var.https_port`. Um default igual ao literal antigo quer dizer que a rede em si não muda;
só a tag é nova.

**Uma variável obrigatória sem valor vira uma pergunta, ou um erro.** Num terminal, o Terraform
pergunta, usando a descrição:

```
ana@laptop:~/shop$ terraform plan
var.environment
  Which copy of the shop this is: dev or prod.

  Enter a value: dev
```

Onde ninguém pode responder, como num pipeline, o `-input=false` transforma a pergunta num erro que
nomeia a variável e a linha que a declarou. Falhar na hora é o que você quer ali:

```
ana@laptop:~/shop$ terraform plan -input=false
╷
│ Error: No value for required variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│ 
│ The root module input variable "environment" is not set, and has no default
│ value. Use a -var or -var-file command line argument to provide a value for
│ this variable.
╵
```

Há três jeitos comuns de passar um valor sem ser perguntado. **Na linha de comando**,
`-var environment=dev`, ou `-var-file=prod.tfvars` para um arquivo cheio deles. **No ambiente**,
como `TF_VAR_` seguido do nome da variável; o `terraform console` avalia uma expressão contra a
configuração, e a aula 3 o usa de verdade:

```
ana@laptop:~/shop$ echo var.environment | TF_VAR_environment=dev terraform console
"dev"
```

**Num arquivo que o Terraform carrega sozinho**: `terraform.tfvars`, ou qualquer nome terminado em
`.auto.tfvars`, no diretório da configuração. A Ana escreve uma linha:

```hcl
environment = "dev"
```

E o plano tem a sua resposta. Esta é a metade dele sobre a VPC:

```
  # aws_vpc.shop will be updated in-place
  ~ resource "aws_vpc" "shop" {
        id                                   = "vpc-e011d9a0de19f8728"
      ~ tags                                 = {
          + "Environment" = "dev"
            "Name"        = "shop"
        }
      ~ tags_all                             = {
          + "Environment" = "dev"
            # (1 unchanged element hidden)
        }
        # (19 unchanged attributes hidden)
    }

Plan: 0 to add, 2 to change, 0 to destroy.
```

`~` é **atualizar no lugar**: a VPC mantém o id e só as tags mudam, o que a API da AWS consegue
fazer numa VPC em funcionamento. Nem todo argumento muda assim, e a aula 6 trata dos que forçam uma
substituição.

**Quando a mesma variável é definida em vários lugares, vence a fonte que vem depois na ordem do
Terraform, e o ambiente vem primeiro.** Isso surpreende quem está acostumado a ferramentas em que
uma variável de ambiente se sobrepõe a um arquivo. A ordem, da mais fraca para a mais forte:
variáveis `TF_VAR_`, depois `terraform.tfvars`, depois `terraform.tfvars.json`, depois os
arquivos `*.auto.tfvars` em ordem alfabética, depois `-var` e `-var-file` na ordem em que aparecem
na linha de comando. A Ana testa:

```
ana@laptop:~/shop$ echo var.environment | terraform console
"dev"
ana@laptop:~/shop$ echo var.environment | TF_VAR_environment=prod terraform console
"dev"
ana@laptop:~/shop$ echo var.environment | terraform console -var environment=prod
"prod"
```

`TF_VAR_environment=prod` perdeu para a única linha do `terraform.tfvars`, sem aviso nenhum, e só o
`-var` venceu o arquivo. É assim que alguém exporta `prod` no shell, lê um plano que diz `dev` e
não percebe. **O valor que um plano usou está no plano**, então leia ali em vez de supor qual
fonte venceu.

O tipo é conferido antes de o valor ser usado. Uma porta que não é número é recusada, e a mensagem
nomeia a variável e a origem do valor errado:

```
ana@laptop:~/shop$ echo var.https_port | terraform console -var https_port=https
╷
│ Error: Invalid value for input variable
│ 
│   on variables.tf line 12:
│   12: variable "https_port" {
│ 
│ Unsuitable value for var.https_port set using -var="https_port=...": a
│ number is required.
╵
```

Com o `terraform.tfvars` no lugar, o `apply` põe a tag nova nos dois recursos:

```
Plan: 0 to add, 2 to change, 0 to destroy.
aws_vpc.shop: Modifying... [id=vpc-e011d9a0de19f8728]
aws_vpc.shop: Modifications complete after 0s [id=vpc-e011d9a0de19f8728]
aws_subnet.web_a: Modifying... [id=subnet-d9c8587bd007db2d1]
aws_subnet.web_a: Modifications complete after 0s [id=subnet-d9c8587bd007db2d1]

Apply complete! Resources: 0 added, 2 changed, 0 destroyed.
```

A aula 12 volta ao `terraform.tfvars` por um motivo que esta aula só consegue nomear: um valor que
é uma senha não está seguro nem num arquivo no commit, nem no histórico do shell.
