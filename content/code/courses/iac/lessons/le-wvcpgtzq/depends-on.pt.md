---
title: Dependências que o Terraform não enxerga
version: 1
---

O Terraform decide a ordem das operações a partir das referências. Na aula 2 a sub-rede nomeava
`aws_vpc.shop.id`, então a VPC foi criada primeiro, e ninguém escreveu essa ordem. **O grafo é
montado a partir das expressões, então uma dependência que não está numa expressão não existe para
ele**, e tudo o que não tem caminho entre si e outra coisa é criado ao mesmo tempo, em paralelo.

Isso costuma ser o que você quer, e falha de um jeito específico: quando um recurso precisa de
outro por algo que o Terraform não lê. Em `~/shop/boot`, a instância `web` dá boot baixando um
script de um bucket que a mesma configuração cria:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "boot" {
  bucket = "shop-boot-dev"
}

resource "aws_s3_object" "script" {
  bucket  = aws_s3_bucket.boot.bucket
  key     = "boot.sh"
  content = "#!/bin/sh\necho configuring the web server\n"
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.micro"
  user_data     = "#!/bin/sh\naws s3 cp s3://shop-boot-dev/boot.sh - | sh\n"
}
```

O objeto nomeia o bucket por `aws_s3_bucket.boot.bucket`, uma referência. A instância o nomeia
dentro de uma string, `s3://shop-boot-dev/boot.sh`, que para o Terraform é só texto. `terraform
graph` imprime o que o Terraform sabe, e ele sabe de uma aresta:

```
ana@laptop:~/shop/boot$ terraform graph
digraph G {
  rankdir = "RL";
  node [shape = rect, fontname = "sans-serif"];
  "aws_instance.web" [label="aws_instance.web"];
  "aws_s3_bucket.boot" [label="aws_s3_bucket.boot"];
  "aws_s3_object.script" [label="aws_s3_object.script"];
  "aws_s3_object.script" -> "aws_s3_bucket.boot";
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três recursos. O Terraform enxerga uma seta, do objeto para o bucket, porque a configuração do objeto nomeia o bucket. O script de boot da instância baixa o objeto no boot, mas o nomeia dentro de uma string, então essa dependência aparece tracejada: ela existe no mundo e não no grafo do Terraform.\"><defs><marker id=\"hd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hd-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"90\" width=\"190\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aws_s3_bucket.boot</text><rect x=\"290\" y=\"90\" width=\"190\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aws_s3_object.script</text><rect x=\"540\" y=\"90\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aws_instance.web</text><path d=\"M290 117 L232 117\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hd-ah-phosphor)\"></path><text x=\"261.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">uma referência</text><path d=\"M540 117 L482 117\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#hd-ah-amber)\"></path><text x=\"511.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">uma string no boot</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que o Terraform ordena: só as setas cheias</text><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a tracejada é real e invisível para o grafo</text></svg>", "caption": "Uma dependência que o Terraform não enxerga: o script de boot nomeia o bucket numa string, então o grafo não tem seta para ela."}
```

Então o apply começa a instância e o bucket juntos:

```
ana@laptop:~/shop/boot$ terraform apply -auto-approve | grep -E "Creat"
aws_instance.web: Creating...
aws_s3_bucket.boot: Creating...
aws_s3_bucket.boot: Creation complete after 1s [id=shop-boot-dev]
aws_s3_object.script: Creating...
aws_s3_object.script: Creation complete after 0s [id=shop-boot-dev/boot.sh]
aws_instance.web: Creation complete after 10s [id=i-bf711cb2e8c4a7945]
```

**A instância começou antes de o bucket existir.** No laboratório nada dá boot, então nada quebra.
Numa conta real o primeiro boot da máquina disputaria corrida com o upload, e no dia em que a
instância ganhasse ela subiria sem a configuração, o tipo de falha que não acontece nos testes e
acontece em produção.

## `depends_on`

`depends_on` acrescenta uma aresta à mão. Recebe uma lista de recursos, e o recurso espera por
todos eles:

```
ana@laptop:~/shop/boot$ git diff
diff --git a/main.tf b/main.tf
index 3cc6705..92a755c 100644
--- a/main.tf
+++ b/main.tf
@@ -16,4 +16,6 @@ resource "aws_instance" "web" {
   ami           = "ami-1e749f67"
   instance_type = "t3.micro"
   user_data     = "#!/bin/sh\naws s3 cp s3://shop-boot-dev/boot.sh - | sh\n"
+
+  depends_on = [aws_s3_object.script]
 }
ana@laptop:~/shop/boot$ terraform graph | grep -- "->"
  "aws_instance.web" -> "aws_s3_object.script";
  "aws_s3_object.script" -> "aws_s3_bucket.boot";
```

O grafo agora tem a aresta, e a instância é criada depois do objeto, que vem depois do bucket.
**Isso é tudo o que `depends_on` faz, e ele tem um custo.** Ele diz *espere* e não *por quê*: a
próxima pessoa a ler o arquivo vê uma dependência sem motivo visível e ou a mantém para sempre ou a
apaga como entulho. Tudo o que ele lista precisa terminar antes de o recurso começar, então uma
lista longa transforma um apply paralelo numa fila. E num data source ele adia a leitura para o
apply sempre que a dependência tem mudanças pendentes, que a aula 5 mostrou como `(known after
apply)` onde nada era de fato desconhecido.

## Uma referência é melhor

Aqui havia uma referência a fazer. A instância depende mesmo do bucket e da chave do objeto, então
pode dizer isso na string:

```
ana@laptop:~/shop/boot$ git diff
diff --git a/main.tf b/main.tf
index 3cc6705..6b7b783 100644
--- a/main.tf
+++ b/main.tf
@@ -15,5 +15,5 @@ resource "aws_s3_object" "script" {
 resource "aws_instance" "web" {
   ami           = "ami-1e749f67"
   instance_type = "t3.micro"
-  user_data     = "#!/bin/sh\naws s3 cp s3://shop-boot-dev/boot.sh - | sh\n"
+  user_data     = "#!/bin/sh\naws s3 cp s3://${aws_s3_object.script.bucket}/${aws_s3_object.script.key} - | sh\n"
 }
ana@laptop:~/shop/boot$ terraform graph | grep -- "->"
  "aws_instance.web" -> "aws_s3_object.script";
  "aws_s3_object.script" -> "aws_s3_bucket.boot";
```

A mesma aresta, e nenhum `depends_on`. A dependência agora está na expressão que a tem, o nome do
bucket é escrito uma vez em vez de duas, e renomear o bucket o renomeia também no script de boot.
Recorra ao `depends_on` quando de fato não houver o que referenciar: uma policy que precisa estar
associada antes de um serviço usar uma role, ou um recurso cujo efeito sobre outro é invisível nos
argumentos dos dois. Quando usar, deixe um comentário ao lado dizendo pelo que ele espera.
