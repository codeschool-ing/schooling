---
title: Mover um recurso de um estado para outro
version: 1
---

A divisão moveu três entradas com comandos que ninguém revisou. Isso foi aceitável uma vez, numa
tarde tranquila, com a Ana fazendo as duas metades. **Um movimento entre os estados de dois times é
uma mudança em duas configurações, e o lugar dele é nos arquivos**, onde um pull request pode
mostrá-lo. A aula 6 prometeu um: o time de dados vai assumir o `shop-logs-dev`, que hoje está no
estado da aplicação.

A primeira coisa a saber é o que *não* funciona. O bloco `moved` da aula 4 renomeia um endereço
dentro de um estado; ele não tem como nomear outro estado, então não leva um recurso de um para o
outro. Um movimento entre estados é sempre duas operações, uma em cada configuração: **o dono antigo
larga, e o dono novo importa**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma sequência em três passos, da esquerda para a direita, para o bucket shop-logs-dev. Passo 1: o estado da aplicação o gerencia. Passo 2: depois que a aplicação aplica um bloco removed com destroy = false, nenhum estado o gerencia. Passo 3: depois que o time de dados aplica um bloco import, o estado de dados o gerencia. Embaixo, o bucket na AWS é o mesmo objeto o tempo todo e nunca é tocado.\"><defs><marker id=\"mv-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. antes</text><rect x=\"20\" y=\"50\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app/terraform.tfstate</text><text x=\"120.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.logs</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. depois do removed</text><rect x=\"260\" y=\"50\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">em nenhum estado</text><text x=\"600.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3. depois do import</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">data/terraform.tfstate</text><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_s3_bucket.logs</text><path d=\"M222 90 L258 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-amber)\"></path><path d=\"M462 90 L498 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"240.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">removed</text><text x=\"480.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">import</text><rect x=\"20\" y=\"180\" width=\"680\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">na AWS: o mesmo bucket o tempo todo</text><text x=\"360.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-logs-dev</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca em dois estados ao mesmo tempo</text></svg>", "caption": "Mover um recurso entre estados: largar num, depois importar no outro. O bucket em si nunca se move."}
```

## Primeiro, largar

Na aplicação, o bloco do bucket é apagado, e um bloco `removed` da aula 6 diz que apagar quer dizer
"parar de gerenciar", e não "destruir":

```hcl
removed {
  from = aws_s3_bucket.logs

  lifecycle {
    destroy = false
  }
}
```

```
ana@laptop:~/shop/app$ git diff main.tf
diff --git a/app/main.tf b/app/main.tf
index 72b1aa9..4b7913c 100644
--- a/app/main.tf
+++ b/app/main.tf
@@ -29,7 +29,3 @@ resource "aws_security_group" "web" {
 resource "aws_s3_bucket" "assets" {
   bucket = "shop-assets-dev"
 }
-
-resource "aws_s3_bucket" "logs" {
-  bucket = "shop-logs-dev"
-}
```

O plan é o que a aula 6 mostrou, um ponto em vez de um sinal de menos:

```
 # aws_s3_bucket.logs will no longer be managed by Terraform, but will not be destroyed
 # (destroy = false is set in the configuration)
 . resource "aws_s3_bucket" "logs" {
        id                          = "shop-logs-dev"
        tags                        = {}
        # (15 unchanged attributes hidden)

        # (2 unchanged blocks hidden)
    }

Plan: 0 to add, 0 to change, 0 to destroy.
╷
│ Warning: Some objects will no longer be managed by Terraform
│ 
│ If you apply this plan, Terraform will discard its tracking information for
│ the following objects, but it will not delete them:
│  - aws_s3_bucket.logs
│ 
│ After applying this plan, Terraform will no longer manage these objects.
│ You will need to import them into Terraform to manage them again.
╵

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

O bucket está na AWS e em nenhum estado. Essa lacuna é proposital, e a ordem é o ponto da receita.
Feito ao contrário, importando primeiro, o bucket ficaria por um tempo em dois estados, e duas
configurações gerenciando um objeto é como o apply de um time desfaz o de outro: quem planeja por
último põe de volta a sua ideia do bucket. **Gerenciado por ninguém durante uma hora é seguro;
gerenciado por dois, não.**

## Depois, importar

A configuração do time de dados é deles, com uma key própria no mesmo bucket. O `main.tf` declara o
bucket exatamente como a aplicação declarava, com o backend no mesmo arquivo desta vez:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "data/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

Declarar só o bucket daria um plan com `1 to add`: este estado nunca ouviu falar do bucket, então o
Terraform tentaria criá-lo. Mais um bloco diz que o recurso já existe, e qual objeto real ele é:

```hcl
import {
  to = aws_s3_bucket.logs
  id = "shop-logs-dev"
}
```

Um bloco `import` nomeia duas coisas: `to`, o endereço nesta configuração, e `id`, o objeto na nuvem,
na forma que aquele tipo de recurso usa para importar. Para um bucket, o id é o nome; a página de cada
recurso na documentação do provider diz como é o id de importação dele. O plan lê o bucket e mostra o
que vai entrar no estado:

```
ana@laptop:~/data$ terraform plan
aws_s3_bucket.logs: Preparing import... [id=shop-logs-dev]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]

Terraform will perform the following actions:

  # aws_s3_bucket.logs will be imported
    resource "aws_s3_bucket" "logs" {
        acceleration_status         = null
        arn                         = "arn:aws:s3:::shop-logs-dev"
        bucket                      = "shop-logs-dev"
        bucket_domain_name          = "shop-logs-dev.s3.amazonaws.com"
        bucket_namespace            = "global"
        bucket_prefix               = null
        bucket_region               = "sa-east-1"
        bucket_regional_domain_name = "shop-logs-dev.s3.sa-east-1.amazonaws.com"
        force_destroy               = false
        hosted_zone_id              = "Z7KQH4QJS55SO"
        id                          = "shop-logs-dev"
        object_lock_enabled         = false
        policy                      = null
        region                      = "sa-east-1"
        request_payer               = null
        tags                        = {}
        tags_all                    = {}

        grant {
            id          = "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
            permissions = [
                "FULL_CONTROL",
            ]
            type        = "CanonicalUser"
            uri         = null
        }

        versioning {
            enabled    = false
            mfa_delete = false
        }
    }

Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

**`Plan: 1 to import, 0 to add, 0 to change, 0 to destroy`** é a linha a ler. Ela quer dizer que o
bucket vai entrar no estado, e que o bloco no `main.tf` já o descreve como ele é: se a configuração
discordasse do bucket real, o mesmo plan mostraria também uma mudança, e o time a veria antes de
qualquer coisa acontecer. O apply faz o que o plan disse:

```
ana@laptop:~/data$ terraform apply -auto-approve | tail -n 4
aws_s3_bucket.logs: Importing... [id=shop-logs-dev]
aws_s3_bucket.logs: Import complete [id=shop-logs-dev]

Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
ana@laptop:~/data$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
ana@laptop:~/data$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:10:08       5863 app/terraform.tfstate
2026-10-02 07:10:19       2475 data/terraform.tfstate
2026-10-02 07:10:03       6548 network/terraform.tfstate
```

O bucket agora pertence ao estado do time de dados, que tem uma key própria ao lado das outras duas.
Nada na AWS mudou em momento nenhum. O bloco `import` cumpriu seu papel depois de aplicado; mantê-lo
no arquivo não faz mal, já que o Terraform pula um import cujo endereço já está no estado, e apagá-lo
num commit seguinte é só arrumação.

## Quando ninguém revisa: os comandos de estado

O caminho rápido continua existindo. Baixar os dois estados, `terraform state mv -state-out` como na
divisão, e empurrar os dois de volta faz o mesmo em um minuto. Ele serve para uma emergência ou para
uma reorganização de uma pessoa só, e tem os problemas da divisão: ninguém revisou, e é bom que os
dois estados estejam travados contra todo mundo enquanto isso acontece. Entre dois times, os dois
blocos são a versão que todo mundo consegue ler.
