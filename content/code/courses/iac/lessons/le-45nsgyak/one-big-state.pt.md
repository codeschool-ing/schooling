---
title: O problema de um estado só para tudo
version: 1
---

A aula 7 deixou a loja com uma configuração e um estado, guardado no S3 sob uma key. Desde então a
configuração cresceu. Agora ela tem a rede, o security group `web` e os dois buckets da aula 6, tudo
num `main.tf` só:

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

# The network: made once, changed a few times a year.
resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}

# The application: changed every week.
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

O backend é o da aula 7, sem mudança, e o estado guarda seis recursos sob uma key:

```
ana@laptop:~/shop$ terraform state list
aws_s3_bucket.assets
aws_s3_bucket.logs
aws_security_group.web
aws_subnet.public_a
aws_subnet.public_c
aws_vpc.shop
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:08:56      12484 shop/terraform.tfstate
```

**Nada está quebrado, e é por isso que esse formato dura.** Um diretório, um `apply`, um lugar para
olhar. Um estado só é o começo certo para uma configuração pequena, e todo time começa assim. A
questão é quanto ele custa conforme a configuração cresce, e o custo aparece em três lugares.

## Toda mudança planeja tudo

A Ana põe uma tag no bucket de assets. É uma linha, num recurso:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 6ddd87f..583a3b8 100644
--- a/main.tf
+++ b/main.tf
@@ -49,6 +49,7 @@ resource "aws_security_group" "web" {
 
 resource "aws_s3_bucket" "assets" {
   bucket = "shop-assets-dev"
+  tags   = { Owner = "ana" }
 }
 
 resource "aws_s3_bucket" "logs" {
ana@laptop:~/shop$ terraform plan -no-color | grep -E "Refreshing|^  #|^Plan"
aws_vpc.shop: Refreshing state... [id=vpc-644904a24046c8bab]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_subnet.public_c: Refreshing state... [id=subnet-0bf2cbc4f593b157b]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]
aws_subnet.public_a: Refreshing state... [id=subnet-2fc7f0dc6fb32b7e4]
  # aws_s3_bucket.assets will be updated in-place
Plan: 0 to add, 1 to change, 0 to destroy.
```

**Um recurso a mudar, e seis consultados para descobrir isso.** Antes de todo plan, o Terraform
pergunta à AWS por cada recurso do estado, porque não tem como saber quais alguém mudou à mão. Seis
chamadas não custam nada. Com seiscentas, o plan de uma tag num bucket espera por cada sub-rede, rota e registro DNS que a empresa
tem. O lock da aula 7 fica preso o tempo todo, então ninguém mais consegue planejar a rede enquanto
a Ana mexe na tag do bucket dela.

## O raio de explosão é o estado inteiro

O plan acima mudou um bucket, e poderia ter mudado qualquer coisa. **O estado contra o qual um
comando roda é o conjunto de coisas que um erro alcança.** Um erro de digitação numa referência, um
merge ruim que apaga um bloco, um `-replace` apontado para o endereço errado: cada um é aplicado ao
que o estado guarda. Nesta configuração, uma edição descuidada na aplicação pode destruir a VPC, e
cada sub-rede e grupo dentro dela vai junto.

## Quem pode mudar o quê

As permissões seguem o estado, não o recurso. Quem pode aplicar esta configuração pode mudar tudo
nela, então um pipeline que publica a aplicação todo dia tem as credenciais para reconstruir a rede.
E as pessoas pisam umas nas outras: o time de rede espera o plan da aplicação soltar o lock, e revisa
pull requests cheios de mudanças que não são dele.

## Onde cortar

O corte mais comum segue duas perguntas. **Com que frequência muda, e quem muda?** A VPC e as
sub-redes são feitas uma vez e mexidas poucas vezes por ano, por quem cuida da rede. O security group
e os buckets mudam com a aplicação, toda semana. Duas respostas, então dois estados:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois arranjos lado a lado. À esquerda, um estado só, shop/terraform.tfstate, guarda a VPC, duas sub-redes, o security group web e dois buckets, atrás de um lock que todo mundo divide. À direita, os mesmos recursos em dois estados: network/terraform.tfstate guarda a VPC e as sub-redes e muda poucas vezes por ano; app/terraform.tfstate guarda o security group e os buckets e muda toda semana. A rede publica outputs, e a aplicação os lê com terraform_remote_state.\"><defs><marker id=\"sp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sp-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">um estado, um lock</text><text x=\"145.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop/terraform.tfstate</text><text x=\"145.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_vpc.shop</text><text x=\"145.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.public_a</text><text x=\"145.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.public_c</text><text x=\"145.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_security_group.web</text><text x=\"145.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.assets</text><text x=\"145.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.logs</text><text x=\"145.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toda mudança planeja os seis</text><rect x=\"330\" y=\"30\" width=\"370\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">rede: poucas mudanças por ano</text><text x=\"345.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">network/terraform.tfstate</text><text x=\"345.0\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_vpc.shop</text><text x=\"345.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.public_a  aws_subnet.public_c</text><rect x=\"330\" y=\"180\" width=\"370\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aplicação: muda toda semana</text><text x=\"345.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app/terraform.tfstate</text><text x=\"345.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_security_group.web</text><text x=\"345.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.assets  aws_s3_bucket.logs</text><path d=\"M515 132 L515 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-phosphor)\"></path><text x=\"530.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">outputs</text><text x=\"530.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">terraform_remote_state</text><path d=\"M274 145 L326 145\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-wire)\"></path><text x=\"360.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">dividido por quanto muda e por quem muda</text></svg>", "caption": "Um estado para tudo contra dois estados cortados por quanto as coisas mudam e por quem as muda.", "same": ["outputs"]}
```

Outras linhas são igualmente razoáveis: por ambiente (aula 11), por time, ou pelo tamanho do estrago
de um erro, com o banco de dados separado de tudo que pode ser reconstruído. O que elas têm em comum é
que **o corte segue dono e ciclo de vida, nunca o tamanho de um arquivo**. Um estado dividido ao acaso
dá duas configurações que precisam mudar juntas a cada funcionalidade, o que é pior do que uma.

O preço de dividir é uma fronteira. O security group da aplicação precisa do id da VPC, e depois da
divisão esse id mora em outro estado. As duas próximas seções fazem o corte e depois constroem a ponte
por cima dele.
