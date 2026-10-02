---
title: "terraform import: adotar um bucket que alguém fez à mão"
version: 1
---

O import do time de dados partiu de um recurso que estava sendo gerenciado até um instante antes, com
um bloco pronto para copiar. O caso comum é menos arrumado. O Bruno, que cuida dos backups, criou um
bucket à mão na semana passada, da máquina dele, pôs tags, e pediu à Ana para trazê-lo para a
configuração da loja. Nada em estado nenhum sabe que ele existe:

```
ana@laptop:~/shop/app$ aws s3api get-bucket-tagging --bucket shop-backups-dev
{
    "TagSet": [
        {
            "Key": "Owner",
            "Value": "bruno"
        },
        {
            "Key": "Purpose",
            "Value": "backups"
        }
    ]
}
```

Antes de os blocos import chegarem, no Terraform 1.5, o único caminho era um comando, e ele ainda está
em todo runbook e na maioria das respostas que você vai encontrar: `terraform import ENDEREÇO ID`. Ele
faz uma coisa, na hora: **lê o objeto da nuvem e o grava no estado naquele endereço.** Não escreve
configuração, e não roda sem alguma:

```
ana@laptop:~/shop/app$ terraform import aws_s3_bucket.backups shop-backups-dev
Error: resource address "aws_s3_bucket.backups" does not exist in the configuration.

Before importing this resource, please create its configuration in the root module. For example:

resource "aws_s3_bucket" "backups" {
  # (resource arguments)
}
```

O endereço precisa existir na configuração antes, porque a entrada no estado precisa pertencer a um
bloco. Então a Ana escreve o menor bloco que nomeia o bucket:

```hcl
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-dev"
}
```

```
ana@laptop:~/shop/app$ terraform import aws_s3_bucket.backups shop-backups-dev
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_s3_bucket.backups: Importing from ID "shop-backups-dev"...
aws_s3_bucket.backups: Import prepared!
  Prepared aws_s3_bucket for import
aws_s3_bucket.backups: Refreshing state... [id=shop-backups-dev]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

`Import successful!`, e o bucket está no estado da aplicação. Repare no que não aconteceu. Não houve
plan nem pergunta; ninguém viu o que entrou no estado antes de ser gravado. **O estado agora diz que o
bucket é gerenciado por um bloco que não o descreve**, e é no próximo plan que isso aparece:

```
ana@laptop:~/shop/app$ terraform plan
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_s3_bucket.backups: Refreshing state... [id=shop-backups-dev]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_s3_bucket.backups will be updated in-place
  ~ resource "aws_s3_bucket" "backups" {
        id                          = "shop-backups-dev"
      ~ tags                        = {
          - "Owner"   = "bruno" -> null
          - "Purpose" = "backups" -> null
        }
      ~ tags_all                    = {
          - "Owner"   = "bruno" -> null
          - "Purpose" = "backups" -> null
        }
        # (14 unchanged attributes hidden)

        # (2 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

O Terraform compara o bloco com o bucket como foi importado, e o bloco não diz nada sobre tags, o que
para o Terraform quer dizer "sem tags". O plan arrancaria as duas tags do Bruno. O import estava
certo e a configuração estava incompleta, e a diferença é uma mudança pendente esperando alguém
digitar `yes`. Se esse alguém for um pipeline que aplica todo merge automaticamente, as tags somem.

**O conserto é sempre do lado da configuração: fazer o bloco descrever o que existe**, e planejar até
o plan sair limpo:

```
ana@laptop:~/shop/app$ cat backups.tf
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-dev"
  tags = {
    Owner   = "bruno"
    Purpose = "backups"
  }
}
ana@laptop:~/shop/app$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`, e só agora o import está terminado. A ordem a lembrar é o inverso de criar algo: com um
recurso novo, você escreve o bloco e o apply faz o mundo bater com ele; com um import, o mundo já está
lá, e você edita o bloco até ele bater com o mundo.

## Por que a forma em bloco o substituiu

O comando ainda funciona, e ainda é o caminho mais curto para adotar um objeto num terminal. Mas os
três hábitos dele são os que a aula 7 apontou nos comandos de estado. Ele grava o estado compartilhado
**na hora**, fora de qualquer plan, então um id ou endereço errado chega ao estado sem ninguém revisar.
Ele aceita **um recurso por comando**, então adotar cinquenta quer dizer cinquenta comandos no
histórico do shell de alguém. E não deixa **nenhum rastro no repositório**: a próxima pessoa vê um
`backups.tf` e não tem como saber se o Terraform criou aquele bucket ou o adotou.

Um bloco `import` resolve os três. Ele passa por um plan, onde o import e qualquer diferença aparecem
lado a lado antes de algo ser gravado; pode ficar ao lado de outros cinquenta num arquivo; e faz parte
do commit que acrescenta o recurso. A última seção desta aula vai além, para um recurso cuja
configuração ninguém escreveu.
