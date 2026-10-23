---
title: O plano é onde a revisão acontece
version: 1
---

**Um pull request que muda infraestrutura mostra duas coisas: o código, e o plano que esse código
produz. O plano é o que diz o que vai de fato acontecer, e ele só é útil na medida do que consegue
enxergar.** Esta seção escreve o erro da aula 1 em Terraform e observa o plano escondê-lo, depois
mostrá-lo, depois uma consulta encontrá-lo.

O hábito errado é ler o diff dos arquivos `.tf` e passar o olho no plano como se fosse ruído. O diff
mostra o que alguém digitou. O plano mostra o que a AWS vai ser chamada a fazer, depois de resolvidas
variáveis, valores padrão e referências, e quem aprova o código sem o plano aprovou uma mudança que
nunca viu.

## O bucket de exportação, como código

O caio leva o bucket de exportação para o Terraform, com a política do tablet junto. Inicie o moto
vazio e crie um diretório para a configuração:

```sh
mkdir -p ~/aws/clinic && cd ~/aws/clinic
```

Salve isto como `main.tf` ali:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true
}

locals {
  bucket = "clinic-exports"
}

resource "aws_s3_bucket" "exports" {
  bucket = local.bucket
}

# The reception's tablet reads the day's export.
resource "aws_s3_bucket_policy" "tablet" {
  bucket = aws_s3_bucket.exports.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.exports.arn}/*"
    }]
  })
}
```

A política é a da aula 1, palavra por palavra: `s3:GetObject` para `"Principal": "*"`. Rode `terraform
init` uma vez no diretório, depois peça o plano. O plano completo lista cada atributo do bucket, então
o `sed` recorta a parte da política:

```
ana@laptop:~/aws/clinic$ terraform plan -no-color | sed -n '/tablet will be created/,/^    }/p'
  # aws_s3_bucket_policy.tablet will be created
  + resource "aws_s3_bucket_policy" "tablet" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + policy = (known after apply)
      + region = "sa-east-1"
    }
```

**A política que a revisão existe para pegar não está no plano.** Ela aparece como `(known after
apply)`, porque a linha `Resource` usa o ARN do bucket, um atributo que o Terraform trata como
desconhecido até o bucket ser criado. Quem revisa este plano vê uma política sendo anexada e nada do
que ela diz. O código ainda a mostra, três telas adiante num diff, e é exatamente aí que ela passa
batida.

## Tornando o valor conhecível

O ARN de um bucket não é mistério: é `arn:aws:s3:::` seguido do nome, e o nome está em
`local.bucket`. Mude a linha `Resource` para que ela seja montada a partir do nome:

```hcl
      Resource  = "arn:aws:s3:::${local.bucket}/*"
```

```
ana@laptop:~/aws/clinic$ terraform plan -no-color | sed -n '/tablet will be created/,/^    }/p'
  # aws_s3_bucket_policy.tablet will be created
  + resource "aws_s3_bucket_policy" "tablet" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + policy = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "s3:GetObject"
                      + Effect    = "Allow"
                      + Principal = "*"
                      + Resource  = "arn:aws:s3:::clinic-exports/*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + region = "sa-east-1"
    }
```

Agora o plano diz: `Principal = "*"`, `Action = "s3:GetObject"`. **Escrever a configuração de modo que
o plano consiga mostrar os valores é um hábito de segurança, não uma questão de estilo**, porque o
plano é o documento que quem revisa de fato lê.

## Uma pergunta em vez de uma leitura

Uma pessoa lendo planos se cansa no quadragésimo recurso. Um plano salvo em arquivo pode virar JSON e
receber uma pergunta, a mesma toda vez: que instrução, em qualquer política que esta mudança escreve,
permite algo a todo mundo?

```
ana@laptop:~/aws/clinic$ terraform plan -out=plan.bin -no-color > /dev/null
ana@laptop:~/aws/clinic$ terraform show -json plan.bin | jq -r '.resource_changes[] | select(.change.after.policy != null) | .address as $a | .change.after.policy | fromjson | .Statement[] | select(.Principal == "*") | "\($a)  \(.Effect)  \(.Action)"'
aws_s3_bucket_policy.tablet  Allow  s3:GetObject
```

Uma linha por instrução problemática, com o nome do recurso. A consulta tem um ponto cego, e é o que o
primeiro plano mostrou: **uma política ainda desconhecida no momento do plano não tem valor para
consultar**, então passa em silêncio. Uma consulta como esta é um segundo leitor, e ela só é tão boa
quanto a primeira correção, que foi tornar o valor conhecível.

Nada foi aplicado, e nada será: a revisão acontece antes. A próxima seção entrega o mesmo arquivo a um
scanner que conhece centenas de perguntas como esta.
