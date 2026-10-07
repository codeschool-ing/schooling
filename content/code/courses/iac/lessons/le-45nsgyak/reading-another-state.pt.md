---
title: Ler os outputs de outra configuração
version: 2
---

Depois da divisão, a aplicação encontra a VPC com um data source que procura a tag `Name = shop`.
Funciona hoje, e a aula 5 mostrou o dia em que para de funcionar: alguém cria uma segunda VPC com
essa tag, e a busca encontra duas. **Uma tag é um palpite sobre os recursos de outro time; um output
é uma promessa que eles fizeram.** A configuração da rede já declara três outputs, e o plan depois da
divisão se ofereceu para registrá-los. A Ana aplica, o que não muda recurso nenhum e grava os valores
no estado da rede:

```
ana@laptop:~/shop/network$ terraform apply -auto-approve | tail -n 9

Outputs:

public_subnet_ids = [
  "subnet-2fc7f0dc6fb32b7e4",
  "subnet-0bf2cbc4f593b157b",
]
vpc_cidr = "10.20.0.0/16"
vpc_id = "vpc-644904a24046c8bab"
```

## `terraform_remote_state`

Um data source de um tipo especial lê esses valores. Ele não faz parte do provider da AWS; vem
embutido no Terraform, e recebe as mesmas configurações de um bloco de backend, porque o que ele faz
é ler o estado de outra configuração de onde quer que esse estado esteja guardado. A Ana o põe num
arquivo só dele na aplicação, `app/network.tf`:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "shop-tfstate-123456789012"
    key    = "network/terraform.tfstate"
    region = "sa-east-1"
  }
}
```

O security group da aplicação agora pede o output pelo nome, e a busca por tag sai:

```
ana@laptop:~/shop/app$ git diff main.tf
diff --git a/app/main.tf b/app/main.tf
index d35d71b..72b1aa9 100644
--- a/app/main.tf
+++ b/app/main.tf
@@ -11,14 +11,10 @@ provider "aws" {
   region = "sa-east-1"
 }
 
-data "aws_vpc" "shop" {
-  tags = { Name = "shop" }
-}
-
 resource "aws_security_group" "web" {
   name        = "web"
   description = "web servers"
-  vpc_id      = data.aws_vpc.shop.id
+  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
   tags        = { Name = "web" }
 
   ingress {
```

```
ana@laptop:~/shop/app$ terraform plan
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 1s
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`: o id de VPC que o output dá é o mesmo que a busca por tag encontrava, então o security
group fica onde está. As duas primeiras linhas do plan são a leitura: antes de consultar qualquer coisa dela, a
aplicação buscou `network/terraform.tfstate` no bucket.

Do outro estado, a aplicação enxerga os `outputs` e mais nada. Depois que um apply guarda o que o
data source leu, o `terraform console` mostra:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/app$ echo "data.terraform_remote_state.network.outputs" | terraform console
{
  "public_subnet_ids" = [
    "subnet-2fc7f0dc6fb32b7e4",
    "subnet-0bf2cbc4f593b157b",
  ]
  "vpc_cidr" = "10.20.0.0/16"
  "vpc_id" = "vpc-644904a24046c8bab"
}
```

A Ana faz commit da aplicação como ela está agora.

Os recursos do estado da rede não estão nesse objeto. Os ids deles, as tabelas de rotas, cada
atributo das sub-redes: nada disso pode ser referenciado, só os três valores que a rede escolheu
publicar.

## Um output é um contrato

Escolher o que vira output é escolher do que outras configurações podem depender, e a aula 2 disse
isso antes de haver alguém para depender. Veja o que acontece quando a promessa é quebrada. Alguém
arruma os nomes da rede, renomeia `vpc_id` para `shop_vpc_id`, e aplica:

```
ana@laptop:~/shop/network$ git diff outputs.tf
diff --git a/network/outputs.tf b/network/outputs.tf
index 235be31..d152748 100644
--- a/network/outputs.tf
+++ b/network/outputs.tf
@@ -1,4 +1,4 @@
-output "vpc_id" {
+output "shop_vpc_id" {
   description = "The shop's VPC."
   value       = aws_vpc.shop.id
 }
ana@laptop:~/shop/network$ terraform apply -auto-approve | grep -E "^Apply|vpc_id"
  + shop_vpc_id       = "vpc-644904a24046c8bab"
  - vpc_id            = "vpc-644904a24046c8bab" -> null
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
shop_vpc_id = "vpc-644904a24046c8bab"
```

O plan da própria rede fica tranquilo com isso. **Nada na configuração da rede sabe quem lê os
outputs dela**, então remover um é uma mudança comum, que não toca recurso nenhum. A aplicação
descobre no próximo plan:

```
ana@laptop:~/shop/app$ terraform plan
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Unsupported attribute
│ 
│   on main.tf line 17, in resource "aws_security_group" "web":
│   17:   vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
│     ├────────────────
│     │ data.terraform_remote_state.network.outputs is object with 3 attributes
│ 
│ This object does not have an attribute named "vpc_id".
╵
```

O plan falha antes de causar estrago, e essa é a metade boa. A metade ruim é que ele falha para o
time errado, talvez semanas depois. Por isso um output é tratado como a assinatura de uma função:
acrescentar um é de graça, enquanto renomear ou remover um é uma mudança a anunciar, mantendo o nome
antigo ao lado do novo até que todo leitor tenha migrado. O time de rede pôs o `vpc_id` de volta,
com `git checkout outputs.tf` e um apply em `~/shop/network`.

## O que custa ler um estado

O `terraform_remote_state` mostra só outputs para a configuração, e essa é uma restrição do
Terraform, não do S3. Para ler os outputs, a aplicação precisa **baixar o estado inteiro da rede**,
então quem roda o plan da aplicação precisa de leitura no objeto, com cada atributo de cada recurso
dentro dele. Para uma rede, isso é um mapa da infraestrutura; para um estado que guarda um banco de
dados, a aula 12 mostra que ele guarda também a senha.

Há dois caminhos comuns para contornar isso, e o certo depende de quanto os dois times confiam um no
outro. Um são os data sources da aula 5, com a busca tornada confiável por um acordo sobre as tags,
tratadas como interface: a aplicação precisa de permissão para descrever VPCs, e de mais nada. O
outro é a rede gravar os poucos valores que os outros precisam num lugar feito para compartilhar,
como um parâmetro do SSM, e a aplicação ler dali. Os dois trocam a conveniência de uma referência
por uma porta mais estreita.
