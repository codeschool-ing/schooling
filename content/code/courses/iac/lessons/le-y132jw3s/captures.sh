#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of iac, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# The AWS in these sessions is moto, emulated on the laptop (lab.sh says how),
# and it starts empty on every run. Ids and ARNs that AWS invents are random,
# and so is every password random_password or RDS generates, so a second run
# prints different ones. The password ana types, s3cr3t-Shop-2026, is made up
# for the lesson and is the same on every run.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the files ana wrote (put below), whose contents the lesson shows in full,
#     and the edits she makes to them with sed, which the lesson shows as the
#     changed lines;
#   - her git commits, made quietly, including the one that commits
#     terraform.tfvars by mistake in "where-they-leak";
#   - every terraform init and tofu init, whose output lessons 2 and 17 show;
#   - the passphrase OpenTofu encrypts the state with, exported as
#     TF_VAR_state_passphrase before "protecting-state" the way a pipeline
#     would hand it over from its own secret store. The lesson says so.
#
# OpenTofu's default registry is registry.opentofu.org and the lab's provider
# mirror is filed under registry.terraform.io, so the configuration tofu runs
# names its provider by the full address. The lesson says so in one sentence.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'

tfinit() { # an init whose failure is loud, since every transcript after it depends on it
  terraform init -input=false >/dev/null 2>&1 || { echo "##### FAILED: terraform init in $PWD"; exit 1; }
}

mkdir -p shop && cd shop

block where-they-leak
put main.tf <<'CODE'
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

variable "db_password" {
  type        = string
  description = "The password the shop's application uses for its database."
}

data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  user_data     = <<-EOT
    #!/bin/sh
    echo "DB_PASSWORD=${var.db_password}" > /etc/shop.env
  EOT
  tags = { Name = "web" }
}
CODE
put terraform.tfvars <<'CODE'
db_password = "s3cr3t-Shop-2026"
CODE
put .gitignore <<'CODE'
.terraform/
*.tfstate
*.tfstate.*
CODE
tfinit
# STAGED: the commit that carried the tfvars file, made weeks before.
quiet 'git init -q && git add . && git commit -qm "web server with its database password"'
block leak-git
run 'git ls-files'
run 'git log --oneline'
block leak-git-rm
run 'git rm -q --cached terraform.tfvars && echo "*.tfvars" >> .gitignore'
run 'git commit -qam "stop tracking terraform.tfvars" && git log --oneline'
run 'git show HEAD~1:terraform.tfvars'
block leak-plan
run 'terraform plan -no-color | grep -A 3 "+ user_data  "'
block leak-planfile
run 'terraform plan -out=tfplan > /dev/null'
run 'unzip -l tfplan | tail -n +4 | head -n -2'
run 'unzip -p tfplan | grep -a -c s3cr3t-Shop-2026'
quiet 'rm -f tfplan'

block sensitive-var
run "sed -i 's/^  type        = string\$/  type        = string\n  sensitive   = true/' main.tf"
run 'sed -n "/^variable/,/^}/p" main.tf'
block sensitive-plan
run 'terraform plan -no-color | grep -E "user_data  |^Plan"'
block sensitive-output-error
put outputs.tf <<'CODE'
output "db_password" {
  value = var.db_password
}
CODE
run 'terraform plan'
block sensitive-output
put outputs.tf <<'CODE'
output "db_password" {
  value     = var.db_password
  sensitive = true
}
CODE
run 'terraform apply -auto-approve | tail -n 4'
block sensitive-read
run 'terraform output'
run 'terraform output -raw db_password; echo'
run 'terraform output -json'
block sensitive-state
run 'grep -c s3cr3t-Shop-2026 terraform.tfstate'
run 'jq -r ".resources[] | select(.type == \"aws_instance\") | .instances[0].attributes.user_data" terraform.tfstate'
quiet 'git add . && git commit -qm "mark the password sensitive"'

block in-the-state
mkdir -p ~/shop/secrets && cd ~/shop/secrets
put main.tf <<'CODE'
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
CODE
tfinit
block state-apply
run 'terraform apply -auto-approve -no-color | grep -E "^Plan|^Apply"'
block state-jq
run 'jq ".resources[] | {type, result: .instances[0].attributes.result, secret_string: .instances[0].attributes.secret_string}" terraform.tfstate'
block state-sensitive-attrs
run 'jq -c ".resources[] | {type, sensitive: [.instances[0].sensitive_attributes[][].value]}" terraform.tfstate'
block state-data
put read.tf <<'CODE'
data "aws_secretsmanager_secret_version" "db" {
  secret_id  = aws_secretsmanager_secret.db.id
  depends_on = [aws_secretsmanager_secret_version.db]
}
CODE
run 'terraform apply -auto-approve -no-color | grep -E "^data|^Apply"'
run 'jq ".resources[] | select(.mode == \"data\") | .instances[0].attributes.secret_string" terraform.tfstate'
quiet 'rm read.tf'
quiet 'terraform destroy -auto-approve'
quiet 'aws secretsmanager delete-secret --secret-id shop/db --force-delete-without-recovery'

