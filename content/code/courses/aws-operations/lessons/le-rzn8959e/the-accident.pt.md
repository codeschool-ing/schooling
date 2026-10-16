---
title: O acidente, passo a passo
version: 1
---

O arquivo de estado é a memória do Terraform sobre o que ele fez. **Perdê-lo não apaga nada na nuvem;
faz o Terraform esquecer que fez**, e um Terraform que esqueceu vai tentar fazer tudo de novo. Esta
lição encena o acidente de propósito, para que a saída seja algo que você já fez uma vez antes de
precisar.

A configuração da loja tem quatro recursos, com o estado no bucket que a lição 6 montou:

```hcl
# shop/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true
}

resource "aws_sns_topic" "alerts" {
  name = "shop-alerts"
}

resource "aws_dynamodb_table" "orders" {
  name         = "shop-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/shop/web"
  retention_in_days = 14
}

resource "aws_s3_bucket" "uploads" {
  bucket = "shop-uploads-123456789012"
}
```

```
ana@laptop:~/aws/tf7/shop$ terraform apply -auto-approve -input=false -no-color | grep -E '^(Apply|Outputs)'
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/tf7/shop$ terraform state list
aws_cloudwatch_log_group.web
aws_dynamodb_table.orders
aws_s3_bucket.uploads
aws_sns_topic.alerts
```

## O acidente

Alguém arrumando o bucket de estado apaga o que parece um arquivo velho:

```
ana@laptop:~/aws/tf7/shop$ aws s3 rm s3://shop-tfstate-123456789012/shop/terraform.tfstate
delete: s3://shop-tfstate-123456789012/shop/terraform.tfstate
```

Nada na conta mudou: o tópico, a tabela, o grupo de logs e o bucket continuam lá, atendendo tráfego.
Pergunte ao Terraform:

```
ana@laptop:~/aws/tf7/shop$ terraform plan -no-color | grep -E '^  # |^Plan:'
  # aws_cloudwatch_log_group.web will be created
  # aws_dynamodb_table.orders will be created
  # aws_s3_bucket.uploads will be created
  # aws_sns_topic.alerts will be created
Plan: 4 to add, 0 to change, 0 to destroy.
```

**Quatro para adicionar.** O Terraform lê o estado, não encontra nada e conclui que nenhum dos quatro
existe. O plan é calmo e errado, e é idêntico ao plan de uma conta vazia.

## O que aplicá-lo faria

A próxima pessoa a rodar a esteira não lê o plan com cuidado:

```
ana@laptop:~/aws/tf7/shop$ terraform apply -auto-approve -input=false -no-color 2>&1 | grep -E '^(aws_.*(complete|Creating)|Error:)' 
aws_cloudwatch_log_group.web: Creating...
aws_s3_bucket.uploads: Creating...
aws_sns_topic.alerts: Creating...
aws_dynamodb_table.orders: Creating...
aws_sns_topic.alerts: Creation complete after 0s [id=arn:aws:sns:sa-east-1:123456789012:shop-alerts]
Error: creating AWS DynamoDB Table (shop-orders): operation error DynamoDB: CreateTable, https response error StatusCode: 400, RequestID: raRO4kfrfB1RajNvqFMUbADigUh7KFbS44GgTeSPdFoHvsSeTL4Q, ResourceInUseException: Table already exists: shop-orders
Error: creating CloudWatch Logs Log Group (/shop/web): operation error CloudWatch Logs: CreateLogGroup, https response error StatusCode: 400, RequestID: I8QTPzPT6LB55jXymliGEgaNyEJJlPvTsbp8BuUXU1SguhqEyLi0, ResourceAlreadyExistsException: The specified log group already exists
Error: creating S3 Bucket (shop-uploads-123456789012): operation error S3: CreateBucket, https response error StatusCode: 409, RequestID: NRhyDYuqLlymd5pVI5DIf9jKdsG6mgDYZnahjzLCarzHSBf8wTL7, HostID: 9Gjjt1m+cjU4OPvX9O9/8RuvnG41MRb/18Oux2o5H5MY7ISNTlXN+Dz9IG62/ILVxhAGI0qyPfg=, BucketAlreadyOwnedByYou: Your previous request to create the named bucket succeeded and you already own it.
ana@laptop:~/aws/tf7/shop$ terraform state list
aws_sns_topic.alerts
```

Leia os resultados um a um, porque eles diferem, e a diferença é o perigo:

- **o tópico foi adotado em silêncio**: criar um tópico do SNS com um nome que existe devolve o tópico
  existente, então o Terraform o registrou como feito, e nada parece errado;
- **a tabela, o grupo de logs e o bucket falharam**, cada um com o "já existe" do próprio serviço.

O estado agora tem um recurso de quatro. Todo plan seguinte vai tentar criar três coisas que existem,
e falhar do mesmo jeito, até alguém consertar o registro. Uma versão pior do mesmo acidente acontece
com um recurso que **não tem nome**, como uma regra de security group ou uma instância EC2: a criação
funciona, e a conta passa a ter dois, um que o Terraform gerencia e um que ninguém gerencia.

**A regra é curta: quando um plan quer criar algo que você sabe que existe, pare.** Ele nunca está
dizendo que o recurso sumiu. Está dizendo que o estado sumiu.
