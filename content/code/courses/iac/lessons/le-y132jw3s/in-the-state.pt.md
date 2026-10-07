---
title: O estado guarda todo valor em texto puro
version: 2
---

Uma conclusão razoável a esta altura é que o problema veio de uma pessoa digitando a senha. Se o Terraform
a gerar, ninguém digita, ninguém commita, e não há nada para vazar. A Ana tenta isso: um
`random_password` cria a senha, e o AWS Secrets Manager a guarda, onde a aplicação pode buscá-la.
`~/shop/secrets/main.tf`:

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

Ninguém digitou nada. O estado tem a senha mesmo assim, duas vezes:

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
  "secret_string": "(?9)(nP+eyR49qE-tz<s"
}
{
  "type": "random_password",
  "result": "(?9)(nP+eyR49qE-tz<s",
  "secret_string": null
}
```

**A senha gerada está no estado em texto puro**, uma vez como o `result` do `random_password` e outra
como o `secret_string` para onde ela foi copiada. E ela não está lá porque o Terraform deixou de
perceber que é secreta. O estado lista, para cada recurso, os atributos que o provider declarou
sensitive:

```
ana@laptop:~/shop/secrets$ jq -c ".resources[] | {type, sensitive: [.instances[0].sensitive_attributes[][].value]}" terraform.tfstate
{"type":"aws_secretsmanager_secret","sensitive":[]}
{"type":"aws_secretsmanager_secret_version","sensitive":["secret_binary","secret_string","secret_string_wo"]}
{"type":"random_password","sensitive":["bcrypt_hash","result"]}
```

O Terraform sabe. Ele usa essa lista para manter os valores fora da tela, e grava os valores ao lado
dela do mesmo jeito.

## Por que o estado precisa guardá-los

O estado é como o Terraform compara (aula 7). Para decidir se um plan futuro tem algo a fazer, ele
precisa do valor que gravou por último. Para o `random_password`, esse é o propósito do recurso: a
senha fica guardada para que a próxima execução a reaproveite em vez de gerar uma nova a cada vez.
O que um provider devolve para um recurso vai para o estado, e um provider devolve o que recebeu.

**Ler um segredo também o coloca lá.** A configuração da aplicação da Ana não cria a senha; só
precisa consultá-la, com um data source (aula 5), aqui em `read.tf`, ao lado do `main.tf`:

```hcl
data "aws_secretsmanager_secret_version" "db" {
  secret_id  = aws_secretsmanager_secret.db.id
  depends_on = [aws_secretsmanager_secret_version.db]
}
```

```
ana@laptop:~/shop/secrets$ terraform apply -auto-approve -no-color | grep -E "^data|^Apply"
data.aws_secretsmanager_secret_version.db: Reading...
data.aws_secretsmanager_secret_version.db: Read complete after 0s [id=arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/db-kXEiPh|AWSCURRENT]
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/secrets$ jq ".resources[] | select(.mode == \"data\") | .instances[0].attributes.secret_string" terraform.tfstate
"(?9)(nP+eyR49qE-tz<s"
```

O mesmo valor, pela terceira vez, vindo de uma configuração que só o leu. Um time que guarda as
senhas com cuidado num gerenciador de segredos, e as lê para o Terraform com data sources, copiou
todas elas para um arquivo de estado.

## O que vem daí

**Um estado é tão secreto quanto o valor mais secreto que ele contém.** Para a rede da loja na aula
7, isso era um mapa da conta; com um banco dentro, é o banco. Todo mundo que consegue ler o bucket
consegue ler a senha, junto com cada versão antiga que o versionamento guardou, que era o propósito
do versionamento e agora também é o problema.

Então a ordem das defesas importa. Proteger o estado vem por último, em "protecting-state", porque
guarda o que quer que tenha entrado. Antes disso, o melhor caminho é impedir que o valor entre, e
há dois jeitos: dar ao Terraform um valor que ele não tem permissão de guardar, ou não dar o valor a
ele. As duas próximas seções tratam de cada um.

Antes de seguir, a Ana desmonta este experimento, porque a próxima seção cria um secret com o mesmo
nome:

```sh
rm read.tf
terraform destroy -auto-approve
aws secretsmanager delete-secret --secret-id shop/db --force-delete-without-recovery
```

O último comando é necessário porque o `destroy` só agenda a exclusão de um secret, como a AWS faz,
e um secret à espera de exclusão continua ocupando o nome.
