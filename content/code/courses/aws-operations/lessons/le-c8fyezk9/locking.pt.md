---
title: A trava, a tabela, e o arquivo que a substituiu
version: 1
---

Dois applies gravando o mesmo estado no mesmo instante perdem uma das duas gravações, e a lição 7 de
`iac` mostrou o segundo apply recusado por uma trava. Na AWS a trava viveu por anos numa **tabela do
DynamoDB**: antes de gravar, o Terraform põe um item com o caminho do estado como chave, com a condição
de não existir item igual, e o apaga depois. Desde o Terraform 1.10 o backend pode travar com **um
arquivo no mesmo bucket**, usando as gravações condicionais do S3, e a tabela agora está depreciada.
Uma equipe na AWS encontra as duas, e precisa passar de uma para a outra sem nenhum momento sem trava.

## A tabela

O backend que nomeia a tabela:

```hcl
# dynamodb/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    dynamodb_table = "shop-tflocks"
  }
}
```

```
ana@laptop:~/aws/tf/shop$ terraform init -input=false -no-color | sed -n '/Warning/,/instead/p'
Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
instead.
```

Depreciado, e ainda funcionando. Com um apply esperando no prompt em outro terminal, a trava é um item
na tabela:

```
ana@laptop:~/aws/tf/shop$ aws dynamodb scan --table-name shop-tflocks --query 'Items[].Info.S' --output text | jq .
{
  "ID": "7ff338c3-b61a-0cb9-3bba-2898e38b6fc6",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "root@vm",
  "Version": "1.16.4",
  "Created": "2026-10-16T16:14:36.695112232Z",
  "Path": "shop-tfstate-123456789012/shop/terraform.tfstate"
}
```

`Who` nomeia o usuário e a máquina que pegaram a trava (aqui, a máquina em que as transcrições foram
gravadas, como `root@vm`), e `Created` diz desde quando. Um segundo plan, de qualquer lugar, é recusado
com o mesmo registro:

```
ana@laptop:~/aws/tf/shop$ terraform plan -lock-timeout=0s -no-color 2>&1 | sed -n '/Error: Error acquiring/,$p'
Error: Error acquiring the state lock

Error message: operation error DynamoDB: PutItem, https response error
StatusCode: 400, RequestID:
dNydrC0WGKgVI72hPGxZltPQeZMFf2sZjBaX8ZI7YImnJNLiI878,
ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        7ff338c3-b61a-0cb9-3bba-2898e38b6fc6
  Path:      shop-tfstate-123456789012/shop/terraform.tfstate
  Operation: OperationTypeApply
  Who:       root@vm
  Version:   1.16.4
  Created:   2026-10-16 16:14:36.695112232 +0000 UTC
  Info:      


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

`ConditionalCheckFailedException` é o DynamoDB dizendo que o item já existe, e esse é o mecanismo
inteiro: **uma trava é uma gravação que só funciona quando a de mais ninguém está lá**.

## Passando para o arquivo de trava

A migração são dois releases, para não haver momento sem ninguém travando. Primeiro, os dois:

```hcl
# both/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
    dynamodb_table = "shop-tflocks"
  }
}
```

```
ana@laptop:~/aws/tf/shop$ terraform init -input=false -reconfigure -no-color | grep -E 'Warning|Successfully|deprecated'
Successfully configured the backend "s3"! Terraform will automatically
Warning: Deprecated Parameter
The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
```

Com os dois definidos, o Terraform pega as duas travas, então um colega ainda na configuração antiga e
outro na nova se excluem. Segure a trava de novo e olhe no bucket e na tabela:

```
ana@laptop:~/aws/tf/shop$ aws s3 ls s3://shop-tfstate-123456789012/shop/
2026-10-16 13:14:33       2827 terraform.tfstate
2026-10-16 13:14:42        224 terraform.tfstate.tflock
ana@laptop:~/aws/tf/shop$ aws dynamodb scan --table-name shop-tflocks --query 'Items[].LockID.S' --output text
shop-tfstate-123456789012/shop/terraform.tfstate	shop-tfstate-123456789012/shop/terraform.tfstate-md5
```

O estado tem um vizinho, `terraform.tfstate.tflock`, e a tabela também guarda o item de trava. O
segundo item dela, terminado em `-md5`, não é trava: o backend do DynamoDB guarda ali o checksum do
último estado que gravou, para que uma leitura que devolva uma cópia mais antiga do objeto seja
percebida em vez de usada. Quando o apply termina, o arquivo vai embora:

```
ana@laptop:~/aws/tf/shop$ aws s3 ls s3://shop-tfstate-123456789012/shop/
2026-10-16 13:14:33       2827 terraform.tfstate
```

Quando a configuração de todo mundo tiver os dois, o segundo release tira a tabela:

```hcl
# lockfile/backend.tf
terraform {
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
  }
}
```

```
ana@laptop:~/aws/tf/shop$ terraform init -input=false -reconfigure -no-color | grep -E 'Warning|Successfully'
Successfully configured the backend "s3"! Terraform will automatically
```

Nenhum aviso. A tabela pode ser apagada depois que a última configuração que a nomeia sumir, e a
configuração de bootstrap perde seu penúltimo recurso.

## Quando uma trava fica para trás

Um notebook que fecha no meio de um apply deixa a trava: o item na tabela, ou o arquivo `.tflock`. O
Terraform recusa todo plan seguinte, com razão, porque não consegue distinguir uma trava abandonada de
uma viva. **`terraform force-unlock <ID>` a remove**, com o ID que a recusa imprimiu, e só é seguro
depois de confirmar com a pessoa em `Who` que o apply dela não está mais rodando. Um force-unlock
durante um apply vivo é exatamente o acidente dos dois escritores que a trava existe para evitar.
