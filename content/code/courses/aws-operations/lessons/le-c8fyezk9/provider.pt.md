---
title: O provider, e de quem são as credenciais que ele usa
version: 1
---

O `iac` ensinou o Terraform contra o moto desde a primeira lição: providers, estado, um backend remoto
e uma trava. Esta lição e a próxima tratam da parte que só aparece quando o provider aponta para uma
conta real que outras pessoas também mudam: com a identidade de quem o Terraform age, onde mora o
estado e como ele é protegido. O Terraform vai para `~/.local/bin`, na versão que o `iac` usou:

```sh
cd ~/aws
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
```

Num computador Arm o arquivo é `terraform_1.16.4_linux_arm64.zip`.

```
ana@laptop:~/aws/tf/bootstrap$ terraform version
Terraform v1.16.4
on linux_amd64
```

## De onde vêm as credenciais

O bloco do provider desta lição não nomeia chave nenhuma, e não deve. O provider da AWS procura
credenciais numa ordem fixa, a mesma da linha de comando da AWS, e fica com a primeira que encontra:

1. **variáveis de ambiente**: `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`, que é como este curso lhe
   dá o par `test` do moto;
2. **um perfil** em `~/.aws/config` e `~/.aws/credentials`, escolhido com `AWS_PROFILE` ou com
   `profile` no bloco; com o IAM Identity Center, `aws sso login` preenche o perfil com credenciais de
   vida curta, que a lição 11 de `aws-foundations` configura;
3. **o papel da própria máquina**: um instance profile do EC2, um papel de tarefa do ECS, o papel de um
   projeto do CodeBuild, que é como uma esteira deve rodar o Terraform.

**Uma chave escrita no bloco do provider é uma chave no repositório**, e o repositório sobrevive a toda
rotação. A ordem acima é o motivo de ela nunca ser necessária: no notebook o perfil fornece
credenciais, na esteira o papel fornece.

## O provider da loja

```hcl
# shop/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true

  default_tags {
    tags = {
      team       = "shop"
      managed-by = "terraform"
    }
  }
}

resource "aws_sns_topic" "alerts" {
  name = "shop-alerts"
}
```

`s3_use_path_style` é para o moto: faz o provider endereçar um bucket como `localhost:4567/bucket` em
vez de `bucket.localhost:4567`. Contra a AWS ele fica de fora. O endpoint em si vem de
`AWS_ENDPOINT_URL`, a variável que a linha de comando usa, e que o provider também lê.

**`default_tags` põe as mesmas tags em cada recurso que o provider cria** e que aceita tags, sem nada
escrito recurso a recurso:

```
ana@laptop:~/aws/tf/shop$ terraform apply -auto-approve -input=false -no-color | grep -E '^(aws_|Apply)'
aws_sns_topic.alerts: Creating...
aws_sns_topic.alerts: Creation complete after 0s [id=arn:aws:sns:sa-east-1:123456789012:shop-alerts]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/tf/shop$ aws sns list-tags-for-resource --resource-arn arn:aws:sns:sa-east-1:123456789012:shop-alerts --query 'Tags[].[Key,Value]' --output text
team	shop
managed-by	terraform
```

O tópico foi criado com duas tags que ninguém escreveu nele. A lição 24 é sobre por que cada recurso
precisa de um dono a quem possa ser atribuído; este bloco é o jeito mais barato de ter um, porque não
dá para criar um recurso por este provider sem ele.

## Um papel por ambiente

Equipes com várias contas (produção, homologação, uma sandbox por pessoa) costumam rodar uma
configuração do Terraform por conta, com o provider assumindo um papel em cada uma:

```hcl
provider "aws" {
  region = "sa-east-1"
  assume_role {
    role_arn = "arn:aws:iam::210987654321:role/terraform-deploy"
  }
}
```

As credenciais achadas pela ordem acima são usadas só para assumir esse papel, e tudo o que o Terraform
faz na conta é feito como o papel, que é o que o CloudTrail registra na lição 20. Esse bloco não foi
executado aqui: ele precisa de uma segunda conta para onde apontar.
