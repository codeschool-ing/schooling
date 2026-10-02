---
title: Lendo um plano, símbolo por símbolo
version: 1
---

O plano da aula 2 só criava coisas, então toda linha começava com `+` e o resumo dizia tudo. Esse é
o caso fácil, e ele cria um mau hábito: ler a última linha e confiar nela. **Um plano é uma lista
de recursos, cada um com exatamente uma ação, e o resumo é uma contagem dessas ações que perde os
motivos.** Os motivos estão no corpo, e uma revisão lê o corpo.

Para ver todos de uma vez, a Ana faz quatro edições de uma tacada na configuração da loja: renomeia
a sub-rede `a`, passa a instância `web` para uma imagem mais nova, apaga a sub-rede `b` e acrescenta
um bucket de arquivos, uma política que deixa o `web` lê-lo e uma senha para um banco de dados que
vem depois:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 5c3e89a..bda5b76 100644
--- a/main.tf
+++ b/main.tf
@@ -11,14 +11,7 @@ resource "aws_subnet" "a" {
   vpc_id            = aws_vpc.shop.id
   cidr_block        = "10.20.1.0/24"
   availability_zone = "sa-east-1a"
-  tags              = { Name = "shop-a" }
-}
-
-resource "aws_subnet" "b" {
-  vpc_id            = aws_vpc.shop.id
-  cidr_block        = "10.20.2.0/24"
-  availability_zone = "sa-east-1c"
-  tags              = { Name = "shop-b" }
+  tags              = { Name = "shop-public-a" }
 }
 
 resource "aws_security_group" "web" {
@@ -44,7 +37,7 @@ resource "aws_vpc_security_group_ingress_rule" "ssh" {
 }
 
 resource "aws_instance" "web" {
-  ami                    = "ami-1e749f67"
+  ami                    = "ami-785db401"
   instance_type          = "t3.micro"
   subnet_id              = aws_subnet.a.id
   vpc_security_group_ids = [aws_security_group.web.id]
@@ -62,3 +55,24 @@ resource "aws_iam_role" "web" {
     }]
   })
 }
+
+resource "aws_s3_bucket" "assets" {
+  bucket_prefix = "shop-assets-"
+}
+
+data "aws_iam_policy_document" "assets_read" {
+  statement {
+    actions   = ["s3:GetObject"]
+    resources = ["${aws_s3_bucket.assets.arn}/*"]
+  }
+}
+
+resource "aws_iam_role_policy" "web_assets" {
+  name   = "assets-read"
+  role   = aws_iam_role.web.id
+  policy = data.aws_iam_policy_document.assets_read.json
+}
+
+resource "random_password" "db" {
+  length = 24
+}
```

O `terraform plan` abre com uma legenda que lista só os símbolos que este plano usa. Este usa cinco:

```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place
  - destroy
-/+ destroy and then create replacement
 <= read (data resources)
```

| símbolo | o que o Terraform vai fazer | neste plano |
| --- | --- | --- |
| `+` | criar um objeto novo | o bucket, a role policy, a senha |
| `~` | mudar o objeto onde ele está | a sub-rede `a`, cuja tag muda |
| `-` | destruir o objeto | a sub-rede `b` |
| `-/+` | destruí-lo e depois criar um substituto | a instância `web` |
| `<=` | ler um data source | o documento de política |

O corpo vem ordenado por endereço, data sources primeiro, e **cada recurso abre com uma linha de
comentário dizendo o que vai acontecer com ele e, quando não é óbvio, por quê**. A substituição diz
isso duas vezes, no comentário e ao lado do argumento responsável:

```
  # aws_instance.web must be replaced
-/+ resource "aws_instance" "web" {
      ~ ami                                  = "ami-1e749f67" -> "ami-785db401" # forces replacement
```

`# forces replacement` é a linha a procurar. A AMI não pode mudar numa instância em execução, então
o provider declara esse argumento imutável, e todo o resto do bloco é consequência: a instância
nova vai ter outro id, outro endereço privado e outro volume raiz. A aula 6 trata de quais
argumentos fazem isso e de como mudar a ordem para `+/-`.

A destruição também traz o motivo:

```
  # aws_subnet.b will be destroyed
  # (because aws_subnet.b is not in configuration)
  - resource "aws_subnet" "b" {
```

**Apagar um bloco do arquivo é a forma de pedir ao Terraform que destrua algo**, e o plano diz que
foi isso que aconteceu. A mesma linha aparece quando um recurso foi renomeado em vez de apagado, que
é o caso que pega as pessoas de surpresa; a aula 4 mostrou os blocos `moved` para ele.

O data source tem outro verbo:

```
  # data.aws_iam_policy_document.assets_read will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "assets_read" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:GetObject",
            ]
          + resources = [
              + (known after apply),
            ]
        }
    }
```

Um data source normalmente é lido durante o plano, e você nem o vê no corpo. Este cita o ARN do
bucket, que só existe quando o bucket existir, então a leitura fica para o apply e **o `(known
after apply)` se espalha para tudo que é construído a partir dele**: o texto da política e a role
policy que a usa. Esse marcador indica um valor que a nuvem inventa; a aula 2 o encontrou nos ids.
A aula 5 explica quando uma leitura é adiada.

Outro marcador esconde um valor que existe, sim:

```
  # random_password.db will be created
  + resource "random_password" "db" {
      + bcrypt_hash = (sensitive value)
      + id          = (known after apply)
      + length      = 24
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + numeric     = true
      + result      = (sensitive value)
      + special     = true
      + upper       = true
    }
```

`(sensitive value)` quer dizer que o provider marcou o atributo como secreto, então o plano não o
imprime. Não quer dizer que o valor fique guardado em lugar mais seguro, e a aula 12 mostra
exatamente onde ele vai parar.

Depois, o resumo:

```
Plan: 4 to add, 1 to change, 2 to destroy.
```

Confira contra o corpo. O bucket, a role policy e a senha são três criações; a instância `web` nova
é a quarta. A sub-rede `b` é uma destruição; a instância `web` antiga é a segunda. **Uma
substituição conta duas vezes, uma em cada coluna**, e o data source não conta nada. Então
`2 to destroy` não diz se duas coisas estão indo embora ou se uma coisa está sendo reconstruída. Só
as linhas `#` dizem.