block ephemeral
mkdir -p ~/shop/secrets-wo && cd ~/shop/secrets-wo
put main.tf <<'CODE'
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
CODE
tfinit
block wo-list
run 'terraform providers schema -json | jq -r ".provider_schemas[].resource_schemas | to_entries[] | select(any(.value.block.attributes[]; .write_only == true)) | .key"'
block ephemeral-error
run 'terraform plan'
block ephemeral-wo
run "sed -i 's/^  secret_string = ephemeral.random_password.db.result\$/  secret_string_wo         = ephemeral.random_password.db.result\n  secret_string_wo_version = 1/' main.tf"
run 'sed -n "/aws_secretsmanager_secret_version/,/^}/p" main.tf'
block ephemeral-apply
run 'terraform apply -auto-approve'
block ephemeral-state
run 'terraform state list'
run 'jq ".resources[] | select(.type == \"aws_secretsmanager_secret_version\") | .instances[0].attributes | {secret_string, secret_string_wo, secret_string_wo_version}" terraform.tfstate'
run 'aws secretsmanager get-secret-value --secret-id shop/db --query "[VersionId, SecretString]" --output text'
block ephemeral-again
run 'terraform plan | tail -n 3'
block ephemeral-rotate
run "sed -i 's/secret_string_wo_version = 1/secret_string_wo_version = 2/' main.tf"
run 'terraform apply -auto-approve -no-color | grep -E "secret_string_wo_version|^Plan|^Apply"'
run 'aws secretsmanager get-secret-value --secret-id shop/db --query "[VersionId, SecretString]" --output text'

block secret-managers
mkdir -p ~/shop/db && cd ~/shop/db
put main.tf <<'CODE'
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
CODE
tfinit
block db-plan
run 'terraform plan -no-color | grep -E "manage_master_user_password|  password|master_user_secret|^Plan"'
block db-apply
run 'terraform apply -auto-approve | tail -n 4'
block db-state
run 'jq ".resources[] | select(.type == \"aws_db_instance\") | .instances[0].attributes | {password, password_wo, master_user_secret}" terraform.tfstate'
block db-read
run 'aws secretsmanager list-secrets --query "SecretList[].Name" --output text'
run 'aws secretsmanager get-secret-value --secret-id "$(terraform output -raw db_secret_arn)" --query SecretString --output text | jq keys'
block db-policy
run 'jq -r ".resources[] | select(.type == \"aws_iam_policy\") | .instances[0].attributes.policy" terraform.tfstate | jq .Statement'

block protecting-state
mkdir -p ~/shop/tofu && cd ~/shop/tofu
put main.tf <<'CODE'
terraform {
  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.7"
    }
  }
}

resource "random_password" "db" {
  length = 20
}
CODE
quiet 'tofu init -input=false'
block tofu-plain
run 'tofu apply -auto-approve -no-color | grep -E "^Apply"'
run 'jq -r ".resources[0].instances[0].attributes.result" terraform.tfstate'
block tofu-encrypt
put encryption.tf <<'CODE'
variable "state_passphrase" {
  type      = string
  sensitive = true
}

terraform {
  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.passphrase
    }

    method "unencrypted" "migrate" {}

    state {
      method = method.aes_gcm.state

      fallback {
        method = method.unencrypted.migrate
      }
    }
  }
}
CODE
# STAGED: the passphrase, the way a pipeline hands it over from its secret store.
export TF_VAR_state_passphrase='lantern-orbit-velvet-quarry-2026'
run 'tofu apply -auto-approve -no-color | grep -E "^Apply"'
block tofu-file
run 'jq "keys" terraform.tfstate'
run 'jq -r ".encrypted_data" terraform.tfstate | cut -c 1-64'
run 'grep -c "\"result\"" terraform.tfstate'
run 'jq -r ".meta[]" terraform.tfstate | base64 -d; echo'
block tofu-read
run 'tofu state list'
run 'tofu plan | tail -n 3'
block tofu-no-fallback
put encryption.tf <<'CODE'
variable "state_passphrase" {
  type      = string
  sensitive = true
}

terraform {
  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.passphrase
    }

    state {
      method = method.aes_gcm.state
    }
  }
}
CODE
run 'sed -n "/state {/,/^    }/p" encryption.tf'
run 'tofu plan | tail -n 3'
block tofu-wrong
run "TF_VAR_state_passphrase='a-different-passphrase-entirely' tofu plan"
block tofu-terraform
run 'terraform init'
mkdir -p ~/shop/tofu-copy && cd ~/shop/tofu-copy
run 'cp ../tofu/terraform.tfstate . && terraform state list'
