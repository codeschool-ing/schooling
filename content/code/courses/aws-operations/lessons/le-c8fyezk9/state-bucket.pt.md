---
title: O bucket de estado, que precisa existir primeiro
version: 1
---

Um backend remoto guarda o estado num bucket, e a lição 7 de `iac` o pôs lá. Duas perguntas que ela
não precisou responder vêm primeiro numa conta real: **quem cria o bucket**, e **o que o bucket precisa
garantir**, dado que ele guarda o único registro do que o Terraform gerencia e, muitas vezes, segredos
em texto puro dentro desse registro.

## O ovo e a galinha

O bucket não pode ser criado pela configuração cujo estado ele vai guardar: essa configuração precisa
do bucket antes do primeiro `init`. As respostas comuns são uma configuração pequena e separada, com
estado **local**, aplicada uma vez e raramente tocada, ou uma stack do CloudFormation feita por quem
monta a conta. A loja usa a primeira:

```hcl
# bootstrap/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true
}

resource "aws_s3_bucket" "state" {
  bucket = "shop-tfstate-123456789012"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = "shop-tflocks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

Cada recurso é uma garantia:

- o **versionamento** guarda cada estado anterior como uma versão mais antiga do mesmo objeto, e é o
  que torna o acidente da lição 7 sobrevivível;
- a **criptografia com uma chave do KMS** (lição 18) significa que ler o objeto exige permissão na
  chave além do bucket, uma segunda porta na frente dos segredos que o estado guarde;
- o **bloqueio de acesso público** torna impossível aplicar por engano uma política ou ACL pública;
- **`prevent_destroy`** faz o Terraform recusar qualquer plano que apague o bucket, inclusive um
  `terraform destroy` rodado no diretório errado.

A tabela é para a trava da próxima seção. Aplicado:

```
ana@laptop:~/aws/tf/bootstrap$ terraform apply -auto-approve -input=false -no-color | grep -E '^(aws_|Apply)'
aws_s3_bucket.state: Creating...
aws_dynamodb_table.locks: Creating...
aws_s3_bucket.state: Creation complete after 0s [id=shop-tfstate-123456789012]
aws_s3_bucket_versioning.state: Creating...
aws_s3_bucket_public_access_block.state: Creating...
aws_s3_bucket_server_side_encryption_configuration.state: Creating...
aws_s3_bucket_public_access_block.state: Creation complete after 0s [id=shop-tfstate-123456789012]
aws_s3_bucket_server_side_encryption_configuration.state: Creation complete after 0s [id=shop-tfstate-123456789012]
aws_s3_bucket_versioning.state: Creation complete after 1s [id=shop-tfstate-123456789012]
aws_dynamodb_table.locks: Creation complete after 6s [id=shop-tflocks]
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/tf/bootstrap$ aws s3api get-bucket-versioning --bucket shop-tfstate-123456789012
{
    "Status": "Enabled"
}
ana@laptop:~/aws/tf/bootstrap$ aws s3api get-public-access-block --bucket shop-tfstate-123456789012 --query PublicAccessBlockConfiguration
{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
}
```

O `terraform.tfstate` local desta configuração pequena é o único arquivo de estado que mora fora do
bucket. Não faça commit de nada dele, guarde uma cópia num lugar seguro, e espere mexer nele mais ou
menos uma vez por ano.

## Quem pode lê-lo

As permissões do bucket decidem quem pode ler cada valor que o Terraform guardou, incluindo qualquer
senha de banco que um recurso tenha devolvido. **Acesso de leitura ao bucket de estado é acesso de
leitura aos segredos da produção**, então ele pertence ao papel da esteira e às poucas pessoas que rodam
o Terraform à mão, e uma política de bucket recusando o que não vem por TLS, como o CDK escreveu na
lição 5, também cabe nele. A lição 12 de `iac` é sobre manter segredos fora do estado, que é a metade
melhor da resposta.
