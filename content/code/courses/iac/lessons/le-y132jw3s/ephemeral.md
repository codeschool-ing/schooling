---
title: Values that are never written down
version: 2
---

Terraform 1.10 added a kind of value the state never sees, and 1.11 added the place to put it. An
**ephemeral** value exists for the length of one run: it is produced when Terraform needs it,
handed to whatever needs it, and dropped, and it is written neither to the plan file nor to the
state. A **write-only argument** is an argument of a resource that accepts such a value, passes it
to the provider during the apply, and keeps no record of it afterwards. Lesson 1 installed
Terraform 1.16.4, so your lab has both.

An ephemeral value comes from one of two places. An ephemeral **resource** produces one: the random
provider has `ephemeral "random_password"`, and the AWS provider has ephemeral resources that read a
secret out of Secrets Manager or Parameter Store for the length of a run. And a variable declared
with `ephemeral = true` is one, for a value that arrives from outside, through `TF_VAR_` or `-var`.

Ana rewrites the configuration from the last section in a new directory, `~/shop/secrets-wo`, with
the password made by an ephemeral resource. Her first attempt at `main.tf` keeps the same argument:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

ephemeral "random_password" "db" {
  length = 20
}

resource "aws_secretsmanager_secret" "db" {
  name = "shop/db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = ephemeral.random_password.db.result
}
```

```
ana@laptop:~/shop/secrets-wo$ terraform plan
╷
│ Error: Invalid use of ephemeral value
│ 
│   with aws_secretsmanager_secret_version.db,
│   on main.tf line 28, in resource "aws_secretsmanager_secret_version" "db":
│   28:   secret_string = ephemeral.random_password.db.result
│ 
│ Ephemeral values are not valid for "secret_string", because it is not a
│ write-only attribute and must be persisted to state.
╵
```

The message is the rule. **An ephemeral value may not go anywhere that is persisted**, and an
ordinary argument is persisted, so Terraform refuses before planning anything. What the value can
go into is a write-only argument, and the resource has one, named like the argument it replaces
with `_wo` on the end:

```
ana@laptop:~/shop/secrets-wo$ sed -i 's/^  secret_string = ephemeral.random_password.db.result$/  secret_string_wo         = ephemeral.random_password.db.result\n  secret_string_wo_version = 1/' main.tf
ana@laptop:~/shop/secrets-wo$ sed -n "/aws_secretsmanager_secret_version/,/^}/p" main.tf
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string_wo         = ephemeral.random_password.db.result
  secret_string_wo_version = 1
}
```

The run opens the ephemeral resource and closes it again while planning, because an ephemeral value
is produced fresh whenever it is needed, and the plan prints `(write-only attribute)` where the
value would be. The apply opens it once more, around the resource that consumes it:

```
ana@laptop:~/shop/secrets-wo$ terraform apply -auto-approve
ephemeral.random_password.db: Opening...
ephemeral.random_password.db: Opening complete after 0s
ephemeral.random_password.db: Closing...
ephemeral.random_password.db: Closing complete after 0s
```

```
  # aws_secretsmanager_secret_version.db will be created
  + resource "aws_secretsmanager_secret_version" "db" {
      + arn                      = (known after apply)
      + has_secret_string_wo     = (known after apply)
      + id                       = (known after apply)
      + region                   = "sa-east-1"
      + secret_arn               = (known after apply)
      + secret_id                = (known after apply)
      + secret_string_wo         = (write-only attribute)
      + secret_string_wo_version = 1
      + version_id               = (known after apply)
      + version_stages           = (known after apply)
    }
