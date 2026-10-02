---
title: Valores que nunca são anotados
version: 1
---

O Terraform 1.10 trouxe um tipo de valor que o estado nunca vê, e o 1.11 trouxe o lugar onde
colocá-lo. Um valor **efêmero** (*ephemeral*) existe durante uma execução: é produzido quando o
Terraform precisa dele, entregue a quem precisa, e descartado, sem ser gravado nem no arquivo de plan
nem no estado. Um **argumento write-only** é um argumento de um recurso que aceita um valor assim,
repassa-o ao provider durante o apply e não guarda registro dele depois. O laboratório roda o
Terraform 1.16.4, então os dois estão aqui.

Um valor efêmero vem de um de dois lugares. Um **recurso** efêmero produz um: o provider random tem
`ephemeral "random_password"`, e o provider da AWS tem recursos efêmeros que leem um segredo do
Secrets Manager ou do Parameter Store durante uma execução. E uma variável declarada com
`ephemeral = true` é um, para um valor que chega de fora, por `TF_VAR_` ou `-var`.

A Ana reescreve a configuração da seção anterior num diretório novo, com a senha feita por um recurso
efêmero. A primeira tentativa mantém o mesmo argumento:

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

A mensagem é a regra. **Um valor efêmero não pode ir para nenhum lugar que seja persistido**, e um
argumento comum é persistido, então o Terraform recusa antes de planejar qualquer coisa. O valor pode
ir para um argumento write-only, e o recurso tem um, com o nome do argumento que ele substitui e
`_wo` no fim:

```
ana@laptop:~/shop/secrets-wo$ sed -i 's/^  secret_string = ephemeral.random_password.db.result$/  secret_string_wo         = ephemeral.random_password.db.result\n  secret_string_wo_version = 1/' main.tf
ana@laptop:~/shop/secrets-wo$ sed -n "/aws_secretsmanager_secret_version/,/^}/p" main.tf
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string_wo         = ephemeral.random_password.db.result
  secret_string_wo_version = 1
}
```

A execução abre o recurso efêmero e o fecha de novo durante o planejamento, porque um valor efêmero é
produzido do zero sempre que é necessário, e o plan imprime `(write-only attribute)` onde o valor
estaria. O apply o abre mais uma vez, em volta do recurso que o consome:

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
aws_secretsmanager_secret.db: Creation complete after 0s [id=arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/db-gEukTM]
aws_secretsmanager_secret_version.db: Creating...
aws_secretsmanager_secret_version.db: Creation complete after 0s [id=arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/db-gEukTM|terraform-hiC47oIDWpnzGYtchiJzyfQ2Lu]
ephemeral.random_password.db: Closing...
ephemeral.random_password.db: Closing complete after 0s

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Agora o estado, e depois a AWS:

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
terraform-hiC47oIDWpnzGYtchiJzyfQ2Lu	%<wUfcy(acJ7?dzO5+7>
```

O `random_password` não está mais no estado, porque um recurso efêmero nunca está. O
`secret_string` está vazio e o `secret_string_wo` é null: **a senha chegou à AWS e a nada no disco da
Ana**. O Secrets Manager a guarda, sob o id de versão que o provider criou.

## O preço: o Terraform não consegue vê-la

Um valor que não é guardado não pode ser comparado. O recurso efêmero gerou uma senha nova também na
segunda execução, e o plan não disse nada:

```
ana@laptop:~/shop/secrets-wo$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

O Terraform não sabe qual é o valor guardado, então não tem como saber se ele mudou. É para isso que
serve o `secret_string_wo_version`: um número comum, guardado no estado, que o Terraform compara sim.
O valor write-only é enviado quando o recurso é criado e sempre que o número muda. Trocar a senha vira
uma edição que alguém pode revisar num pull request:

```
ana@laptop:~/shop/secrets-wo$ sed -i 's/secret_string_wo_version = 1/secret_string_wo_version = 2/' main.tf
ana@laptop:~/shop/secrets-wo$ terraform apply -auto-approve -no-color | grep -E "secret_string_wo_version|^Plan|^Apply"
      ~ secret_string_wo_version = 1 -> 2 # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
ana@laptop:~/shop/secrets-wo$ aws secretsmanager get-secret-value --secret-id shop/db --query "[VersionId, SecretString]" --output text
terraform-snxSG0E3KnvUNSPVrhawUmDqYK	<SO_P*Ns)0nuBxX@FxwB
```

Neste recurso, o número novo substitui o objeto de versão, que é como o Secrets Manager guarda um
valor novo, e a AWS agora tem outra senha. A mesma cegueira vale para o drift (aula 7): se alguém
mudar o segredo à mão, nenhum plan vai perceber, porque não há nada no estado com que comparar.

## Onde existem argumentos write-only

Só onde um provider escreveu um. No provider da AWS do laboratório, a lista é curta:

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

O banco, o cluster de banco, o parâmetro, a versão do secret: os argumentos que são senhas nos
lugares óbvios. Tudo o que está fora da lista continua guardando o que recebe, e um data source
continua gravando o que lê, então procure um argumento `_wo` na documentação do recurso antes de
supor que o estado está limpo.
