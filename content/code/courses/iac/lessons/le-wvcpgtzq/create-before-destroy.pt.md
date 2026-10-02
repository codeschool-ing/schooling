---
title: Criar antes de destruir, e o nome que atrapalha
version: 1
---

Uma substituição são duas operações, e elas têm uma ordem. **Por padrão o Terraform destrói o
recurso antigo primeiro e cria o novo depois**, que é o que `-/+ destroy and then create
replacement` diz com todas as letras. A Ana aplica a troca de imagem da seção anterior e fica só
com as linhas que relatam o progresso:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "Destr|Creat"
aws_instance.web: Destroying... [id=i-f60bc6ad037ef6535]
aws_instance.web: Destruction complete after 10s
aws_instance.web: Creating...
aws_instance.web: Creation complete after 10s [id=i-2c8873777c5bd44a7]
```

Entre `Destruction complete` e `Creation complete` não existe instância `web` nenhuma. No
laboratório esse intervalo não custa nada, porque o moto não roda máquina. Numa conta real ele dura
o tempo que uma máquina leva para dar boot e começar a atender, e a loja fica sem servidor web esse
tempo todo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 288\" role=\"img\" aria-label=\"Duas linhas do tempo da mesma substituição. Na primeira, o padrão, a instância antiga é destruída, depois por um tempo nada existe, depois a nova é criada. Na segunda, com create_before_destroy, a nova é criada primeiro, as duas existem por um momento, e só então a antiga é destruída.\"><defs><marker id=\"or-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o padrão: destruir, depois criar</text><text x=\"700.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">-/+</text><rect x=\"20\" y=\"52\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">instância antiga</text><rect x=\"470\" y=\"52\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">instância nova</text><rect x=\"262\" y=\"52\" width=\"196\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nada existe</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">create_before_destroy: criar, depois destruir</text><text x=\"700.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">+/-</text><rect x=\"20\" y=\"158\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">instância antiga</text><rect x=\"300\" y=\"208\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">instância nova</text><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><path d=\"M395 112 L700 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#or-ah-wire)\"></path><path d=\"M300 256 L300 262 L420 262 L420 256\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">as duas existem</text></svg>", "caption": "A mesma substituição em duas ordens. O padrão deixa um intervalo em que nenhuma existe; create_before_destroy fecha esse intervalo, e exige que as duas coexistam."}
```

## Invertendo a ordem

`create_before_destroy` é um argumento de lifecycle, e os argumentos de lifecycle ficam num bloco
`lifecycle` dentro do recurso. Eles não descrevem o recurso para a AWS; dizem ao Terraform como
tratá-lo. A Ana acrescenta um na `web`:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 1b1c85a..891f592 100644
--- a/main.tf
+++ b/main.tf
@@ -28,4 +28,8 @@ resource "aws_instance" "web" {
   instance_type = "t3.micro"
   subnet_id     = aws_subnet.a.id
   tags          = { Name = "web" }
+
+  lifecycle {
+    create_before_destroy = true
+  }
 }
```

e volta a instância para a imagem mais antiga, o que é outra substituição:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "then|Destr|Creat"
+/- create replacement and then destroy
aws_instance.web: Creating...
aws_instance.web: Creation complete after 10s [id=i-6deb06a6fc79f194d]
aws_instance.web (deposed object a7b0101c): Destroying... [id=i-2c8873777c5bd44a7]
aws_instance.web: Destruction complete after 10s
```

O símbolo agora é `+/-`, **create replacement and then destroy**. A instância nova é criada
primeiro, e a antiga fica guardada como *deposed object*, uma entrada no state que o Terraform
ainda precisa destruir, até a nova existir. Se a criação da substituta falhar, a antiga nem é
tocada.

## Duas coisas que não podem existir duas vezes

O preço é que, por um momento, as duas existem. Para uma instância isso é inofensivo. Para qualquer
coisa cujo nome precisa ser único, é uma colisão. O nome de um security group precisa ser único
dentro da VPC, e a Ana acrescenta um grupo chamado `web`, com a mesma configuração de lifecycle:

```
ana@laptop:~/shop/app$ git show --format= -U1
diff --git a/main.tf b/main.tf
index d5b3605..b6ac7a8 100644
--- a/main.tf
+++ b/main.tf
@@ -35 +35,11 @@ resource "aws_instance" "web" {
 }
+
+resource "aws_security_group" "web" {
+  name        = "web"
+  description = "web servers"
+  vpc_id      = aws_vpc.shop.id
+
+  lifecycle {
+    create_before_destroy = true
+  }
+}
```

Mudar a descrição dele força uma substituição, e a substituta é criada primeiro, com o nome que o
grupo antigo ainda ocupa:

```
Plan: 1 to add, 0 to change, 1 to destroy.
aws_security_group.web: Creating...
╷
│ Error: creating Security Group (web): operation error EC2: CreateSecurityGroup, https response error StatusCode: 400, RequestID: fDtrMqfbSnnexOm9LqLWCBSFqM2AssK7VE35L0t3S2csl1OKpO6x, api error InvalidGroup.Duplicate: The security group 'web' already exists
│ 
│   with aws_security_group.web,
│   on main.tf line 37, in resource "aws_security_group" "web":
│   37: resource "aws_security_group" "web" {
│ 
╵
```

A AWS recusou o segundo `web`, e nada mais aconteceu: o grupo antigo continua intacto, porque
destruí-lo era o passo seguinte. **A correção é parar de fixar o nome.** `name_prefix` dá ao
Terraform o começo do nome e o deixa acrescentar um sufixo único, então o grupo antigo e o novo
podem coexistir durante o instante da troca:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index b6ac7a8..0d2ae36 100644
--- a/main.tf
+++ b/main.tf
@@ -35,8 +35,8 @@ resource "aws_instance" "web" {
 }
 
 resource "aws_security_group" "web" {
-  name        = "web"
-  description = "web servers"
+  name_prefix = "web-"
+  description = "the shop web servers"
   vpc_id      = aws_vpc.shop.id
 
   lifecycle {
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "Destr|Creat"
aws_security_group.web: Creating...
aws_security_group.web: Creation complete after 0s [id=sg-7bd9ca389f1f7168d]
aws_security_group.web (deposed object 92705d6e): Destroying... [id=sg-873abb194bdcfb043]
aws_security_group.web: Destruction complete after 0s
ana@laptop:~/shop/app$ aws ec2 describe-security-groups --filters "Name=group-name,Values=web*" --query "SecurityGroups[].GroupName" --output text
web-1180f21630fc619080001bfd97
```

A ordem é a da figura: criar, depois destruir o deposed object. O mesmo vale para qualquer coisa
com nome único, um load balancer, uma role do IAM, um bucket; onde o provider oferece um
`name_prefix`, ele existe para isso.

**Por que o security group é o caso típico.** Numa conta real a AWS se recusa a apagar um grupo que
ainda está associado a uma instância em execução, então a ordem padrão tentaria destruir primeiro e
falharia. O grupo deste laboratório não está associado a nada: o moto perdeu a lista de grupos de
uma instância quando o grupo foi substituído, o que a AWS não faz, então a aula deixa a associação
de fora em vez de citar um plan que só o moto imprimiria. E uma regra que a documentação afirma: o
Terraform também aplica `create_before_destroy`, implicitamente, a todo recurso de que o recurso
marcado depende.
