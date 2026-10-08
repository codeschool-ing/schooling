---
title: Mirar num recurso só, e por que isso não é hábito
version: 2
---

O `-target` limita um plano a um endereço e àquilo de que ele depende. Parece precisão, um jeito de aplicar
só a parte de que você tem certeza. **O próprio aviso do Terraform o chama de ferramenta para
situações excepcionais**, e o motivo aparece na primeira vez que você o usa.

A Ana tem três mudanças esperando no `main.tf`. Uma sub-rede `d` nova é necessária hoje. Uma tag
`Project` na VPC é arrumação. E a instância de batch passa para um tipo maior, o que ela quer fazer
à noite, quando nenhum job está rodando:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 15f2e65..ef2de0f 100644
--- a/main.tf
+++ b/main.tf
@@ -4,7 +4,7 @@ provider "aws" {
 
 resource "aws_vpc" "shop" {
   cidr_block = "10.20.0.0/16"
-  tags       = { Name = "shop", Owner = "ana" }
+  tags       = { Name = "shop", Owner = "ana", Project = "shop" }
 }
 
 resource "aws_subnet" "a" {
@@ -92,8 +92,15 @@ resource "aws_subnet" "c" {
 
 resource "aws_instance" "batch" {
   ami                    = "ami-785db401"
-  instance_type          = "t3.micro"
+  instance_type          = "t3.small"
   subnet_id              = aws_subnet.c.id
   vpc_security_group_ids = [aws_security_group.batch.id]
   tags                   = { Name = "batch" }
 }
+
+resource "aws_subnet" "d" {
+  vpc_id            = aws_vpc.shop.id
+  cidr_block        = "10.20.4.0/24"
+  availability_zone = "sa-east-1c"
+  tags              = { Name = "shop-d" }
+}
```

Ela pede só a sub-rede, com `terraform plan -target=aws_subnet.d`. O fim do plano:

```
  # aws_vpc.shop will be updated in-place
  ~ resource "aws_vpc" "shop" {
        id                                   = "vpc-bf1e4c53969619f51"
      ~ tags                                 = {
            "Name"    = "shop"
            "Owner"   = "ana"
          + "Project" = "shop"
        }
      ~ tags_all                             = {
          + "Project" = "shop"
            # (2 unchanged elements hidden)
        }
        # (19 unchanged attributes hidden)
    }

Plan: 1 to add, 1 to change, 0 to destroy.
╷
│ Warning: Resource targeting is in effect
│ 
│ You are creating a plan with the -target option, which means that the
│ result of this plan may not represent all of the changes requested by the
│ current configuration.
│ 
│ The -target option is not for routine use, and is provided only for
│ exceptional situations such as recovering from errors or mistakes, or when
│ Terraform specifically suggests to use it as part of an error message.
╵
```

O plano é da sub-rede, que fica acima deste trecho, **e da tag da VPC**, que ela não pediu. A
sub-rede `d` cita `aws_vpc.shop.id`, então a VPC é uma dependência, e um target traz as dependências
junto com o que estiver pendente nelas. O resize da instância, de que nada na sub-rede depende, fica
de fora. Então o plano com target não é "só o que eu nomeei" nem "tudo o que está no arquivo": é uma
fatia do grafo, e a fatia é decidida por referências que talvez você não tenha em mente.

Ela aplica mesmo assim, já que uma tag é inofensiva, com `terraform apply -target=aws_subnet.d
-auto-approve`, e o Terraform acrescenta um segundo aviso no fim:

```
aws_vpc.shop: Modifying... [id=vpc-bf1e4c53969619f51]
aws_vpc.shop: Modifications complete after 0s [id=vpc-bf1e4c53969619f51]
aws_subnet.d: Creating...
aws_subnet.d: Creation complete after 0s [id=subnet-d13af5782a2f49e4a]
╷
│ Warning: Resource targeting is in effect
│ 
│ You are creating a plan with the -target option, which means that the
│ result of this plan may not represent all of the changes requested by the
│ current configuration.
│ 
│ The -target option is not for routine use, and is provided only for
│ exceptional situations such as recovering from errors or mistakes, or when
│ Terraform specifically suggests to use it as part of an error message.
╵
╷
│ Warning: Applied changes may be incomplete
│ 
│ The plan was created with the -target option in effect, so some changes
│ requested in the configuration may have been ignored and the output values
│ may not be fully updated. Run the following command to verify that no other
│ changes are pending:
│     terraform plan
│ 
│ Note that the -target option is not suitable for routine use, and is
│ provided only for exceptional situations such as recovering from errors or
│ mistakes, or when Terraform specifically suggests to use it as part of an
│ error message.
╵

Apply complete! Resources: 1 added, 1 changed, 0 destroyed.
```

**"Applied changes may be incomplete" é o preço.** A configuração no arquivo e a infraestrutura agora
discordam de propósito, e vão continuar discordando até alguém rodar um plano completo:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|Plan:"
  # aws_instance.batch will be updated in-place
Plan: 0 to add, 1 to change, 0 to destroy.
```

O resize continua pendente. Neste caso a Ana sabe que está, e o aplica à noite com um `terraform
apply` comum. O perigo é o dia em que ninguém sabe: um apply com target deixa mudanças para trás sem
registro de que ficaram, e a próxima pessoa a rodar um plano completo as encontra misturadas à
mudança dela, sem revisão.

## Quando é a ferramenta certa

O aviso nomeia os casos, e eles têm a mesma forma: **algo está quebrado e o plano completo não
ajuda**.

- Recuperar-se de um erro, quando um recurso precisa ser consertado antes de qualquer outra coisa
  poder ser planejada com juízo, por exemplo recriar um recurso que alguém apagou à mão enquanto o
  resto do plano ainda não é seguro de aplicar.
- Quando o próprio Terraform sugere isso num erro. Um `for_each` sobre valores que só são conhecidos
  depois do apply não pode ser planejado num passo só, e o erro diz para aplicar primeiro, com
  `-target`, as coisas de onde esses valores vêm.
- Uma configuração grande no meio de um incidente, quando um plano completo demora o bastante para
  fazer diferença e a correção é um recurso só.

Cada um desses é seguido de um plano e um apply completos assim que for seguro, então o drift que o
`-target` criou dura minutos. **Se você recorre ao `-target` toda semana, a configuração está dizendo
alguma coisa**: duas coisas que mudam em ritmos diferentes estão dividindo um estado só. Separá-las,
como a aula 8 fez com a rede e a aplicação, dá a cada uma o próprio plano, e aí um plano completo de
qualquer uma é a coisa pequena e precisa que o `-target` fingia ser.
