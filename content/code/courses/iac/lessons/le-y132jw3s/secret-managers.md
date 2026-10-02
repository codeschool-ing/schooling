---
title: Letting AWS generate and hold the password
version: 1
---

A write-only argument still has Terraform holding the password for a moment, and still has it
choosing the password and deciding when it changes. For a database there is a cleaner arrangement:
**the database service generates the password itself, keeps it in Secrets Manager, and Terraform
never sees it at all.** On RDS that is one argument, `manage_master_user_password`.

Ana's database for the shop, with no password anywhere in the file:

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

There is no `password` argument and no variable for one. The plan has nothing to print in its
place, only the request and an attribute that will be known later:

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

db_secret_arn = "arn:aws:secretsmanager:sa-east-1:123456789012:secret:rds!db-4f7fbe3d-8f65-4fdd-85d6-0171c918addf-loSgBQ"
```

The output is not marked sensitive, and does not need to be: an ARN says where a secret is, and
reading it still takes a permission. In the state, the database's `password` is null, and what RDS
reported back is the secret's ARN and the KMS key it is encrypted with:

```
ana@laptop:~/shop/db$ jq ".resources[] | select(.type == \"aws_db_instance\") | .instances[0].attributes | {password, password_wo, master_user_secret}" terraform.tfstate
{
  "password": null,
  "password_wo": null,
  "master_user_secret": [
    {
      "kms_key_id": "arn:aws:kms:sa-east-1:123456789012:key/e08148b2-9cf8-4859-b517-9b6607d63adf",
      "secret_arn": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:rds!db-4f7fbe3d-8f65-4fdd-85d6-0171c918addf-loSgBQ",
      "secret_status": "active"
    }
  ]
}
```

## Who holds the password now

RDS created a secret of its own in Secrets Manager, next to the `shop/db` that "ephemeral" left
behind:

```
ana@laptop:~/shop/db$ aws secretsmanager list-secrets --query "SecretList[].Name" --output text
shop/db	rds!db-4f7fbe3d-8f65-4fdd-85d6-0171c918addf
ana@laptop:~/shop/db$ aws secretsmanager get-secret-value --secret-id "$(terraform output -raw db_secret_arn)" --query SecretString --output text | jq keys
[
  "password",
  "username"
]
```

The second command is what the application does when it starts: it asks Secrets Manager for the
secret by its ARN and gets back a small JSON document with the user name and the password. Here
`jq keys` prints only the field names, which is the habit to keep when checking that a secret is
there without putting it on a screen.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three parties. Terraform creates the database and asks RDS to manage its password. RDS generates the password and keeps it in AWS Secrets Manager. The state receives only the secret's ARN. At runtime the application, allowed by an IAM policy naming that ARN, reads the password from Secrets Manager. The password never passes through Terraform.\"><defs><marker id=\"mg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"mg-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Terraform</text><text x=\"115.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">creates the database</text><rect x=\"20\" y=\"180\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the state</text><text x=\"115.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only the ARN</text><rect x=\"300\" y=\"30\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">RDS</text><text x=\"380.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">generates the password</text><rect x=\"300\" y=\"180\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Secrets Manager</text><text x=\"380.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">holds the password</text><rect x=\"540\" y=\"180\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the application</text><text x=\"620.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads it at runtime</text><path d=\"M212 60 L298 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-phosphor)\"></path><text x=\"255.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--phosphor)\">manage_master_user_password</text><path d=\"M115 92 L115 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-phosphor)\"></path><text x=\"160.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">secret_arn</text><path d=\"M380 92 L380 178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-amber)\"></path><text x=\"440.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the password</text><path d=\"M538 210 L462 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-wire)\"></path><text x=\"500.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">secretsmanager:GetSecretValue</text></svg>", "caption": "A managed password: AWS generates it and holds it, and Terraform only ever sees where it is."}
```

**The application can only ask if something lets it.** The configuration also created the policy that
does, naming that one secret and that one action, and nothing else:

```
ana@laptop:~/shop/db$ jq -r ".resources[] | select(.type == \"aws_iam_policy\") | .instances[0].attributes.policy" terraform.tfstate | jq .Statement
[
  {
    "Action": "secretsmanager:GetSecretValue",
    "Effect": "Allow",
    "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:rds!db-4f7fbe3d-8f65-4fdd-85d6-0171c918addf-loSgBQ"
  }
]
```

Attached to the role the application runs as (lesson 15 builds roles like it for a pipeline), that
policy is the whole of the access. Somebody who can read the state learns where the password is
and, without that permission, cannot read it.

## What this buys, and what it costs

Look back at the four copies from "where-they-leak". The password is in none of them: not in git,
not in a plan, not in a plan file, not in the state. Changing it does not need an apply either,
because RDS and Secrets Manager rotate it between themselves, and every read is an AWS API call
that a real account records in CloudTrail. Moto keeps no such log, so this lab cannot show it.

The cost moves to the application. It has to fetch the secret at start, cope with the call failing,
and fetch it again after a rotation instead of keeping the first value for ever. AWS publishes
caching clients for several languages that do exactly this. Where a service has no managed option, the same
shape still works by hand: a secret in Secrets Manager or a `SecureString` in Parameter Store,
written by a write-only argument or by whoever owns the value, and read by the application at
runtime. **Terraform's job becomes saying which secret exists and who may read it**, which are
facts worth reviewing in a pull request, and not the secret itself.
