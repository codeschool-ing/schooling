---
title: Lendo o plano, e dizendo yes
version: 1
---

**Um plano é a proposta do Terraform: o que a configuração pede, o que já existe, e a diferença
entre os dois escrita como ações.** Nada muda enquanto você lê. O `terraform plan` imprime a
proposta e para; o `terraform apply` imprime a mesma proposta e depois pergunta. Este é o começo do
primeiro plano da loja:

```
ana@laptop:~/shop$ terraform plan

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_security_group.web will be created
  + resource "aws_security_group" "web" {
      + arn                    = (known after apply)
      + description            = "web servers"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = "web"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + region                 = "sa-east-1"
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = (known after apply)
    }

```

Leia o cabeçalho primeiro. Cada ação tem um símbolo, e o cabeçalho lista os que este plano usa:
aqui só `+`, criar. Esta aula encontra mais dois, `~` e `-`, e a aula 9 passa por todos eles e pelo
que procurar em cada um.

Depois vem cada recurso, pelo endereço, com todos os atributos que ele vai ter. Os valores do
arquivo aparecem como foram escritos: `"web"`, `"web servers"`. Alguns vêm dos padrões do provider,
como `revoke_rules_on_delete = false`, que ninguém digitou. E `region` está lá embora nenhum
recurso a mencione, porque o bloco do provider a definiu para todos. **`(known after apply)` marca
o que ninguém sabe até a AWS responder**: o id, o ARN, e o `vpc_id`, porque ele é o id da VPC e a
VPC ainda não existe. Um plano é calculado antes de qualquer coisa acontecer, então um valor que a
nuvem inventa é uma lacuna nele.

O mesmo tipo de bloco se repete para a sub-rede, a VPC e a regra, em ordem alfabética de endereço,
não na ordem em que serão criados. O plano termina na linha que vale ler primeiro:

```
Plan: 4 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

Quatro a criar, nada a mudar ou destruir: exatamente os quatro blocos do `main.tf`, que é a
conferência a fazer toda vez. Um plano que diz `1 to destroy` quando você não esperava nenhum é a
hora de parar. A nota embaixo fala de salvar um plano com `-out`, assunto da aula 9; aqui o plano é descartado.

O `terraform apply` calcula o mesmo plano de novo, imprime e para numa pergunta. **Qualquer coisa
que não seja exatamente a palavra `yes` cancela**, que foi o que aconteceu quando a Ana respondeu
`no`:

```
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: no
Apply cancelled.
```

E com `yes`:

```
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 2s [id=vpc-7327c901412b20229]
aws_subnet.web_a: Creating...
aws_security_group.web: Creating...
aws_subnet.web_a: Creation complete after 1s [id=subnet-246685d4ada451bad]
aws_security_group.web: Creation complete after 1s [id=sg-3475d5edf795d5594]
aws_vpc_security_group_ingress_rule.https: Creating...
aws_vpc_security_group_ingress_rule.https: Creation complete after 0s [id=sgr-dcc6bf0490cd0c301]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

**A ordem do log é o grafo da seção anterior.** A VPC sozinha primeiro. Depois a sub-rede e o
security group, os dois começados antes que qualquer um terminasse. Depois a regra, que precisou
esperar o id do grupo. O Terraform percorre o grafo e começa o que não tem mais nada a esperar, até
dez operações de uma vez, a não ser que `-parallelism` diga outra coisa.

Os ids no fim de cada linha são os que a AWS inventou, aqui o moto, e mudam a cada execução do
laboratório. O Terraform escreveu cada um num arquivo novo, `terraform.tfstate`, no momento em que
o recebeu. É por esse arquivo que ele sabe qual VPC real é `aws_vpc.shop`, e o
`terraform state list` mostra os quatro endereços que ele passou a acompanhar. A AWS concorda
quanto à sub-rede:

```
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.web_a
aws_vpc.shop
aws_vpc_security_group_ingress_rule.https
ana@laptop:~/shop$ aws ec2 describe-subnets --filters Name=tag:Name,Values=shop-web-a --query "Subnets[].[SubnetId,VpcId,CidrBlock]" --output text
subnet-246685d4ada451bad	vpc-7327c901412b20229	10.20.1.0/24
```

Depois, o teste com que a aula 1 terminou: rodar o apply de novo, sem mudar nada.

```
ana@laptop:~/shop$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-7327c901412b20229]
aws_security_group.web: Refreshing state... [id=sg-3475d5edf795d5594]
aws_subnet.web_a: Refreshing state... [id=subnet-246685d4ada451bad]
aws_vpc_security_group_ingress_rule.https: Refreshing state... [id=sgr-dcc6bf0490cd0c301]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

As linhas `Refreshing state` são o Terraform lendo cada recurso de volta da AWS pelo id que
guardou. **`No changes` quer dizer que a configuração e o mundo concordam**, então não há nada a
perguntar, e nada foi feito.

O `-auto-approve` respondeu à pergunta nesta execução, e é assim que o Terraform roda onde ninguém
pode digitar. Usado à mão, ele pula o único momento em que você lê o plano antes que aconteça. A
aula 15 mostra a versão segura: um pipeline que aplica um plano que alguém já revisou, em vez de um
plano novo que ninguém leu.
