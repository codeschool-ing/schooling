---
title: Versionando o que você publica
version: 1
---

Um número de versão é uma mensagem do autor do módulo para todo mundo que o chama. A convenção que
quase todo módulo usa é o **versionamento semântico**: `MAJOR.MINOR.PATCH`. Um patch conserta algo
sem mudar o que quem chama enxerga, uma versão minor acrescenta algo que quem chama pode ignorar, e
uma versão major avisa que alguém, em algum lugar, vai ter de mudar o próprio código. A convenção só
funciona se o autor souber o que conta como mudança visível, e num módulo Terraform isso é mais
amplo do que parece.

A parte óbvia da interface são as variáveis e os outputs. **A parte menos óbvia é o endereço de cada
recurso lá dentro**, porque o state de cada chamador o registra. A Ana aprende isso com uma mudança
que ela acha que é só arrumação. Ela pretende acrescentar sub-redes públicas um dia, então as atuais
deveriam se chamar `private`, e ela manda a renomeação para um branch:

```
ana@laptop:~/src/terraform-aws-network$ git diff
diff --git a/main.tf b/main.tf
index cc2a8ee..f257067 100644
--- a/main.tf
+++ b/main.tf
@@ -4,7 +4,7 @@ resource "aws_vpc" "this" {
   tags                 = { Name = var.name }
 }
 
-resource "aws_subnet" "this" {
+resource "aws_subnet" "private" {
   for_each = var.subnets
 
   vpc_id            = aws_vpc.this.id
diff --git a/outputs.tf b/outputs.tf
index ba4964c..6078538 100644
--- a/outputs.tf
+++ b/outputs.tf
@@ -5,5 +5,5 @@ output "vpc_id" {
 
 output "subnet_ids" {
   description = "The id of each subnet, keyed like var.subnets."
-  value       = { for k, s in aws_subnet.this : k => s.id }
+  value       = { for k, s in aws_subnet.private : k => s.id }
 }
```

Duas linhas, nenhuma variável e nenhum output tocados. Quem experimenta o branch recebe isto:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # module.analytics.aws_subnet.private["a"] will be created
  # module.analytics.aws_subnet.this["a"] will be destroyed
  # (because aws_subnet.this is not in configuration)
  # module.shop.aws_subnet.private["a"] will be created
  # module.shop.aws_subnet.private["c"] will be created
  # module.shop.aws_subnet.this["a"] will be destroyed
  # (because aws_subnet.this is not in configuration)
  # module.shop.aws_subnet.this["c"] will be destroyed
  # (because aws_subnet.this is not in configuration)
Plan: 3 to add, 0 to change, 3 to destroy.
```

**Três sub-redes destruídas e três criadas, em duas redes, para mudar um nome que ninguém de fora do
módulo jamais viu.** Do ponto de vista do state, `module.shop.aws_subnet.this["a"]` sumiu da
configuração e `module.shop.aws_subnet.private["a"]` apareceu, e a aula 9 mostrou o que o plan faz
com isso. Nestas sub-redes vazias o custo é ganhar ids novos. Em sub-redes com máquinas dentro, a
AWS se recusa a apagar uma sub-rede que ainda tem interfaces de rede, e o apply pararia no meio; no
subnet group de um banco de dados, é uma indisponibilidade.

Dentro do módulo, um bloco `moved` diz que os dois endereços são o mesmo objeto. A aula 4 o usou numa
configuração root; num módulo ele é escrito uma vez pelo autor e poupa todo mundo que chama:

```hcl
# v1.1.0 renamed aws_subnet.this to aws_subnet.private.
moved {
  from = aws_subnet.this
  to   = aws_subnet.private
}
```

Integrado ao `main` e marcado como `v1.1.0`, ele planeja assim para o mesmo chamador:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # module.analytics.aws_subnet.this["a"] has moved to module.analytics.aws_subnet.private["a"]
  # module.shop.aws_subnet.this["a"] has moved to module.shop.aws_subnet.private["a"]
  # module.shop.aws_subnet.this["c"] has moved to module.shop.aws_subnet.private["c"]
Plan: 0 to add, 0 to change, 0 to destroy.
```

E cada entrada do plan completo mostra que o objeto é o que já existe:

```
  # module.analytics.aws_subnet.this["a"] has moved to module.analytics.aws_subnet.private["a"]
    resource "aws_subnet" "private" {
        id                                             = "subnet-80ae92981cef43bdb"
        tags                                           = {
            "Name" = "analytics-a"
        }
        # (21 unchanged attributes hidden)
    }
```