```

```
Plan: 2 to add, 0 to change, 0 to destroy.
ephemeral.random_password.db: Opening...
ephemeral.random_password.db: Opening complete after 0s
aws_secretsmanager_secret.db: Creating...
aws_secretsmanager_secret.db: Creation complete after 0s [id=arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/db-DbkrLp]
aws_secretsmanager_secret_version.db: Creating...
aws_secretsmanager_secret_version.db: Creation complete after 0s [id=arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/db-DbkrLp|terraform-NMPEy8K6cBHWa6IhrzMm6DaUuU]
ephemeral.random_password.db: Closing...
ephemeral.random_password.db: Closing complete after 0s

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Now the state, and then AWS:

```
ana@laptop:~/shop/secrets-wo$ terraform state list
aws_secretsmanager_secret.db
aws_secretsmanager_secret_version.db
ana@laptop:~/shop/secrets-wo$ jq ".resources[] | select(.type == \"aws_secretsmanager_secret_version\") | .instances[0].attributes | {secret_string, secret_string_wo, secret_string_wo_version}" terraform.tfstate
{
  "secret_string": "",
  "secret_string_wo": null,
  "secret_string_wo_version": 1
}
ana@laptop:~/shop/secrets-wo$ aws secretsmanager get-secret-value --secret-id shop/db --query "[VersionId, SecretString]" --output text
terraform-NMPEy8K6cBHWa6IhrzMm6DaUuU	ngOV9>cMQsdK[39k8ZBf
```

`random_password` is not in the state any more, because an ephemeral resource never is.
`secret_string` is empty and `secret_string_wo` is null: **the password reached AWS and nothing on
Ana's disk**. Secrets Manager holds it, under the version id the provider created.

## The price: Terraform cannot see it

A value that is not kept cannot be compared. The ephemeral resource generated a new password on the
second run as well, and the plan said nothing:

```
ana@laptop:~/shop/secrets-wo$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

Terraform does not know what the stored value is, so it cannot know whether it changed. That is
what `secret_string_wo_version` is for: a plain number, kept in the state, which Terraform does
compare. The write-only value is sent when the resource is created and whenever the number changes.
Rotating the password is an edit somebody can review in a pull request:

```
ana@laptop:~/shop/secrets-wo$ sed -i 's/secret_string_wo_version = 1/secret_string_wo_version = 2/' main.tf
ana@laptop:~/shop/secrets-wo$ terraform apply -auto-approve -no-color | grep -E "secret_string_wo_version|^Plan|^Apply"
      ~ secret_string_wo_version = 1 -> 2 # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
ana@laptop:~/shop/secrets-wo$ aws secretsmanager get-secret-value --secret-id shop/db --query "[VersionId, SecretString]" --output text
terraform-9rdFy781rAK0qcHNgidIkxlMLx	ddj$V9fsVCL:ojD1srEg
```

For this resource the new number replaces the version object, which is how Secrets Manager stores a
new value, and AWS now holds a different password. The same blindness applies to drift (lesson 7):
if somebody changes the secret by hand, no plan will notice, because there is nothing in the state
to compare it with.

## Where write-only arguments exist

Only where a provider has written one. In version 6.67.0 of the AWS provider, the one these lessons
were recorded with, that is a short list. Yours is the newest 6.x on the day you ran
`terraform init`, since the configuration asks for `~> 6.0`, and a newer one may list more:

```
ana@laptop:~/shop/secrets-wo$ terraform providers schema -json | jq -r ".provider_schemas[].resource_schemas | to_entries[] | select(any(.value.block.attributes[]; .write_only == true)) | .key"
aws_acm_certificate
aws_bedrockagentcore_api_key_credential_provider
aws_db_instance
aws_docdb_cluster
aws_elasticache_replication_group
aws_elasticache_user
aws_kms_ciphertext
aws_rds_cluster
aws_redshift_cluster
aws_redshiftserverless_namespace
aws_secretsmanager_secret_version
aws_ssm_parameter
aws_transfer_host_key
```

The database, the database cluster, the parameter, the secret version: the arguments that are
passwords in the obvious places. Anything outside the list still keeps what it is given, and a
data source still writes what it reads, so check the resource's documentation for a `_wo` argument
before assuming the state is clean.
