---
title: The state keeps every value in plain text
version: 1
---

A reasonable next thought is that the trouble came from a person typing the password. If Terraform
generates it, nobody types it, nobody commits it, and there is nothing to leak. Ana tries that: a
`random_password` makes the password, and AWS Secrets Manager stores it, where the application can
fetch it:

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

resource "random_password" "db" {
  length = 20
}

resource "aws_secretsmanager_secret" "db" {
  name = "shop/db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}
```

```
ana@laptop:~/shop/secrets$ terraform apply -auto-approve -no-color | grep -E "^Plan|^Apply"
Plan: 3 to add, 0 to change, 0 to destroy.
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Nobody typed anything. The state has it anyway, twice:

```
ana@laptop:~/shop/secrets$ jq ".resources[] | {type, result: .instances[0].attributes.result, secret_string: .instances[0].attributes.secret_string}" terraform.tfstate
{
  "type": "aws_secretsmanager_secret",
  "result": null,
  "secret_string": null
}
{
  "type": "aws_secretsmanager_secret_version",
  "result": null,
  "secret_string": "f6agby3@{ahN7&Q7FdG1"
}
{
  "type": "random_password",
  "result": "f6agby3@{ahN7&Q7FdG1",
  "secret_string": null
}
```

**The generated password is in the state in plain text**, once as the `result` of
`random_password` and once as the `secret_string` it was copied into. And it is not there because
Terraform failed to notice that it is secret. The state lists, for each resource, the attributes
its provider declared sensitive:

```
ana@laptop:~/shop/secrets$ jq -c ".resources[] | {type, sensitive: [.instances[0].sensitive_attributes[][].value]}" terraform.tfstate
{"type":"aws_secretsmanager_secret","sensitive":[]}
{"type":"aws_secretsmanager_secret_version","sensitive":["secret_binary","secret_string","secret_string_wo"]}
{"type":"random_password","sensitive":["bcrypt_hash","result"]}
```

Terraform knows. It uses that list to keep the values off the screen, and writes the values
beside it all the same.

## Why the state has to keep them

The state is how Terraform compares (lesson 7). To decide whether a later plan has anything to do,
it needs the value it last wrote, and for `random_password` that is the point of the resource: the
password is stored so that the next run reuses it instead of generating a new one every time.
Whatever a provider returns for a resource goes into the state, and a provider returns what it was
given.

**Reading a secret puts it there too.** Ana's application configuration does not create the
password; it only needs to look it up, with a data source (lesson 5):

```hcl
data "aws_secretsmanager_secret_version" "db" {
  secret_id  = aws_secretsmanager_secret.db.id
  depends_on = [aws_secretsmanager_secret_version.db]
}
```

```
ana@laptop:~/shop/secrets$ terraform apply -auto-approve -no-color | grep -E "^data|^Apply"
data.aws_secretsmanager_secret_version.db: Reading...
data.aws_secretsmanager_secret_version.db: Read complete after 0s [id=arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/db-LuGmIM|AWSCURRENT]
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/secrets$ jq ".resources[] | select(.mode == \"data\") | .instances[0].attributes.secret_string" terraform.tfstate
"f6agby3@{ahN7&Q7FdG1"
```

Same value, a third time, from a configuration that only read it. A team that keeps its passwords
carefully in a secret manager, and reads them into Terraform with data sources, has copied every
one of them into a state file.

## What follows

**A state is as secret as the most secret value in it.** For the shop's network in lesson 7 that
was a map of the account; with a database in it, it is the database. Everybody who can read the
bucket can read the password, along with every old version that versioning has kept, which was
the point of versioning and is now also the problem.

So the order of the defences matters. Protecting the state comes last, in "protecting-state",
because it guards whatever got in. Before that, the better move is to stop the value getting in at
all, and there are two ways: give Terraform a value it is not allowed to keep, or do not give it
the value. The next two sections take them in turn.
