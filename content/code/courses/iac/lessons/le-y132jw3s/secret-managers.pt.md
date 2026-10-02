---
title: Deixar a AWS gerar e guardar a senha
version: 1
---

Um argumento write-only ainda deixa a senha nas mãos do Terraform por um instante, e ainda é ele quem
a escolhe e decide quando ela muda. Para um banco de dados existe um arranjo mais limpo: **o próprio
serviço de banco gera a senha, guarda-a no Secrets Manager, e o Terraform nunca a vê.** No RDS isso é
um argumento, `manage_master_user_password`.

O banco da Ana para a loja, sem senha em lugar nenhum do arquivo:

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

resource "aws_db_instance" "shop" {
  identifier                  = "shop"
  engine                      = "postgres"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  username                    = "shop"
  manage_master_user_password = true
  skip_final_snapshot         = true
}

data "aws_iam_policy_document" "read_db_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.shop.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "read_db_secret" {
  name   = "shop-read-db-secret"
  policy = data.aws_iam_policy_document.read_db_secret.json
}

output "db_secret_arn" {
  value = aws_db_instance.shop.master_user_secret[0].secret_arn
}
```

Não há argumento `password` nem variável para ele. O plan não tem nada para imprimir no lugar, só o
pedido e um atributo que vai ser conhecido depois:

```
ana@laptop:~/shop/db$ terraform plan -no-color | grep -E "manage_master_user_password|  password|master_user_secret|^Plan"
      + manage_master_user_password           = true
      + master_user_secret                    = (known after apply)
      + master_user_secret_kms_key_id         = (known after apply)
Plan: 2 to add, 0 to change, 0 to destroy.
```

```
ana@laptop:~/shop/db$ terraform apply -auto-approve | tail -n 4

Outputs:

db_secret_arn = "arn:aws:secretsmanager:sa-east-1:123456789012:secret:rds!db-2a952c72-39f9-4294-8d6c-f41b50db2586-mXIrIx"
```

O output não está marcado como sensitive, e não precisa estar: um ARN diz onde um segredo está, e
lê-lo continua exigindo uma permissão. No estado, o `password` do banco é null, e o que o RDS
devolveu foi o ARN do secret e a chave KMS com que ele é cifrado:

```
ana@laptop:~/shop/db$ jq ".resources[] | select(.type == \"aws_db_instance\") | .instances[0].attributes | {password, password_wo, master_user_secret}" terraform.tfstate
{
  "password": null,
  "password_wo": null,
  "master_user_secret": [
    {
      "kms_key_id": "arn:aws:kms:sa-east-1:123456789012:key/9b1c52f5-c868-4a45-9513-6a4ca85d79df",
      "secret_arn": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:rds!db-2a952c72-39f9-4294-8d6c-f41b50db2586-mXIrIx",
      "secret_status": "active"
    }
  ]
}
```

## Quem guarda a senha agora

O RDS criou um secret próprio no Secrets Manager, ao lado do `shop/db` que a seção "ephemeral"
deixou para trás:

```
ana@laptop:~/shop/db$ aws secretsmanager list-secrets --query "SecretList[].Name" --output text
shop/db	rds!db-2a952c72-39f9-4294-8d6c-f41b50db2586
ana@laptop:~/shop/db$ aws secretsmanager get-secret-value --secret-id "$(terraform output -raw db_secret_arn)" --query SecretString --output text | jq keys
[
  "password",
  "username"
]
```

O segundo comando é o que a aplicação faz quando sobe: pede o secret ao Secrets Manager pelo ARN e
recebe um pequeno documento JSON com o nome de usuário e a senha. Aqui o `jq keys` imprime só os nomes
dos campos, que é o hábito a manter quando se confere que um segredo existe sem colocá-lo numa tela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três partes. O Terraform cria o banco e pede ao RDS que gerencie a senha. O RDS gera a senha e a guarda no AWS Secrets Manager. O estado recebe só o ARN do secret. Em tempo de execução, a aplicação, autorizada por uma política IAM que nomeia esse ARN, lê a senha no Secrets Manager. A senha nunca passa pelo Terraform.\"><defs><marker id=\"mg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"mg-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Terraform</text><text x=\"115.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cria o banco</text><rect x=\"20\" y=\"180\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o estado</text><text x=\"115.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só o ARN</text><rect x=\"300\" y=\"30\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">RDS</text><text x=\"380.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gera a senha</text><rect x=\"300\" y=\"180\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Secrets Manager</text><text x=\"380.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guarda a senha</text><rect x=\"540\" y=\"180\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a aplicação</text><text x=\"620.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê na execução</text><path d=\"M212 60 L298 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-phosphor)\"></path><text x=\"255.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--phosphor)\">manage_master_user_password</text><path d=\"M115 92 L115 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-phosphor)\"></path><text x=\"160.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">secret_arn</text><path d=\"M380 92 L380 178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-amber)\"></path><text x=\"440.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a senha</text><path d=\"M538 210 L462 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-wire)\"></path><text x=\"500.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">secretsmanager:GetSecretValue</text></svg>", "caption": "Uma senha gerenciada: a AWS a gera e a guarda, e o Terraform só enxerga onde ela está.", "same": ["Terraform", "RDS", "Secrets Manager"]}
```

A aplicação só consegue pedir se alguma coisa deixar. A configuração também criou a política que
deixa, nomeando esse único secret e essa única ação, e nada mais:

```
ana@laptop:~/shop/db$ jq -r ".resources[] | select(.type == \"aws_iam_policy\") | .instances[0].attributes.policy" terraform.tfstate | jq .Statement
[
  {
    "Action": "secretsmanager:GetSecretValue",
    "Effect": "Allow",
    "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:rds!db-2a952c72-39f9-4294-8d6c-f41b50db2586-mXIrIx"
  }
]
```

Anexada ao role com que a aplicação roda (a aula 15 monta roles parecidos para um pipeline), essa
política é todo o acesso. Quem consegue ler o estado descobre onde a senha está e, sem essa
permissão, não consegue lê-la.

## O que isso compra, e o que custa

Volte às quatro cópias de "where-they-leak". A senha não está em nenhuma: nem no git, nem num plan,
nem num arquivo de plan, nem no estado. Trocá-la também não exige um apply, porque o RDS e o Secrets
Manager fazem a rotação entre si, e cada leitura é uma chamada à API da AWS que uma conta real
registra no CloudTrail. O moto não mantém esse log, então este laboratório não consegue mostrá-lo.

O custo passa para a aplicação. Ela precisa buscar o segredo ao subir, lidar com a chamada falhando,
e buscá-lo de novo depois de uma rotação em vez de guardar o primeiro valor para sempre. A AWS publica
clientes com cache para várias linguagens que fazem exatamente isso. Onde um serviço não tem opção
gerenciada, a mesma forma funciona à mão: um secret no Secrets Manager ou um `SecureString` no
Parameter Store, gravado por um argumento write-only ou por quem for dono do valor, e lido pela
aplicação em tempo de execução. **O trabalho do Terraform passa a ser dizer qual segredo existe e
quem pode lê-lo**, fatos que vale revisar num pull request, e não o segredo em si.
