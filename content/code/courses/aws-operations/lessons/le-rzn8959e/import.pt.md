---
title: Quando não sobra versão, importe o que existe
version: 1
---

Às vezes não há histórico de onde restaurar: o versionamento estava desligado, o próprio bucket sumiu,
ou o estado nunca esteve num bucket. Os recursos ainda existem, então **o Terraform pode ser
informado sobre eles de novo, um por um**, importando cada um para um estado novo. Desde o Terraform
1.5 isso é escrito na configuração como blocos `import`, revisados como qualquer mudança, e o Terraform
até escreve os blocos de recurso por você.

A configuração reconstruída guarda o estado numa chave nova, para nada tocar o original:

```hcl
# rebuilt/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop-rebuilt/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
  }
}
```

e nomeia, para cada recurso, o endereço que ele vai ter e o id que ele tem na AWS:

```hcl
# rebuilt/imports.tf
import {
  to = aws_cloudwatch_log_group.web
  id = "/shop/web"
}

import {
  to = aws_s3_bucket.uploads
  id = "shop-uploads-123456789012"
}
```

Cada tipo de recurso documenta qual é o id de importação: o nome para um grupo de logs, o nome para um
bucket, o ARN para um tópico, a URL para uma fila. Sem blocos `resource` escritos ainda,
`-generate-config-out` pede ao Terraform que os escreva a partir do que encontrar:

```
ana@laptop:~/aws/tf7/rebuilt$ terraform plan -generate-config-out=generated.tf -no-color | grep -E '^Plan:|generated'
  # (config will be generated)
  # (config will be generated)
Plan: 2 to import, 0 to add, 0 to change, 0 to destroy.
generated configuration format may change in future versions.
Terraform has generated configuration and written it to generated.tf. Please
ana@laptop:~/aws/tf7/rebuilt$ cat generated.tf | grep -v -E "^ *#|= null$" | head -24

resource "aws_cloudwatch_log_group" "web" {
  deletion_protection_enabled = false
  name                        = "/shop/web"
  region                      = "sa-east-1"
  retention_in_days           = 14
  skip_destroy                = false
  tags                        = {}
  tags_all                    = {}
}

resource "aws_s3_bucket" "uploads" {
  bucket              = "shop-uploads-123456789012"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
  region              = "sa-east-1"
  tags                = {}
  tags_all            = {}
}
```

`2 to import`, e um arquivo de blocos de recurso escrito a partir das respostas da própria conta. O
arquivo gerado define cada argumento, inclusive padrões que ninguém escreveria à mão
(`skip_destroy = false`, `force_destroy = false`), e é um rascunho: **leia, apague o que só repete um
padrão e compare com o que a equipe quis**, porque ele descreve o recurso como ele é, com erros e tudo.
Depois o `terraform apply` registra as importações, e o estado existe de novo.

Só dois dos quatro recursos da loja são importados aqui. Para o tópico do SNS e a tabela do DynamoDB,
o moto devolve zeros em atributos que a AWS preenche, e os blocos gerados falhariam na validação com
valores que nenhum tópico real tem; contra a AWS, os mesmos dois blocos `import` funcionam como estes.

## Qual saída, e quando

| o que sobrou | a saída |
|---|---|
| uma versão do estado no bucket | copiá-la por cima (seção anterior) |
| uma cópia do `terraform state pull` | `terraform state push` |
| nada, mas os recursos existem | blocos `import`, recurso por recurso |

Importar é a mais lenta das três e a única que não precisa de preparação anterior, e por isso a
próxima seção é sobre garantir que ela nunca seja a única disponível.
