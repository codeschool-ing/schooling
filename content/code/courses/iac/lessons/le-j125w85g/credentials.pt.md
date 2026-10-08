---
title: Credenciais sem chave no repositório
version: 2
---

O jeito óbvio de deixar um pipeline entrar na AWS é o errado: criar um usuário IAM, gerar uma
access key e colá-la nos secrets do repositório como `AWS_ACCESS_KEY_ID` e
`AWS_SECRET_ACCESS_KEY`. Funciona de primeira. **A chave então vive até alguém rotacioná-la,
funciona de qualquer computador do mundo e pode ser lida por todo workflow capaz de citar o
secret.** Basta um passo que imprima o ambiente num log, ou uma dependência que a mande para algum
lugar, e a chave é de outra pessoa por todo o tempo em que ninguém perceber.

## Provar quem você é, a cada job

A federação OpenID Connect elimina a chave guardada. O serviço de CI já sabe exatamente a qual
repositório, branch e environment um job pertence, e pode afirmar isso num token que ele assina. A
AWS é instruída uma vez a confiar nesse emissor, e cada role diz quais tokens podem assumi-lo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma sequência entre três partes: o job no runner, o emissor de tokens do GitHub e o AWS STS. Um: o job pede um token ao GitHub. Dois: o GitHub assina um token cujo subject nomeia o repositório e o environment. Três: o job envia o token ao STS e pede para assumir o role shop-apply. Quatro: o STS confere a assinatura com o provedor registrado, e a audience e o subject com a trust policy do role. Cinco: o STS devolve credenciais que expiram dentro de uma hora.\"><defs><marker id=\"oi-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"20\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o job, no runner</text><path d=\"M110 56 L110 285\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"265\" y=\"20\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o emissor de tokens do GitHub</text><path d=\"M360 56 L360 285\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"515\" y=\"20\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AWS STS</text><path d=\"M610 56 L610 285\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M110 85 L358 85\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"235.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1  um token, por favor</text><path d=\"M360 125 L112 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"235.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2  um token assinado</text><text x=\"235.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">sub: repo:example/shop:environment:production</text><path d=\"M110 170 L608 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3  este token, para o role shop-apply</text><text x=\"600.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4  assinatura, aud e sub</text><text x=\"600.0\" y=\"216.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">conferidos com a trust policy</text><path d=\"M610 255 L112 255\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"360.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5  credenciais temporárias, uma hora no máximo</text></svg>", "caption": "Nenhuma chave fica guardada em lugar nenhum: cada job prova quem é com um token que o GitHub assina para aquela execução, e sai com credenciais que expiram dentro de uma hora.", "same": ["AWS STS"]}
```

Nada secreto fica guardado em lugar nenhum. O token é emitido para um job, as credenciais que ele
compra expiram dentro de uma hora, e uma cópia vazada num log vale pouco na manhã seguinte. No
workflow do GitHub, `id-token: write` é a permissão que deixa um job pedir o token, e a
`configure-aws-credentials` faz os passos 1, 3 e 5. No GitLab, o `id_tokens` põe o token numa
variável; o `before_script` o grava num arquivo, e o SDK da AWS dentro do provider vê
`AWS_ROLE_ARN` e `AWS_WEB_IDENTITY_TOKEN_FILE` e faz a troca sozinho.

## Dois roles, e o que cada um pode fazer

O lado da AWS também é Terraform, numa configuração própria que um administrador aplica uma vez.
Ela não pode ser aplicada pelo pipeline para o qual cria os roles. A Ana a guarda em
`~/ci-roles/main.tf`, fora do repositório da loja:

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

locals {
  repo   = "repo:example/shop"
  bucket = "arn:aws:s3:::shop-tfstate-123456789012"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Who may become each role: a job of this repository, and for apply
# only a job running in the production environment.
data "aws_iam_policy_document" "trust" {
  for_each = {
    plan  = ["${local.repo}:pull_request", "${local.repo}:ref:refs/heads/main"]
    apply = ["${local.repo}:environment:production"]
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "ci" {
  for_each             = data.aws_iam_policy_document.trust
  name                 = "shop-${each.key}"
  assume_role_policy   = each.value.json
  max_session_duration = 3600
}

# plan reads the network and the state, and writes only the lock file
resource "aws_iam_role_policy" "plan" {
  name = "plan"
  role = aws_iam_role.ci["plan"].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:Describe*"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = local.bucket },
      { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${local.bucket}/shop/*" },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.bucket}/shop/terraform.tfstate.tflock"
      },
    ]
  })
}

# apply changes the network and writes the state
resource "aws_iam_role_policy" "apply" {
  name = "apply"
  role = aws_iam_role.ci["apply"].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:*"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = local.bucket },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.bucket}/shop/*"
      },
    ]
  })
}
```

```
ana@laptop:~/ci-roles$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

As linhas importantes são as condições sobre o `sub`, o claim que diz para qual job o token foi
emitido. Eis a trust policy do role de apply como a AWS a guarda:

```
ana@laptop:~/ci-roles$ aws iam get-role --role-name shop-apply --query Role.AssumeRolePolicyDocument
{
    "Statement": [
        {
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:example/shop:environment:production"
                }
            },
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
            }
        }
    ],
    "Version": "2012-10-17"
}
ana@laptop:~/ci-roles$ aws iam list-role-policies --role-name shop-plan --output text
POLICYNAMES	plan
```

**O role de apply só confia num job que roda no environment `production`**, e um job só entra nesse
environment depois que alguém da revisão o aprova. Então a aprovação e o direito de escrever são o
mesmo portão: uma execução não aprovada não consegue obter credenciais que mudem alguma coisa, diga
o YAML dela o que disser. O role de plan confia em pull requests e em pushes na `main`, e só pode
ler: a rede, o state, e uma escrita que surpreende muita gente, o objeto `.tflock` que o
`use_lockfile` da aula 7 põe ao lado do state. Um plan também trava o state, então um role de plan
"só de leitura" que não pode escrever essa chave não consegue fazer plan.

Só leitura importa por um motivo que vai além da arrumação. **Um plan roda código do pull
request.** Providers executam durante um plan, e um data source como o `external` roda o programa
que ele nomear, então quem consegue abrir um pull request consegue fazer o `plan` agir com as
credenciais do role de plan. É por isso que essas credenciais devem poder ler e nada mais, e é por
isso que o GitHub não entrega os secrets de um repositório a um pull request vindo de um fork.

Na AWS de verdade, o `ReadOnlyAccess` é o atalho comum para o role de plan. O moto do laboratório
não carrega as políticas gerenciadas da AWS, então as leituras estão escritas aqui uma a uma, e
ficam mais estreitas de qualquer forma: `ec2:Describe*` e o state, que é tudo contra o que esta
configuração faz plan.

Dois limites do laboratório, ditos com clareza. O moto guarda a trust policy e **não a avalia**: ele
entregaria credenciais a qualquer token, então esta aula consegue mostrar a política que a AWS
guarda, e não a AWS recusando um job da branch errada. E o provedor mostrado confia no GitHub; para
o GitLab, a mesma configuração registra `https://gitlab.com` como emissor e compara um `sub` como
`project_path:example/shop:ref_type:branch:ref:main`.