**Zero para adicionar, zero para destruir: uma versão minor, como deveria ser.** O bloco `moved`
fica no módulo enquanto alguém puder atualizar a partir de uma versão anterior a ele, o que na
prática quer dizer até a próxima versão major, quando o autor pode decidir parar de carregá-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três tags do módulo de rede em sequência. v1.0.0 é a primeira versão, com as sub-redes em aws_subnet.this. v1.1.0 é uma versão minor: as sub-redes mudam de nome e um bloco moved vem junto, então o plan de quem chama dá 0 to add e 0 to destroy, onde sem o bloco dava 3 to add e 3 to destroy. v2.0.0 é uma versão major: a variável cidr vira cidr_block, e todo mundo que chama precisa editar uma linha.\"><defs><marker id=\"vs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"130.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">primeira versão</text><rect x=\"60\" y=\"52\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v1.0.0</text><text x=\"370.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">minor</text><rect x=\"300\" y=\"52\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v1.1.0</text><text x=\"610.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">major</text><rect x=\"540\" y=\"52\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v2.0.0</text><path d=\"M202 70 L297 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vs-ah-wire)\"></path><path d=\"M442 70 L537 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vs-ah-wire)\"></path><text x=\"130.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma VPC e suas sub-redes</text><text x=\"130.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aws_subnet.this</text><text x=\"130.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quem chama fixa a tag</text><text x=\"370.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sub-redes renomeadas, mais</text><text x=\"370.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">moved { }</text><text x=\"370.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0 to add, 0 to destroy</text><text x=\"370.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sem o bloco:</text><text x=\"370.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">3 to add, 3 to destroy</text><text x=\"610.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma variável renomeada</text><text x=\"610.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cidr → cidr_block</text><text x=\"610.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">quem chama edita uma linha</text></svg>", "caption": "O que cada tag pede de quem chama. A renomeação com um bloco moved é uma versão minor; a de uma variável não tem como ser escondida, então é major.", "same": ["minor", "major"]}
```

## Uma mudança que não dá para esconder

Algumas mudanças exigem que todo chamador aja. A Ana renomeia a variável `cidr` para `cidr_block`,
o nome que o próprio recurso `aws_vpc` usa:

```
ana@laptop:~/src/terraform-aws-network$ git diff
diff --git a/main.tf b/main.tf
index f257067..4cf5fb6 100644
--- a/main.tf
+++ b/main.tf
@@ -1,5 +1,5 @@
 resource "aws_vpc" "this" {
-  cidr_block           = var.cidr
+  cidr_block           = var.cidr_block
   enable_dns_hostnames = true
   tags                 = { Name = var.name }
 }
diff --git a/variables.tf b/variables.tf
index 84ff13e..4924107 100644
--- a/variables.tf
+++ b/variables.tf
@@ -3,13 +3,13 @@ variable "name" {
   description = "Name tag of the VPC, and the prefix of every subnet's Name."
 }
 
-variable "cidr" {
+variable "cidr_block" {
   type        = string
   description = "The VPC's address range, such as 10.20.0.0/16."
 
   validation {
-    condition     = can(cidrhost(var.cidr, 0))
-    error_message = "The cidr must be an IPv4 range such as 10.20.0.0/16."
+    condition     = can(cidrhost(var.cidr_block, 0))
+    error_message = "cidr_block must be an IPv4 range such as 10.20.0.0/16."
   }
 }
 
ana@laptop:~/src/terraform-aws-network$ git tag v2.0.0
ana@laptop:~/src/terraform-aws-network$ git push -q origin main v2.0.0
```

Não existe `moved` para uma variável: quem passa `cidr` está passando um argumento que não existe
mais. Então isto é a `v2.0.0`, e a tag vem com uma nota dizendo o que fazer:

```
# Changelog

## v2.0.0

BREAKING: the variable `cidr` is now `cidr_block`, the name the aws_vpc
resource uses. Rename the argument in every module block that calls this one.

## v1.1.0

The subnets are `aws_subnet.private` instead of `aws_subnet.this`. A `moved`
block carries existing subnets across, so upgrading plans no changes.

## v1.0.0

A VPC and a map of subnets.
```

Quem sobe o `ref` descobre no `init`, antes de qualquer plan:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for analytics...
- analytics in .terraform/modules/analytics
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for shop...
- shop in .terraform/modules/shop
╷
│ Error: Unsupported argument
│ 
│   on analytics.tf line 5, in module "analytics":
│    5:   cidr = "10.30.0.0/16"
│ 
│ An argument named "cidr" is not expected here.
╵
╷
│ Error: Unsupported argument
│ 
│   on main.tf line 18, in module "shop":
│   18:   cidr = "10.20.0.0/16"
│ 
│ An argument named "cidr" is not expected here.
╵
```

**Esse é o tipo bom de mudança incompatível: barulhenta, cedo, e apontando a linha a editar.** A Ana
renomeia o argumento nas duas chamadas, e a atualização não custa nada na AWS:

```
ana@laptop:~/shop$ git diff -U0 | grep "^[-+] "
-  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.1.0"
+  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0"
-  cidr = "10.30.0.0/16"
+  cidr_block = "10.30.0.0/16"
-  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.1.0"
+  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0"
-  cidr = "10.20.0.0/16"
+  cidr_block = "10.20.0.0/16"
ana@laptop:~/shop$ terraform init | grep Downloading
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for shop...
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v2.0.0 for analytics...
ana@laptop:~/shop$ terraform plan | grep "No changes"
No changes. Your infrastructure matches the configuration.
```

A lista do que quebra quem usa um módulo sai de tudo isso: remover ou renomear uma variável ou um
output, acrescentar uma variável sem default, estreitar o tipo de uma variável, mudar o endereço de
um recurso sem um bloco `moved`, e subir a versão do Terraform ou do provider que o módulo exige. Um
default cujo valor novo muda recursos existentes também entra na lista, mesmo sem quebrar o código
de ninguém: o próximo plan deles faz algo que eles não pediram. Quem chama se protege fixando uma tag
e mudando-a de propósito, lendo o changelog e o plan quando muda, que é o que a Ana fez aqui a cada
passo.
