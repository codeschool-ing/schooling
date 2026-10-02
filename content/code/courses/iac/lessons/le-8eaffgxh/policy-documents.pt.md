---
title: Documentos montados por uma data source
version: 1
---

Nem toda data source pergunta algo a uma nuvem. Algumas calculam a resposta no notebook, a partir do
que você entrega, e a mais usada delas monta **documentos de policy do IAM**: o JSON que diz quem pode
fazer o quê em qual recurso. Uma policy pode ser escrita como uma string de JSON dentro da
configuração, e funciona. Também é um bloco de texto que o Terraform não consegue conferir, onde uma
vírgula faltando é descoberta pela AWS na hora do apply e o nome de um bucket digitado num ARN não
acompanha o bucket quando ele é renomeado.

`data "aws_iam_policy_document"` escreve o JSON para você a partir de blocos HCL, então referências,
funções e as próprias verificações de sintaxe do Terraform valem para ele. O bucket da Ana para as
imagens da loja ganha duas declarações (statements). A primeira recusa todo pedido que não use TLS,
uma base comum para buckets. A segunda deixa a conta ler objetos, mas só a partir dos endereços do
escritório, que o time de segurança mantém num arquivo do repositório:

```
203.0.113.0/28
198.51.100.32/29
```

```hcl
resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-${data.aws_caller_identity.current.account_id}"
}

data "aws_iam_policy_document" "assets" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.assets.arn, "${aws_s3_bucket.assets.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "OfficeReadsObjects"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = split("\n", trimspace(data.local_file.office.content))
    }
  }
}

data "local_file" "office" {
  filename = "${path.module}/office-cidrs.txt"
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets.json
}
```

Três data sources se encontram nesse arquivo. **`data.aws_caller_identity`**, da primeira seção, dá
ao bucket um nome único da conta e cita a conta na segunda declaração. **`data "local_file"`** lê a
lista do escritório; ela vem do provider `hashicorp/local`, e lê um arquivo da máquina que roda o
Terraform, não algo na AWS. E o documento de policy transforma as declarações em JSON.

O plano mostra de novo dois momentos diferentes:

```
ana@laptop:~/shop/app$ terraform plan
data.local_file.office: Reading...
data.local_file.office: Read complete after 0s [id=d31eb9db97a1f63a12b9d3ed7b67d80fde5b4ab8]
```
```
  # data.aws_iam_policy_document.assets will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "assets" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:*",
            ]
          + effect    = "Deny"
          + resources = [
              + (known after apply),
              + (known after apply),
            ]
          + sid       = "DenyInsecureTransport"
```

O arquivo foi lido primeiro, no plan, porque o `filename` é conhecido desde o começo, e por isso as
duas faixas já são valores comuns mais abaixo no mesmo documento:

```
          + condition {
              + test     = "IpAddress"
              + values   = [
                  + "203.0.113.0/28",
                  + "198.51.100.32/29",
                ]
              + variable = "aws:SourceIp"
            }
```

O documento de policy é adiado, e desta vez pelo outro motivo: **os `resources` dele se referem ao
ARN do bucket, um valor que não existe até a AWS criar o bucket**, então a configuração se refere a
valores ainda desconhecidos. Durante o apply, a ordem é exatamente a que isso implica:

```
Plan: 2 to add, 0 to change, 0 to destroy.
aws_s3_bucket.assets: Creating...
aws_s3_bucket.assets: Creation complete after 0s [id=shop-assets-123456789012]
data.aws_iam_policy_document.assets: Reading...
data.aws_iam_policy_document.assets: Read complete after 0s [id=2993801947]
aws_s3_bucket_policy.assets: Creating...
aws_s3_bucket_policy.assets: Creation complete after 0s [id=shop-assets-123456789012]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

O bucket, depois o documento, depois a policy que precisava dos dois. O que chegou à AWS é JSON
comum, lido aqui de volta do próprio bucket:

```
ana@laptop:~/shop/app$ aws s3api get-bucket-policy --bucket shop-assets-123456789012 --query Policy --output text | jq .
{
  "Statement": [
    {
      "Action": "s3:*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Effect": "Deny",
      "Principal": "*",
      "Resource": [
        "arn:aws:s3:::shop-assets-123456789012/*",
        "arn:aws:s3:::shop-assets-123456789012"
      ],
      "Sid": "DenyInsecureTransport"
    },
    {
      "Action": "s3:GetObject",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": [
            "203.0.113.0/28",
            "198.51.100.32/29"
          ]
        }
      },
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Resource": "arn:aws:s3:::shop-assets-123456789012/*",
      "Sid": "OfficeReadsObjects"
    }
  ],
  "Version": "2012-10-17"
}
```

Dois detalhes nele vieram da data source, não da Ana. A linha `"Version": "2012-10-17"`, que toda
policy do IAM deveria ter e que é fácil esquecer à mão, é acrescentada por ela. E o `Principal` da
primeira declaração é o `"*"` sozinho, que é como a AWS escreve "qualquer um" quando o bloco diz
`type = "*"`.

**Um arquivo lido por uma data source é uma entrada da configuração, igual a uma variável.** Editar o
`office-cidrs.txt` muda o próximo plano, e a revisão desse pull request é onde alguém deveria
perguntar por que apareceu uma faixa nova. Para um arquivo que existe antes do plan, a função
`file()` lê do mesmo jeito; a data source se justifica quando o arquivo é escrito por outra coisa na
mesma execução, e aí a leitura espera como qualquer outra.
